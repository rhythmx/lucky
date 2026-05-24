logmsg claude::debug setting up claude

export PATH="$HOME/.local/bin:$PATH"

if ! command -v claude >/dev/null; then
	logmsg claude::warn "claude module enabled but not command not installed. install with `curl -fsSL https://claude.ai/install.sh | bash`"
	return 1
fi

export DISABLE_TELEMETRY=1
export DISABLE_ERROR_REPORTING=1
export DISABLE_FEEDBACK_COMMAND=1
export CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY=1
export NODE_USE_SYSTEM_CA=1
export CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS=1


