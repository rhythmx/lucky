logmsg haskell::debug Setting up haskell if needed

if [ -d ${HOME}/.cabal/bin ]
then
    logmsg haskell::debug a cabal installation was found. adding to PATH
    PATH=$PATH:${HOME}/.cabal/bin
fi
