#!/bin/bash

##
##    One variable we have to declare before doing anything else
##

export NODE_COUNT=15

##
##    Now we can source the shell libs and set everything up
##

RELOADER="$0"
echo "${RELOADER}"
echo "--------------------"

source ./xtoph-setup/xtoph-setup.shlib
source ./xtoph-setup/virthost-menu.shlib
source ./xtoph-setup/network-menu.shlib
source ./xtoph-setup/ansible-menu.shlib
source ./xtoph-setup/node-menu.shlib
source ./xtoph-setup/bastion-menu.shlib
source ./xtoph-setup/ldap-menu.shlib

##
##    Variables unique to this Project
##

export PROJECT_NAME=""

export WORKSHOP_ADMIN_UID="cloud-admin"
export WORKSHOP_STUDENT_UID="cloud-user"
export RHSM_UID=""

export WORKSHOP_ROOT_PW
export WORKSHOP_ADMIN_PW
export WORKSHOP_STUDENT_PW
export RHSM_PW

##
##    Load current answer file
##

[[ -e ./config/provision-setup.ans ]] && . ./config/provision-setup.ans


# ---

general_dump () {

##
##    NOTE: don't save passwords
##          user will always need
##          to enter ALL of them
##

cat <<EOVARS

## GENERAL SETTINGS

    PROJECT_NAME="${PROJECT_NAME}"
    WORKSHOP_ADMIN_UID="${WORKSHOP_ADMIN_UID}"
    WORKSHOP_STUDENT_UID="${WORKSHOP_USER_UID}"
    RHSM_UID="${RHSM_UID}"

    ##WORKSHOP_ADMIN_PW=""
    ##WORKSHOP_STUDENT_PW=""
    ##RHSM_PW=""

EOVARS

}


# ---

general_settings () {

    ##
    ##    Bash Lesson:  the bash shell parameter expansion ':+' passes
    ##                  expansion if paramenter is set and not null
    ##                  we use this to mask passwords for example
    ##

    echo ""
    echo "Project Name ... ${PROJECT_NAME}"
    echo ""

    echo "[ GENERAL ]"
    echo "    RHSM           ... ${RHSM_UID} / ${RHSM_PW:+**********}"
    echo "    Workshop Admin ... ${WORKSHOP_ADMIN_UID} / ${WORKSHOP_ADMIN_PW:+**********}"
    echo "    Workshop User  ... ${WORKSHOP_STUDENT_UID} / ${WORKSHOP_STUDENT_PW:+**********}"

}



# ---

save_settings () {

    ##
    ##    NOTE: don't save passwords
    ##          user will always need
    ##          to enter ALL of them
    ##

    ##
    ##    NOTE:  Network broadcast and netmask
    ##           are calculated from the prefix
    ##           and also not saved
    ##

    if [[ ! -z ${NETWORK_PREFIX} && ! -z ${NETWORK_ID} ]]; then
        NETWORK_BROADCAST=`ipcalc ${NETWORK_ID}/${NETWORK_PREFIX} -b | cut -d= -f2`
        NETWORK_NETMASK=`ipcalc ${NETWORK_ID}/${NETWORK_PREFIX} -m | cut -d= -f2`
    fi

    general_dump  >  ./config/provision-setup.ans
    ansible_dump  >> ./config/provision-setup.ans
    virthost_dump >> ./config/provision-setup.ans
    bastion_dump  >> ./config/provision-setup.ans
    network_dump  >> ./config/provision-setup.ans
    node_dump     >> ./config/provision-setup.ans
    ldap_dump     >> ./config/provision-setup.ans

}



# ---

current_settings () {
    general_settings
    ansible_settings
    network_settings
    ldap_settings
    bastion_settings
    virthost_settings
    node_settings
}

# ---

general_bulk_edit () {

    TMPFILE="$(mktemp /var/tmp/ocp-workshop-setup.XXXXX)"

    general_dump > $TMPFILE

    vi $TMPFILE

    read -p "Accept BULK EDIT update (Y/N)? " input

    if [[ "${input^^}" == "Y" ]]; then
      source $TMPFILE
      echo "Changes sourced..."
    fi

    rm $TMPFILE

}

# ---


prepare_deployment () {

    echo ""

    echo "## Install Ansible from ${ANSIBLE_SOURCE}"

    case ${ANSIBLE_SOURCE} in 

      "RHSM") 
        ./sample-scripts/rhel9-install-ansible-rhsm.sh 
        ;;

      "EPEL") 
        ./sample-scripts/rhel9-install-ansible-epel.sh 
        ;;
    
      "INSTALLED") 
        echo " - success (ansible already installed)"
        ;;

      "*" )
        echo "WARNING: you must set a valid ansible source"
        return 1
        ;;
    esac



    echo -n "## Parsing sample-configs"



    echo -n "## Templating configuration files"
    ansible-playbook sample-configs/provision-setup.yml

    echo -n "## Encrypt the credentials.yml"

    if [[ -z "${ANSIBLE_VAULT_PW}" ]]; then
      echo " - FAILED" 
      echo "WARNING: you must set the ANSIBLE_VAULT_PW"
      return 1
    else
      echo "${ANSIBLE_VAULT_PW}" > ./config/vault-pw.tmp
      ansible-vault encrypt --vault-password-file ./config/vault-pw.tmp config/credentials.yml 1>/dev/null 2>&1

      if [[ $? ]] ; then
        rm -f ./config/vault-pw.tmp
        echo " - success" 
      else
        rm -f ./config/vault-pw.tmp
        echo " - FAILED" 
        return 1
      fi
    fi

}

# ---

general_menu () {

    SAVED_PROMPT="$PS3"

    PS3="GENERAL MENU: "

    current_settings

    select action in "RETURN to previous menu"   \
                     "Set RHSM UID/PW"           \
                     "Set Workshop Admin UID/PW" \
                     "Set Workshop Student UID/PW"  \
                     "Set Default BMC UID/PW"    
                     
    do
      case ${action}  in

          "Set RHSM UID/PW" )
             set_uidpw "RH Subscription Manager" RHSM_UID RHSM_PW 
              ;; 
          "Set Workshop Admin UID/PW" )
             set_uidpw "Workshop Admin" WORKSHOP_ADMIN_UID WORKSHOP_ADMIN_PW
              ;; 
          "Set Workshop Student UID/PW" )
             set_uidpw "Workshop Student" WORKSHOP_STUDENT_UID WORKSHOP_STUDENT_PW
              ;; 
          "Set Default BMC UID/PW" )
              set_uidpw "Default BMC" BMC_UID_DEFAULT BMC_PW_DEFAULT
              ;; 
          "RETURN to previous menu")
              PS3=${SAVED_PROMPT}
              break
              ;;

          "*")
              echo "That's NOT an option, try again..."
              ;;
      esac 
              
      ##
      ##    Reprint the current settings
      ##

      current_settings

      ##
      ##    The following causes the select
      ##    statement to reprint the menu
      ##

      REPLY=

    done

}

# ---

main_menu () {

    PS3="MAIN MENU (select action): "

    current_settings

    select action in "PREPARE Deployment" \
                     "Set Project Name" \
                     "General Settings" \
                     "Ansible Settings" \
                     "Network Settings" \
                     "LDAP Settings" \
                     "Bastion Settings" \
                     "Virt Host Settings" \
                     "Node Settings" \
                     "SAVE Current Params" \
                     "RELOAD Saved Params"
    do
      case ${action}  in

        "Set Project Name")
          set_key "Project Name" PROJECT_NAME
          ;;
        "General Settings")
          general_menu
          ;;
        "Ansible Settings")
          ansible_menu
          ;;
        "Network Settings")
          network_menu
          ;;
        "LDAP Settings")
          ldap_menu
          ;;
        "Bastion Settings")
          bastion_menu
          ;;
        "Virt Host Settings")
          virthost_menu
          ;;
        "Node Settings")
          node_menu
          ;;
        "PREPARE Deployment")
          save_settings
          prepare_deployment
          ;;
        "SAVE Current Params")
          save_settings
          ;;
        "RELOAD Saved Params")
          exec "${RELOADER}"
          break
          ;;
        "*")
          echo "That's NOT an option, try again..."
          ;;       
 
      esac

      ##
      ##    Reprint the current settings
      ##

      current_settings

      ##
      ##    The following causes the select
      ##    statement to reprint the menu
      ##

      REPLY=

    done

}


##
##    Testing for 'ansible-playbook' command
##

[[ -x `which ansible-playbook` ]] && ANSIBLE_SOURCE="INSTALLED"


##
##    Engage the main_menu
##

main_menu



