
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

function ssh_agent_reset_if_dead() {
    kill -0 $SSH_AGENT_PID > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        logmsg debug "ssh agent env contains stale information, deleting it"
        unset SSH_AUTH_SOCK
        unset SSH_AGENT_PID
        return 0
    else
        return 1
    fi
}

# Check current ENV vars
if [ -n "$SSH_AGENT_PID" -a -S "$SSH_AUTH_SOCK" ]; then
    ssh_agent_reset_if_dead || logmsg debug Using existing \
                                      ssh agent from environment
fi

# If no ssh_agent env exists
if [ -z "$SSH_AGENT_PID" ]; then
    if [ -f "$SSH_AGENT_ENVFILE" ]; then
        source "$SSH_AGENT_ENVFILE"
        if ssh_agent_reset_if_dead; then
            rm -f "$SSH_AGENT_ENVFILE"
            ssh_agent_init
        else
            logmsg debug "Using ssh agent from env file"
        fi
    else
        logmsg info "Starting a new ssh agent"
        ssh_agent_init
    fi
fi

# Handle the case where something external (desktop environment) has started the agent but has not created the environment file
