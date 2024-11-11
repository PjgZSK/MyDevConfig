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

# find in .cs file
fcs()
{
    searchText="$1"
    __findIn "*.cs" $searchText 
}

# find in .cpp file
fcpp()
{
    searchText="$1"
    __findIn "*.cpp" $searchText 
}

# find in .hpp file
fhpp()
{
    searchText="$1"
    __findIn "*.hpp" $searchText 
}

# find in custom file
fcus()
{
    __findIn "$1" "$2" 
}

# find in specific file
__findIn()
{
    filePatternText="$1"
    searchText="$2"
    find . -name "$filePatternText" -print0 | xargs -0 sed -n -s -e "/"$searchText"/IF" -e "/"$searchText"/I=" -e "/"$searchText"/Ip" -e "/"$searchText"/a\\ " -e "/"$searchText"/a\\ "

}
