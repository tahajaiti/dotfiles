#!/usr/bin/env bash
#=============================================================================#
#                    Optimized SWWW Wallpaper Changer v2.0                   #
#=============================================================================#
# Performance optimizations:
#   - Pre-cached wallpaper list (no repeated find calls)
#   - Efficient array shuffling without subprocess spawning
#   - Proper file descriptor management
#   - No memory leaks from subshells
#   - Smart daemon health monitoring
#   - Atomic operations where possible
#=============================================================================#

set -euo pipefail
shopt -s nullglob extglob

#--- CONFIGURATION ---#
readonly WALLPAPER_DIR="${WALLPAPER_DIR:-$HOME/Pictures/wallpapers}"
readonly SLEEP_DURATION="${SLEEP_DURATION:-200}"
readonly TRANSITION_DURATION="${TRANSITION_DURATION:-2.5}"
readonly TRANSITION_BEZIER="${TRANSITION_BEZIER:-0.25,0.1,0.25,1.0}"
readonly LOG_FILE="${LOG_FILE:-$HOME/.local/share/swww-changer.log}"
readonly MAX_LOG_SIZE="${MAX_LOG_SIZE:-1048576}"  # 1MB max log size
readonly DAEMON_CHECK_INTERVAL=10  # Check daemon health every N cycles

# Transition effects array
readonly -a TRANSITIONS=(fade wipe grow center outer random)

# Supported extensions (lowercase, case-insensitive matching done separately)
readonly -a IMAGE_EXTENSIONS=(jpg jpeg png gif webp bmp tiff)

#--- GLOBAL STATE ---#
declare -a WALLPAPER_CACHE=()
declare -i CACHE_INDEX=0
declare -i CYCLE_COUNT=0
declare LAST_WALLPAPER=""
declare -i TRANSITION_INDEX=0

#--- LOGGING ---#
log() {
    local level="$1"
    shift
    # Use printf for efficiency, avoid date subprocess when possible
    printf '[%s] [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$level" "$*" >> "$LOG_FILE" 2>/dev/null || true
}

log_info()  { log "INFO" "$@"; }
log_warn()  { log "WARN" "$@"; }
log_error() { log "ERROR" "$@"; }

# Rotate log if too large (prevents unbounded growth)
rotate_log() {
    if [[ -f "$LOG_FILE" ]]; then
        local size
        size=$(stat -c%s "$LOG_FILE" 2>/dev/null || echo 0)
        if ((size > MAX_LOG_SIZE)); then
            mv -f "$LOG_FILE" "${LOG_FILE}.old" 2>/dev/null || true
            log_info "Log rotated (was ${size} bytes)"
        fi
    fi
}

#--- DEPENDENCY CHECK ---#
check_dependencies() {
    local -a missing=()
    local dep
    
    for dep in swww swww-daemon; do
        command -v "$dep" &>/dev/null || missing+=("$dep")
    done
    
    if ((${#missing[@]} > 0)); then
        log_error "Missing dependencies: ${missing[*]}"
        printf 'ERROR: Missing dependencies: %s\n' "${missing[*]}" >&2
        exit 1
    fi
}

#--- DAEMON MANAGEMENT ---#
init_daemon() {
    # Check if daemon is responsive (more reliable than pgrep)
    if swww query &>/dev/null; then
        log_info "swww-daemon already running and responsive"
        return 0
    fi
    
    # Kill any zombie/unresponsive daemon processes
    if pgrep -x swww-daemon &>/dev/null; then
        log_warn "Found unresponsive swww-daemon, killing..."
        pkill -9 -x swww-daemon 2>/dev/null || true
        sleep 0.5
    fi
    
    log_info "Starting swww-daemon..."
    # Note: --format argb is the default, so we omit it entirely
    swww-daemon &
    disown
    
    # Wait for daemon with exponential backoff
    local -i attempt=0 max_attempts=10 wait_ms=100
    while ((attempt < max_attempts)); do
        if swww query &>/dev/null; then
            # Give daemon time to fully initialize buffers
            sleep 0.3
            log_info "swww-daemon started successfully"
            return 0
        fi
        sleep "0.$((wait_ms))"
        ((wait_ms = wait_ms * 2 > 1000 ? 1000 : wait_ms * 2))
        ((attempt++))
    done
    
    log_error "Failed to start swww-daemon after $max_attempts attempts"
    return 1
}

check_daemon_health() {
    if ! swww query &>/dev/null; then
        log_warn "Daemon unhealthy, attempting restart..."
        pkill -9 -x swww-daemon 2>/dev/null || true
        sleep 1
        init_daemon
    fi
}

#--- WALLPAPER CACHE MANAGEMENT ---#
# Fisher-Yates shuffle - O(n) in-place, no subprocesses
shuffle_array() {
    local -i i j n=${#WALLPAPER_CACHE[@]}
    local temp
    
    for ((i = n - 1; i > 0; i--)); do
        j=$((RANDOM % (i + 1)))
        temp="${WALLPAPER_CACHE[i]}"
        WALLPAPER_CACHE[i]="${WALLPAPER_CACHE[j]}"
        WALLPAPER_CACHE[j]="$temp"
    done
}

# Build wallpaper cache - single traversal, no repeated find calls
build_cache() {
    WALLPAPER_CACHE=()
    CACHE_INDEX=0
    
    local ext file
    local -a patterns=()
    
    # Build glob patterns for all extensions
    for ext in "${IMAGE_EXTENSIONS[@]}"; do
        patterns+=("$WALLPAPER_DIR"/**/*."$ext" "$WALLPAPER_DIR"/**/*."${ext^^}")
    done
    
    # Use globbing instead of find (faster, no subprocess)
    shopt -s globstar nocaseglob 2>/dev/null || true
    
    for file in "${patterns[@]}"; do
        [[ -f "$file" && -r "$file" ]] && WALLPAPER_CACHE+=("$file")
    done
    
    shopt -u globstar nocaseglob 2>/dev/null || true
    
    if ((${#WALLPAPER_CACHE[@]} == 0)); then
        # Fallback to find if globbing fails (some systems)
        while IFS= read -r -d '' file; do
            WALLPAPER_CACHE+=("$file")
        done < <(find "$WALLPAPER_DIR" -type f \( \
            -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \
            -o -iname '*.gif' -o -iname '*.webp' -o -iname '*.bmp' \
            -o -iname '*.tiff' \) -print0 2>/dev/null)
    fi
    
    local count=${#WALLPAPER_CACHE[@]}
    if ((count == 0)); then
        log_error "No wallpapers found in $WALLPAPER_DIR"
        return 1
    fi
    
    shuffle_array
    log_info "Cached $count wallpapers"
    return 0
}

# Get next wallpaper from shuffled cache
get_next_wallpaper() {
    # Reshuffle when cache exhausted
    if ((CACHE_INDEX >= ${#WALLPAPER_CACHE[@]})); then
        shuffle_array
        CACHE_INDEX=0
        log_info "Cache reshuffled"
    fi
    
    local wp="${WALLPAPER_CACHE[CACHE_INDEX]}"
    ((CACHE_INDEX++))
    
    # Verify file still exists (could be deleted)
    if [[ ! -f "$wp" ]]; then
        log_warn "Wallpaper no longer exists: $wp"
        return 1
    fi
    
    # Skip if same as last (avoid immediate repeat)
    if [[ "$wp" == "$LAST_WALLPAPER" ]] && ((${#WALLPAPER_CACHE[@]} > 1)); then
        return 1
    fi
    
    printf '%s' "$wp"
}

#--- TRANSITION MANAGEMENT ---#
get_next_transition() {
    local transition="${TRANSITIONS[TRANSITION_INDEX]}"
    ((TRANSITION_INDEX = (TRANSITION_INDEX + 1) % ${#TRANSITIONS[@]}))
    printf '%s' "$transition"
}

#--- WALLPAPER APPLICATION ---#
apply_wallpaper() {
    local wallpaper="$1"
    local transition="$2"
    
    # Direct swww call without eval (safer, faster)
    if swww img "$wallpaper" \
        --transition-type "$transition" \
        --transition-duration "$TRANSITION_DURATION" \
        --transition-bezier "$TRANSITION_BEZIER" 2>/dev/null; then
        
        LAST_WALLPAPER="$wallpaper"
        log_info "Set: ${wallpaper##*/} (${transition})"
        return 0
    else
        log_error "Failed to set: ${wallpaper##*/}"
        return 1
    fi
}

#--- SIGNAL HANDLERS ---#
cleanup() {
    log_info "Shutting down gracefully..."
    exit 0
}

reload_cache() {
    log_info "Reloading wallpaper cache (SIGHUP received)..."
    build_cache || log_warn "Cache reload failed, using existing cache"
}

# Interruptible sleep helper (keeps current signal behavior responsive)
sleep_interruptible() {
    local secs="$1"
    sleep "$secs" &
    wait $! 2>/dev/null || true
}

# Try to set a wallpaper immediately on startup (avoid waiting full interval on initial failure)
apply_initial_wallpaper() {
    local -i attempt=0 max_attempts=10
    local wallpaper transition

    log_info "Applying initial wallpaper..."
    while ((attempt < max_attempts)); do
        if ! wallpaper=$(get_next_wallpaper); then
            log_warn "Startup: failed to pick wallpaper, rebuilding cache..."
            build_cache || true
        else
            transition=$(get_next_transition)
            if apply_wallpaper "$wallpaper" "$transition"; then
                return 0
            fi
        fi

        ((attempt++))
        sleep_interruptible 1
    done

    log_warn "Startup: could not set wallpaper after ${max_attempts} attempts; continuing."
    return 1
}

trap cleanup SIGTERM SIGINT SIGQUIT
trap reload_cache SIGHUP

#--- VALIDATION ---#
validate_config() {
    if [[ ! -d "$WALLPAPER_DIR" ]]; then
        log_error "Directory not found: $WALLPAPER_DIR"
        printf 'ERROR: Wallpaper directory not found: %s\n' "$WALLPAPER_DIR" >&2
        exit 1
    fi
    
    if ! [[ "$SLEEP_DURATION" =~ ^[0-9]+$ ]] || ((SLEEP_DURATION < 1)); then
        log_error "Invalid SLEEP_DURATION: $SLEEP_DURATION"
        exit 1
    fi
}

#--- MAIN ---#
main() {
    # Initialize
    mkdir -p "$(dirname "$LOG_FILE")"
    rotate_log

    log_info "=== SWWW Wallpaper Changer v2.0 Started ==="
    log_info "Directory: $WALLPAPER_DIR | Interval: ${SLEEP_DURATION}s"

    check_dependencies
    validate_config
    build_cache || exit 1
    init_daemon || exit 1

    # Change wallpaper immediately on startup (then the normal timer applies)
    apply_initial_wallpaper || true

    local wallpaper transition
    local -i retry_count=0 max_retries=5

    # Main loop: sleep first, then change (so interval is between changes)
    while true; do
        sleep_interruptible "$SLEEP_DURATION"
        ((CYCLE_COUNT++))

        # Periodic daemon health check
        if ((CYCLE_COUNT % DAEMON_CHECK_INTERVAL == 0)); then
            check_daemon_health
            rotate_log
        fi

        # Get and apply wallpaper
        if wallpaper=$(get_next_wallpaper); then
            transition=$(get_next_transition)

            if apply_wallpaper "$wallpaper" "$transition"; then
                retry_count=0
            else
                ((retry_count++))
            fi
        else
            ((retry_count++))
        fi

        # Handle persistent failures
        if ((retry_count >= max_retries)); then
            log_warn "Multiple failures, rebuilding cache..."
            build_cache || {
                log_error "Cache rebuild failed, waiting..."
                sleep_interruptible 60
            }
            retry_count=0
        fi
    done
}

# Entry point
main "$@"