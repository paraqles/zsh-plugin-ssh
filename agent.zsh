if [ -z "$SSH_CONNECTION" ]; then
  if [ ${SSH_AUTH_SOCK[(i)gpg]} ]; then
    unset SSH_AGENT_PID
    unset SSH_AUTH_SOCK
  fi
  if [ -z "$SSH_AGENT_PID" ]; then
    if [ -x $(which pgrep) ]; then
      SSH_AGENT_PID=$(pgrep ssh-agent)
      export SSH_AGENT_PID
    else
      SSH_AGENT_PID=$(ps -u `whoami` -xco pid,command | grep -i ssh-agent | tr -s " " | sed -e 's/^ *//g' -e 's/ *$//g' | cut -d " " -f 1)
      export SSH_AGENT_PID
    fi

    if [ -z "$SSH_AGENT_PID" ]; then
      SSH_AUTH_SOCK=$HOME/.ssh/auth_socket
      if [ -r "$SSH_AUTH_SOCK" ]; then
        rm "$SSH_AUTH_SOCK"
      fi
      eval $(ssh-agent -a $SSH_AUTH_SOCK -s)
    fi
  fi
  if [ -z "$SSH_AUTH_SOCK" ]; then
    export SSH_AUTH_SOCK=$HOME/.ssh/auth_socket
  fi

  SSH_ADD=$(which ssh-add)
  keys=$($SSH_ADD -l | cut -d " " -f 3)

  add_key=()
  for k_file in `ls $SSH_ID_DIR/*`; do
    if [ ! ${keys[(i)$k_file]} -le ${#keys} ]; then
      add_key[$(($#add_key +1))]=$k_file
    fi
  done

  if [[ ! -z "$add_key" ]]; then
    $SSH_ADD $add_key
  fi
fi

