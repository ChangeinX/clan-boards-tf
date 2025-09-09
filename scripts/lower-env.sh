#!/usr/bin/env bash
set -euo pipefail

# Lower environment suspend/resume helper
# - Scales ECS services to 0 on suspend; restores on resume
# - Stops/starts RDS instance (included by default)
# - Stores previous desired counts and DB identifier under scripts/.env_state/<env>.json

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
STATE_DIR="$SCRIPT_DIR/.env_state"
mkdir -p "$STATE_DIR"

ts() { date '+%Y-%m-%dT%H:%M:%S%z'; }
log() { echo "[$(ts)] [lower-env] $*"; }
warn() { echo "[$(ts)] [lower-env][warn] $*" >&2; }
err() { echo "[$(ts)] [lower-env][error] $*" >&2; exit 1; }

need_cmd() { command -v "$1" >/dev/null 2>&1 || err "Missing required command: $1"; }

usage() {
  cat <<EOF
Usage: $0 --env <dev|qa> --action <suspend|resume> [--skip-rds] [--plan-only] [--app-name <name>] [--aws-profile <profile>] [--timeout <sec>] [--interval <sec>] [--max-parallel <n>] [--sequential] [--resume-after-rds]

Examples:
  $0 --env dev --action suspend
  $0 --env dev --action resume
  $0 --env qa  --action suspend --plan-only

Options:
  --env <name>         Target environment directory under environments/ (dev or qa)
  --action <op>        Operation to perform: suspend or resume
  --skip-rds           Do not manage the RDS instance (defaults to included)
  --plan-only          Show actions without executing
  --app-name <name>    Override app name (otherwise discovered from Terraform vars)
  --aws-profile <name> Use specific AWS CLI profile
  --timeout <sec>      Max seconds to wait for each resource (default: 900)
  --interval <sec>     Seconds between status checks (default: 10)
  --max-parallel <n>   Max concurrent ECS service operations (default: 3)
  --sequential         Disable parallel operations (equivalent to --max-parallel 1)
  --resume-after-rds   Resume sequentially: start RDS and wait before ECS
EOF
}

ENV_NAME=""
ACTION=""
INCLUDE_RDS=1
PLAN_ONLY=0
APP_NAME_OVERRIDE=""
AWS_PROFILE=""
TIMEOUT_SECS=900
INTERVAL_SECS=10
MAX_PARALLEL=3
RESUME_AFTER_RDS=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --env) ENV_NAME="$2"; shift 2;;
    --action) ACTION="$2"; shift 2;;
    --skip-rds) INCLUDE_RDS=0; shift;;
    --plan-only) PLAN_ONLY=1; shift;;
    --app-name) APP_NAME_OVERRIDE="$2"; shift 2;;
    --aws-profile) AWS_PROFILE="$2"; shift 2;;
    --timeout) TIMEOUT_SECS="$2"; shift 2;;
    --interval) INTERVAL_SECS="$2"; shift 2;;
    --max-parallel) MAX_PARALLEL="$2"; shift 2;;
    --sequential) MAX_PARALLEL=1; shift;;
    --resume-after-rds) RESUME_AFTER_RDS=1; shift;;
    -h|--help) usage; exit 0;;
    *) err "Unknown argument: $1";;
  esac
done

[[ -n "$ENV_NAME" ]] || { usage; err "--env is required"; }
[[ -n "$ACTION" ]] || { usage; err "--action is required"; }
[[ "$ENV_NAME" == "dev" || "$ENV_NAME" == "qa" ]] || err "--env must be 'dev' or 'qa'"
[[ "$ACTION" == "suspend" || "$ACTION" == "resume" ]] || err "--action must be 'suspend' or 'resume'"

need_cmd aws
need_cmd jq

ENV_DIR="$REPO_ROOT/environments/$ENV_NAME"
[[ -d "$ENV_DIR" ]] || err "Environment directory not found: $ENV_DIR"

STATE_FILE="$STATE_DIR/${ENV_NAME}.json"

# Resolve app name from override or Terraform variables default
resolve_app_name() {
  if [[ -n "$APP_NAME_OVERRIDE" ]]; then
    echo "$APP_NAME_OVERRIDE"
    return
  fi
  local var_file="$ENV_DIR/variables.tf"
  if [[ -f "$var_file" ]]; then
    # Extract default value for variable "app_name"
    local name
    name=$(awk '/variable\s+"app_name"\s*{/,/}/ { if ($1=="default") { gsub("\"","",$3); print $3 } }' "$var_file" | tail -n1)
    if [[ -n "$name" ]]; then
      echo "$name"
      return
    fi
  fi
  err "Unable to determine app_name. Provide --app-name explicitly."
}

APP_NAME="$(resolve_app_name)"
CLUSTER_NAME="${APP_NAME}-cluster"

# AWS wrapper that respects optional profile
aws_call() {
  if [[ -n "${AWS_PROFILE:-}" ]]; then
    aws --profile "$AWS_PROFILE" "$@"
  else
    aws "$@"
  fi
}

# Limit number of concurrent background jobs to $MAX_PARALLEL
throttle_jobs() {
  # In some shells, jobs -pr may be empty; ensure non-negative integer
  while :; do
    local running
    running=$(jobs -pr | wc -l | tr -d ' ')
    [[ -z "$running" ]] && running=0
    if (( running < MAX_PARALLEL )); then
      break
    fi
    sleep 0.2
  done
}

# Resolve DB endpoint from Terraform outputs (if present)
get_db_endpoint() {
  if command -v tofu >/dev/null 2>&1; then
    (
      cd "$ENV_DIR"
      tofu output -json 2>/dev/null | jq -r '.db_endpoint.value // empty'
    )
  else
    echo "" # tofu not installed
  fi
}

# Resolve DB instance identifier either via endpoint match or name prefix
get_db_instance_id() {
  local endpoint="$1"
  local id=""
  if [[ -n "$endpoint" ]]; then
    id=$(aws_call rds describe-db-instances --output json \
      | jq -r --arg ep "$endpoint" '.DBInstances[] | select(.Endpoint.Address==$ep) | .DBInstanceIdentifier' | head -n1 || true)
  fi
  if [[ -z "$id" ]]; then
    # Best-effort fallback by name prefix (unique per env)
    id=$(aws_call rds describe-db-instances --output json \
      | jq -r --arg pfx "${APP_NAME}-db-" '.DBInstances[] | select(.DBInstanceIdentifier|startswith($pfx)) | .DBInstanceIdentifier' | head -n1 || true)
  fi
  echo "$id"
}

# List expected ECS service names (known set in modules/ecs)
expected_services() {
  printf "%s\n" \
    "${APP_NAME}-worker-svc" \
    "${APP_NAME}-user-svc" \
    "${APP_NAME}-messages-svc" \
    "${APP_NAME}-notifications-svc" \
    "${APP_NAME}-recruiting-svc"
}

aws_whoami() {
  aws_call sts get-caller-identity --output json 2>/dev/null | jq -r '.Account + "@" + (.Arn|split(":")[3])' || echo "unknown"
}

update_service_desired() {
  local svc="$1"; local desired="$2"
  aws_call ecs update-service --cluster "$CLUSTER_NAME" --service "$svc" --desired-count "$desired" >/dev/null
}

describe_service_desired() {
  local svc="$1"
  aws_call ecs describe-services --cluster "$CLUSTER_NAME" --services "$svc" --output json \
    | jq -r '.services[0].desiredCount // empty'
}

describe_service_counts() {
  local svc="$1"
  aws_call ecs describe-services --cluster "$CLUSTER_NAME" --services "$svc" --output json \
    | jq -r '.services[0] | {desired: (.desiredCount // 0), running: (.runningCount // 0), pending: (.pendingCount // 0), status: (.status // "UNKNOWN"), deployments: ([.deployments[]?.rolloutState] // [])}'
}

wait_for_ecs_service() {
  local svc="$1"; local target_desired="$2"
  local start_ts=$(date +%s)
  while true; do
    local now=$(date +%s)
    local elapsed=$(( now - start_ts ))
    if (( elapsed > TIMEOUT_SECS )); then
      warn "Timeout waiting for ECS $svc to reach desired=$target_desired"
      return 1
    fi
    local json
    if ! json=$(describe_service_counts "$svc" 2>/dev/null); then
      warn "Failed to describe ECS service $svc"
      sleep "$INTERVAL_SECS"; continue
    fi
    local desired running pending deployments status
    desired=$(echo "$json" | jq -r '.desired')
    running=$(echo "$json" | jq -r '.running')
    pending=$(echo "$json" | jq -r '.pending')
    status=$(echo "$json" | jq -r '.status')
    deployments=$(echo "$json" | jq -r '.deployments | join(",")')
    log "ECS $svc status: desired=$desired running=$running pending=$pending state=$status deployments=[$deployments]"
    if [[ "$running" == "$target_desired" && "$pending" == "0" ]]; then
      return 0
    fi
    sleep "$INTERVAL_SECS"
  done
}

scale_and_wait() {
  local svc="$1"; local target="$2"
  log "Scaling $svc to $target"
  if ! update_service_desired "$svc" "$target"; then
    warn "Failed to scale $svc"
    return 1
  fi
  if ! wait_for_ecs_service "$svc" "$target"; then
    warn "ECS $svc did not reach desired=$target in time"
    return 1
  fi
  return 0
}

rds_status() {
  local id="$1"
  aws_call rds describe-db-instances --db-instance-identifier "$id" --output json \
    | jq -r '.DBInstances[0].DBInstanceStatus'
}

wait_for_rds_status() {
  local id="$1"; local target="$2"
  local start_ts=$(date +%s)
  while true; do
    local now=$(date +%s)
    local elapsed=$(( now - start_ts ))
    if (( elapsed > TIMEOUT_SECS )); then
      warn "Timeout waiting for RDS $id status=$target"
      return 1
    fi
    local st
    st=$(rds_status "$id" 2>/dev/null || echo "unknown")
    log "RDS $id status: $st (target: $target)"
    if [[ "$st" == "$target" ]]; then
      return 0
    fi
    sleep "$INTERVAL_SECS"
  done
}

save_state() {
  local ecs_services_json="$1"; shift
  local db_id="$1"; shift
  local db_status="$1"; shift
  jq -n \
    --arg env "$ENV_NAME" \
    --arg app "$APP_NAME" \
    --arg cluster "$CLUSTER_NAME" \
    --arg dbid "$db_id" \
    --arg dbst "$db_status" \
    --arg ts "$(date -Iseconds)" \
    --argjson services "$ecs_services_json" \
    '{version:1, env:$env, app_name:$app, cluster_name:$cluster, saved_at:$ts, ecs:{services:$services}, rds:{db_instance_identifier:$dbid, status_before:$dbst}}' > "$STATE_FILE"
}

load_state() {
  [[ -f "$STATE_FILE" ]] || err "State file not found: $STATE_FILE. Did you run suspend?"
  cat "$STATE_FILE"
}

# Validate AWS caller for visibility
log "AWS: $(aws_whoami)"
log "Environment: $ENV_NAME | App: $APP_NAME | Cluster: $CLUSTER_NAME"
log "Concurrency: max_parallel=$MAX_PARALLEL"

case "$ACTION" in
  suspend)
    # Collect current desired counts into a temp file: "<svc> <desired>"
    svc_tmp=$(mktemp)
    > "$svc_tmp"
    for svc in $(expected_services); do
      if desired=$(describe_service_desired "$svc" 2>/dev/null); then
        if [[ -n "$desired" && "$desired" != "null" ]]; then
          printf "%s %s\n" "$svc" "$desired" >> "$svc_tmp"
        else
          warn "Service not found or no desiredCount: $svc (skipping)"
        fi
      else
        warn "Service describe failed: $svc (skipping)"
      fi
    done

    # Build JSON object of services -> desired from the temp file
    ECS_SERVICES_JSON=$(awk '{printf("{\"%s\": %s}\n",$1,$2)}' "$svc_tmp" | jq -s 'add // {}')

    DB_ENDPOINT=""
    DB_ID=""
    DB_STATUS=""
    if [[ $INCLUDE_RDS -eq 1 ]]; then
      DB_ENDPOINT="$(get_db_endpoint || true)"
      DB_ID="$(get_db_instance_id "$DB_ENDPOINT" || true)"
      if [[ -z "$DB_ID" ]]; then
        warn "Could not resolve RDS instance identifier. Skipping RDS."
        INCLUDE_RDS=0
      else
        DB_STATUS="$(rds_status "$DB_ID")"
      fi
    fi

    log "Planned actions (suspend):"
    while read -r line; do
      [[ -z "$line" ]] && continue
      svc_name=$(echo "$line" | awk '{print $1}')
      desired_val=$(echo "$line" | awk '{print $2}')
      log "- ECS service $svc_name: $desired_val -> 0"
    done < "$svc_tmp"
    if [[ $INCLUDE_RDS -eq 1 ]]; then
      log "- RDS instance $DB_ID: $DB_STATUS -> stopped"
    fi

    if [[ $PLAN_ONLY -eq 1 ]]; then
      log "Plan-only mode; no changes applied."
      exit 0
    fi

    # Save state prior to changes
    save_state "$ECS_SERVICES_JSON" "${DB_ID:-}" "${DB_STATUS:-}"
    log "Saved state to $STATE_FILE"

    # Apply ECS scaling (in parallel up to MAX_PARALLEL) and RDS stop in parallel
    failures=0
    pids=()
    # Kick off RDS stop concurrently (if included)
    if [[ $INCLUDE_RDS -eq 1 ]]; then
      if [[ "$DB_STATUS" == "stopped" ]]; then
        log "RDS $DB_ID already stopped"
      else
        (
          log "Stopping RDS $DB_ID"
          aws_call rds stop-db-instance --db-instance-identifier "$DB_ID" >/dev/null \
            && wait_for_rds_status "$DB_ID" "stopped"
        ) &
        pids+=($!)
      fi
    fi

    # Start ECS scale+wait tasks
    while read -r line; do
      [[ -z "$line" ]] && continue
      svc_name=$(echo "$line" | awk '{print $1}')
      desired_val=$(echo "$line" | awk '{print $2}')
      if [[ "$desired_val" -gt 0 ]]; then
        throttle_jobs
        ( scale_and_wait "$svc_name" 0 ) &
        pids+=($!)
      else
        log "Service $svc_name already at 0"
      fi
    done < "$svc_tmp"

    rm -f "$svc_tmp"

    # Wait for all background tasks and collect failures
    for pid in "${pids[@]}"; do
      if ! wait "$pid"; then
        failures=$((failures+1))
      fi
    done

    if [[ ${failures:-0} -gt 0 ]]; then
      warn "Suspend completed with $failures failure(s)."
      exit 1
    fi
    log "Suspend completed successfully."
    ;;

  resume)
    STATE_JSON="$(load_state)"

    SAVED_APP=$(echo "$STATE_JSON" | jq -r '.app_name')
    [[ "$SAVED_APP" == "$APP_NAME" ]] || warn "App name mismatch (state=$SAVED_APP, current=$APP_NAME). Proceeding."

  # Determine RDS plan (no actions yet; plan-only safe)
  DB_ID=$(echo "$STATE_JSON" | jq -r '.rds.db_instance_identifier // empty')
  failures=0
  rds_pid=""
  if [[ -n "$DB_ID" && $INCLUDE_RDS -eq 1 ]]; then
    CUR_DB_STATUS=$(rds_status "$DB_ID" 2>/dev/null || echo "unknown")
    if [[ $RESUME_AFTER_RDS -eq 1 ]]; then
      log "Planned: RDS instance $DB_ID: ${CUR_DB_STATUS} -> available (sequential)"
    else
      log "Planned: RDS instance $DB_ID: ${CUR_DB_STATUS} -> available (eager)"
    fi
  fi

    # Restore ECS services
    KEYS=$(echo "$STATE_JSON" | jq -r '.ecs.services | keys[]' || true)

    log "Planned actions (resume):"
    for svc in $KEYS; do
      cur=$(describe_service_desired "$svc" 2>/dev/null || echo "?")
      target=$(echo "$STATE_JSON" | jq -r --arg k "$svc" '.ecs.services[$k]')
      log "- ECS service $svc: ${cur} -> ${target}"
    done

  if [[ $PLAN_ONLY -eq 1 ]]; then
    log "Plan-only mode; no changes applied."
    exit 0
  fi

  if [[ $RESUME_AFTER_RDS -eq 1 ]]; then
    # Sequential resume: ensure RDS is available first
    if [[ -n "$DB_ID" && $INCLUDE_RDS -eq 1 ]]; then
      CUR_DB_STATUS=${CUR_DB_STATUS:-unknown}
      if [[ "$CUR_DB_STATUS" != "available" ]]; then
        log "Starting RDS $DB_ID (sequential)"
        if ! aws_call rds start-db-instance --db-instance-identifier "$DB_ID" >/dev/null; then
          warn "Failed to start RDS $DB_ID"
          failures=$((failures+1))
        else
          if ! wait_for_rds_status "$DB_ID" "available"; then
            warn "RDS $DB_ID failed to start in time"
            failures=$((failures+1))
          fi
        fi
      else
        log "RDS $DB_ID already available"
      fi
    fi

    # Now scale ECS services in parallel
    pids=()
    for svc in $KEYS; do
      target=$(echo "$STATE_JSON" | jq -r --arg k "$svc" '.ecs.services[$k]')
      throttle_jobs
      ( scale_and_wait "$svc" "$target" ) &
      pids+=($!)
    done
    for pid in "${pids[@]}"; do
      if ! wait "$pid"; then
        failures=$((failures+1))
      fi
    done
  else
    # Eager resume: start RDS in background (if needed) and scale ECS concurrently
    if [[ -n "$DB_ID" && $INCLUDE_RDS -eq 1 ]]; then
      CUR_DB_STATUS=${CUR_DB_STATUS:-unknown}
      if [[ "$CUR_DB_STATUS" != "available" ]]; then
        (
          log "Starting RDS $DB_ID (eager)"
          aws_call rds start-db-instance --db-instance-identifier "$DB_ID" >/dev/null \
            && wait_for_rds_status "$DB_ID" "available"
        ) &
        rds_pid=$!
      else
        log "RDS $DB_ID already available"
      fi
    fi

    # Scale ECS services in parallel up to MAX_PARALLEL
    pids=()
    for svc in $KEYS; do
      target=$(echo "$STATE_JSON" | jq -r --arg k "$svc" '.ecs.services[$k]')
      throttle_jobs
      ( scale_and_wait "$svc" "$target" ) &
      pids+=($!)
    done
    # Also wait on RDS if we kicked it off
    if [[ -n "$rds_pid" ]]; then
      pids+=("$rds_pid")
    fi
    for pid in "${pids[@]}"; do
      if ! wait "$pid"; then
        failures=$((failures+1))
      fi
    done
  fi

    if [[ ${failures:-0} -gt 0 ]]; then
      warn "Resume completed with $failures failure(s)."
      exit 1
    fi
    log "Resume completed successfully."
    ;;
esac
