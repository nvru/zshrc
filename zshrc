#!/usr/bin/env zsh

# =========================
# Interactive shell check
# =========================

[[ $- != *i* ]] && return
[[ -n $PS1 ]] || return

# =========================
# PATH setup
# =========================
typeset -U PATH path

# Go fallback
if command -v go >/dev/null 2>&1; then
	go_bin="$(go env GOPATH)/bin"
else
	go_bin="$HOME/go/bin"
fi

path=(
	# User / custom
	/opt/bin
	"$HOME/bin"
	"$HOME/.local/bin"

	# Languages & tools
	"$HOME/.cargo/bin"
	"$go_bin"
	"$HOME/.pdtm/go/bin"
	"$HOME/.local/share/nvim/mason/bin"

	# Compiler cache
	/usr/lib/ccache/bin
	/usr/lib64/ccache
	/usr/lib/ccache

	# System paths
	/usr/local/sbin
	/usr/local/bin
	/usr/sbin
	/usr/bin
	/sbin
	/bin

	# Misc / extra
	/usr/bin/core_perl

	"$path"
)

if [[ -x "$HOME/.local/bin/mise" ]]; then
	eval "$("$HOME"/.local/bin/mise activate --shims zsh)"
fi

export PATH

# =========================================================
# Plugins
# =========================================================

: ${ZPLUGINDIR:=${ZDOTDIR:-$HOME/.local/share/zsh/plugins}}

mkdir -p "$ZPLUGINDIR"

zplugin-load() {
	local repo="$1"
	local name="${repo:t}"
	local dir="$ZPLUGINDIR/$name"
	local init="$dir/$name.plugin.zsh"
	local initfiles

	# Install plugin if missing
	if [[ ! -d "$dir" ]]; then
		print "Installing $repo..."

		git clone \
			--quiet \
			--depth=1 \
			--recursive \
			--shallow-submodules \
			"https://github.com/$repo" \
			"$dir" || {
			print -u2 "Failed to install $repo"
			return 1
		}
	fi

	# Cache the detected init file
	if [[ ! -e "$init" ]]; then
		initfiles=("$dir"/*.{plugin.zsh,zsh-theme,zsh,sh}(N))

		if ((! $#initfiles)); then
			print -u2 "No loadable file found for $repo"
			return 1
		fi

		# If the first file isn't already the desired path,
		# create a symlink named <plugin>.plugin.zsh.
		if [[ "${initfiles[1]}" != "$init" ]]; then
			ln -sf "${initfiles[1]}" "$init"
		fi
	fi

	fpath+=("$dir")

	if (($+functions[zsh - defer])); then
		zsh-defer source "$init"
	else
		source "$init"
	fi
}

zplugin-update() {
	local dir

	for dir in "$ZPLUGINDIR"/*(/N); do
		print "Updating ${dir:t}..."
		git -C "$dir" pull --ff-only
	done
}

zplugin-list() {
	local dir

	for dir in "$ZPLUGINDIR"/*(/N); do
		print "${dir:t}"
	done
}

zplugin-clean() {
	local dir

	for dir in "$ZPLUGINDIR"/*(/N); do
		if [[ ! -d "$dir/.git" ]]; then
			print "Removing ${dir:t}"
			rm -rf "$dir"
		fi
	done
}

zplugin-load romkatv/zsh-defer
zplugin-load zsh-users/zsh-autosuggestions
zplugin-load zsh-users/zsh-syntax-highlighting
zplugin-load zsh-users/zsh-completions

# =========================
# Prompt
# =========================

red='%F{1}'
white='%F{15}'
green='%F{2}'
blue='%B%F{4}'
cyan='%B%F{6}'
fg_light='%F{111}'
blue_soft='%F{75}'
nc='%f%b'
reset='%f%b'

autoload -U colors && colors
setopt PROMPT_SUBST

if [[ $EUID -eq 0 ]]; then
	prompt_symbol="#"
else
	prompt_symbol="$"
fi

tty_name=$(tty)
tty_name=${tty_name#/dev/}

theme="oblong"

case "$theme" in
p10k)
	zplugin-load romkatv/powerlevel10k
	if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
		source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
	fi
	[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh || print "⚠️ ~/.p10k.zsh not found"
	;;
blackarch)
	PS1="%{$fg[blue]%}%B[%b%{$fg[cyan]%}%n%{$fg[grey]%}%B@%b%{$fg[cyan]%}%m%{$fg[blue]%}%B]-%b%{$fg[blue]%}%B[%b%{$fg[white]%}%~%{$fg[blue]%}%B]%b
%{$fg[cyan]%}%B>>>%b%{$reset_color%} "
	;;
ash-full)
	PS1="%~\$(git_branch) ${prompt_symbol} "
	;;
ash)
	PS1="%~ ${prompt_symbol} "
	;;
gruvbox)
	local gruv_orange="%F{214}"
	local gruv_green="%F{142}"
	local gruv_blue="%F{109}"
	local gruv_gray="%F{245}"
	local gruv_reset="%f"

	PROMPT="${gruv_blue}%~ ${gruv_orange}\$(git_branch)${gruv_reset}
${gruv_green}❯ ${gruv_reset}"
	;;
oblong | obolong)
	VIRTUAL_ENV_DISABLE_PROMPT=1
	setopt nopromptbang prompt{cr,percent,sp,subst}
	PS1='%(?:%F{white}:%F{red})◼ ${VIRTUAL_ENV:+"(${VIRTUAL_ENV:t}) "}%(!:%F{red}:%F{white})%n%f:$(_prompt_oblong_pwd)$(_prompt_oblong_git)%f%(!:#:$) '
	PROMPT="$PS1"
	RPS1='%(?::%F{red}$?)'
	;;
*)
	PROMPT="${fg_light}%n${nc} in ${blue_soft}%~${nc}${white}\$(git_branch)\$(go_version) ${prompt_symbol} "
	;;
esac

PROMPT_EOL_MARK=""

# =========================
# Shell options
# =========================

HISTSIZE=10000
SAVEHIST=$HISTSIZE
HISTFILE="$HOME/.local/share/zsh/history"
HISTDUP=erase

setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_FIND_NO_DUPS

setopt autocd
setopt nobeep
setopt numeric_glob_sort
setopt extendedglob
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT

# Completion
autoload -Uz compinit
zmodload zsh/complist
compinit -d "$XDG_CACHE_HOME/zsh/zcompdump"

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' select-prompt '%SScrolling: %p%s'
zstyle ':completion:*' completer _expand _complete
zstyle ':completion:*' rehash true
zstyle ':completion:*' use-compctl false
zstyle ':completion:*' format '>>> %d'
zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' verbose true
zstyle ':completion:*' list-prompt '%SAt %p: Hit TAB for more, or the character to insert%s'
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

# Keybindings
autoload -U select-word-style
select-word-style bash
autoload -Uz edit-command-line
zle -N edit-command-line

bindkey -e
bindkey '^X^E' edit-command-line
bindkey '^[^H' backward-kill-word
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region
bindkey '^[[7~' beginning-of-line
bindkey '^[[H' beginning-of-line
bindkey '^[[8~' end-of-line
bindkey '^[[F' end-of-line
bindkey '^[[2~' overwrite-mode
bindkey '^[[3~' delete-char
bindkey '^[[C' forward-char
bindkey '^[[D' backward-char
bindkey '^[[5~' history-beginning-search-backward
bindkey '^[[6~' history-beginning-search-forward
bindkey '^[Oc' forward-word
bindkey '^[Od' backward-word
bindkey '^[[1;5D' backward-word
bindkey '^[[1;5C' forward-word
bindkey '^[[Z' undo
bindkey ' ' magic-space

# =========================
# Exports
# =========================

export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

if command -v nvim >/dev/null 2>&1; then
	export EDITOR="nvim"
	export VISUAL="nvim"
	export MANPAGER="nvim +Man!"
else
	export EDITOR="vim"
	export VISUAL="vim"
	export MANPAGER="less"
fi

export LS_COLORS='no=00:fi=00:di=00;34:ln=01;36:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.gz=01;31:*.bz2=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.avi=01;35:*.fli=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.ogg=01;35:*.mp3=01;35:*.wav=01;35:*.xml=00;31:'
export TIMEFMT=$'\nreal\t%E\nuser\t%U\nsys\t%S\ncpu\t%P'
# export TZ=''
export LESS_TERMCAP_mb=$'\E[01;31m'
export LESS_TERMCAP_md=$'\E[01;31m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_so=$'\E[01;44;33m'
export LESS_TERMCAP_ue=$'\E[0m'
export LESS_TERMCAP_us=$'\E[01;32m'

mkdir -p \
	"$XDG_CONFIG_HOME" \
	"$XDG_CACHE_HOME" \
	"$XDG_DATA_HOME" \
	"$XDG_STATE_HOME"

if [[ -n "$TTY" ]]; then
	export GPG_TTY=$(tty)
else
	export GPG_TTY="$TTY"
fi

[[ -n "$TERM" ]] && infocmp "$TERM" >/dev/null 2>&1 || export TERM=xterm

# =========================
# Source
# =========================

if [[ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
	source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
	ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=244'
fi

[[ -f /etc/zsh_command_not_found ]] && source /etc/zsh_command_not_found

[[ -f /opt/homebrew/opt/fzf/shell/key-bindings.zsh ]] && source /opt/homebrew/opt/fzf/shell/key-bindings.zsh
[[ -f /opt/homebrew/opt/fzf/shell/completion.zsh ]] && source /opt/homebrew/opt/fzf/shell/completion.zsh

[[ -f /usr/local/opt/fzf/shell/key-bindings.zsh ]] && source /usr/local/opt/fzf/shell/key-bindings.zsh
[[ -f /usr/local/opt/fzf/shell/completion.zsh ]] && source /usr/local/opt/fzf/shell/completion.zsh

[[ -f /usr/share/fzf/key-bindings.zsh ]] && source /usr/share/fzf/key-bindings.zsh
[[ -f /usr/share/fzf/completion.zsh ]] && source /usr/share/fzf/completion.zsh

[[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]] && source /usr/share/doc/fzf/examples/key-bindings.zsh
[[ -f /usr/share/doc/fzf/examples/completion.zsh ]] && source /usr/share/doc/fzf/examples/completion.zsh

# Node / NVM
if command -v nvm >/dev/null; then
	export NVM_DIR="$HOME/.nvm"
	[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
	[[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"
fi

# =========================
# Functions
# =========================

mk() { mkdir -p nmap content creds misc exploits scripts vpn; }

git_branch() {
	local branch
	branch=$(git branch --show-current 2>/dev/null)
	[[ -n $branch ]] && printf " %s" "$branch"
}

_prompt_oblong_pwd() {
	local git_root current_dir
	if git_root=$(command git rev-parse --show-toplevel 2>/dev/null); then
		current_dir="${PWD#${git_root:h}/}"
	else
		current_dir=${(%):-%~}
	fi
	print -n "%F{blue}${current_dir}%f"
}

_prompt_oblong_git() {
	local branch dirty clean
	branch=$(git branch --show-current 2>/dev/null)
	[[ -z $branch ]] && return
	if git diff --quiet --ignore-submodules HEAD 2>/dev/null; then
		clean="%F{green} ◍ "
	else
		dirty="%F{red} ◍ "
	fi
	print -n " %F{white}${branch}${clean}${dirty}%f"
}

vf() {
	local file
	file=$(fzf --preview "bat --color=always {} 2>/dev/null || cat {}") && ${EDITOR:-vim} "$file"
}

fkill() {
	local pid
	pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')
	[[ -n "$pid" ]] && echo "$pid" | xargs kill -${1:-9}
}

interfaces() {
	node <<-EOF
		var os = require('os');
		var i = os.networkInterfaces();
		Object.keys(i).forEach(function(name) {
			i[name].forEach(function(int) {
				if (int.family === 'IPv4') {
					console.log('%s: %s', name, int.address);
				}
			});
		});
	EOF
}

load() {
	node -p <<-EOF
		var os = require('os');
		var c = os.cpus().length;
		os.loadavg().map(function(l) {
			return (l/c).toFixed(2);
		}).join(' ');
	EOF
}

meminfo() {
	node <<-EOF
		var os = require('os');
		var free = os.freemem();
		var total = os.totalmem();
		var used = total - free;
		console.log('memory: %dmb / %dmb (%d%%)',
		    Math.round(used / 1024 / 1024),
		    Math.round(total / 1024 / 1024),
		    Math.round(used * 100 / total));
	EOF
}

colordiff() {
	local red green cyan reset
	red=$(tput setaf 1 2>/dev/null)
	green=$(tput setaf 2 2>/dev/null)
	cyan=$(tput setaf 6 2>/dev/null)
	reset=$(tput sgr0 2>/dev/null)

	diff -u "$@" | awk -v red="$red" -v green="$green" -v cyan="$cyan" -v reset="$reset" '
        /^\-/ { printf("%s", red) }
        /^\+/ { printf("%s", green) }
        /^@/ { printf("%s", cyan) }
        { print $0 reset }'

	return "${PIPESTATUS[0]}"
}

go_version() {
	command -v go >/dev/null 2>&1 || return
	[[ -f go.mod ]] || return
	local v
	v=$(go version 2>/dev/null | awk '{print $3}')
	[[ -n $v ]] && printf " [%s]" "$v"
}

# =========================
# Aliases
# =========================

if command -v doas >/dev/null 2>&1; then
	alias sudo='doas'
	alias root='doas env PATH="$PATH"'
else
	alias root='sudo -E env "PATH=$PATH"'
fi

if command -v nvim >/dev/null 2>&1; then
	alias vi="nvim"
elif command -v vim >/dev/null 2>&1; then
	alias vi="vim"
fi

alias r="reset"
alias ip='ip --color=auto'
alias dir="dir --color=auto"
alias vdir="vdir --color=auto"
alias fgrep="fgrep --color=auto"
alias egrep="egrep --color=auto"
alias dd="dd status=progress"
alias cp="cp -i -v"
alias rm="rm -i"
alias mv="mv -i"
alias df="df -h"
alias free="free -h"
alias du="du -h"
alias shred="shred -zf"
alias wget="wget -U 'noleak'"
alias curl="curl --user-agent 'noleak'"
alias parr='vardump'
alias c='clear'
alias grep='grep --color=auto'
alias open='xdg-open'
alias yayf="yay -Slq | fzf --multi --preview 'yay -Sii {1}' --preview-window=down:75% | xargs -ro yay -S"

if command -v eza >/dev/null 2>&1 && eza --version >/dev/null 2>&1; then
	alias l='eza -lahg --icons --group-directories-first'
	alias ls='eza -g --icons --group-directories-first'
	alias sl='eza -g --icons --group-directories-first'
	alias ll='eza -lhg --icons --group-directories-first'
	alias la='eza -lahg --icons --group-directories-first'
	alias lt='eza --tree --icons'
	alias l2='eza --tree --level=2 --icons'
	alias l3='eza --tree --level=3 --icons'
	alias lnew='eza -lahg --sort=modified --icons'
	alias lold='eza -lahg --sort=modified --reverse --icons'
	[[ -n ${functions[compdef]} ]] && compdef eza=ls
elif command -v exa >/dev/null 2>&1 && exa --version >/dev/null 2>&1; then
	alias l='exa -lahg --icons --group-directories-first'
	alias ls='exa -g --icons --group-directories-first'
	alias sl='exa -g --icons --group-directories-first'
	alias ll='exa -lhg --icons --group-directories-first'
	alias la='exa -lahg --icons --group-directories-first'
	alias lt='exa --tree --icons'
	alias l2='exa --tree --level=2 --icons'
	alias l3='exa --tree --level=3 --icons'
	alias lnew='exa -lahg --sort=modified --icons'
	alias lold='exa -lahg --sort=modified --reverse --icons'
	[[ -n ${functions[compdef]} ]] && compdef exa=ls
else
	alias l='ls -ahls --color=auto'
	alias sl='ls --color=auto'
	alias ls='ls --color=auto'
	alias ll='ls -lh'
	alias la='ls -lha'
fi

alias rot13="tr 'A-Za-z' 'N-ZA-Mn-za-m'"

# =========================
# Shell integration
# =========================

if command -v fzf >/dev/null 2>&1; then
	eval "$(fzf --zsh)"
	zplugin-load Aloxaf/fzf-tab
	zstyle ':completion:*' menu no
	zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
	export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --info=inline"

	if command -v fd >/dev/null 2>&1; then
		export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
		export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
		export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
	fi

	if command -v bat >/dev/null 2>&1; then
		export _FZF_PREVIEW_CMD='bat --color=always --style=plain,numbers --line-range=:500 {}'
	fi

	export FZF_CTRL_T_OPTS="--preview '$_FZF_PREVIEW_CMD'"

	_fzf_file_no_hidden() {
		local cmd result
		cmd="${FZF_DEFAULT_COMMAND/--hidden /}"
		result=$(eval "${cmd:-find . -type f}" | fzf --preview "$_FZF_PREVIEW_CMD") &&
			LBUFFER+="$result"
		zle reset-prompt
	}
	zle -N _fzf_file_no_hidden
fi

if command -v zoxide >/dev/null 2>&1; then
	eval "$(zoxide init --cmd cd zsh)"
fi

if command -v nala >/dev/null 2>&1; then
	apt() {
		if [[ $EUID -eq 0 ]]; then
			command nala "$@"
		elif command -v doas >/dev/null 2>&1; then
			command doas nala "$@"
		else
			command sudo nala "$@"
		fi
	}

	\sudo() {
		if [[ "$1" == "apt" ]]; then
			shift
			if [[ $EUID -eq 0 ]]; then
				command nala "$@"
			elif command -v doas >/dev/null 2>&1; then
				command doas nala "$@"
			else
				command sudo nala "$@"
			fi
		else
			command sudo "$@"
		fi
	}
fi
