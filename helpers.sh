docker_delete_stopped() {
    docker ps -a -q -f status=exited | xargs docker rm
}

docker_delete_dead() {
    docker ps -a -q -f status=dead | xargs docker rm
}

docker_delete_dangling_images() {
    docker images -q -f dangling=true | xargs docker rmi
}
