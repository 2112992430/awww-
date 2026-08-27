# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Which plugins would you like to load?
plugins=(git)

source $ZSH/oh-my-zsh.sh

# powerlevel10k（配置见 ~/.p10k.zsh，可运行 `p10k configure` 重新生成）
source /usr/share/zsh/plugins/powerlevel10k/powerlevel10k.zsh-theme

# 自动补全建议
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# vi 模式
source /usr/share/zsh/plugins/zsh-vi-mode/zsh-vi-mode.zsh

# 补全：tab 上下左右选择
zstyle ':completion:*' menu select
autoload -Uz compinit
compinit

# 自动补全菜单
source /usr/share/zsh/plugins/zsh-autocomplete/zsh-autocomplete.plugin.zsh

export PATH=$PATH:$HOME/.local/bin
bindkey -v

# p10k 自定义配置
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

export PATH=~/.npm-global/bin:$PATH
# >>> miyu zsh hook >>>
[ -r "$HOME/.config/miyu/shell/zsh-hook.zsh" ] && source "$HOME/.config/miyu/shell/zsh-hook.zsh"
# <<< miyu zsh hook <<<
export PATH="$HOME/.cargo/bin:$PATH"

# 语法高亮（必须放在最后加载）
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
