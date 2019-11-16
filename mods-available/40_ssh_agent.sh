
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
        logmsg ssh_agent::error Failed to start an ssh agent
        return
    fi
    echo $agent_output > $SSH_AGENT_ENVFILE
    source "$SSH_AGENT_ENVFILE"
}

function ssh_agent_reset_if_dead() {
    kill -0 "$SSH_AGENT_PID" > /dev/null 2>&1
    pid_exists=$?
    if [ -S "$SSH_AUTH_SOCK" ] && [ $pid_exists ]; then
        logmsg ssh_agent::debug ssh pid is live and sock exists
        return 1
    else
        logmsg ssh_agent::debug "ssh agent env contains stale information, deleting it"
        unset SSH_AUTH_SOCK
        unset SSH_AGENT_PID
        return 0
    fi
}

logmsg ssh_agent::debug Checking environment

# Check current ENV vars
if [ -n "$SSH_AGENT_PID" ] || [ -n "$SSH_AUTH_SOCK" ]; then
    ssh_agent_reset_if_dead || logmsg ssh_agent::debug Using existing \
                                      ssh agent from environment
fi

# Fallback to saved env file
if [ -z "$SSH_AGENT_PID" ] && [ -z "$SSH_AUTH_SOCK" ]; then
    logmsg ssh_agent::debug Checking environment file

    if [ -f "$SSH_AGENT_ENVFILE" ]; then
        logmsg ssh_agent::debug Loading existing agent file
        source "$SSH_AGENT_ENVFILE"
    fi
    if ssh_agent_reset_if_dead ; then
       rm -f "$SSH_AGENT_ENVFILE"
    else
        logmsg ssh_agent::debug Using existing \
               ssh agent from envfile
    fi
fi

# If no ssh_agent env exists
if [ -z "$SSH_AGENT_PID" ]; then
    logmsg ssh_agent::info "Starting a new ssh agent"
    ssh_agent_init
fi

# Handle the case where something external (desktop environment) has started the agent but has not created the environment file
