#!/usr/bin/env bash

docker_machine_load_defaults() {
    if [ -z $DOCKER_MACHINE_NAME ]; then
        # "default" for kitematic compatibility
        export DOCKER_MACHINE_NAME="default"
    fi
    if [ -z $DOCKER_MACHINE_CPUS ]; then
        docker_machine_set_cpus 1
    fi
    if [ -z $DOCKER_MACHINE_DISK_SIZE ]; then
        docker_machine_set_disk_size 20000
    fi
    if [ -z $DOCKER_MACHINE_MEMORY ]; then
        docker_machine_set_memory 2096
    fi
    if [ -z $DOCKER_MACHINE_DRIVER ]; then
        docker_machine_set_driver "virtualbox"
    fi
}

docker_machine_set_name() {
    if [ -z $1 ]; then
        echo "Missing machine name to use" >&2
        return 1
    fi
    export DOCKER_MACHINE_NAME=$1
}

docker_machine_set_cpus() {
    if [ -z $1 ]; then
        echo "Missing cpu count" >&2
        return 1
    fi
    export DOCKER_MACHINE_CPUS=$1
}

docker_machine_set_disk_size() {
    if [ -z $1 ]; then
        echo "Missing disk size" >&2
    fi
    export DOCKER_MACHINE_DISK_SIZE=$1
}

docker_machine_set_memory() {
    if [ -z $1 ]; then
        echo "Missing memory value" >&2
        return 1
    fi
    export DOCKER_MACHINE_MEMORY=$1
}

docker_machine_set_driver() {
    if [ -z $1 ]; then
        echo "Missing driver value" >&2
        return 1
    fi
    export DOCKER_MACHINE_DRIVER=$1
}

docker_machine_ensure_created() {
    docker_machine_errored && docker_machine_destroy
    docker_machine_exists
    if [ $? -ne 0 ]; then
        docker-machine create -d ${DOCKER_MACHINE_DRIVER} \
            --virtualbox-cpu-count "${DOCKER_MACHINE_CPUS}" \
            --virtualbox-disk-size "${DOCKER_MACHINE_DISK_SIZE}" \
            --virtualbox-memory "${DOCKER_MACHINE_MEMORY}" \
            ${DOCKER_MACHINE_NAME}
    fi
}

docker_machine_errored() {
    docker-machine ls --filter state=Error 2> /dev/null | grep "^${DOCKER_MACHINE_NAME} " >> /dev/null 2>/dev/null
    return $?
}

docker_machine_upgrade() {
    docker-machine upgrade ${DOCKER_MACHINE_NAME}
}

docker_machine_exists() {
    docker-machine ls | grep "^${DOCKER_MACHINE_NAME} " >> /dev/null
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
    docker_machine_exists
    if [ $? -eq 0 ]; then
        docker_machine_isrunning || docker_machine_start
    else
        echo "Docker machine ${DOCKER_MACHINE_NAME} does not exist" >&2
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

docker_machine_unalias() {
    unalias docker
    unalias "docker-compose"
}

docker_machine_alias() {
    docker_machine_isrunning
    if [ $? -ne 0 ]; then
        alias docker="docker_machine_ensure && docker_machine_unalias && docker $@"
        alias "docker-compose"="docker_machine_ensure && docker_machine_unalias && docker-compose $@"
    else
        docker_machine_eval_config
    fi
}

docker_machine_forward_port_vbox() {
    docker_machine_exists
    if [ $? -ne 0 ]; then
        echo "You haven't created a docker-machine VM yet" >&2
        return 1
    fi

    if [ -z $1 ]; then
        echo "Usage: $0 port [tcp|udp]" >&2
        return 1
    fi

    local port=$1
    local proto="tcp"

    if [ ! -z $2 ]; then
        proto=$2
    fi

    local subcommand="modifyvm"
    if (docker_machine_isrunning); then
        subcommand="controlvm"
    fi

    VboxManage ${subcommand} "${DOCKER_MACHINE_NAME}" natpf1 \
        "user-defined-port${port},${proto},,${port},,${port}"
}

docker_machine_forward_port_ssh() {
    docker_machine_isrunning
    if [ $? -ne 0 ]; then
        echo "Your docker-machine VM isn't running" >&2
        return 1
    fi

    if [ -z $1 ]; then
        echo "Usage: $0" >&2
        return 1
    fi

    local port=$1

    ssh -o StrictHostKeyChecking=no \
        -i $HOME/.docker/machine/machines/${DOCKER_MACHINE_NAME}/id_rsa \
        -f \
        -L ${port}:localhost:${port} \
        docker@$(docker-machine ip ${DOCKER_MACHINE_NAME}) \
        -N
}

docker_machine_load_defaults
docker_machine_alias
