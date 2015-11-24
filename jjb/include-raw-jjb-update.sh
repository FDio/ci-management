jenkins-jobs update --delete-old jjb/

# Submit patches for any jobs that can be auto updated
function submitJJB {
    git commit -asm "Update automated project templates"
    git push origin HEAD:refs/for/master
}

gitdir=$(git rev-parse --git-dir); scp -p -P 29418 rotterdam-jobbuilder@gerrit.projectrotterdam.info:hooks/commit-msg ${gitdir}/hooks/
git diff --exit-code || submitJJB
