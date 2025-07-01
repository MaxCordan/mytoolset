# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to automatically update without prompting.
# DISABLE_UPDATE_PROMPT="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  alias-finder
  ansible
  aws
  git
  sudo
  kubectl
  terraform
  zsh-autosuggestions
  zsh-syntax-highlighting
  zsh-completions
)
# source <(kubectl completion zsh)
source $ZSH/oh-my-zsh.sh
autoload -U compinit && compinit

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"
# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
alias ll='ls -lah'
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

export AWS_PAGER=""
function eks-login() {
  aws_region=${2:-"us-east-1"}
  eks_clusters=$(aws eks list-clusters --output text --query 'clusters[]')
  for cluster in ${(z)eks_clusters[@]}; do
    aws eks --region $aws_region update-kubeconfig --name ${cluster};
  done
}
function eks-use() {
  cluster_name=${1}
  aws_region=${2:-"us-east-1"}
  account_id=$(aws sts get-caller-identity --query "Account" --output text)
  kubectl config use-context arn:aws:eks:${aws_region}:${account_id}:cluster/${cluster_name}-cluster
}
function aws-use() {
  rm -f ~/.aws
  ln -s ~/.aws_${1} ~/.aws
}
function aws-mfa() {
  token=${1}
  user_id=$(aws sts get-caller-identity --query UserId --output text)
  mfa_device=$(aws iam list-virtual-mfa-devices --query "VirtualMFADevices[?User.UserId=='${user_id}'].SerialNumber" --output text)
  output=$(aws sts get-session-token --serial-number ${mfa_device} --token-code ${token})
  export AWS_ACCESS_KEY_ID=$(echo $output | jq -r ."Credentials.AccessKeyId")
  export AWS_SECRET_ACCESS_KEY=$(echo $output | jq -r ."Credentials.SecretAccessKey")
  export AWS_SESSION_TOKEN=$(echo $output | jq -r ."Credentials.SessionToken")
}
function aws-asume-role() {
  output=$(aws sts assume-role --role-arn "arn:aws:iam::${1}:role/${2}" --role-session-name AWSCLI-Session)
  export AWS_ACCESS_KEY_ID=$(echo $output | jq -r ."Credentials.AccessKeyId")
  export AWS_SECRET_ACCESS_KEY=$(echo $output | jq -r ."Credentials.SecretAccessKey")
  export AWS_SESSION_TOKEN=$(echo $output | jq -r ."Credentials.SessionToken")
}
function aws-mfa-reset() {
  unset AWS_ACCESS_KEY_ID
  unset AWS_SECRET_ACCESS_KEY
  unset AWS_SESSION_TOKEN
}
function ssh-aws() {
  aws ssm start-session --target $1 --document-name AWS-StartInteractiveCommand --parameters command="cd ~ && bash -l"
}
function ec2-list-instances() {
  aws_region="us-east-1"
  FILTERS=()
  while [ -n "$1" ]; do
    case "$1" in
      -r) aws_region=${2}
      shift ;;
      -ip) FILTERS+=("Name=network-interface.addresses.private-ip-address,Values=$2")
      shift ;;
      -p) FILTERS+=("Name=tag:Project,Values=$2")
      shift ;;
      -e) FILTERS+=("Name=tag:Environment,Values=$2")
      shift ;;
      -t) FILTERS+=("Name=tag:Type,Values=$2")
      shift ;;
      -n) FILTERS+=("Name=tag:Name,Values=$2")
      shift ;;
    esac
    shift
  done
  aws ec2 --region $aws_region describe-instances --query "Reservations[*].Instances[*].{a_Name:Tags[?Key=='Name']|[0].Value,c_IP:PrivateIpAddress,b_Instance:InstanceId}" --filters $FILTERS --output=table
}
