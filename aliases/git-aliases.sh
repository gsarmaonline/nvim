if [ ! -d .git ]
then
    echo "Not a git repository"
    return
fi


alias gic='git commit --no-verify'
alias gich='git checkout'
alias gis='git status'
alias gil='git log'
alias gib='git branch'
alias gia='git add'
alias gid='git diff'
alias gidc='git diff --cached'

# Default branch: master/main 
alias gichm="git checkout $(git rev-parse --abbrev-ref origin/HEAD | awk -F/ '{print $2}')"
alias giplm="git pull -r origin $(git rev-parse --abbrev-ref origin/HEAD | awk -F/ '{print $2}')"
alias gipsm="git push origin $(git rev-parse --abbrev-ref origin/HEAD | awk -F/ '{print $2}')"

# Current branch
alias curr_branch="echo $(git rev-parse --abbrev-ref HEAD)"
alias gipl="git pull -r origin $(git rev-parse --abbrev-ref HEAD)"
alias gips="git push origin $(git rev-parse --abbrev-ref HEAD)"

alias gir='git reset'
alias pr_create="gh pr create"
