# nvm, don't include directly from builds any more
#if [ -d ${HOME}/code/lean/bin ]
#then
#    PATH=$PATH:${HOME}/code/lean/bin
#fi


unset LEAN_PATH
if which lean >/dev/null 2>&1
then
	# path must be unset before calling so that compile time path is output
	LEAN_PATH=`lean --path`
	LEAN_PATH=$LEAN_PATH:"/home/sean/code/lim/cxxlean/lean/src:/home/sean/code/lim/cxxlean/lean/src/cxx/ast"
fi

export LEAN_PATH
