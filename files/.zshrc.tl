agentpid=$(pgrep gpg-agent)
if [ ! -z "$agentpid" ]; then
  export GPG_AGENT_INFO=/Users/ch/.gnupg/S.gpg-agent:${agentpid}:1
fi

export PATH="$HOME/.cargo/bin:$PATH"

# fuck coredumps on macos, also because of ghc
ulimit -c 0
