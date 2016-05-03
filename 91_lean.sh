# nvm, don't include directly from builds any more
#if [ -d ${HOME}/code/lean/bin ]
#then
#    PATH=$PATH:${HOME}/code/lean/bin
#fi

LEAN_PATH="/home/sean/code/lim/cxxlean/lean/src:/home/sean/code/lim/cxxlean/lean/src/cxx/ast"
if which lean >/dev/null 2>&1
then
	LEAN_PATH=`lean --path`:$LEAN_PATH
fi

export LEAN_PATH
