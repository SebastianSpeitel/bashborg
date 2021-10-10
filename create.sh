global_repo=$BORG_REPO
global_passphrase=$BORG_PASSPHRASE
global_passcommand=$BORG_PASSCOMMAND
global_archive=$(date -I)
global_path="~"
global_ignorefile=".borgignore"

function create(){
    
    local name=${current_name:-"$global_name"}
    unset current_name
    local repo=${current_repo:-"$global_repo"}
    unset current_repo
    local path=${current_path:-"$global_path"}
    unset current_path
    local compression=${current_compression:-"$global_compression"}
    unset current_compression
    local archive=${current_archive:-"$global_archive"}
    unset current_archive
    local ignorefile=${current_ignorefile:-"$global_ignorefile"}
    unset current_ignorefile
    local passphrase=${current_passphrase:-"$global_passphrase"}
    unset current_passphrase
    local passcommand=${current_passcommand:-"$global_passcommand"}
    unset current_passcommand
    local check=${current_check:-"$global_check"}
    unset current_check
    
    local command="borg create --progress --stats"
    if [[ -n "$compression" ]]; then
        command="${command} --compression ${compression}"
    fi
    
    if [[ -n "$ignorefile" ]]; then
        if [[ "$ignorefile" != /* ]]; then
            ignorefile="$path/$ignorefile"
        fi
        
        local realignorefile=$(eval echo $ignorefile)
        
        if [[ -f "$realignorefile" ]]; then
            command="${command} --exclude-from ${ignorefile}"
        fi
    fi
    
    if [[ -n "$passphrase" ]]; then
        export BORG_PASSPHRASE="$passphrase"
    fi
    
    if [[ -n "$passcommand" ]]; then
        export BORG_PASSPHRASE="$(eval $passcommand)"
    fi
    
    command="${command} ${repo}::${archive} ${path}"
    
    echo "Creating backup ${name}"
    
    [[ -z "$DRYRUN" ]] && eval "${command}"
    [[ -n "$DRYRUN" ]] && echo "[DRYRUN] ${command}"
    
    if [[ -n "$check" ]]; then
        local check_command="borg check --progress ${repo}::${archive}"
        
        echo "Checking backup ${name}"
        [[ -z "$DRYRUN" ]] && eval "${check_command}"
    fi
}

function Backup(){
    if [ -n "${current_name}" ]; then
        create
    fi
    current_name=$1
}

function Repo(){
    if [ -z "${current_name}" ]; then
        global_repo=$1
    fi
    current_repo=$1
}

function Compression(){
    if [ -z "${current_name}" ]; then
        global_compression=$1
    fi
    current_compression=$1
}

function Passphrase(){
    if [ -z "${current_name}" ]; then
        global_passphrase=$1
    fi
    current_passphrase=$1
}

function PassCommand(){
    if [ -z "${current_name}" ]; then
        global_passcommand=$1
    fi
    current_passcommand=$1
}

function Path(){
    if [ -z "${current_name}" ]; then
        global_path=$1
    fi
    current_path=$1
}

function Archive(){
    if [ -z "${current_name}" ]; then
        global_archive=$1
    fi
    current_archive=$1
}

function IgnoreFile(){
    if [ -z "${current_name}" ]; then
        global_ignorefile=$1
    fi
    current_ignorefile=$1
}

function Check(){
    if [ -z "${current_name}" ]; then
        global_check=$1
    fi
    current_check=$1
}

if [[ -n "$BORG_CONFIG_DIR" ]]; then
    CONFIG_PATH="$BORG_CONFIG_DIR/backups"
    elif [[ -n "$BORG_BASE_DIR" ]]; then
    CONFIG_PATH="$BORG_BASE_DIR/.config/borg/backups"
else
    CONFIG_PATH="$HOME/.config/borg/backups"
fi

config=$(cat "$CONFIG_PATH")


function validate(){
    DRYRUN="true"

    # Important! $LINENO has to be the line before eval 
    local line_offset=$LINENO
    errors=$(eval "$config" 2>&1 >/dev/null)
    unset DRYRUN
    
    if [[ -n "$errors" ]]; then
        echo "Invalid config" >&2
        
        function format_error(){
            local line_offset=$2
            local line=$(echo $1 | grep -Pom1 "(?<=line )\d+(?=:)")
            if [[ -z "$line" ]]; then
                printf "Error:\n\t%s\n" "$1" >&2
                return
            fi
            local line=$((line - line_offset))
            printf "Error in line $line:\n" >&2
            
            local error=$(echo $1 | grep -Pom1 "(?<=\d: ).*")
            if [[ -z "$error" ]]; then
                printf "\t%s\n" "$1" >&2
                return
            fi
            
            local unknown_option=$(echo $error | grep -Pom1 "\w+(?=: command not found)")
            if [[ -n "$unknown_option" ]]; then
                printf "\tunknown option '%s'\n" "$unknown_option" >&2
                return
            fi
            
            printf "\t%s\n" "$error" >&2
        }
        # Export function, so it is available inside shell opened by xargs
        export -f format_error
        
        
        echo "$errors" | xargs -I {} bash -c "format_error '{}' '$line_offset'"
        exit 1
    fi
}

validate

if [[ "$1" == --dry-run ]]; then
    export DRYRUN="true"
    echo "Dry run"
fi

eval "$config"
Backup