#!/bin/zsh
# shellcheck shell=bash

# Cleans Docker in OrbStack every 14 days, as liqd-casino worktree stacks grew it to 487 GB in five
# weeks. Removes the stacks of worktrees that are gone (containers, volumes, networks), then images,
# stopped containers and build cache unused for a week, and the anonymous volumes and networks
# nothing uses. Stacks of worktrees that still exist keep their volumes, and so does the shared
# liqd-shared stack.
#
# launchd starts it daily (launchd/com.igorkrupenja.dotfiles.docker-cleanup.plist) and it does
# nothing until 14 days have passed since the last cleanup. A due run that finds a container, a
# compose watcher or a build running changes nothing and tries again the next day.
#
#   docker-cleanup.sh            clean if due
#   docker-cleanup.sh --now      clean now
#   docker-cleanup.sh --dry-run  show what a cleanup would remove

export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH"

REPO=$HOME/Projects/liqd-casino
SHARED_PROJECT=liqd-shared
STAMP=$HOME/.local/state/dotfiles/docker-cleanup
INTERVAL_DAYS=14
UNUSED_FOR=168h
LABEL=com.docker.compose.project

log() {
  echo "$(date '+%Y-%m-%d %H:%M') $*"
}

notify() {
  osascript -e "display notification \"$1\" with title \"Docker cleanup\" sound name \"$2\""
}

days_since_cleanup() {
  echo $((($(date +%s) - $(cat "$STAMP")) / 86400))
}

# Prints why cleaning now is unsafe, or nothing when it is safe
busy_reason() {
  local running
  if [[ $(orb status 2>/dev/null) != Running ]]; then
    echo "OrbStack isn't running"
  elif ! running=$(docker ps -q 2>&1); then
    echo "Docker isn't answering"
  elif [[ -n $running ]]; then
    echo "containers are running"
  elif pgrep -f 'docker[- ]compose .*(watch|up|build)|buildx|docker build' >/dev/null; then
    echo "a compose watcher or build is running"
  fi
}

# Compose project names of the liqd-casino worktrees, as scripts/stack.mts derives them
worktree_projects() {
  git -C "$REPO" worktree list --porcelain 2>/dev/null | sed -n 's/^worktree //p' | while read -r dir; do
    basename "$dir" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g'
  done
}

# Compose projects with containers or volumes whose worktree is gone. Prints nothing when the
# worktrees can't be listed, so a missing checkout never takes every stack's data with it
orphan_projects() {
  local keep project
  keep=$(worktree_projects)
  [[ -n $keep ]] || return 0
  keep=$(printf '%s\n%s' "$keep" "$SHARED_PROJECT")
  {
    docker ps -a --format "{{.Label \"$LABEL\"}}"
    docker volume ls --format "{{.Label \"$LABEL\"}}"
  } | sort -u | while read -r project; do
    if [[ -n $project ]] && ! grep -qxF "$project" <<<"$keep"; then
      echo "$project"
    fi
  done
}

remove_project() {
  local filter="label=$LABEL=$1" ids
  ids=$(docker ps -aq --filter "$filter")
  [[ -z $ids ]] || echo "$ids" | xargs docker rm -v >/dev/null || return 1
  ids=$(docker volume ls -q --filter "$filter")
  [[ -z $ids ]] || echo "$ids" | xargs docker volume rm >/dev/null || return 1
  ids=$(docker network ls -q --filter "$filter")
  [[ -z $ids ]] || echo "$ids" | xargs docker network rm >/dev/null || return 1
}

cleanup() {
  local failed=() project
  docker system df
  for project in $(orphan_projects); do
    log "Removing stack $project, its worktree is gone"
    remove_project "$project" || failed+=("$project")
  done
  docker container prune -f --filter "until=$UNUSED_FOR" || failed+=(containers)
  docker image prune -af --filter "until=$UNUSED_FOR" || failed+=(images)
  docker builder prune -af --filter "until=$UNUSED_FOR" || failed+=("build cache")
  docker volume prune -f || failed+=(volumes)
  docker network prune -f --filter "until=$UNUSED_FOR" || failed+=(networks)
  docker system df

  if [[ ${#failed[@]} -eq 0 ]]; then
    date +%s >"$STAMP"
    log "Cleanup complete"
    notify "Cleanup complete" Ping
  else
    log "Cleanup failed: ${failed[*]}"
    notify "Failed: ${failed[*]}" Basso
    return 1
  fi
}

dry_run() {
  local reason
  reason=$(busy_reason)
  [[ -z $reason ]] || echo "A scheduled run would skip now: $reason"
  echo "Stacks whose worktree is gone, removed with their volumes:"
  orphan_projects | sed 's/^/  /'
  echo "Also pruned: images, stopped containers and build cache unused for $UNUSED_FOR, unused anonymous volumes and networks"
  docker system df
}

main() {
  local mode=due days reason
  [[ $1 == --now ]] && mode=now
  [[ $1 == --dry-run ]] && mode=dry
  mkdir -p "$(dirname "$STAMP")"
  if [[ ! -f $STAMP ]]; then
    date +%s >"$STAMP"
    if [[ $mode == due ]]; then
      log "First run, counting $INTERVAL_DAYS days from today"
      return 0
    fi
  fi
  if [[ $mode == dry ]]; then
    dry_run
    return
  fi

  days=$(days_since_cleanup)
  if [[ $mode == due && $days -lt $INTERVAL_DAYS ]]; then
    return 0
  fi
  reason=$(busy_reason)
  if [[ -n $reason ]]; then
    log "Skipped, $reason (last cleanup $days days ago)"
    [[ $mode == due && $days -ge $((INTERVAL_DAYS + 7)) ]] &&
      notify "Overdue by $((days - INTERVAL_DAYS)) days: $reason" Basso
    return 0
  fi
  log "Cleaning Docker, last cleanup $days days ago"
  cleanup
}

main "$@"
