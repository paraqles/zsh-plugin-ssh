
# If we have a forwarded agent, do nothing
if [ -z "$SSH_CONNECTION" ]; then

  # Check if gpg-agent took other the socket variable
  # On some linux systems the agent does not work well with `ssh-add`
  #gpg_pid=$(ps -u `whoami` -o pid,command | grep -i gpg-ag | grep -i ent | sed -Ee 's/^\s*//g' | cut -d " " -f 1)
  if [[ ! -z "$GPG_AGENT_INFO" ]]; then
    # We have unset the variables and use ssh-agent.
    # to provide an agent with rsa 8192 bit support
    #source $HOME/.gpg-agent-info
    unset SSH_AGENT_PID
    unset SSH_AUTH_SOCK
  fi

  if [[ ! $SSH_AUTH_SOCK =~ "com\.apple\.launchd" ]]; then

    # Check if we have a PID for an ssh-agent
    if [[ -z "$SSH_AGENT_PID" ]]; then

      # If we have not try to find if a agent is running for the current user
      if [[ -x $(which pgrep) ]]; then
        echo "Find SSH Agent with pgrep"
        SSH_AGENT_PID=$(pgrep -u `whoami` ssh-agent)
      else
        echo "Find SSH Agent with ps"
        SSH_AGENT_PID=$(ps -u `whoami` -o pid,command | grep -i sh-ag | grep -i ent | sed -Ee 's/^\s*//g' | cut -d " " -f 1)
      fi
      export SSH_AGENT_PID

    else
      # if we have a PID, check if the corresponding agent is still running
      if [[ ! `kill -0 $SSH_AGENT_PID 2>/dev/null` ]]; then
        unset SSH_AGENT_PID
      fi

    fi

    # if we have no PID start a new agent.
    if [[ -z "$SSH_AGENT_PID" ]]; then

      SSH_AUTH_SOCK=$HOME/.ssh/auth_socket
      # check if there is an old socket file and remove it
      if [ -w "$SSH_AUTH_SOCK" ]; then
        rm $SSH_AUTH_SOCK
      fi

      eval `ssh-agent -a $SSH_AUTH_SOCK -s`
    fi

  fi

  # Set environment
  if [[ -z "$SSH_AUTH_SOCK" && ! -z "$SSH_AGENT_PID" ]]; then
    SSH_AUTH_SOCK=$HOME/.ssh/auth_socket
  fi

  export SSH_AUTH_SOCK
  export SSH_AGENT_PID

  if [[ ! -z $(ls $SSH_ID_DIR ) ]]; then
    # get ssh-add command and the keys in ssh-agent
    SSH_ADD=$(which ssh-add)
    keys=$($SSH_ADD -l | cut -d " " -f 3)

    # go through all files in $SSH_ID_DIR
    add_key=()
    for k_file in `ls $SSH_ID_DIR/*`; do
      if [[ "$k_file" -pcre-match 'id_[a-zA-Z0-9]*_?rsa(?!\.(pub)|(ppk))$' ]]; then
        # Check if current key is already in the ssh-agent.
        if [[ ! $keys =~ $k_file ]]; then
          add_key[$(($#add_key +1))]=$k_file
        fi
      fi
    done

    if [[ ! -z "$add_key" ]]; then
      $SSH_ADD $add_key
    fi

    unset SSH_ADD
  fi
fi

