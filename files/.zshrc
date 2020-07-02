# Based on grml's zshrc, which is GPLv2, (c) Michael Prokop <mika@grml.org> and others.

#PS4='+$(date "+%s:%N") %N:%i> '
#exec 3>&2 2>/tmp/startlog.$$
#setopt xtrace prompt_subst

# .cache/zsh is used for completion cache, and .cache is used for history and zcompdump
[ -d $HOME/.cache/zsh ] || mkdir -p $HOME/.cache/zsh

isdarwin(){
    [[ $OSTYPE == darwin* ]] && return 0 || return 1
}
isfreebsd(){
    [[ $OSTYPE == freebsd* ]] && return 0 || return 1
}

# Setup PATH from system defaults on macOS.
isdarwin && [ -x /usr/libexec/path_helper ] && eval `/usr/libexec/path_helper -s`

# Need this here to detect which emacsclient to start.
if [[ -d $HOME/bin ]]; then
  export PATH=$HOME/bin:$PATH
fi

setopt append_history extended_history histignorealldups histignorespace extended_glob longlistjobs notify hash_list_all completeinword nohup auto_pushd pushd_ignore_dups nonomatch nobeep noglobdots noshwordsplit unset nocorrect

check_com() {
    emulate -L zsh
    [[ -n ${commands[$1]}  ]] && return 0 || return 1
}

export EDITOR=vim
#export ALTERNATE_EDITOR=emacs
#check_com emacsclient && {
#  export EDITOR="$(which emacsclient)"
#  if [ -f $HOME/.cache/zsh/emacsclient_c ]; then
#    export EDITOR="$EDITOR -c"
#  elif [ \! -f $HOME/.cache/zsh/emacsclient_no_c ]; then
#    echo "detecting $EDITOR capabilities"
#    if [ \! -z "$($EDITOR --help | grep -- '-c')" ]; then
#      export EDITOR="$EDITOR -c"
#      touch $HOME/.cache/zsh/emacsclient_c
#      echo " ... using -c"
#    else
#      touch $HOME/.cache/zsh/emacsclient_no_c
#      echo " ... no -c"
#    fi
#  fi
#}
export PAGER=${PAGER:-less}
export SHELL='/bin/zsh'

# color setup for ls:
check_com dircolors && eval $(dircolors -b)
# color setup for ls on OS X / FreeBSD:
isdarwin && export CLICOLOR=1
isfreebsd && export CLICOLOR=1

# support colors in less
export LESS_TERMCAP_mb=$'\E[01;31m'
export LESS_TERMCAP_md=$'\E[01;31m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_so=$'\E[01;44;33m'
export LESS_TERMCAP_ue=$'\E[0m'
export LESS_TERMCAP_us=$'\E[01;32m'

REPORTTIME=5       # report about cpu-/system-/user-time of command if running longer than 5 seconds

# automatically remove duplicates from these arrays
typeset -U path cdpath fpath manpath
# }}}

# {{{ keybindings
bindkey -e

if [[ "$TERM" != emacs ]] ; then
  [[ -z "$terminfo[kdch1]" ]] || bindkey -M emacs "$terminfo[kdch1]" delete-char
  bindkey "^[[7~" beginning-of-line
  bindkey "^[[8~" end-of-line
fi

## use Ctrl-left-arrow and Ctrl-right-arrow for jumping to word-beginnings on the CL
bindkey "\e[5C" forward-word
bindkey "\e[5D" backward-word
bindkey "\e[1;5C" forward-word
bindkey "\e[1;5D" backward-word
## the same for alt-left-arrow and alt-right-arrow
bindkey '^[[1;3C' forward-word
bindkey '^[[1;3D' backward-word

# Search backward in the history for a line beginning with the current
# line up to the cursor and move the cursor to the end of the line then
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end  history-search-end

#m# k Shift-tab Perform backwards menu completion
if [[ -n "$terminfo[kcbt]" ]]; then
    bindkey "$terminfo[kcbt]" reverse-menu-complete
elif [[ -n "$terminfo[cbt]" ]]; then # required for GNU screen
    bindkey "$terminfo[cbt]"  reverse-menu-complete
fi

autoload history-search-end

# completion system
autoload compinit && compinit -d $HOME/.cache/zcompdump

autoload zed # use ZLE editor to edit a file or function

zmodload -i zsh/complist
zmodload -a zsh/stat zstat

# press esc-e for editing command line in $EDITOR or $VISUAL
if autoload edit-command-line && zle -N edit-command-line ; then
    #k# Edit the current line in \kbd{\$EDITOR}
    bindkey '\ee' edit-command-line
fi

if [[ -n ${(k)modules[zsh/complist]} ]] ; then
    #k# menu selection: pick item but stay in the menu
    bindkey -M menuselect '\e^M' accept-and-menu-complete
    # also use + and INSERT since it's easier to press repeatedly
    bindkey -M menuselect "+" accept-and-menu-complete
    bindkey -M menuselect "^[[2~" accept-and-menu-complete

    # accept a completion and try to complete again by using menu
    # completion; very useful with completing directories
    # by using 'undo' one's got a simple file browser
    bindkey -M menuselect '^o' accept-and-infer-next-history
fi

# run command line as user root via sudo:
sudo-command-line() {
    [[ -z $BUFFER ]] && zle up-history
    if [[ $BUFFER != sudo\ * ]]; then
        BUFFER="sudo $BUFFER"
        CURSOR=$(( CURSOR+5 ))
    fi
}
zle -N sudo-command-line

#k# prepend the current command with "sudo"
bindkey "^Os" sudo-command-line

# {{{ history
HISTFILE=$HOME/.cache/zsh_history
HISTSIZE=5000
SAVEHIST=10000 # useful for setopt append_history
# }}}

# directory based profiles {{{
CHPWD_PROFILE='default'
function chpwd_profiles() {
    # Say you want certain settings to be active in certain directories.
    # This is what you want.
    #
    # zstyle ':chpwd:profiles:/usr/src/grml(|/|/*)'   profile grml
    # zstyle ':chpwd:profiles:/usr/src/debian(|/|/*)' profile debian
    #
    # When that's done and you enter a directory that matches the pattern
    # in the third part of the context, a function called chpwd_profile_grml,
    # for example, is called (if it exists).
    #
    # If no pattern matches (read: no profile is detected) the profile is
    # set to 'default', which means chpwd_profile_default is attempted to
    # be called.
    #
    # A word about the context (the ':chpwd:profiles:*' stuff in the zstyle
    # command) which is used: The third part in the context is matched against
    # ${PWD}. That's why using a pattern such as /foo/bar(|/|/*) makes sense.
    # Because that way the profile is detected for all these values of ${PWD}:
    #   /foo/bar
    #   /foo/bar/
    #   /foo/bar/baz
    # So, if you want to make double damn sure a profile works in /foo/bar
    # and everywhere deeper in that tree, just use (|/|/*) and be happy.
    #
    # The name of the detected profile will be available in a variable called
    # 'profile' in your functions. You don't need to do anything, it'll just
    # be there.
    #
    # Then there is the parameter $CHPWD_PROFILE is set to the profile, that
    # was is currently active. That way you can avoid running code for a
    # profile that is already active, by running code such as the following
    # at the start of your function:
    #
    # function chpwd_profile_grml() {
    #     [[ ${profile} == ${CHPWD_PROFILE} ]] && return 1
    #   ...
    # }
    #
    # The initial value for $CHPWD_PROFILE is 'default'.
    #
    # Version requirement:
    #   This feature requires zsh 4.3.3 or newer.
    #   If you use this feature and need to know whether it is active in your
    #   current shell, there are several ways to do that. Here are two simple
    #   ways:
    #
    #   a) If knowing if the profiles feature is active when zsh starts is
    #      good enough for you, you can put the following snippet into your
    #      .zshrc.local:
    #
    #   (( ${+functions[chpwd_profiles]} )) && print "directory profiles active"
    #
    #   b) If that is not good enough, and you would prefer to be notified
    #      whenever a profile changes, you can solve that by making sure you
    #      start *every* profile function you create like this:
    #
    #   function chpwd_profile_myprofilename() {
    #       [[ ${profile} == ${CHPWD_PROFILE} ]] && return 1
    #       print "chpwd(): Switching to profile: $profile"
    #     ...
    #   }
    #
    #      That makes sure you only get notified if a profile is *changed*,
    #      not everytime you change directory, which would probably piss
    #      you off fairly quickly. :-)
    #
    # There you go. Now have fun with that.
    local -x profile

    zstyle -s ":chpwd:profiles:${PWD}" profile profile || profile='default'
    if (( ${+functions[chpwd_profile_$profile]} )) ; then
        chpwd_profile_${profile}
    fi

    CHPWD_PROFILE="${profile}"
    return 0
}
chpwd_functions=( ${chpwd_functions} chpwd_profiles )
# }}}

# gather version control information for inclusion in a prompt {{{

if autoload vcs_info; then
    # `vcs_info' in zsh versions 4.3.10 and below have a broken `_realpath'
    # function, which can cause a lot of trouble with our directory-based
    # profiles. So:
    if [[ ${ZSH_VERSION} == 4.3.<-10> ]] ; then
        function VCS_INFO_realpath () {
            setopt localoptions NO_shwordsplit chaselinks
            ( builtin cd -q $1 2> /dev/null && pwd; )
        }
    fi

    zstyle ':vcs_info:*' max-exports 2

    if [[ -o restricted ]]; then
        zstyle ':vcs_info:*' enable NONE
    fi
fi

# Change vcs_info formats for the grml prompt. The 2nd format sets up
# $vcs_info_msg_1_ to contain "zsh: repo-name" used to set our screen title.
# TODO: The included vcs_info() version still uses $VCS_INFO_message_N_.
#       That needs to be the use of $VCS_INFO_message_N_ needs to be changed
#       to $vcs_info_msg_N_ as soon as we use the included version.
setup_vcsinfo() {
  local BLUE RED GREEN CYAN MAGENTA YELLOW WHITE NO_COLOUR
  autoload colors && colors
  BLUE="%{${fg[blue]}%}"
  RED="%{${fg_bold[red]}%}"
  GREEN="%{${fg[green]}%}"
  CYAN="%{${fg[cyan]}%}"
  MAGENTA="%{${fg[magenta]}%}"
  YELLOW="%{${fg[yellow]}%}"
  WHITE="%{${fg[white]}%}"
  NO_COLOUR="%{${reset_color}%}"

  if [[ "$TERM" == dumb ]] ; then
    zstyle ':vcs_info:*' actionformats "(%s%)-[%b|%a] " "zsh: %r"
    zstyle ':vcs_info:*' formats       "(%s%)-[%b] "    "zsh: %r"
  else
    # these are the same, just with a lot of colours:
    zstyle ':vcs_info:*' actionformats "${MAGENTA}(${NO_COLOUR}%s${MAGENTA})${YELLOW}-${MAGENTA}[${GREEN}%b${YELLOW}|${RED}%a${MAGENTA}]${NO_COLOUR} " \
                                       "zsh: %r"
    zstyle ':vcs_info:*' formats       "${MAGENTA}(${NO_COLOUR}%s${MAGENTA})${YELLOW}-${MAGENTA}[${GREEN}%b${MAGENTA}]${NO_COLOUR}%} " \
                                       "zsh: %r"
    zstyle ':vcs_info:(sv[nk]|bzr):*' branchformat "%b${RED}:${YELLOW}%r"
  fi
  zstyle ':vcs_info:*' enable git hg svn
}
setup_vcsinfo
# }}}

info_print () {
	local esc_begin esc_end
	esc_begin="$1" 
	esc_end="$2" 
	shift 2
	printf '%s' ${esc_begin}
	for item in "$@"
	do
		printf '%s ' "$item"
	done
	printf '%s' "${esc_end}"
}

set_title () {
	info_print $'\e]0;' $'\a' "$@"
}

precmd () {
	vcs_info
	case $TERM in
		(xterm*|rxvt*) set_title ${(%):-"%n@%m: %~"} ;;
	esac
}


setopt prompt_subst
setopt transient_rprompt

EXITCODE="%(?..%?%1v )"
PS2='\`%_> '      # secondary prompt, printed when the shell needs more information to complete a command.
PS3='?# '         # selection prompt used within a select loop.
PS4='+%N:%i:%_> ' # the execution trace prompt (setopt xtrace). default: '+%N:%i>'

# set variable debian_chroot if running in a chroot with /etc/debian_chroot
if [[ -z "$debian_chroot" ]] && [[ -r /etc/debian_chroot ]] ; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

hash -d doc=/usr/share/doc
hash -d log=/var/log

# do we have GNU ls with color-support?
if ls --help 2>/dev/null | grep -- --color= >/dev/null && [[ "$TERM" != dumb ]] ; then
    #a1# execute \kbd{@a@}:\quad ls with colors
    alias ls='ls -b -CF --color=auto'
    #a1# List files, append qualifier to filenames \\&\quad(\kbd{/} for directories, \kbd{@} for symlinks ...)
    alias l='ls -lF --color=auto'
else
    alias ls='ls -b -CF'
    alias l='ls -lF'
fi

alias cp='nocorrect cp'         # no spelling correction on cp
alias mkdir='nocorrect mkdir'   # no spelling correction on mkdir
alias mv='nocorrect mv'         # no spelling correction on mv
alias rm='nocorrect rm'         # no spelling correction on rm

alias s='ssh'
alias acki='ack -i'

# debian stuff
if [[ -r /etc/debian_version ]] ; then
    #a3# Execute \kbd{apt-cache search}
    alias acs='apt-cache search'
    #a3# Execute \kbd{apt-cache show}
    alias acsh='apt-cache show'
    #a3# Execute \kbd{apt-cache policy}
    alias acp='apt-cache policy'
    #a3# Execute \kbd{apt-get dist-upgrade}
    alias adg="sudo apt-get dist-upgrade"
    #a3# Execute \kbd{apt-get install}
    alias agi="sudo apt-get install"
    #a3# Execute \kbd{apt-get upgrade}
    alias ag="sudo apt-get upgrade"
    #a3# Execute \kbd{apt-get update}
    alias au="sudo apt-get update"
    alias dquilt="QUILT_PATCHES=debian/patches quilt"
fi

# {{{ Use hard limits, except for a smaller stack and no core dumps
unlimit
limit stack 8192
limit -s
# }}}

# {{{ completion system

# note: use 'zstyle' for getting current settings
#         press ^Xh (control-x h) for getting tags in context; ^X? (control-x ?) to run complete_debug with trace output
grmlcomp() {
    # TODO: This could use some additional information

    # allow one error for every three characters typed in approximate completer
    zstyle ':completion:*:approximate:'    max-errors 'reply=( $((($#PREFIX+$#SUFFIX)/3 )) numeric )'

    # don't complete backup files as executables
    zstyle ':completion:*:complete:-command-::commands' ignored-patterns '(aptitude-*|*\~)'

    # start menu completion only if it could find no unambiguous initial string
    zstyle ':completion:*:correct:*'       insert-unambiguous true
    zstyle ':completion:*:corrections'     format $'%{\e[0;31m%}%d (errors: %e)%{\e[0m%}'
    zstyle ':completion:*:correct:*'       original true

    # activate color-completion
    zstyle ':completion:*:default'         list-colors ${(s.:.)LS_COLORS}

    # format on completion
    zstyle ':completion:*:descriptions'    format $'%{\e[0;31m%}completing %B%d%b%{\e[0m%}'

    # automatically complete 'cd -<tab>' and 'cd -<ctrl-d>' with menu
    # zstyle ':completion:*:*:cd:*:directory-stack' menu yes select

    # insert all expansions for expand completer
    zstyle ':completion:*:expand:*'        tag-order all-expansions
    zstyle ':completion:*:history-words'   list false

    # activate menu
    zstyle ':completion:*:history-words'   menu yes

    # ignore duplicate entries
    zstyle ':completion:*:history-words'   remove-all-dups yes
    zstyle ':completion:*:history-words'   stop yes

    # match uppercase from lowercase
    zstyle ':completion:*'                 matcher-list 'm:{a-z}={A-Z}'

    # separate matches into groups
    zstyle ':completion:*:matches'         group 'yes'
    zstyle ':completion:*'                 group-name ''

        # if there are more than 5 options allow selecting from a menu
        zstyle ':completion:*'               menu select=5

    zstyle ':completion:*:messages'        format '%d'
    zstyle ':completion:*:options'         auto-description '%d'

    # describe options in full
    zstyle ':completion:*:options'         description 'yes'

    # on processes completion complete all user processes
    zstyle ':completion:*:processes'       command 'ps -au$USER'

    # offer indexes before parameters in subscripts
    zstyle ':completion:*:*:-subscript-:*' tag-order indexes parameters

    # provide verbose completion information
    zstyle ':completion:*'                 verbose true

    # recent (as of Dec 2007) zsh versions are able to provide descriptions
    # for commands (read: 1st word in the line) that it will list for the user
    # to choose from. The following disables that, because it's not exactly fast.
    zstyle ':completion:*:-command-:*:'    verbose false

    # set format for warnings
    zstyle ':completion:*:warnings'        format $'%{\e[0;31m%}No matches for:%{\e[0m%} %d'

    # define files to ignore for zcompile
    zstyle ':completion:*:*:zcompile:*'    ignored-patterns '(*~|*.zwc)'
    zstyle ':completion:correct:'          prompt 'correct to: %e'

    # Ignore completion functions for commands you don't have:
    zstyle ':completion::(^approximate*):*:functions' ignored-patterns '_*'

    # Provide more processes in completion of programs like killall:
    zstyle ':completion:*:processes-names' command 'ps c -u ${USER} -o command | uniq'

    # complete manual by their section
    zstyle ':completion:*:manuals'    separate-sections true
    zstyle ':completion:*:manuals.*'  insert-sections   true
    zstyle ':completion:*:man:*'      menu yes select

    # provide .. as a completion
    zstyle ':completion:*' special-dirs ..

    zstyle ':completion:*' completer _oldlist _expand _complete _files _ignored

    # caching
    zstyle ':completion:*' use-cache yes
    zstyle ':completion:*' cache-path $HOME/.cache/zsh/

    # host completion /* add brackets as vim can't parse zsh's complex cmdlines 8-) {{{ */
    [[ -r ~/.ssh/known_hosts ]] && _ssh_hosts=(${${${${(f)"$(<$HOME/.ssh/known_hosts)"}:#[\|]*}%%\ *}%%,*}) || _ssh_hosts=()
    hosts=(
        $(hostname)
        "$_ssh_hosts[@]"
        localhost
    )
    zstyle ':completion:*:hosts' hosts $hosts

    # use generic completion system for programs not yet defined; (_gnu_generic works
    # with commands that provide a --help option with "standard" gnu-like output.)
    for compcom in cp deborphan df feh fetchipac head hnb ipacsum mv \
                   pal stow tail uname ; do
        [[ -z ${_comps[$compcom]} ]] && compdef _gnu_generic ${compcom}
    done; unset compcom

    # see upgrade function in this file
    compdef _hosts upgrade
}
grmlcomp
# }}}

help-zshglob() {
    echo -e "
    /      directories
    .      plain files
    @      symbolic links
    =      sockets
    p      named pipes (FIFOs)
    *      executable plain files (0100)
    %      device files (character or block special)
    %b     block special files
    %c     character special files
    r      owner-readable files (0400)
    w      owner-writable files (0200)
    x      owner-executable files (0100)
    A      group-readable files (0040)
    I      group-writable files (0020)
    E      group-executable files (0010)
    R      world-readable files (0004)
    W      world-writable files (0002)
    X      world-executable files (0001)
    s      setuid files (04000)
    S      setgid files (02000)
    t      files with the sticky bit (01000)

  print *(m-1)          # Files modified up to a day ago
  print *(a1)           # Files accessed a day ago
  print *(@)            # Just symlinks
  print *(Lk+50)        # Files bigger than 50 kilobytes
  print *(Lk-50)        # Files smaller than 50 kilobytes
  print **/*.c          # All *.c files recursively starting in \$PWD
  print **/*.c~file.c   # Same as above, but excluding 'file.c'
  print (foo|bar).*     # Files starting with 'foo' or 'bar'
  print *~*.*           # All Files that do not contain a dot
  chmod 644 *(.^x)      # make all plain non-executable files publically readable
  print -l *(.c|.h)     # Lists *.c and *.h
  print **/*(g:users:)  # Recursively match all files that are owned by group 'users'
  echo /proc/*/cwd(:h:t:s/self//) # Analogous to >ps ax | awk '{print $1}'<"
}

# aliases {{{
alias insecssh='ssh -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null"'
alias insecscp='scp -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null"'
alias emacs='emacs -nw'
# }}}

# Begin of old .zshrc.local

export HGMERGE=vimdiff
export LANG=en_US.UTF-8
export LC_TIME=de_AT.UTF-8
export LC_CTYPE=en_US.UTF-8
unset LC_ALL
export FULLNAME="Chris Hofstaedtler"
export LESSHISTFILE=$HOME/.cache/lesshst
export CCACHE_DIR=$HOME/.cache/ccache

alias mutt=neomutt
alias M-ch='mutt -F ~/.mutt/M-ch'
alias M-zeha='mutt -F ~/.mutt/M-zeha'
alias M-deb='mutt -F ~/.mutt/M-deb'
alias M-ddva='mutt -F ~/.mutt/M-ddva'
alias M-tgf='mutt -F ~/.mutt/M-tgf'
alias iex='iex --erl "-kernel shell_history enabled"'

zstyle ":chpwd:profiles:$HOME/Source/cardsys(|/|/*)" profile ddva
zstyle ":chpwd:profiles:$HOME/Source/Deduktiva(|/|/*)" profile ddva
zstyle ":chpwd:profiles:$HOME/Source/PowerDNS(|/|/*)" profile ddva
zstyle ":chpwd:profiles:$HOME/Source/yesss(|/|/*)" profile ddva
zstyle ":chpwd:profiles:$HOME/Source/SynPro(|/|/*)" profile synpro
zstyle ":chpwd:profiles:$HOME/Source(|/|/*)" profile zeha
zstyle ":chpwd:profiles:$HOME/Debian(|/|/*)" profile debian

chpwd_profile_initdefaults() {
  export EMAIL="chris.hofstaedtler@deduktiva.com"
  export DEBEMAIL=$EMAIL
  unset DEBSIGN_KEYID
}
chpwd_profile_zeha() {
  [[ ${profile} == ${CHPWD_PROFILE} ]] && return 1
  print 'Switching to profile "zeha"'
  export EMAIL="chris@hofstaedtler.name"
  export DEBEMAIL=$EMAIL
  unset DEBSIGN_KEYID
}
chpwd_profile_ddva() {
  [[ ${profile} == ${CHPWD_PROFILE} ]] && return 1
  print 'Switching to profile "ddva"'
  export EMAIL="chris.hofstaedtler@deduktiva.com"
  export DEBEMAIL=$EMAIL
  unset DEBSIGN_KEYID
}
chpwd_profile_synpro() {
  [[ ${profile} == ${CHPWD_PROFILE} ]] && return 1
  print 'Switching to profile "synpro"'
  export EMAIL="christian.hofstaedtler@synpro.solutions"
  export DEBEMAIL=$EMAIL
  unset DEBSIGN_KEYID
}
chpwd_profile_debian() {
  [[ ${profile} == ${CHPWD_PROFILE} ]] && return 1
  print 'Switching to profile "Debian"'
  export EMAIL="zeha@debian.org"
  export DEBEMAIL=$EMAIL
  export DEBSIGN_KEYID=93052E03
  export MAILRC=~/.mailrc-debian
}

chpwd_profile_default() {
  [[ ${profile} == ${CHPWD_PROFILE} ]] && return 1
  [[ ${CHPWD_PROFILE} == "pylons" ]] && deactivate && unset debian_chroot
  unset MAILRC
  chpwd_profile_initdefaults
}
chpwd_profile_initdefaults

if [ -n "$SSH_AUTH_SOCK" -a -f $HOME/.ssh/id_rsa ]; then
  ssh-add -l >/dev/null || ssh-add
fi

RCHOST=${HOST/.*}

function lprompt {
  if [[ "$TERM" == dumb ]] ; then
    PROMPT="${EXITCODE}${debian_chroot:+($debian_chroot)}%n@%m %40<...<%B%~%b%<< %# "
    return
  fi

  autoload colors && colors

  local col red white reset
  col=red
  [[ $RCHOST == nq ]] && col=green
  [[ $RCHOST == tn ]] && col=green
  [[ $RCHOST == tx ]] && col=green
  [[ $RCHOST == tl ]] && col=green
  [ $EUID == 0 ] && col=red
  reset="%{$reset_color%}"
  col="${reset}%{$fg_bold[$col]%}"
  red="${reset}%{$fg_bold[red]%}"
  white="${reset}%{$fg_bold[white]%}"

  # a simple modification from the grml prompt
  PROMPT="${red}${EXITCODE}${reset}%D{%R} ${white}"'${debian_chroot:+($debian_chroot)}'"${reset}%n@${col}%m${reset}:%40<...<%B%~%b%<< "'${vcs_info_msg_0_}'"%# "
}
if [[ $RCHOST == tl ]]; then
  . ~/.config/zsh/agnoster.zsh-theme
  prompt_time() {
    prompt_segment $PRIMARY_FG white "%D{%R}"
  }
  typeset -aHg AGNOSTER_PROMPT_SEGMENTS=(
    prompt_status
    prompt_time
    prompt_context
    prompt_virtualenv
    prompt_dir
    prompt_git
    prompt_end
  )
else
  lprompt
fi

[[ $RCHOST == percival ]] && umask 077 || umask 022

[[ -r ~/.zshrc.$RCHOST ]] && source ~/.zshrc.$RCHOST

unset RCHOST

#unsetopt xtrace
#exec 2>&3 3>&-

#
# that's all folks.
#
