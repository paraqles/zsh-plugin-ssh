export SSH_AUTH_SOCK=$HOME/.ssh/auth_socket

# If we have a forwarded agent, do nothing
if [ -z "$SSH_CONNECTION" ]; then

  # Check if gpg-agent took other the socket variable
  # On some linux systems the agent does not work well with `ssh-add`
  if [[ $SSH_AUTH_SOCK =~ 'gpg' ]]; then
    unset SSH_AGENT_PID
    unset SSH_AUTH_SOCK
  fi

  # Check if we have a PID for an ssh-agent
  if [ -z "$SSH_AGENT_PID" ]; then

    # If we have not try to find if a agent is running for the current user
    if [ -x $(which pgrep) ]; then
      SSH_AGENT_PID=$(pgrep ssh-agent)
    else
      SSH_AGENT_PID=$(ps -u `whoami` -o pid,command | grep -i sh-ag | grep -i ent | sed -Ee 's/^\s*//g' | cut -d " " -f 1)
    fi
    export SSH_AGENT_PID

  else
    # if we have a PID, check if the corresponding agent is still running
    if kill -0 $SSH_AGENT_PID; then
      # Just a NOP (do not know better way)
      echo "" > /dev/null
    else
      unset SSH_AGENT_PID
    fi
  fi

  # if we have no PID start a new agent.
  if [ -z "$SSH_AGENT_PID" ]; then

    # check if there is an old socket file and remove it
    if [ -w "$SSH_AUTH_SOCK" ]; then
      rm $SSH_AUTH_SOCK
    fi

    eval `ssh-agent -a $SSH_AUTH_SOCK -s`
  fi

  # Set environment
  export SSH_AUTH_SOCK
  export SSH_AGENT_PID

  # get ssh-add command and the keys in ssh-agent
  SSH_ADD=$(which ssh-add)
  keys=$($SSH_ADD -l | cut -d " " -f 3)

  # go through all files in $SSH_ID_DIR
  add_key=()
  for k_file in `ls $SSH_ID_DIR/*`; do
    #pub=${k_file%pub}
    #ppk=${k_file%ppk}

    # If $pub and $ppk equal to $k_file, the file name does not contain
    # pub or ppk at most end.
    # So then it is save to try to add this id file to the agent.
    #if [ "$pub" = "$k_file" -a "$ppk" = "$k_file" ]; then

    if [[ ! $k_file =~ '(pub|ppk)$' ]]; then
      # Check if current key is already in the ssh-agent.
      #if [ ! ${keys[(i)$k_file]} -le ${#keys} ]; then

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

