#!/bin/bash

# Usefull Alias
alias tree="tree -CA"
alias ll="ls -a -l"
alias gs="git status -s"
alias ga="git add "
alias gc="git commit -m"
alias gac="git add . && git commit -m"
alias gacam="git add . && git commit --amend"
alias gp="git push"
alias gl="git pull"
alias gcb="git checkout -b"
alias go="git checkout"
alias gd="git diff"
alias gb="git branch"
alias glo="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
alias v="gvim"

# Useful Functions

# list .cs files
lcs() {
    # ls -a | grep ".cs$"
    for f in ./*; do
        case $f in
        *\.cs) echo "$f" ;;
        # *) echo "$f error file" ;;
        esac
    done
}
# find in .cs file
fcs() {
    searchText="$1"
    startPoint="$2"
    __findIn "*.cs" "$searchText" "$startPoint"
}

# find in .cpp file
fcpp() {
    searchText="$1"
    startPoint="$2"
    __findIn "*.cpp" "$searchText" "$startPoint"
}

# find in .hpp file
fhpp() {
    searchText="$1"
    startPoint="$2"
    __findIn "*.hpp" "$searchText" "$startPoint"
}

# find in custom file
fcus() {
    __findIn "$1" "$2" "$3"
}

# find in specific file
__findIn() {
    filePatternText="$1"
    searchText="$2"
    startPoint="$3"

    if [[ $startPoint == "" ]]; then
        startPoint="."
    fi

    find "$startPoint" -name "$filePatternText" -print0 | xargs -0 sed -n -s -e "/""$searchText""/IF" -e "/""$searchText""/I=" -e "/""$searchText""/Ip" -e "/""$searchText""/Ia\\ " -e "/""$searchText""/Ia\\ "
}
