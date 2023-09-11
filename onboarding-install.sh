#!/usr/bin/env bash

###################################################################
#Description	: Guides you through the omboarding of your new Mac
#                 Script is a POSIX bash script, so you can run it on Mac in zsh and on Windows in Git Bash.
#Args           : Keine
###################################################################

###################################################################
# Base Imports. Inline of ./tests/scripts/shared
###################################################################

# ---colors.sh--------------
# ANSI Colors to make identifying our echo messages easier
# --------------------------
export C_NOCOLOR='\033[0m'
export C_MARK='\033[0;35m'     # PURPLE
export C_ERROR='\033[0;31m'    # RED
export C_WARNING='\033[1;33m'  # YELLOW
export C_SCRIPT='\033[1;36m'   # LIGHTCYAN
export C_PROGRESS='\033[1;32m' # LIGHTGREEN
export C_DISABLED='\033[1;37m' # GREY
export C_SECTION='\033[4;32m'    # GREEN underline

# ---determineMachine.sh----
# Check Machine
# --------------------------
unameOut="$(uname -s)"
case "${unameOut}" in
Linux*) export MACHINE=Linux ;;
Darwin*) export MACHINE=Mac ;;
CYGWIN*) export MACHINE=Cygwin ;;
MINGW*) export MACHINE=MinGw ;;
*) export MACHINE="UNKNOWN:${unameOut}" ;;
esac

if [[ "$MACHINE" == "UNKNOWN:"* ]]; then
    echo -e "${C_ERROR}Machine is unknown.${C_NOCOLOR} On what machine are you running this? Use Git Bash on Windows or MacOs terminal."
    exit 1
elif [[ "$MACHINE" == "Linux" ]]; then
    echo -e "${C_ERROR}Machine is Linux.${C_NOCOLOR} Use Windows with Git Bash or MacOs."
    exit 1
fi

# ---setMachineApps.sh------
# set a clipboard that is available on your machine
# --------------------------
if command -v "clip" &>/dev/null; then
    export SH_CLIP="clip"
elif command -v "pbcopy" &>/dev/null; then
    export SH_CLIP="pbcopy"
else
    echo -e "${C_WARNING}⚠ Could not find a clipboard app. Copy to clipboard suggestions won't work.${C_NOCOLOR} What shell are you using?"
fi

###################################################################
# Functions
###################################################################
RGR_SCRIPT_CONFIG="${BASH_SOURCE[0]}.config"
function getConfigOrDefault() {
    local KEY="$1"
    local DEFAULT_VALUE="${2:-YES}"

    local VALUE=$(git config -f "$RGR_SCRIPT_CONFIG" "$KEY")
    if [[ -z $VALUE ]]; then
        setConfig "$KEY" "$DEFAULT_VALUE"
        VALUE="$DEFAULT_VALUE"
    fi
    echo "$VALUE"
}

function setConfig() {
    local KEY="$1"
    local VALUE="$2"

    git config -f "$RGR_SCRIPT_CONFIG" "$KEY" "$VALUE"
}

function promptYesNoConfig(){
    local KEY="$1"
    local QUESTION="$2"

    echo "$QUESTION: [YES/no]"
    read -r VALUE
    shopt -s nocasematch; if [[ -z $VALUE && ${VALUE} != 'no' ]]; then
        VALUE="YES"
        setConfig "$KEY" "$VALUE"
        echo "$VALUE"
    else
        VALUE="NO"
        setConfig "$KEY" "$VALUE"
        echo "$VALUE"
    fi
}

###################################################################
# Precondition checks
###################################################################

# Give tips how to enable colors
echo "Welcome to the machine setup script that helps you install the right things."
echo "  If this script has no color, and you see weird symbols like ${C_PROGRESS}(ANSI Color Codes) ${C_NOCOLOR}"
echo "  Then add the following to your ~/.bash_profile or ~/.zprofile: export CLICOLOR=1"
echo ""

echo -e "${C_PROGRESS}Running on ${MACHINE}${C_NOCOLOR}"

# Curl check to make sure this is somewhat regular bash
if ! command -v curl &>/dev/null; then
    echo -e "${C_ERROR}☐ Curl is NOT installed. Are you sure this is (Git) bash?${C_NOCOLOR}"
    exit 1
fi
echo -e "${C_PROGRESS}✓ curl is installed${C_NOCOLOR}"

###################################################################
# Check Shell
###################################################################
echo -e "${C_SECTION}Check Shells${C_NOCOLOR}"
RGR_DEFAULT_SHELL=$(echo $SHELL)
echo -e "${C_PROGRESS}✓ Your default shell is ${RGR_DEFAULT_SHELL}.${C_NOCOLOR}"
if [[ "$MACHINE" == "Mac" ]]; then
    if [[ "${RGR_DEFAULT_SHELL}" != *"fish" ]]; then
        echo -e "  Do you want to switch your default shell to fish?"
        echo -e "  - The docs are quite helpful here: https://fishshell.com/docs/current/index.html"
        echo -e "  - Try ${C_SCRIPT}which fish${C_NOCOLOR}"
        echo -e "  - Then change your local shell to that of fish ${C_SCRIPT}chsh -s /opt/homebrew/bin/fish${C_NOCOLOR}"
    fi
    if [[ "${RGR_DEFAULT_SHELL}" == *"fish" ]]; then
        echo -e "  Do you want to configure fish?"
        echo -e "  - The docs are quite helpful here: https://fishshell.com/docs/current/index.html#configuration"
        echo -e "  - Your config is in ${C_SCRIPT}~/.config/fish/config.fish${C_NOCOLOR}"
        echo -e "    - Add a fish greeting to the config ${C_SCRIPT}set -U fish_greeting "🐟"${C_NOCOLOR}"
    fi
fi

###################################################################
# Check Package Managers
###################################################################
echo -e "${C_SECTION}Check Package Managers${C_NOCOLOR}"
if command -v "brew" &>/dev/null; then
    RGR_PKG="brew"
    RGR_PKG_NAME="Homebrew"
    RGR_PKG_INSTALL="${RGR_PKG} install"
    RGR_PKG_UI_INSTALL="${RGR_PKG} install --cask"
    RGR_PKG_LIST="${RGR_PKG} list"
    RGR_PKG_UI_LIST="${RGR_PKG} list --cask"

    # mdfind -name 'MongoDB Compass' -onlyin /Applications -onlyin ~/Applications/ -onlyin /System/Applications
    RGR_APP_INTELLIJ=$(mdfind -name 'IntelliJ' -onlyin /Applications -onlyin ~/Applications/ 2>/dev/null)
    RGR_APP_INTELLIJ_VERSION=$(defaults read "$RGR_APP_INTELLIJ/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null)
    RGR_APP_VS_CODE=$(mdfind -name 'Visual Studio Code' -onlyin /Applications -onlyin ~/Applications/ 2>/dev/null)
    RGR_APP_VS_CODE_VERSION=$(defaults read "$RGR_APP_VS_CODE/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null)
elif command -v "choco" &>/dev/null; then
    RGR_PKG="choco"
    RGR_PKG_NAME="Chocolatey"
    RGR_PKG_INSTALL="${RGR_PKG} install"
    RGR_PKG_UI_INSTALL="${RGR_PKG_INSTALL}"
    RGR_PKG_LIST="${RGR_PKG} list"
    RGR_PKG_UI_LIST="${RGR_PKG} list"

    #RGR_APP_COMPASS=$(find "/C/Program Files" "/C/Program Files (x86)" -name MongoDBCompass.exe -not -path "WindowsApps/*")
fi

if [ -n "${RGR_PKG+1}" ]; then
    echo -e "${C_PROGRESS}✓ Your package installer is ${RGR_PKG_NAME}. Good choice!${C_NOCOLOR}"
else
    echo -e "${C_WARNING}☐ You don't have a package manager or it's not in your shell profile. Consider installing one, because it'll make it easier to keep your environment current. Good choices are:${C_NOCOLOR}"
    echo -e "  - Windows"
    echo -e "    - https://scoop.sh"
    echo -e "    - https://chocolatey.org"
    echo -e "  - Mac"
    echo -e "    - https://brew.sh"
    echo -e "    - https://www.macports.org (not a good idea, because it only provides newest version and as devs we often need older versions)"
    exit 1
fi

###################################################################
# Git
###################################################################
# (!) Check git early because then the following code can use git config to read config files
echo -e "${C_SECTION}Git${C_NOCOLOR}"
# --------------------------
# Git
# --------------------------
if ! command -v "git" &>/dev/null; then
    echo -n "${RGR_PKG_INSTALL} git" | "$SH_CLIP"
    echo -e "${C_ERROR}☐ Git is NOT installed.${C_NOCOLOR}"
    echo -e "  - Try (already in your clipboard): ${C_SCRIPT}${RGR_PKG_INSTALL} git${C_NOCOLOR}"
    exit 1
fi
echo -e "${C_PROGRESS}✓ Your $(git --version)${C_NOCOLOR}"

# --------------------------
# Git Config
# --------------------------
if [[ -n $(git config user.name) ]]; then
    echo "  Git user: $(git config user.name)"
else
    echo -e "${C_ERROR}☐ Please set the git user and email.${C_NOCOLOR}"
    echo -e "  - Try: ${C_SCRIPT}git config --global user.name <Alex Doe>${C_NOCOLOR}"
    echo -e "  - See also https://git-scm.com/book/en/v2/Getting-Started-First-Time-Git-Setup"
    exit 1
fi
if [[ -n $(git config user.email) ]]; then
    echo "  Git email: $(git config user.email)"
else
    echo -e "${C_ERROR}☐ Please set the git user and email.${C_NOCOLOR}"
    echo -e "  - Try: ${C_SCRIPT}git config --global user.email <alex.doe-extern@deutschebahn.com>${C_NOCOLOR}"
    echo -e "  - See also https://git-scm.com/book/en/v2/Getting-Started-First-Time-Git-Setup"
    exit 1
fi
if [[ $(git config pull.rebase) == 'true' ]]; then
    echo "  Git set to rebase on pull"
else
    echo -e "${C_WARNING}⚠ Your git is NOT set to rebase on pull.${C_NOCOLOR} Since we are working trunk-based, this'll lead to many additional merge commits with confusing diffs and mudden the git log."
    echo -e "  - Try: ${C_SCRIPT}git config --global pull.rebase true${C_NOCOLOR}"
    exit 1
fi

# --------------------------
# SSH Config
# --------------------------
if [[ ! -d "$HOME/.ssh" ]]; then
    echo -e "${C_WARNING}⚠ You don't have a ~/.ssh folder.${C_NOCOLOR} It's recommended to have one because you can check out git with a secure ssh key."
    echo -e "  - Go to the Gitlab > Edit Profile > SSH Keys and follow the official Gitlab tutorial."
    echo -e "    Something like ${C_SCRIPT}ssh-keygen -t ed25519 -C 'Gitlab'${C_NOCOLOR} to generate a key."
    echo -e "    The .pub is your public key, the other one is private. Keep it only on your machine."
    # exit 1
else
    echo -e "${C_PROGRESS}✓ You have an .ssh folder${C_NOCOLOR}"
fi

###################################################################
# Script Config
###################################################################
echo -e "${C_SECTION}Check Script Config${C_NOCOLOR}"
if [ -f "$RGR_SCRIPT_CONFIG" ]; then
    echo -e "${C_PROGRESS}✓ Script config [$RGR_SCRIPT_CONFIG] exists.${C_NOCOLOR}"
else
    echo -e "${C_WARNING}☐ Creating script config [$RGR_SCRIPT_CONFIG].${C_NOCOLOR}"
fi
touch -a "${RGR_SCRIPT_CONFIG}"

# --------------------------
# Flags
# --------------------------
RGR_JM_WANTED="$(getConfigOrDefault 'manager.language.jvm')"
RGR_K8S_WANTED="$(getConfigOrDefault 'ops.k8s.all')"

###################################################################
# Check Language Managers
###################################################################
echo -e "${C_SECTION}Check Language Managers${C_NOCOLOR}"
# --------------------------
# Java Manager
# --------------------------
if [ "$RGR_JM_WANTED" == "YES" ]; then
    if ! command -v "sdk" &>/dev/null && $(promptYesNoConfig "manager.language.jvm" "You don't have a JVM manager installed. Do you want to install one? It'll make make upgrading your java versions much easier.") = "YES"; then
        echo -e "${C_WARNING}☐ You don't have a java manager. Good choices are:${C_NOCOLOR}"
        echo -e "  - https://sdkman.io"
        echo -e "  - To make fish work with sdk man use this gist: https://gist.github.com/fedragon/cccf6d65dd6e0da1dc2a1200db8412f4"
        echo -e "  - Side note. To manage Python you can use pyenv and for Ruby it's rbenv. 😀"
        exit 1
    else
        RGR_JM="sdk"
        RGR_JM_INSTALL="${RGR_NM} install lts"
        echo -e "${C_PROGRESS}✓ Your java manager is ${RGR_JM}. Good choice!${C_NOCOLOR}"
    fi
else
    echo -e "${C_DISABLED}⧗ We are not checking that you have a jvm manager ${C_NOCOLOR}"
fi
# --------------------------
# Node Manager
# --------------------------
if command -v "nvm" &>/dev/null; then
    RGR_NM="nvm"
    RGR_NM_INSTALL="${RGR_NM} install --flts"
elif command -v "fnm" &>/dev/null; then
    RGR_NM="fnm"
    RGR_NM_INSTALL="${RGR_NM} install --lts"
fi

if [ -n "${RGR_NM+1}" ]; then
    echo -e "${C_PROGRESS}✓ Your node manager is ${RGR_NM}. Good choice!${C_NOCOLOR}"
else
    echo -e "${C_WARNING}☐ You don't have a node manager. Consider installing one, because it'll make upgrading your node versions much easier. Good choices are:${C_NOCOLOR}"
    echo -e "  - https://github.com/Schniz/fnm PORT=fnm)"
    echo -e "  - https://github.com/nvm-sh/nvm PORT=nvm"
    echo -e "  - Side note. To manage Python you can use pyenv, for Ruby it's rbenv and for Java it's sdkman. 😀"
    echo -n "${RGR_PKG_INSTALL} " | "$SH_CLIP"
    echo -e "  The script to install is already in your clipboard, you just have to ${C_MARK}pick${C_NOCOLOR} which one you want"
    exit 1
fi

###################################################################
# Check Installed Languages
###################################################################
echo -e "${C_SECTION}Languages${C_NOCOLOR}"
# --------------------------
# Java
# --------------------------
if ! command -v "java" &>/dev/null; then
    echo -n "sdk install java" | "$SH_CLIP"
    echo -e "${C_ERROR}☐ Java is NOT globally installed.${C_NOCOLOR}"
    echo -e "  - Try (already in your clipboard): ${C_SCRIPT}sdk install java${C_NOCOLOR}"
    exit 1
fi
echo -e "${C_PROGRESS}✓ Your java version is $(java --version | sed -n 1p)${C_NOCOLOR}"
# --------------------------
# Node
# --------------------------
if ! command -v "node" &>/dev/null; then
    echo -n "${RGR_NM_INSTALL}" | "$SH_CLIP"
    echo -e "${C_ERROR}☐ Node is NOT globally installed.${C_NOCOLOR}"
    echo -e "  - Try (already in your clipboard): ${C_SCRIPT}${RGR_NM_INSTALL} ${C_NOCOLOR}"
    exit 1
fi
echo -e "${C_PROGRESS}✓ Your node version is $(node --version)${C_NOCOLOR}"

###################################################################
# IDE
###################################################################
echo -e "${C_SECTION}IDE${C_NOCOLOR}"
# --------------------------
# IntelliJ
# --------------------------
if [[ ! -d "$RGR_APP_INTELLIJ" ]]; then
    echo -n "${RGR_PKG_UI_INSTALL} jetbrains-toolbox" | "$SH_CLIP"
    echo -e "${C_ERROR}☐ IntelliJ is NOT installed or not installed via JetBrains Toolbox.${C_NOCOLOR} IntelliJ is our IDE of choice and the toolbox is the product that keeps it current."
    echo -e "  - Try (already in your clipboard): ${C_SCRIPT}${RGR_PKG_UI_INSTALL} jetbrains-toolbox${C_NOCOLOR}"
    echo -e "  - Then start and use the toolbox to install IntelliJ"
    echo -e "  - See also https://www.jetbrains.com/toolbox-app/"
    exit 1
fi
echo -e "${C_PROGRESS}✓ Your IntelliJ version $RGR_APP_INTELLIJ_VERSION${C_NOCOLOR}"
# --------------------------
# VS Code
# --------------------------
if [[ ! -d "$RGR_APP_INTELLIJ" ]]; then
    echo -n "${RGR_PKG_UI_INSTALL} visual-studio-code" | "$SH_CLIP"
    echo -e "${C_ERROR}☐ VS Code is NOT installed.${C_NOCOLOR}"
    echo -e "  - Try (already in your clipboard): ${C_SCRIPT}${RGR_PKG_UI_INSTALL} visual-studio-code${C_NOCOLOR}"
    echo -e "  - See also https://code.visualstudio.com"
    exit 1
fi
echo -e "${C_PROGRESS}✓ Your VS Code version $RGR_APP_VS_CODE_VERSION${C_NOCOLOR}"

###################################################################
# Check Installed Container Apps
###################################################################
echo -e "${C_SECTION}Container Apps${C_NOCOLOR}"
# --------------------------
# Docker
# --------------------------
if command -v "docker" &>/dev/null && ! command -v "colima" &>/dev/null; then
    echo -e "${C_WARNING}⚠ Docker CLI is installed. You probably did so by installing Docker Desktop but that REQUIRES a paid license.${C_NOCOLOR}"
    echo -e "  - Please use colima with docker instead"
    echo -e "  - See also https://www.docker.com/pricing/"
    exit 1
fi

if ! command -v "colima" &>/dev/null; then
    echo -n "${RGR_PKG_INSTALL} colima" | "$SH_CLIP"
    echo -e "${C_ERROR}☐ Colima is NOT installed.${C_NOCOLOR} It's the container runtime for MacOs (Containers in Linux Machines)."
    echo -e "  - Try (already in your clipboard): ${C_SCRIPT}${RGR_PKG_INSTALL} colima${C_NOCOLOR}"
    echo -e "  - See also https://github.com/abiosoft/colima"
    exit 1
fi
echo -e "${C_PROGRESS}✓ Your $(colima version | sed -n 1p)${C_NOCOLOR}"
if [[ $(colima status 2>&1) == *"not running"* ]]; then
    echo -e "${C_WARNING}⚠ Colima is not running${C_NOCOLOR}"
    echo -e "  - Try: ${C_SCRIPT}colima start${C_NOCOLOR}"
    exit 1
fi
echo -e "${C_PROGRESS}✓ Colima is running${C_NOCOLOR}"

if ! command -v "docker" &>/dev/null; then
    echo -n "${RGR_PKG_INSTALL} docker" | "$SH_CLIP"
    echo -e "${C_ERROR}☐ Docker is NOT installed.${C_NOCOLOR} You need docker in almost any project."
    echo -e "  - Try (already in your clipboard): ${C_SCRIPT}${RGR_PKG_INSTALL} docker${C_NOCOLOR}"
    echo -e "  - See also https://www.docker.com"
    exit 1
fi
echo -e "${C_PROGRESS}✓ Your Docker Client $(docker version | sed -n 2p)${C_NOCOLOR}"


echo -e "${C_SECTION}K8s Tools${C_NOCOLOR}"
###################################################################
# Check Installed K8S Tools
###################################################################
if [ "$RGR_K8S_WANTED" == "YES" ]; then
    # --------------------------
    # Kubernetes
    # --------------------------
    if ! command -v "kubectl" &>/dev/null; then
        echo -n "${RGR_PKG_INSTALL} kubectl" | "$SH_CLIP"
        echo -e "${C_ERROR}☐ Kubectl is NOT installed.${C_NOCOLOR} It's cli to access kubernetes."
        echo -e "  - Try (already in your clipboard): ${C_SCRIPT}${RGR_PKG_INSTALL} kubectl${C_NOCOLOR}"
        echo -e "  - See also https://kubernetes.io/docs/tasks/tools/"
        exit 1
    fi
    echo -e "${C_PROGRESS}✓ Your Kubectl $(kubectl version --short | sed -n 1p)${C_NOCOLOR}"

    if ! kubectl cluster-info &>/dev/null; then
        echo -e "${C_ERROR}☐ Kubectl does not have a valid cluster config (OR your internet and VPN connection is broken).${C_NOCOLOR} You need the cluster config to connect to your kubernetes cluster."
        echo -e "  - By default kubectl checks ~/.kube/config for a kubeconfig file"
        echo -e "  - You can get this file from the IATA rancher."
        echo -e "  - The rancher url for IATA can be found in the wiki: https://ri-wiki.jaas.service.deutschebahn.com/pages/viewpage.action?pageId=136776124"
        echo -e "  - Open IATA Rancher Url > betrieblive-iata > top right, just under 'Cluster Explorer', you have ${C_MARK}Kubeconfig File${C_NOCOLOR}"
        echo -e "  - ${C_MARK}Don't forget to remove possible group/world read rights.${C_NOCOLOR} Try ${C_SCRIPT}chmod go-rwx ~/.kube/config${C_NOCOLOR}"
        exit 1
    fi
    echo -e "${C_PROGRESS}✓ Your kubeconfig file looks good.${C_NOCOLOR}"
    if ! command -v "helm" &>/dev/null; then
        echo -n "${RGR_PKG_INSTALL} helm" | "$SH_CLIP"
        echo -e "${C_ERROR}☐ Helm is NOT installed.${C_NOCOLOR} It's the package manager for Kubernetes."
        echo -e "  - Try (already in your clipboard): ${C_SCRIPT}${RGR_PKG_INSTALL} helm${C_NOCOLOR}"
        echo -e "  - See also https://helm.sh"
        exit 1
    fi
    echo -e "${C_PROGRESS}✓ Your Helm version $(helm version --short)${C_NOCOLOR}"
else
    echo -e "${C_DISABLED}⧗ We are not checking your K8s tools${C_NOCOLOR}"
fi

###################################################################
# Check Installed K8s Convenience
###################################################################
echo -e "${C_SECTION}K8s Convenience${C_NOCOLOR}"
if [ "$RGR_K8S_WANTED" == "YES" ]; then
    if ! command -v "fzf" &>/dev/null; then
        echo -e "${C_WARNING}⚠ You don't have fzf.${C_NOCOLOR} fzf is an interactive cli filter that provides awesome autocomplete to kubectx."
        echo -e "  - Try (not in your clipboard, because it's optional): ${C_SCRIPT}${RGR_PKG_INSTALL} fzf${C_NOCOLOR}"
        echo -e "  - See also https://github.com/junegunn/fzf"
    else
        echo -e "${C_PROGRESS}✓ Your fzf version is $(fzf --version)${C_NOCOLOR}"
    fi
    if ! command -v "kubectx" &>/dev/null; then
        echo -e "${C_WARNING}⚠ You don't have kubectx.${C_NOCOLOR} Kubectx is a tool to quickly switch between multiple contexts. Helpful for us because we have IATA, STGA and PRDA."
        echo -e "  - Try (not in your clipboard, because it's optional): ${C_SCRIPT}${RGR_PKG_INSTALL} kubectx${C_NOCOLOR}"
        echo -e "  - See also https://github.com/ahmetb/kubectx"
        echo -e "  - In Git Bash fzf seems to have some problems. Regular Windows Terminal works fine though."
    else
        echo -e "${C_PROGRESS}✓ Your kubectx is ${C_MARK}$(kubectx -c)${C_NOCOLOR} and your namespace ${C_MARK}$(kubens -c)${C_NOCOLOR}"
    fi
    if ! command -v "k" &>/dev/null; then
        echo -e "${C_WARNING}⚠ You don't have the alias 'k' for kubectl. You probably also don't have auto-complete enabled.${C_NOCOLOR}"
        echo -e "  - See official Kubernetes Cheatsheet to get both: https://kubernetes.io/docs/reference/kubectl/cheatsheet/"
        echo -e "  - You should add the ${C_SCRIPT}alias k=kubectl${C_NOCOLOR} to your .bashrc or .zshrc"
    else
        echo -e "${C_PROGRESS}✓ You have 'k' alias for kubectl${C_NOCOLOR}"
    fi
    if ! command -v "kc" &>/dev/null; then
        echo -e "${C_WARNING}⚠ You don't have the alias 'kc' for kubectx.${C_NOCOLOR}"
        echo -e "  - You should add the ${C_SCRIPT}alias kc=kubectx${C_NOCOLOR} to your .bashrc or .zshrc"
    else
        echo -e "${C_PROGRESS}✓ You have 'kc' alias for kubectx.${C_NOCOLOR} Switch the Kubernetes Context by typing ${C_SCRIPT}kc${C_NOCOLOR}."
    fi
    if ! command -v "kns" &>/dev/null; then
        echo -e "${C_WARNING}⚠ You don't have the alias 'kns' for kubens.${C_NOCOLOR}"
        echo -e "  - You should add the ${C_SCRIPT}alias kns=kubens${C_NOCOLOR} to your .bashrc or .zshrc"
    else
        echo -e "${C_PROGRESS}✓ You have 'kns' alias for kubens.${C_NOCOLOR} Switch Kubernetes Namespaces by typing ${C_SCRIPT}kns${C_NOCOLOR}."
    fi
    if ! command -v "k9s" &>/dev/null; then
        echo -e "${C_WARNING}⚠ You don't have k9s.${C_NOCOLOR} k9s is a cli-tool to view Kubernetes in the command-line."
        echo -e "  - Try (not in your clipboard, because it's optional): ${C_SCRIPT}${RGR_PKG_INSTALL} k9s${C_NOCOLOR}"
        echo -e "  - See also https://github.com/derailed/k9s"
    else
        echo -e "${C_PROGRESS}✓ Your k9s $(k9s version --short | sed -n 1p).${C_NOCOLOR} Type ${C_SCRIPT}k9s${C_NOCOLOR} to open the dashboard in your current context."
    fi
else
    echo -e "${C_DISABLED}⧗ We are not checking your K8s convenience${C_NOCOLOR}"
fi

###################################################################
# On Mac, check XCode is isntalled, it takes a long while
###################################################################
if [[ "$MACHINE" == "Mac" ]]; then
    echo -e "${C_SECTION}Mac IDEs${C_NOCOLOR}"
    RGR_APP_XCODE=$(mdfind -name "Xcode" -onlyin "/Applications" -onlyin "$HOME/Applications/" 2>/dev/null)
    RGR_APP_XCODE_VERSION=$(defaults read "$RGR_APP_XCODE/Contents/version.plist" CFBundleShortVersionString)
    if [[ ! -d "$RGR_APP_XCODE" ]]; then
        echo -e "${C_WARNING}⚠ Xcode is NOT installed.${C_NOCOLOR} It's the Mac IDE and the only way to build and run iOS Apps."
        echo -e "  - To install, use the official MacOS App Store. The download is large and takes quite a while. Maybe you want to ${C_MARK}start it now${C_NOCOLOR}."
        echo -e "  - ${C_WARNING}Please start the download now.${C_NOCOLOR}"
        echo -e "  - See also https://apps.apple.com/de/app/xcode/"
    fi
    echo -e "${C_PROGRESS}✓ Your Xcode version $RGR_APP_XCODE_VERSION${C_NOCOLOR}"

    if ! command -v "xcodebuild" &>/dev/null; then
        echo -e "${C_ERROR}☐ Xcodebuild is NOT installed.${C_NOCOLOR} It's the Xcode cli build tool."
        echo -e "  - It should've been installed together with Xcode."
        echo -e "  - See also https://developer.apple.com/library/archive/technotes/tn2339/_index.html"
        return 1
    fi
    echo -e "${C_PROGRESS}✓ Your Xcodebuild $(xcodebuild -version | sed -n 2p)${C_NOCOLOR}"
fi

###################################################################
# Check Dev Helper
###################################################################
echo -e "${C_SECTION}Dev Apps${C_NOCOLOR}"
# --------------------------
# Steampipe
# --------------------------
if ! command -v "steampipe" &>/dev/null; then
    echo -n "${RGR_PKG_INSTALL} turbot/tap/steampipe" | "$SH_CLIP"
    echo -e "${C_ERROR}☐ Steampipe is NOT installed.${C_NOCOLOR} It's an almost universal query cli for web services."
    echo -e "  - Try (already in your clipboard): ${C_SCRIPT}${RGR_PKG_INSTALL} turbot/tap/steampipe${C_NOCOLOR}"
    echo -e "  - See also https://steampipe.io/docs"
    exit 1
fi
echo -e "${C_PROGRESS}✓ Your $(steampipe -v)${C_NOCOLOR}"

###################################################################
# Finalize
###################################################################
echo -e "${C_SECTION}Finalize${C_NOCOLOR}"
# --------------------------
# CLI Suggestions
# --------------------------
echo -e "We are done :)"