# If we have a forwarded agent, do nothing
if [[ -z "$SSH_CONNECTION" ]]; then

  # Avoid actions when using Mac OS Keychain
  if [[ ! $SSH_AUTH_SOCK =~ "com\.apple\.launchd" ]]; then
    echo USE OPENSSH

    export SSH_AGENT_PID=$(find_pid ssh-agent)
    export SSH_AUTH_SOCK=$HOME/.ssh/auth_socket

    check_pid_running $SSH_AGENT_PID
    if [[ "$?" -gt 0 ]]; then
      echo SSH AGENT not running
      unset SSH_AGENT_PID

      # check if there is an old socket file and remove it
      if [[ -w "$SSH_AUTH_SOCK" ]]; then
        echo SSH AUTH sock exists
        rm $SSH_AUTH_SOCK
      fi

      echo Start new SSH AGENT
      eval $(ssh-agent -a $SSH_AUTH_SOCK -s)
    fi
  fi

  if [[ -n $(ls $SSH_ID_DIR) ]]; then
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

    if [[ -n "$add_key" ]]; then
      $SSH_ADD $add_key
    fi

    unset SSH_ADD
    unset add_key
    unset keys
  fi
fi

