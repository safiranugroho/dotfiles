ZSH_THEME="powerlevel10k/powerlevel10k"

# Use case-sensitive completion.
CASE_SENSITIVE="true"

# Disable bi-weekly auto-update checks.
DISABLE_AUTO_UPDATE="true"

# Disable automatically update without prompting.
DISABLE_UPDATE_PROMPT="true"

# Disable auto-setting terminal title.
DISABLE_AUTO_TITLE="true"

# Enable command auto-correction.
ENABLE_CORRECTION="true"

# Format history time
HIST_STAMPS="mm/dd/yyyy"

# Plugins
plugins=(git ruby python heroku docker z)

# Environment variables
source ~/.exports

# Oh My Zsh
source $ZSH/oh-my-zsh.sh

# Functions 
source ~/.functions

# Aliases
source ~/.aliases

# p10k config 
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
