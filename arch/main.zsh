if [[ $TERM == xterm-termite ]]; then
    . /etc/profile.d/vte.sh
    __vte_osc7
fi

if [ -r ~/.zshrc -a -r ~/.zshrc.global -a ! -r ~/.zshrc.local ] ; then
    printf '-!-\n'
    printf '-!- Looks like you are using the old zshrc layout of grml.\n'
    printf '-!- Please read the notes in the grml-zsh-refcard, being'
    printf '-!- available at: http://grml.org/zsh/\n'
    printf '-!-\n'
    printf '-!- If you just want to get rid of this warning message execute:\n'
    printf '-!-        touch ~/.zshrc.local\n'
    printf '-!-\n'
fi

# Restore grml-zsh ###
autoload -Uz promptinit
promptinit
prompt restore

# Oh my zsh
export ZSH=$HOME/.oh-my-zsh
ZSH_THEME="robbyrussell"
plugins=(git gitfast git-extras github colorize extract pandoc heroku)
source $ZSH/oh-my-zsh.sh

# Pyenv and Others Virtualenv support
function virtual_env_prompt () {
    REPLY=${VIRTUAL_ENV+(${VIRTUAL_ENV:t}) }
}

grml_theme_add_token virtual-env -f virtual_env_prompt '%F{magenta}' '%f'

zstyle ':prompt:grml:left:setup' items rc virtual-env change-root user at host path vcs percent

# add `|' to output redirections in the history
setopt histallowclobber

# try to avoid the 'zsh: no matches found...'
setopt nonomatch

# warning if file exists ('cat /dev/null > ~/.zshrc')
setopt NO_clobber

# don't warn me about bg processes when exiting
setopt nocheckjobs

# alert me if something failed
setopt printexitvalue

# with spelling correction, assume dvorak kb
setopt dvorak

# Allow comments even in interactive shells
setopt interactivecomments

# Use a default width of 80 for manpages for more convenient reading
export MANWIDTH=${MANWIDTH:-80}

# Color 256
export TERM='xterm-termite'

# Set a search path for the cd builtin
cdpath=(.. ~)

# variation of our manzsh() function; pick you poison:
manzsh()  { /usr/bin/man zshall |  most +/"$1" ; }

# Switching shell safely and efficiently? http://www.zsh.org/mla/workers/2001/msg02410.html
bash() {
    NO_SWITCH="yes" command bash "$@"
}
restart () {
    exec $SHELL $SHELL_ARGS "$@"
}

## Handy functions for use with the (e::) globbing qualifier (like nt)
contains() { grep -q "$*" $REPLY }
sameas() { diff -q "$*" $REPLY &>/dev/null }
ot () { [[ $REPLY -ot ${~1} ]] }

# get_ic() - queries imap servers for capabilities; real simple. no imaps
ic_get() {
    emulate -L zsh
    local port
    if [[ ! -z $1 ]] ; then
        port=${2:-143}
        print "querying imap server on $1:${port}...\n";
        print "a1 capability\na2 logout\n" | nc $1 ${port}
    else
        print "usage:\n  $0 <imap-server> [port]"
    fi
}

## List all occurrences of programm in current PATH
plap() {
    emulate -L zsh
    if [[ $# = 0 ]] ; then
        echo "Usage:    $0 program"
        echo "Example:  $0 zsh"
        echo "Lists all occurrences of program in the current PATH."
    else
        ls -l ${^path}/*$1*(*N)
    fi
}

## Find out which libs define a symbol
lcheck() {
    if [[ -n "$1" ]] ; then
        nm -go /usr/lib/lib*.a 2>/dev/null | grep ":[[:xdigit:]]\{8\} . .*$1"
    else
        echo "Usage: lcheck <function>" >&2
    fi
}

# Download a file and display it locally
uopen() {
    emulate -L zsh
    if ! [[ -n "$1" ]] ; then
        print "Usage: uopen \$URL/\$file">&2
        return 1
    else
        FILE=$1
        MIME=$(curl --head $FILE | \
               grep Content-Type | \
               cut -d ' ' -f 2 | \
               cut -d\; -f 1)
        MIME=${MIME%$'\r'}
        curl $FILE | see ${MIME}:-
    fi
}

## Memory overview
memusage() {
    ps aux | awk '{if (NR > 1) print $5;
                   if (NR > 2) print "+"}
                   END { print "p" }' | dc
}

# Memory percent
mempercent() {
    TOTALMEM=`free | awk '{print $2}' | xargs | awk '{print $2}'`
    USAGEMEM=`free | awk '{print $3}' | xargs | awk '{print $2}'`
    PERCENT=$(echo "$USAGEMEM/$TOTALMEM" | bc -l)
    print $PERCENT
}

## print hex value of a number
hex() {
    emulate -L zsh
    if [[ -n "$1" ]]; then
        printf "%x\n" $1
    else
        print 'Usage: hex <number-to-convert>'
        return 1
    fi
}

# associate types and extensions (be aware with perl scripts and anwanted behaviour!)
check_com zsh-mime-setup || { autoload zsh-mime-setup && zsh-mime-setup }
alias -s pl='perl -S'

## ctrl-s will no longer freeze the terminal.
stty erase "^?"

## you want to automatically use a bigger font on big terminals?
if [[ "$TERM" == "xterm" ]] && [[ "$LINES" -ge 50 ]] && [[ "$COLUMNS" -ge 80 ]] && [[ -z "$SSH_CONNECTION" ]]; then
    large
fi

## Some quick Perl-hacks aka /useful/ oneliner
bew() { perl -le 'print unpack "B*","'$1'"' }
web() { perl -le 'print pack "B*","'$1'"' }
hew() { perl -le 'print unpack "H*","'$1'"' }
weh() { perl -le 'print pack "H*","'$1'"' }
pversion()    { perl -M$1 -le "print $1->VERSION" } # i. e."pversion LWP -> 5.79"
getlinks ()   { perl -ne 'while ( m/"((www|ftp|http):\/\/.*?)"/gc ) { print $1, "\n"; }' $* }
gethrefs ()   { perl -ne 'while ( m/href="([^"]*)"/gc ) { print $1, "\n"; }' $* }
getanames ()  { perl -ne 'while ( m/a name="([^"]*)"/gc ) { print $1, "\n"; }' $* }
getforms ()   { perl -ne 'while ( m:(\</?(input|form|select|option).*?\>):gic ) { print $1, "\n"; }' $* }
getstrings () { perl -ne 'while ( m/"(.*?)"/gc ) { print $1, "\n"; }' $*}
getanchors () { perl -ne 'while ( m/�([^��\n]+)�/gc ) { print $1, "\n"; }' $* }
showINC ()    { perl -e 'for (@INC) { printf "%d %s\n", $i++, $_ }' }
vimpm ()      { vim `perldoc -l $1 | sed -e 's/pod$/pm/'` }
vimhelp ()    { vim -c "help $1" -c on -c "au! VimEnter *" }

set -o vi

export EDITOR=nvim

alias aulas="cd $HOME/Personal/GIT/aulas"
alias vision="cd $HOME/Personal/UFRPE/Mestrado_IA/VISAO"
alias intelivix="cd $HOME/Personal/Intelivix"

## pyenv
if [[ -d $HOME/.pyenv ]]; then
    export PYENV_USER="$HOME/.pyenv"
    export PATH="$PYENV_USER/bin:$PATH"
    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)"
fi

## local_user: pipenv and others
if [[ -d $HOME/.local ]]; then
    export LOCAL_USER="$HOME/.local"
    export PATH="$LOCAL_USER/bin:$PATH"
fi

if (( $+commands[pipenv] )); then
    eval "$(pipenv --completion)"
fi

if (( $+commands[pip] )); then
    eval "$(pip completion --zsh)"
fi

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
