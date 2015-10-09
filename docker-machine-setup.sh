#!/usr/bin/env bash

export DOCKER_BIN=$(which docker)
export DOCKER_MACHINE_NAME="default" # for kitematic compatibility

DOCKER_MACHINE_CPUS=4
DOCKER_MACHINE_DISK_SIZE=20000
DOCKER_MACHINE_MEMORY=2048
DOCKER_MACHINE_DRIVER="virtualbox"

docker_machine_ensure_created() {
    docker_machine_errored && docker_machine_destroy
    docker-machine ls | grep -v Error | grep ${DOCKER_MACHINE_NAME} >> /dev/null
    if [ $? -ne 0 ]; then
        docker-machine create -d ${DOCKER_MACHINE_DRIVER} \
            --virtualbox-cpu-count "${DOCKER_MACHINE_CPUS}" \
            --virtualbox-disk-size "${DOCKER_MACHINE_DISK_SIZE}" \
            --virtualbox-memory "${DOCKER_MACHINE_MEMORY}" \
            ${DOCKER_MACHINE_NAME}
    fi
}

docker_machine_errored() {
    docker-machine ls 2> /dev/null | grep Error | grep ${DOCKER_MACHINE_NAME} >> /dev/null 2>/dev/null
    return $?
}

docker_machine_upgrade() {
    docker-machine upgrade ${DOCKER_MACHINE_NAME}
}

docker_machine_exists() {
    docker-machine ls | grep ${DOCKER_MACHINE_NAME} >> /dev/null
    return $?
}

docker_machine_destroy() {
    docker_machine_exists && docker-machine rm ${DOCKER_MACHINE_NAME}
}

docker_machine_start() {
    docker-machine start ${DOCKER_MACHINE_NAME}
}

docker_machine_stop() {
    docker_machine_isrunning && docker-machine stop ${DOCKER_MACHINE_NAME}
}

docker_machine_restart() {
    docker-machine restart ${DOCKER_MACHINE_NAME}
}

docker_machine_status() {
    docker-machine status ${DOCKER_MACHINE_NAME}
}
docker_machine_isrunning() {
    docker_machine_status 2>&1 | grep Running >> /dev/null
    return $?
}

docker_machine_ensure_running() {
    docker_machine_isrunning
    if [ $? -ne 0 ]; then
        docker_machine_start
    fi
}

docker_machine_eval_config() {
        eval $(docker-machine env ${DOCKER_MACHINE_NAME})
}

docker_machine_recreate() {
    docker_machine_isrunning
    if [ $? -eq 0 ]; then
        docker_machine_stop
    fi
    docker_machine_destroy
    docker_prep_env
}

docker_machine_ensure() {
    echo "Doing one-time check docker VM is running..." >&2
    docker_machine_ensure_created \
    && docker_machine_ensure_running \
    && docker_machine_eval_config
}

docker_machine_alias() {
    docker_machine_isrunning
    if [ $? -ne 0 ]; then
        alias docker="docker_machine_ensure && unset docker && ${DOCKER_BIN} $@"
    else
        docker_machine_eval_config
    fi
}

docker_machine_alias
