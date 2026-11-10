#!/bin/bash

# Usage: pr-watch.sh <owner/repo> <number> [since]
# Watches a pull request for what the Claude app's Auto-fix never reports and exits on the first
# event newer than `since`, printing it with its time; re-arm it with that time as `since`.
# While the PR is open: an approval from someone other than the author, a close, a drop from the
# merge queue, or, with auto-merge off, a head commit that was not ready at start turning ready to
# merge (a merge state flicker on the same head never counts). Then the merge, and after it each
# environment the merge commit reaches: the push runs of DEPLOY_WORKFLOW (default deploy.yml) on
# DEPLOY_BRANCHES in promotion order (default "main:dev qa:qa prod:prod"), reporting a successful
# deploy, or a failed one with no retry running. It never reads the PR's own CI.

set -u

repo="$1"
number="$2"
since="${3:-$(date -u +%Y-%m-%dT%H:%M:%SZ)}"
workflow="${DEPLOY_WORKFLOW:-deploy.yml}"
branches="${DEPLOY_BRANCHES:-main:dev qa:qa prod:prod}"
owner="${repo%/*}"
name="${repo#*/}"
query='query($o:String!,$n:String!,$p:Int!){repository(owner:$o,name:$n){pullRequest(number:$p){state mergedAt closedAt headRefOid mergeCommit{oid} reviewDecision mergeStateStatus autoMergeRequest{enabledAt} author{login} mergeQueueEntry{state} reviews(last:50,states:[APPROVED]){nodes{author{login} submittedAt}}}}}'

failures=0
in_queue=false
left_queue_polls=0
first_poll=true
ready_head=""
contains_cache=$'\n'
done_branches=" "

poll_failed() {
  failures=$((failures + 1))
  if ((failures >= 30)); then
    echo "PR #$number watcher stopped after 30 failed polls: $1"
    exit 1
  fi
}

contains_merge() {
  local sha="$1" status
  case "$contains_cache" in
    *$'\n'"$sha yes"$'\n'*) return 0 ;;
    *$'\n'"$sha no"$'\n'*) return 1 ;;
  esac
  status=$(gh api "repos/$repo/compare/$merge_sha...$sha" --jq .status 2>&1) || return 2
  if [[ "$status" == ahead || "$status" == identical ]]; then
    contains_cache+="$sha yes"$'\n'
    return 0
  fi
  contains_cache+="$sha no"$'\n'
  return 1
}

check_environment() {
  local branch="$1" environment="$2" runs created id sha run_status conclusion updated url rc
  local reached=false deployed_before=false deployed="" failed="" running=false
  runs=$(gh api --paginate "repos/$repo/actions/workflows/$workflow/runs?branch=$branch&event=push&per_page=100&created=%3E%3D$runs_from" \
    --jq '.workflow_runs[] | "\(.created_at) \(.id) \(.head_sha) \(.status) \(.conclusion // "none") \(.updated_at) \(.html_url)"' 2>&1) || return 2
  runs=$(LC_ALL=C sort <<<"$runs")
  while read -r created id sha run_status conclusion updated url; do
    [[ -z "$id" ]] && continue
    if [[ "$reached" == false ]]; then
      contains_merge "$sha"
      rc=$?
      ((rc == 2)) && return 2
      ((rc == 1)) && continue
      reached=true
    fi
    if [[ "$run_status" != completed ]]; then
      running=true
    elif [[ "$conclusion" == success ]]; then
      if [[ "$updated" > "$since" ]]; then
        [[ -z "$deployed" ]] && deployed="PR #$number DEPLOYED to $environment at $updated: $url"
      else
        deployed_before=true
      fi
    elif [[ "$conclusion" =~ ^(failure|timed_out|startup_failure)$ && "$updated" > "$since" ]]; then
      failed="PR #$number DEPLOY to $environment FAILED at $updated: $url"
    fi
  done <<<"$runs"
  if [[ "$deployed_before" == true ]]; then
    environment_state=done
  elif [[ -n "$deployed" ]]; then
    environment_state=event
    environment_message="$deployed"
  elif [[ -n "$failed" && "$running" == false ]]; then
    environment_state=event
    environment_message="$failed"
  else
    environment_state=waiting
  fi
}

watch_deploys() {
  local pair branch environment interval workflow_check
  until workflow_check=$(gh api "repos/$repo/actions/workflows/$workflow" --jq .state 2>&1); do
    if [[ "$workflow_check" == *"Not Found"* ]]; then
      echo "PR #$number merged at $merged_at; $repo has no $workflow deploys to watch"
      exit 0
    fi
    poll_failed "$workflow_check"
    sleep 60
  done
  runs_from=$(jq -rn --arg t "$merged_at" '$t | fromdate - 3600 | todate')
  while true; do
    interval=60
    environment_state=done
    for pair in $branches; do
      branch="${pair%%:*}"
      environment="${pair#*:}"
      [[ "$done_branches" == *" $branch "* ]] && continue
      if ! check_environment "$branch" "$environment"; then
        poll_failed "$branch deploy runs"
        environment_state=waiting
        break
      fi
      failures=0
      case "$environment_state" in
        done)
          done_branches+="$branch "
          ;;
        event)
          echo "$environment_message"
          exit 0
          ;;
        waiting)
          [[ "$pair" != "${branches%% *}" ]] && interval=300
          break
          ;;
      esac
    done
    if [[ "$environment_state" == done ]]; then
      echo "PR #$number is deployed to every environment: $branches"
      exit 0
    fi
    sleep "$interval"
  done
}

while true; do
  if ! json=$(gh api graphql -f query="$query" -F o="$owner" -F n="$name" -F p="$number" 2>&1); then
    if [[ "$json" == *"Could not resolve to a"* ]]; then
      echo "PR #$number not found in $repo"
      exit 1
    fi
    poll_failed "$json"
    sleep 60
    continue
  fi
  failures=0
  pr=$(jq -c '.data.repository.pullRequest' <<<"$json")
  state=$(jq -r '.state // "MISSING"' <<<"$pr")

  case "$state" in
    MERGED)
      merged_at=$(jq -r '.mergedAt' <<<"$pr")
      merge_sha=$(jq -r '.mergeCommit.oid' <<<"$pr")
      if [[ "$merged_at" > "$since" ]]; then
        echo "PR #$number MERGED at $merged_at"
        exit 0
      fi
      watch_deploys
      ;;
    CLOSED)
      echo "PR #$number CLOSED without merging at $(jq -r '.closedAt' <<<"$pr")"
      exit 0
      ;;
    OPEN) ;;
    *)
      echo "PR #$number not found in $repo"
      exit 1
      ;;
  esac

  approvals=$(jq -r --arg since "$since" --arg n "$number" \
    '.author.login as $author | .reviews.nodes[]
      | select(.submittedAt > $since and .author.login != $author)
      | "PR #\($n) APPROVED by \(.author.login) at \(.submittedAt)"' <<<"$pr")
  if [[ -n "$approvals" ]]; then
    echo "$approvals"
    exit 0
  fi

  if [[ "$(jq -r '.mergeQueueEntry != null' <<<"$pr")" == true ]]; then
    in_queue=true
    left_queue_polls=0
  elif [[ "$in_queue" == true ]]; then
    left_queue_polls=$((left_queue_polls + 1))
    if ((left_queue_polls >= 2)); then
      echo "PR #$number LEFT THE MERGE QUEUE without merging at $(date -u +%Y-%m-%dT%H:%M:%SZ)"
      exit 0
    fi
  fi

  ready=$(jq -r '.reviewDecision == "APPROVED" and .mergeStateStatus == "CLEAN" and .autoMergeRequest == null' <<<"$pr")
  head=$(jq -r '.headRefOid' <<<"$pr")
  if [[ "$ready" == true ]]; then
    if [[ "$first_poll" == false && "$head" != "$ready_head" ]]; then
      echo "PR #$number READY to merge at $(date -u +%Y-%m-%dT%H:%M:%SZ) on ${head:0:9}: approved, checks green, auto-merge off"
      exit 0
    fi
    ready_head="$head"
  fi
  first_poll=false

  sleep 60
done
