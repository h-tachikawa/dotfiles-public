# masutaka's original .zshrc for zsh 4.0.2-later

#---------------------------------------------------------------------
# Shell variables
#---------------------------------------------------------------------
if [ -z "$WINDOW" ]; then
	WINDOW='?'
fi

# プロンプト(man zshmisc)
PROMPT='%B%U%m%u:%/ $%b '
RPROMPT="[%T]%1(v|%F{green}%1v%f|)"

# 履歴を保存するファイル
HISTFILE=$HOME/.zhistory

# メモリ内の履歴の数
HISTSIZE=1000000

# $HISTFILE に保存される履歴の数
SAVEHIST=1000000

# 新規メールが来ても、メッセージを出さない。
MAILCHECK=0

FPATH=$HOME/.zsh/functions:/usr/local/share/zsh/site-functions:$FPATH

#---------------------------------------------------------------------
# Shell options
#---------------------------------------------------------------------
# tab キーを押したときに beep しない。
setopt nolistbeep

# cd の際に自動的に pushdしてくれる。(for alias=d)
setopt auto_pushd

# コマンドの問い合わせ訂正
setopt correct

# {a-c} を a b c に展開する機能が使える。
#setopt	brace_ccl

# ワイルドカード拡張、ファイル名で #, ~, ^ の 3 文字を正規表現として扱う。(man zshexpn)
setopt extended_glob

# $HISTFILEに時間も記録
setopt extended_history

# 同じコマンドの history は履歴に入れない
setopt hist_ignore_all_dups

# 前回と同じコマンドの history は履歴に入れない
setopt hist_ignore_dups

# コマンドラインの先頭にスペースをいれておくとそのコマンドはヒストリに追加しない。
setopt hist_ignore_space

# バックグラウンド・ジョブの終了を即座に通知する。
setopt notify

# コマンドの返り値が 0 以外の時に表示してくれる。
#setopt print_exit_value

# プロンプトに環境変数やエスケープシーケンスを含める。
#setopt prompt_subst

# 既にpushdしたディレクトリはダブらせずにディレクトリスタックの先頭に持って来る。
setopt pushd_ignore_dups

# 他の端末と履歴の同期を取る。=>
# 適当なタイミングで 'fc -RI'する方が使い易いかも。
setopt share_history

# 既存のファイルへの上書きリダイレクト防止
unsetopt clobber

# シェル終了時に子プロセスに HUP を送らない
setopt nocheckjobs nohup

## cdr
autoload -Uz chpwd_recent_dirs cdr add-zsh-hook
add-zsh-hook chpwd chpwd_recent_dirs
mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/shell"
zstyle ':completion:*:*:cdr:*:*' menu selection
zstyle ':completion:*' recent-dirs-insert both
zstyle ':chpwd:*' recent-dirs-max 500
zstyle ':chpwd:*' recent-dirs-default true
zstyle ':chpwd:*' recent-dirs-file "${XDG_CACHE_HOME:-$HOME/.cache}/shell/chpwd-recent-dirs"
zstyle ':chpwd:*' recent-dirs-pushd true

## show vcs branch name (1/2)
autoload -Uz vcs_info
zstyle ':vcs_info:*' enable git svn hg bzr
zstyle ':vcs_info:*' formats '(%s:%b)'
zstyle ':vcs_info:*' actionformats '(%s:%b|%a)'
zstyle ':vcs_info:(svn|bzr):*' branchformat '%b:r%r'
zstyle ':vcs_info:bzr:*' use-simple true

## まともな kill の補完にする。
zstyle ':completion:*:processes' command 'ps x -o pid,s,args'

## 補完時に大文字小文字を区別しない。
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

function preexec() {
	# screen へのヒント情報。(1/2)
	# コマンド実行中はコマンド名を、未実行ならカレントディレクトリを表示する。
	if [ "$TERM" = "screen" ]; then
		echo -ne "\ek#${1%% *}\e\\"
	fi
}
function precmd() {
	# screen へのヒント情報。(2/2)
	if [ "$TERM" = "screen" ]; then
		echo -ne "\ek$(basename $(pwd))\e\\"
	fi

	## show vcs branch name (2/2)
    psvar=()
    LANG=en_US.UTF-8 vcs_info
    [[ -n "$vcs_info_msg_0_" ]] && psvar[1]="$vcs_info_msg_0_"
}

if [ "$EMACS" != "t" ]; then
	# ディレクトリ名だけでcd
	setopt auto_cd

	# Ctrl-Sで端末を固まらせない。
	stty -ixon

	# 補間候補を C-fとかC-nとかで選択できる。
	zstyle ':completion:*:default' menu select=1

	# /usr(/local)?/share/zsh/4.0.6/functions 以下にある補間コレクションを使う。
	autoload -Uz compinit; compinit -u

	if [ -f /usr/local/share/zsh/site-functions/go ]; then
		source /usr/local/share/zsh/site-functions/go
	fi

	# tetris
#	autoload -Uz tetris; zle -N tetris

	#--------------------------------------------------------------------- peco
	function exists() { type $1 > /dev/null }

	if exists peco; then
		function peco_select_history() {
			local tac
			exists gtac && tac="gtac" || { exists tac && tac="tac" || { tac="tail -r" } }
			BUFFER=$(fc -l -n 1 | eval $tac | peco --query "$LBUFFER")
			CURSOR=$#BUFFER         # move cursor
			zle clear-screen
		}
		zle -N peco_select_history
		bindkey '^R' peco_select_history

		function peco_cdr () {
			local selected_dir=$(cdr -l | awk '{ print $2 }' | peco)
			if [ -n "$selected_dir" ]; then
				BUFFER="cd ${selected_dir}"
				zle accept-line
			fi
			zle clear-screen
		}
		zle -N peco_cdr
		bindkey '^xb' peco_cdr

		function peco-pkill() {
			for pid in `ps aux | peco | awk '{ print $2 }'`; do
				kill $pid
				echo "Killed ${pid}"
			done
		}
		alias pk="peco-pkill"

		function peco_ghn_open() {
			local url=$(ghn list | peco --query "$LBUFFER")
			if [ -n "$url" ]; then
				open ${url}
			fi
		}
		zle -N peco_ghn_open
		bindkey '^x^o' peco_ghn_open

		function peco_ghq_look() {
			local selected_dir=$(ghq list --full-path | peco --query "$LBUFFER")
			if [ -n "$selected_dir" ]; then
				BUFFER="cd ${selected_dir}"
				zle accept-line
			fi
			zle clear-screen
		}
		zle -N peco_ghq_look
		bindkey '^x^y' peco_ghq_look
	fi

	#--------------------------------------------------------------------- Key binding
	function my-backward-kill-word() {
		local WORDCHARS="${WORDCHARS:s#/#}"
		zle backward-kill-word
	}
	zle -N my-backward-kill-word
	bindkey '^[h' my-backward-kill-word

	function my-backward-word() {
		local WORDCHARS="${WORDCHARS:s#/#}"
		zle backward-word
	}
	zle -N my-backward-word
	bindkey '^[b' my-backward-word	# 本当は C-, を使いたい。

	function my-forward-word() {
		local WORDCHARS="${WORDCHARS:s#/#}"
		zle forward-word
	}
	zle -N my-forward-word
	bindkey '^[f' my-forward-word	# 本当は C-. を使いたい。

	if [ "$OS_KIND" = "Darwin" ]; then
		# C-x C-p で直前の履歴をクリップボードにコピー
		pbcopy-last-history(){
			zle up-line-or-history
			print -rn $BUFFER | pbcopy
			zle kill-whole-line
		}
		zle -N pbcopy-last-history
		bindkey '^x^p' pbcopy-last-history
	fi

	# ファイル名で補完させる。
	#function _mkdir() { _files }

	# shell-mode風
	autoload -Uz history-search-end
	zle -N history-beginning-search-backward-end history-search-end
	zle -N history-beginning-search-forward-end history-search-end
	bindkey "^[p" history-beginning-search-backward-end
	bindkey "^[n" history-beginning-search-forward-end

	if zle -la | grep -q '^history-incremental-pattern-search'; then
		# glob(*) で履歴をインクリメンタル検索可能。zsh 4.3.10 以降でのみ有効。
#		bindkey '^R' history-incremental-pattern-search-backward
		bindkey '^S' history-incremental-pattern-search-forward
	fi

	bindkey '^[?'	run-help		# カーソル下の manを表示。
	bindkey '^q^q'	quoted-insert
	bindkey '^v'	undefined-key
	bindkey '^w'	kill-region
fi

#---------------------------------------------------------------------
# Functions
#---------------------------------------------------------------------
if [ "$EMACS" = "t" ]; then
	function kd() {
		ls -alF $*
	}
else
	function kd() {
		ls -alF $* | more
	}
fi

function psme() {
	ps auxw$1 | egrep "^(USER|$USER)" | sort -k 2 -n
}

function psnot() {
	ps auxw$1 | egrep -v "^$USER" | sort -k 2 -n
}

function svndiff() {
	svn diff $* | vim -R -
}

#---------------------------------------------------------------------
# Aliases
#---------------------------------------------------------------------
if [ "$OS_KIND" = Darwin ]; then
	alias emacs=/Applications/Emacs.app/Contents/MacOS/Emacs
	alias emacsdevel=/Applications/Emacs-devel.app/Contents/MacOS/Emacs
fi

if type hub > /dev/null; then
	eval "$(hub alias -s)"
fi

if [ "$EMACS" = "t" ]; then
	alias git="git --no-pager"
fi

if exists peco; then
	alias -g B='`git branch | peco | sed -e "s/^\*[ ]*//"`'
fi

alias -g G='2>&1 | grep'
alias -g L='2>&1 | less'

alias be="bundle exec"
alias ce="carton exec"

alias cp="cp -i"
alias mv="mv -i"
alias rm="rm -i"

alias cdg="cd \$(git rev-parse --show-toplevel)"
alias e="eval $EDITOR"
alias expandurl="perl -MLWP::UserAgent -lE 'say LWP::UserAgent->new->head(shift)->request->uri'"
alias g="git"
alias hall="history -E -i 1"
alias ll="kd"
alias rootinstalllog="echo 'find /usr/local -cnewer timestamp | sort'"
alias v="vagrant"

# Local Variables:
# coding: utf-8
# mode: shell-script
# tab-width: 4
# End:
