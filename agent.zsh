# If we have a forwarded agent, do nothing
if [[ -z "$SSH_CONNECTION" ]]; then

  # Avoid actions when using Mac OS Keychain
  if [[ ! $SSH_AUTH_SOCK =~ "com\.apple\.launchd" ]]; then
    export SSH_AGENT_PID=$(find_pid 'ssh-agent')

    if [[ -z "$SSH_AGENT_PID" ]]; then
      export SSH_AGENT_PID=$(find_pid '.*ssh-agent')
    fi

    check_pid_running $SSH_AGENT_PID
    if [[ "$?" -gt 0 ]]; then
      unset SSH_AGENT_PID

      export SSH_AUTH_SOCK=$HOME/.ssh/auth_socket

      # check if there is an old socket file and remove it
      if [[ -w "$SSH_AUTH_SOCK" ]]; then
        rm $SSH_AUTH_SOCK
      fi

      eval $(ssh-agent -a $SSH_AUTH_SOCK -s)
    else
      export SSH_AUTH_SOCK=$(find /tmp -type s -iname 'agent.*' 2>/dev/null)
    fi
  fi

  if [[ -n $(ls $SSH_ID_DIR) ]]; then
    # get ssh-add command and the keys in ssh-agent
    SSH_ADD=$(which ssh-add)
    keys=$($SSH_ADD -l | cut -d " " -f 3)

    # go through all files in $SSH_ID_DIR
    add_key=()
    for k_file in `ls $SSH_ID_DIR/*`; do
      # Check if file is a private key -> Convention over Configuration
      if [[ "$k_file" -pcre-match 'id_\w*_?(?:rsa|dsa|ecdsa)?(?!\.(?:pub|ppk))$' ]]; then
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

