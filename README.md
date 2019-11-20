# Local User Configuration Kit (LUCKy)

## Installation

    cd $HOME
    git clone https://github.com/rhythmx/bashrc .bashrc.d
    $HOME/.bashrc.d/lucky.sh install

## Usage

### List available config modules

    $ lucky.sh list-all
    utils                (prio: 00)
    colors               (prio: 01)
    local_installs       (prio: 01)
    editor               (prio: 02)
    general              (prio: 05)
    aliases              (prio: 10)
    cygwin               (prio: 30)
    prompt               (prio: 50)
    passwd_gen           (prio: 70)
    mkgif                (prio: 90)
    youtuber             (prio: 90)
    android              (prio: 91)
    haskell              (prio: 91)
    lean                 (prio: 91)
    rvm                  (prio: 95)

### Enable / Disable modules

    $ lucky.sh disable rvm
    rvm has been disabled

    $ lucky.sh enable rvm
    rvm is now enabled

### Reloading module after changes

    $ eval $(lucky.sh reload rvm)

## TODO ##

- Add some sort of management for local project built with git
  - At a minimum, I'd like to have an alert for local compiled packages with a major revision available
- Alert if common or desired utilties are not available
- Alert if certain system resources are not available
- Support library to allow alerts during prompt generation
