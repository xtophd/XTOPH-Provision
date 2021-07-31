#!/bin/bash

##
## NOTE: you must point to the correct inventory and extravars yml
##
##   Take a sample configs from ./sample-configs and 
##   copy them to ./playbooks/config
##

myInventory="./config/master-config.yml"

if [[ ! -e "${myInventory}" || ! -e "./xtoph-deploy.yml" ]] ; then
    echo "ERROR: Are you in the right directory? Can not find ${myInventory} | xtoph-deploy.yml" ; exit
    exit
fi

##
##
##

if [[ $2 != "" ]]; then

    echo "Ansible limit set to: $2"

    myLimits="-l $2"

else

    echo "This shell wrapper requires that an ansible limit be specified."
    echo "If you want to deploy all hosts, use 'all' as your limit specifier"
    echo ""
    echo "Examples:"
    echo "  ./xtoph_deploy.sh setup  all"
    echo "  ./xtoph_deploy.sh deploy inventory-hostname"

    if [[ $2 == "all" ]]; then

      myLimits=""

    else

      exit

    fi
fi

##
##
##

case "$1" in

    "deploy"     | \
    "undeploy"   | \
    "redeploy"   | \
    "workshop"   | \
    "setup+"     | \
    "setup")

        time  ansible-playbook --ask-vault-pass -i ${myInventory} -f 10 -e xtoph_deploy_cmd=${1} ${myLimits} xtoph-deploy.yml 
        ;;

    *)
        echo "USAGE: xtoph-deploy.sh [ setup | setup+ | deploy | undeploy | redeploy | workshop ] [ ansible-limit ]"
        echo ""
        echo "  setup     ... runs only 'setup' plays"
        echo "  setup+    ... runs both 'setup' and 'deploy' plays"
        echo "  deploy    ... runs only 'deploy' plays"
        echo "  undeploy  ... runs only 'undeploy' plays"
        echo "  redeploy  ... runs both 'undeploy' and 'deploy' plays"
        echo "  workshop  ... runs only the 'workshop' plays" 
        ;;

esac         
