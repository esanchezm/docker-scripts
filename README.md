#Scripts/functions to make life easier with Docker
  
##OSX docker-machine users:
  
_Note: assumes you're using bash, not ZSH, and already have
VirtualBox and Docker Machine installed_  
  
To load the wrapped alias for docker, run:  

    source docker-machine-setup.sh
  
Optionally to have it load on each session:  

    echo "source $(pwd)/docker-machine-setup.sh" >> $HOME/.bashrc
  
You can now use the docker command without fiddling with docker-machine setup.  
  
###Changing VM settings
Docker Machine machine name: 'default' (for Kitematic Compatibility)  
  
To change the machine's name, number of cpus, memory, disk size, or driver,
change the following variables in the script:

    export DOCKER_MACHINE_NAME="default" # for kitematic compatibility
    DOCKER_MACHINE_CPUS=4
    DOCKER_MACHINE_DISK_SIZE=20000
    DOCKER_MACHINE_MEMORY=2048
    DOCKER_MACHINE_DRIVER="virtualbox"
  
###Function names the script will expose if you want to run them manually:

    docker_machine_alias
    docker_machine_destroy
    docker_machine_ensure
    docker_machine_ensure_created
    docker_machine_ensure_running
    docker_machine_errored
    docker_machine_eval_config
    docker_machine_exists
    docker_machine_isrunning
    docker_machine_recreate
    docker_machine_restart
    docker_machine_start
    docker_machine_status
    docker_machine_stop
    docker_machine_upgrade
  
-------------------------
  
