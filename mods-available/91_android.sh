logmsg android::debug setting up android sdk/ndk if available

if [ -d ${HOME}/Android/Sdk ]
then
    logmsg android::debug found an android sdk, adding to path
    PATH=$PATH:${HOME}/Android/Sdk/tools
    PATH=$PATH:${HOME}/Android/Sdk/tools/bin
    PATH=$PATH:${HOME}/Android/Sdk/platform-tools
    PATH=$PATH:${HOME}/Android/Sdk/ndk-bundle
    export PATH
fi

