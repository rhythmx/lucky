if [ -d ${HOME}/Android/Sdk ]
then
    PATH=$PATH:${HOME}/Android/Sdk/tools
    PATH=$PATH:${HOME}/Android/Sdk/tools/bin
    PATH=$PATH:${HOME}/Android/Sdk/platform-tools
    PATH=$PATH:${HOME}/Android/Sdk/ndk-bundle
    export PATH
fi

