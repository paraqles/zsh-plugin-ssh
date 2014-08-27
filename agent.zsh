export SSH_AUTH_SOCK=$HOME/.ssh/auth_socket

if [ -z "$SSH_CONNECTION" ]; then
  gpg=${SSH_AUTH_SOCK#gpg}
  if [ -n "$gpg" -a "$gpg" != "$SSH_AUTH_SOCK" ]; then
    unset SSH_AGENT_PID
    unset SSH_AUTH_SOCK
  fi
  if [ -z "$SSH_AGENT_PID" ]; then
    if [ -x $(which pgrep) ]; then
      SSH_AGENT_PID=$(pgrep ssh-agent)
    else
      SSH_AGENT_PID=$(ps -u `whoami` -xco pid,command | grep -i ssh-agent | sed -E -e 's/^\s*//g' -e 's/\s{2,}/ /g' | cut -d " " -f 1)
    fi
    export SSH_AGENT_PID

    if [ -z "$SSH_AGENT_PID" ]; then
      if [ -w "$SSH_AUTH_SOCK" ]; then
        rm $SSH_AUTH_SOCK
      fi
        
      eval `ssh-agent -a $SSH_AUTH_SOCK -s`
    fi
  fi

  export SSH_AUTH_SOCK
  export SSH_AGENT_PID

  SSH_ADD=$(which ssh-add)
  keys=$($SSH_ADD -l | cut -d " " -f 3)

  add_key=()
  for k_file in `ls $SSH_ID_DIR/*`; do
    pub=${k_file%pub}
    ppk=${k_file%ppk}

    # If $pub and $ppk equal to $k_file, the file name does not contain
    # pub or ppk at most end.
    # So then it is save to try to add this id file to the agent.
    if [ "$pub" = "$k_file" -a "$ppk" = "$k_file" ]; then
      if [ ! ${keys[(i)$k_file]} -le ${#keys} ]; then
        add_key[$(($#add_key +1))]=$k_file
      fi
    fi
  done

  if [[ ! -z "$add_key" ]]; then
    $SSH_ADD $add_key
  fi

  unset SSH_ADD
fi

