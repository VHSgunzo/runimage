#
# /etc/bash.bashrc
#
export SHELL=/usr/bin/bash
export NO_AT_BRIDGE=1
export EDITOR='micro'
export HISTTIMEFORMAT="%F %T "
# If not running interactively, don't do anything
[[ $- != *i* ]] && return

[[ $DISPLAY ]] && shopt -s checkwinsize

case "$TERM" in
    xterm-color) color_prompt=yes ;;
    xterm-256color) color_prompt=yes ;;
esac
force_color_prompt=yes

if [ -n "$force_color_prompt" ]
    then
        if [ -x "$(which tput)" ] && tput setaf 1 >&/dev/null
            then
                color_prompt=yes
            else
                color_prompt=
        fi
fi

if [ "$color_prompt" = yes ];
    then
        PS1="\[\033[0;31m\]\342\224\214\342\224\200\$([[ \$? != 0 ]] && echo \"[\[\033[0;31m\]\342\234\227\[\033[0;37m\]]\342\224\200\")[$(if [[ ${EUID} == 0 ]]; then echo '\[\033[01;31m\]root\[\033[01;33m\]@\[\033[01;96m\]\h'; else echo '\[\033[0;39m\]\u\[\033[01;33m\]@\[\033[01;96m\]\h'; fi)\[\033[0;31m\]]:[\[\033[0;32m\]\w\[\033[0;31m\]]:[\t]\n\[\033[0;31m\]\342\224\224\342\224\200\342\224\200\342\225\274 \[\033[0m\]\[\e[01;33m\]\\$\[\e[0m\] "
    else
        PS1="┌──[\u@\h]:[\w]:[\t]\n└──╼ \$ "
fi

if [ "$color_prompt" = yes ]
    then
        man() {
            env \
            LESS_TERMCAP_mb=$'\e[01;31m' \
            LESS_TERMCAP_md=$'\e[01;31m' \
            LESS_TERMCAP_me=$'\e[0m' \
            LESS_TERMCAP_se=$'\e[0m' \
            LESS_TERMCAP_so=$'\e[01;44;33m' \
            LESS_TERMCAP_ue=$'\e[0m' \
            LESS_TERMCAP_us=$'\e[01;32m' \
            man "$@"
        }
fi

unset color_prompt force_color_prompt

case "$TERM" in
xterm*|rxvt*)
    PS1="\[\033[0;31m\]\342\224\214\342\224\200\$([[ \$? != 0 ]] && echo \"[\[\033[0;31m\]\342\234\227\[\033[0;37m\]]\342\224\200\")[$(if [[ ${EUID} == 0 ]]; then echo '\[\033[01;31m\]root\[\033[01;33m\]@\[\033[01;96m\]\h'; else echo '\[\033[0;39m\]\u\[\033[01;33m\]@\[\033[01;96m\]\h'; fi)\[\033[0;31m\]]:[\[\033[0;32m\]\w\[\033[0;31m\]]:[\t]\n\[\033[0;31m\]\342\224\224\342\224\200\342\224\200\342\225\274 \[\033[0m\]\[\e[01;33m\]\\$\[\e[0m\] "
    ;;
*)
    ;;
esac

if [ -x "$(which dircolors)" ]
    then
        test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
        alias ls='ls --color=auto'
        alias dir='dir --color=auto'
        alias grep='grep --color=auto'
        alias vdir='vdir --color=auto'
        alias fgrep='fgrep --color=auto'
        alias egrep='egrep --color=auto'
fi

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias ll='ls -lh'
alias la='ls -lha'
alias l='ls -CF'
alias em='emacs -nw'
alias _='sudo'
alias _i='sudo -i'
alias please='sudo'
alias fucking='sudo'
alias cip='curl 2ip.ru'
alias start='systemctl start'
alias stop='systemctl stop'
alias restart='systemctl restart'
alias reload='systemctl reload'
alias status='systemctl status'
alias enable='systemctl enable'
alias disable='systemctl disable'
alias daemon-reload='systemctl daemon-reload'
alias dd='dd bs=8192 status=progress'
if [ "$(id -u)" != 0 ]
    then
        alias pac='sudo pacman'
        alias pacman='sudo pacman'
        alias pacman-key='sudo pacman-key'
        alias packey='sudo pacman-key'
    else
        alias pac='pacman'
fi

[ -r /usr/share/bash-completion/bash_completion   ] && . /usr/share/bash-completion/bash_completion

transfer(){ if [ $# -eq 0 ];then echo "No arguments specified.\nUsage:\n transfer <file|directory>\n ... | transfer <file_name>">&2;return 1;fi;if tty -s;then file="$1";file_name=$(basename "$file");if [ ! -e "$file" ];then echo "$file: No such file or directory">&2;return 1;fi;if [ -d "$file" ];then file_name="$file_name.zip" ,;(cd "$file"&&zip -r -q - .)|curl --progress-bar --upload-file "-" "https://transfer.sh/$file_name"|tee /dev/null,;else cat "$file"|curl --progress-bar --upload-file "-" "https://transfer.sh/$file_name"|tee /dev/null;fi;else file_name=$1;curl --progress-bar --upload-file "-" "https://transfer.sh/$file_name"|tee /dev/null;fi;}

webm2gif() {
    ffmpeg -y -i "$1" -vf palettegen _tmp_palette.png
    ffmpeg -y -i "$1" -i _tmp_palette.png -filter_complex paletteuse -r 10 "${1%.webm}.gif"
    rm _tmp_palette.png
}

export GOPATH=$HOME/go
#export GO111MODULE=off
export MAKEFLAGS="-j$(nproc)"
#export MANGOHUD=1
#export ENABLE_VKBASALT=1
export PATH=$GOPATH/bin:$HOME/.local/bin:$HOME/.cargo/bin:$PATH
