#!/bin/bash

readonly VERSION_URL="https://devserver.fydeos.com/stateful-update"
readonly LOG_FILE="/var/log/tatl-update.log"

readonly CURL_BIN="/usr/bin/curl"
readonly CURL_PARAMS="--silent --show-error --connect-timeout 2 --max-time 6"
readonly CURL="$CURL_BIN $CURL_PARAMS"

readonly LOCAL_FYDEOS_BUILD_TYPE="CHROMEOS_RELEASE_BUILD_TYPE"
readonly LOCAL_RELEASE_VERSION="CHROMEOS_RELEASE_VERSION"

readonly LOCAL_TATL_LSB_RELEASE="/mnt/stateful_partition/dev_image/tatl-fydeos/lsb-release"
# readonly LOCAL_TATL_LSB_RELEASE="./lsb-release"
readonly LOCAL_FYDEOS_LSB_RELEASE="/etc/lsb-release"
# readonly LOCAL_FYDEOS_LSB_RELEASE="./os-lsb-release"

readonly RUN_DIR="/run/stateful_update"
# readonly RUN_DIR="./run"

readonly UPDATE_PROGRESS_FILE="$RUN_DIR/progress"
readonly UPDATE_STATE_FILE="$RUN_DIR/state"
readonly CHECKING_STATE="checking"
readonly UPGRADING_STATE="updating"
readonly NO_ACTION_STATE="no_action"

readonly RESULT_FILE="$RUN_DIR/result"
readonly REBOOT_ACTION_REQUIRED="reboot"

readonly STATEFUL_UPDATE_SCRIPT="/usr/bin/stateful_update_fydeos"

OS_MAJOR_VERSION=""
TATL_MAJOR_VERSION=""
LOCAL_DETAIL_VERSION=""

REMOTE_MAJOR_VERSION=""
REMOTE_DETAIL_VERSION=""
# REMOTE_FILE_SIZE=""
# REMOTE_FILE_URL=""
# REMOTE_FILE_MD5SUM=""

logger() {
    date=$(date "+%F %T")
    echo -e "[$date] $*\n" >> "$LOG_FILE"
}

is_empty() {
    local s="$1"
    if [[ "x$s" = "x" ]]; then
        return 0
    else
        return 1
    fi
}

print_progress() {
    local progress="$1"
    echo "progress-$progress"
}

get_state() {
    if [[ -f "$UPDATE_STATE_FILE" ]]; then
        cat "$UPDATE_STATE_FILE"
    fi
}

set_state() {
    local state="$1"
    echo "$state" > "$UPDATE_STATE_FILE"
}

clean_state() {
    rm -f "$UPDATE_STATE_FILE"
}

clean_progress() {
    rm -f "$UPDATE_PROGRESS_FILE"
}

clean_exit() {
    clean_state
    clean_progress
    exit -1
}

set_reboot_required() {
    echo "$REBOOT_ACTION_REQUIRED" > "$RESULT_FILE"
}
##################### replace local version #####################
#==================== replace local version ====================#

##################### version comparison #####################
verlte() {
    [  "$1" = "$(echo -e "$1\n$2" | sort -V | head -n1)" ]
}

verlt() {
    if [[ "$1" = "$2"  ]]; then
        return 1
    fi
    verlte "$1" "$2"
}

# compare local tatl major version and os major version
is_tatl_higher_than_os_major_version() {
    local tatl_major_version="${TATL_MAJOR_VERSION%.*}"
    local os_major_version="${OS_MAJOR_VERSION%.*}"
    verlt "$os_major_version" "$tatl_major_version"
}

is_tatl_lower_than_os_major_version() {
    local tatl_major_version="${TATL_MAJOR_VERSION%.*}"
    local os_major_version="${OS_MAJOR_VERSION%.*}"
    verlt "$tatl_major_version" "$os_major_version"
}

# compare local detail version and remote detail version
is_tatl_local_lower_than_remote_version() {
    local local_version="${LOCAL_DETAIL_VERSION%.*}"
    local remote_version="${REMOTE_DETAIL_VERSION%.*}"
    verlt "$local_version" "$remote_version"
}

is_local_equal_remote_major_version() {
    local os_major_version="${OS_MAJOR_VERSION%.*}"
    local remote_major_version="${REMOTE_MAJOR_VERSION%.*}"
    [[ "$os_major_version" = "$remote_major_version" ]]
}
#==================== version comparison ====================#

##################### read local version #####################
read_local_detail_version() {
    grep "$LOCAL_RELEASE_VERSION" "$LOCAL_TATL_LSB_RELEASE" | awk -F '=' '{print $2}'
}

read_local_major_version() {
    grep "$LOCAL_FYDEOS_BUILD_TYPE" "$LOCAL_TATL_LSB_RELEASE" | awk -F '=' '{print $2}' | awk '{print $3}' | tr -d 'v'
}

read_os_major_version() {
    grep "$LOCAL_FYDEOS_BUILD_TYPE" "$LOCAL_FYDEOS_LSB_RELEASE" | awk -F '=' '{print $2}' | awk '{print $3}' | tr -d 'v'
}

read_local_version() {
    if [[ ! -f "$LOCAL_TATL_LSB_RELEASE" ]] || [[ ! -r "$LOCAL_TATL_LSB_RELEASE" ]]; then
        logger "can't read file $LOCAL_LSB_RELEASE"
        clean_exit
    fi
    if [[ ! -f "$LOCAL_FYDEOS_LSB_RELEASE" ]] || [[ ! -r "$LOCAL_FYDEOS_LSB_RELEASE" ]]; then
        logger "can't read file $LOCAL_LSB_RELEASE"
        clean_exit
    fi
    os_major_version=$(read_os_major_version)
    tatl_major_version=$(read_local_major_version)
    local_detail_version=$(read_local_detail_version)

    if is_empty "$os_major_version" || is_empty "$tatl_major_version" || is_empty "$local_detail_version"; then
        logger "get local version info failed"
        clean_exit
    fi
    OS_MAJOR_VERSION="$os_major_version"
    TATL_MAJOR_VERSION="$tatl_major_version"
    LOCAL_DETAIL_VERSION="$local_detail_version"
    logger "local version info\nOS_MAJOR_VERSION=$OS_MAJOR_VERSION\nTATL_MAJOR_VERSION=$TATL_MAJOR_VERSION\nLOCAL_DETAIL_VERSION=$LOCAL_DETAIL_VERSION"
}
#==================== read local version ====================#

##################### fetch version info #####################
parse_json_field() {
    local json="$1"
    local key="$2"
    echo "$json" | python -c "import sys, json; print json.load(sys.stdin)['${key}']" 2>>"$LOG_FILE"
}

curl_version_info() {
    $CURL "$VERSION_URL" 2>>"$LOG_FILE"
}

parse_json() {
    json="$1"
    major_version=$(parse_json_field "$json" "major_version")
    # size=$(parse_json_field "$json" "size")
    # md5sum=$(parse_json_field "$json" "md5sum")
    version=$(parse_json_field "$json" "version")
    # download_url=$(parse_json_field "$json" "download_url")

    # if is_empty "$size" || is_empty "$md5sum" || is_empty "$version" || is_empty "$download_url"; then
    if is_empty "$version" || is_empty "$major_version"; then
        logger "parse version info failed"
        clean_exit
    fi
    REMOTE_DETAIL_VERSION="$version"
    REMOTE_MAJOR_VERSION="$(echo "$major_version" | tr -d 'v')"
    # REMOTE_FILE_MD5SUM="$md5sum"
    # REMOTE_FILE_SIZE="$size"
    # REMOTE_FILE_URL="$download_url"
}

fetch_version_info() {
    set_state "$CHECKING_STATE"
    print_progress "$CHECKING_STATE"
    logger "fetching version info..."
    version_info=$(curl_version_info)
    if is_empty "$version_info"; then
        logger "fetch version info failed"
        clean_exit
    fi

    logger "fetch version info\n$(echo "$version_info" | python -m json.tool)"
    parse_json "$version_info"
}
#==================== fetch version info ====================#

upgrade() {
    if sh "$STATEFUL_UPDATE_SCRIPT"; then
        set_reboot_required
    fi
}

do_update() {
    if is_tatl_higher_than_os_major_version || ! is_local_equal_remote_major_version; then
        set_state "$NO_ACTION_STATE"
        print_progress "no_action"
    elif is_tatl_lower_than_os_major_version || is_tatl_local_lower_than_remote_version; then
        set_state "$UPGRADING_STATE"
        print_progress "$UPGRADING_STATE"
        upgrade
    else
        set_state "$NO_ACTION_STATE"
        print_progress "latest_no_action"
    fi
}

pre_update() {
    state=$(get_state)
    if [[ "$state" == "$CHECKING_STATE" ]] || [[ "$state" == "$UPGRADING_STATE" ]]; then
        echo "state: $state, please try again later"
        exit -1
    fi
    mkdir -p "$(dirname "$UPDATE_STATE_FILE")"
    if [[ -f "$RESULT_FILE" ]]; then
        if [[ $(cat "$RESULT_FILE") = "$REBOOT_ACTION_REQUIRED" ]]; then
            echo "reboot required"
            exit -1
        else
            rm "$RESULT_FILE"
        fi
    fi

    touch "$UPDATE_STATE_FILE"
    cat /dev/null > "$LOG_FILE"
}

post_update() {
    clean_state
    clean_progress
}

read_current_progress() {
    if [[ -f "$UPDATE_PROGRESS_FILE" ]]; then
        cat "$UPDATE_PROGRESS_FILE" | tail -n 1 | awk '{print $NF}'
    fi
}

main() {
    if [[ $# -eq 1 ]]; then
        if [[ $1 = "version" ]]; then
            read_local_version
            echo "$LOCAL_DETAIL_VERSION"
            exit 0
        elif [[ $1 = "progress" ]]; then
            read_current_progress
            exit 0
        else
            echo "invalid action"
            exit -1
        fi
    fi
    pre_update

    fetch_version_info
    read_local_version
    do_update

    post_update
}

main "$@"
