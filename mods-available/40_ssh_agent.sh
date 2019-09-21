
SSH_AGENT_LIFETIME=86400
SSH_AGENT_ENVFILE="$LUCKY_RUNDIR/ssh_agent.run"

# Example ssh-agent output
#
# SSH_AUTH_SOCK=/tmp/ssh-sIU9GM6LlxHL/agent.15417; export SSH_AUTH_SOCK;
# SSH_AGENT_PID=15418; export SSH_AGENT_PID;
# echo Agent pid 15418;

function ssh_agent_init() {
    agent_output=$(ssh-agent -s -t $SSH_AGENT_LIFETIME | grep -v 'echo Agent')
    if [ $? -ne 0 ]; then
        logmsg error Failed to start an ssh agent
        return
    fi
    echo $agent_output > $SSH_AGENT_ENVFILE
    source "$SSH_AGENT_ENVFILE"
}

if [ -f "$SSH_AGENT_ENVFILE" ]; then
    source "$SSH_AGENT_ENVFILE" 
    kill -0 $SSH_AGENT_PID > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        logmsg debug "ssh agent envfile contains stale information, deleting it"
        unset SSH_AUTH_SOCK
        unset SSH_AGENT_PID
        rm -f "$SSH_AGENT_ENVFILE"
    else
        logmsg debug "using existing ssh agent pid:$SSH_AGENT_PID"
    fi
fi

if [ -z "$SSH_AGENT_PID" ]; then
    logmsg info "Starting a new ssh agent"
    ssh_agent_init
fi
