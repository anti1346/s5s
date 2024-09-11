#!/bin/bash

# Variables
REMOTE_HOST="192.168.0.131"
REMOTE_USER="datasyncuser"
PASSWORD="Password1!"
REMOTE_BASE_PATH="/app"
LOCAL_BASE_PATH="/app"

# 동기화할 디렉터리
declare -A SYNC_PATHS=(
    ["/www/image"]="/www/"
    ["/data/image"]="/data/"
)

# sshpass를 사용하여 동기화를 수행하는 기능
sync_directories() {
    local remote_path=$1
    local local_path=$2

    # 로컬 디렉터리가 있는지 확인하고 없는 경우 생성합니다
    if [ ! -d "${LOCAL_BASE_PATH}${local_path}" ]; then
        echo "Creating local directory: ${LOCAL_BASE_PATH}${local_path}"
        mkdir -p "${LOCAL_BASE_PATH}${local_path}"
    fi

    # 동기화 수행
    sshpass -p "$PASSWORD" rsync -azpgo "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_BASE_PATH}${remote_path}" "${LOCAL_BASE_PATH}${local_path}"
}

# 디렉터리 반복 및 동기화
for remote_path in "${!SYNC_PATHS[@]}"; do
    sync_directories "$remote_path" "${SYNC_PATHS[$remote_path]}"
done