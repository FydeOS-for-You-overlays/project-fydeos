#!/bin/bash

if [[ $# != 3 ]]; then
	echo -e "Usage: $0 <Chrome OS release branch/tag to fork> <old branch that has Flint modifications to pick> <new branch to create>\n"
	exit
fi

chromeos_release=$1
branch_to_pick=$2
new_branch=$3

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Print infomative messages
info() {
	echo -e "${GREEN}$*${NC}"
}

# Print error messages
error() {
	echo -e "${RED}$*${NC}"
}

# If the $new_branch alreadys exists, the user should deal with it manually, the script don't delete any branch
if git show-ref -q --verify refs/heads/${new_branch} || git show-ref -q --verify refs/remotes/origin/${new_branch}; then
	error "Branch ${new_branch} already exists locally or remotely, please remove it or choose a new name for the new branch, then restart the script."
	exit
fi

# The $branch_to_pick must exist locally to run git log on it
info "Checking out branch ${branch_to_pick} first to make sure it exists locally..."
git checkout ${branch_to_pick}

# Filter out all commits done by Flint team
pick_list=$(git log --author='.*@flintos.io' --reverse --no-merges --format=%H)

# Now switch to the new branch and start cherry picking
info "Switching to branch ${new_branch} for cherry picking..."
git checkout ${chromeos_release} -b ${new_branch}

for c in ${pick_list}; do
	info "Cherry picking commit ${c}"
	git cherry-pick ${c}

	if [[ $? != 0 ]]; then # If the cherry picking failed, drop into bash so user can fix it. The loop resumes after user exits from the shell
		error "Cherry-picking commit ${c} failed. Dropping into interactive shell so you can fix it."
		info "Please run necessary commands to fix the cherry-pick. After done type 'exit' or 'Ctrl+D' to exit the shell and resume cherry-picking."
		PS1="Git Shell >> " bash --noprofile --norc
		info "Commit ${c} manually fixed."
	fi
done
