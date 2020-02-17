#!/bin/bash

USER_DEFINED_ARGUMENT=$1

# possible arguments
GITHUB="github"
PERSONAL="personal"
SCHOOL="school"
WORK="work"


# globals
CURRENT_DIR=$(pwd)

GIT_VARS_SET=false
GIT_SERVER=""

SSH_DIR=""
SSH_URL=""

check_current_dir_for_repo_git_config() {
  if [ ! -f "$CURRENT_DIR/.git/config" ]; then
    echo ""
    echo "    Please navigate to the root of your repo"
    echo "    directory, where .git directory exists."
    echo ""
    exit 1
  fi
}

check_for_and_setup_ssh_dirs_and_files() {
  local CONFIG_FILE=$1
  local PRETTY_CONFIG_FILE=$2

  if [ ! -d $SSH_DIR ]; then
    mkdir -p $SSH_DIR
    echo ""
    echo "    Directory $SSH_DIR"
    echo "    was created"
  fi

  if [ ! -f $CONFIG_FILE ]; then
    touch $CONFIG_FILE
    echo "" >> $CONFIG_FILE
    echo ""
    echo "    File $CONFIG_FILE"
    echo "    was created"
  fi

  if [ ! -f ~/.ssh/config ]; then
    touch ~/.ssh/config
    echo "" >> ~/.ssh/config
    echo ""
    echo "    File ~/.ssh/config"
    echo "    was created"
  fi

  if ! cat ~/.ssh/config | grep -qs "Include $CONFIG_FILE" &&
     ! cat ~/.ssh/config | grep -qs "Include $PRETTY_CONFIG_FILE"; then
    sed -i "1s|^|Include $PRETTY_CONFIG_FILE\n|" ~/.ssh/config
    echo ""
    echo "    Needed 'Include' statement was inserted into ~/.ssh/config."
  fi
}

check_for_https() {
  local REPO_NAME=$1
  local PRETTY_CONFIG_FILE=$2
  local GIT_URL=$(cat $CURRENT_DIR/.git/config \
                  | grep url \
                  | cut -d '=' -f 2 \
                  | sed -e 's/^\s*//')

  if echo "$GIT_URL" | grep -qs "ssh://"; then
    echo ""
    echo "    Manual configuration of url is needed..."
    echo ""
    echo "        Your current $REPO_NAME/.git/config url:"
    echo ""
    echo "        $GIT_URL"
    echo ""
    echo "    Example url format needed in $REPO_NAME/.git/config:"
    echo ""
    echo "        ssh://git@simple_example.github.com/05nelsonm/simple_example.git"
    echo ""
    echo "        ssh://git@     repo     .  server  /  owner  /    repo      .git"
    echo ""
    echo "                  |                       |"
    echo "                  |-----------------------|"
    echo "                              |"
    echo "                 *MUST* match the 'Host' field"
    echo "                 in $PRETTY_CONFIG_FILE"
    echo ""
  else
    GIT_SERVER=$(echo "$GIT_URL" | cut -d '/' -f 3)
    local GIT_REPO_OWNER=$(echo "$GIT_URL" | cut -d '/' -f 4)
    local GIT_REPO_DOT_GIT=$(echo "$GIT_URL" | cut -d '/' -f 5)
    SSH_URL="ssh://git@$REPO_NAME.$GIT_SERVER/$GIT_REPO_OWNER/$GIT_REPO_DOT_GIT"
    GIT_VARS_SET=true
  fi
}

generate_ssh_key() {
  local REPO_NAME=$1
  local MACHINE=$(uname -a | cut -d ' ' -f 2)

  if [ "$REPO_NAME" == "" ]; then
    echo ""
    echo "    Nothing passed in variable REPO_NAME"
    echo ""
    exit 1
  fi

  if [ -f $SSH_DIR/$REPO_NAME.rsa ]; then
    echo ""
    echo "    $SSH_DIR/$REPO_NAME.rsa already exists..."
    pipe_pubkey_to_terminal "$REPO_NAME"
    return 1
  fi

  ssh-keygen -b 4096 -t rsa -C "${MACHINE}-sshKey" -f $SSH_DIR/$REPO_NAME.rsa
  pipe_pubkey_to_terminal "$REPO_NAME"
  return 0
}

help() {
  echo ""
  echo "    Arguments accepted by this script:"
  echo ""
  echo "        $GITHUB"
  echo "        $PERSONAL"
  echo "        $SCHOOL"
  echo "        $WORK"
  echo ""
  echo "    Example:"
  echo ""
  echo "        ~/path/to/script/https_to_ssh.sh $WORK"
  echo ""
  echo "    Tip:"
  echo ""
  echo "        Add to the end of your ~/.bashrc file (may require a PC reboot):"
  echo ""
  echo "            alias https_to_ssh=~/path/to/script/https_to_ssh.sh"
  echo ""
  echo "        And just call from the root directory of your git repo:"
  echo ""
  echo "            https_to_ssh $WORK"
  echo ""
}

input_ssh_config() {
  local REPO_NAME=$1
  local CONFIG_FILE=$2
  local PRETTY_SSH_DIR=$3

  if ! cat $CONFIG_FILE | grep -qs "Host $REPO_NAME.$GIT_SERVER"; then
    echo "Host $REPO_NAME.$GIT_SERVER" >> $CONFIG_FILE
    echo "  HostName $GIT_SERVER" >> $CONFIG_FILE
    echo "  User git" >> $CONFIG_FILE
    echo "  IdentityFile $PRETTY_SSH_DIR/$REPO_NAME.rsa" >> $CONFIG_FILE
    echo "  IdentitiesOnly yes" >> $CONFIG_FILE
    echo "" >> $CONFIG_FILE
  else
    echo ""
    echo "    There is a already a Host entry in"
    echo "    $CONFIG_FILE"
    echo "    that matches this repo's name."
    echo ""
  fi
}

pipe_pubkey_to_terminal() {
  local REPO_NAME=$1

  echo ""
  cat $SSH_DIR/$REPO_NAME.rsa.pub
  echo ""
  echo "    Add ^^^^^^ to your repo"
  echo ""
}

prompt_ssh_keygen() {
  local REPO_NAME=$1
  local YN=

  while true; do

    echo ""
    read -p "    Would you like to create ssh keys for $REPO_NAME? [y/n]: " YN
    echo ""
    case $YN in
      [Yy]* ) return 0;;
      [Nn]* ) return 1;;
      * ) echo "    Please answer y or n."; echo "";;
    esac

  done
}

init() {
  check_current_dir_for_repo_git_config

  local REPO_NAME=$(echo "$CURRENT_DIR" | rev | cut -d '/' -f 1 | rev)
  local ALTERNATIVE_DIR=$(echo "$SSH_DIR" | rev | cut -d '/' -f -2 | rev)
  local PRETTY_SSH_DIR="~/.ssh/$ALTERNATIVE_DIR"
  local CONFIG_FILE=$SSH_DIR/${USER_DEFINED_ARGUMENT}_config
  local PRETTY_CONFIG_FILE="$PRETTY_SSH_DIR/${USER_DEFINED_ARGUMENT}_config"

  check_for_and_setup_ssh_dirs_and_files "$CONFIG_FILE" "$PRETTY_CONFIG_FILE"

  check_for_https "$REPO_NAME" "$PRETTY_CONFIG_FILE"

  if prompt_ssh_keygen "$REPO_NAME"; then
    generate_ssh_key "$REPO_NAME"
  else
    echo ""
    echo "    Exiting... Nothing was modified"
    echo ""
    exit 1
  fi

  if $GIT_VARS_SET; then
    input_ssh_config "$REPO_NAME" "$CONFIG_FILE" "$PRETTY_SSH_DIR"
    git remote set-url origin $SSH_URL
  else
    echo ""
    echo "    Add the following to your $PRETTY_CONFIG_FILE file:"
    echo ""
    echo "        Host $REPO_NAME.domain.com       <- Ex: $REPO_NAME.github.com"
    echo "          HostName domain.com            <- Ex: github.com"
    echo "          User git"
    echo "          IdentityFile $PRETTY_SSH_DIR/$REPO_NAME.rsa"
    echo "          IdentitiesOnly yes"
    echo ""
  fi

  exit 0
}


case $USER_DEFINED_ARGUMENT in

  "$GITHUB")
    SSH_DIR=~/.ssh/$GITHUB
    init
    ;;

  "$PERSONAL")
    SSH_DIR=~/.ssh/github/$PERSONAL
    init
    ;;

  "$SCHOOL")
    SSH_DIR=~/.ssh/github/$SCHOOL
    init
    ;;

  "$WORK")
    SSH_DIR=~/.ssh/github/$WORK
    init
    ;;

  *)
    help
    ;;

esac

exit 0
