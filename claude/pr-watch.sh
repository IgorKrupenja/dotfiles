#!/bin/bash

# Usage: pr-watch.sh <owner/repo> <number> [since]
# Polls a pull request's reviews and state (never its CI) every 60 seconds and exits on the first
# event the Claude app's Auto-fix does not report: an approval newer than `since` from someone other
# than the author, a merge, a close, a drop from the merge queue, or, with auto-merge off, a head
# commit that was not ready at start turning ready to merge (a merge state flicker on the same head
# never counts). Run it as a background task and re-arm it with the event's time as `since`.

set -u

repo="$1"
number="$2"
since="${3:-$(date -u +%Y-%m-%dT%H:%M:%SZ)}"
owner="${repo%/*}"
name="${repo#*/}"
query='query($o:String!,$n:String!,$p:Int!){repository(owner:$o,name:$n){pullRequest(number:$p){state mergedAt closedAt headRefOid reviewDecision mergeStateStatus autoMergeRequest{enabledAt} author{login} mergeQueueEntry{state} reviews(last:50,states:[APPROVED]){nodes{author{login} submittedAt}}}}}'

failures=0
in_queue=false
left_queue_polls=0
first_poll=true
ready_head=""

while true; do
  if ! json=$(gh api graphql -f query="$query" -F o="$owner" -F n="$name" -F p="$number" 2>&1); then
    if [[ "$json" == *"Could not resolve to a"* ]]; then
      echo "PR #$number not found in $repo"
      exit 1
    fi
    failures=$((failures + 1))
    if ((failures >= 30)); then
      echo "PR #$number watcher stopped after 30 failed polls: $json"
      exit 1
    fi
    sleep 60
    continue
  fi
  failures=0
  pr=$(jq -c '.data.repository.pullRequest' <<<"$json")
  state=$(jq -r '.state // "MISSING"' <<<"$pr")

  case "$state" in
    MERGED)
      echo "PR #$number MERGED at $(jq -r '.mergedAt' <<<"$pr")"
      exit 0
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
      echo "PR #$number LEFT THE MERGE QUEUE without merging"
      exit 0
    fi
  fi

  ready=$(jq -r '.reviewDecision == "APPROVED" and .mergeStateStatus == "CLEAN" and .autoMergeRequest == null' <<<"$pr")
  head=$(jq -r '.headRefOid' <<<"$pr")
  if [[ "$ready" == true ]]; then
    if [[ "$first_poll" == false && "$head" != "$ready_head" ]]; then
      echo "PR #$number READY to merge at ${head:0:9}: approved, checks green, auto-merge off"
      exit 0
    fi
    ready_head="$head"
  fi
  first_poll=false

  sleep 60
done
