#!/bin/bash

###############################################################################
# clean-git-local-branches.sh
# #
# # Removes all local Git branches that have no upstream counterpart on the
# # specified remote, except for protected branches and the current branch.
# # Branches with a last commit within the last 24 hours will prompt for confirmation.
# #
# # Usage:
# #   ./clean-git-local-branches.sh [remote-name] [--dry-run]
# #
# # Arguments:
# #   remote-name   Optional. The git remote to compare with. Defaults to 'origin'.
# #   --dry-run     Optional. If set, will only print actions, not perform them.
# #
# # Author: OpenAI ChatGPT
# ###############################################################################
#
 # Set default remote and dry run flag
 REMOTE="origin"
 DRY_RUN=0

 # Protected branches (never deleted)
 PROTECTED=("main" "master" "develop" "release")

 # --- Parse Arguments ---
 for arg in "$@"; do
   case $arg in
       --dry-run)
             DRY_RUN=1
                   shift
                         ;;
                             *)
                                   REMOTE="$arg"
                                         ;;
                                           esac
                                           done

                                           # --- Step 1: Prune local stale references to remote branches ---
                                           echo "Pruning references to remote branches from '$REMOTE'..."
                                           git fetch "$REMOTE" --prune

                                           # --- Step 2: Gather information about local branches ---
                                           CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
                                           ALL_BRANCHES=$(git for-each-ref --format='%(refname:short)' refs/heads/)

                                           # --- Step 3: Get branches on remote ---
                                           REMOTE_BRANCHES=$(git for-each-ref --format='%(refname:short)' "refs/remotes/$REMOTE/")

                                           # --- Helper: Check if array contains a value ---
                                           contains() {
                                             local e match="$1"
                                               shift
                                                 for e; do [[ "$e" == "$match" ]] && return 0; done
                                                   return 1
                                                   }

                                                   # --- Step 4: Process each branch ---
                                                   for BRANCH in $ALL_BRANCHES; do
                                                     # --- Skip protected branches and current branch ---
                                                       if contains "$BRANCH" "${PROTECTED[@]}"; then
                                                           echo "Skipping protected branch: $BRANCH"
                                                               continue
                                                                 fi
                                                                   if [ "$BRANCH" == "$CURRENT_BRANCH" ]; then
                                                                       echo "Skipping currently checked-out branch: $BRANCH"
                                                                           continue
                                                                             fi

                                                                               # --- Does this branch have a counterpart on remote? ---
                                                                                 HAS_REMOTE=0
                                                                                   for REMOTE_BRANCH in $REMOTE_BRANCHES; do
                                                                                       # Check for exact match
                                                                                           REMOTE_BRANCH_NAME="${REMOTE_BRANCH#${REMOTE}/}"
                                                                                               if [ "$REMOTE_BRANCH_NAME" == "$BRANCH" ]; then
                                                                                                     HAS_REMOTE=1
                                                                                                           break
                                                                                                               fi
                                                                                                                 done
                                                                                                                   if [ "$HAS_REMOTE" -eq 1 ]; then
                                                                                                                       # Branch exists on remote, do not delete
                                                                                                                           continue
                                                                                                                             fi

                                                                                                                               # --- Get last commit date (in seconds since epoch) ---
                                                                                                                                 LAST_COMMIT_EPOCH=$(git log -1 --format="%ct" "$BRANCH")
                                                                                                                                   NOW_EPOCH=$(date +%s)
                                                                                                                                     AGE_SECONDS=$((NOW_EPOCH - LAST_COMMIT_EPOCH))
                                                                                                                                       ONE_DAY_SECONDS=86400

                                                                                                                                         # --- If branch is newer than a day, prompt user ---
                                                                                                                                           if [ "$AGE_SECONDS" -lt "$ONE_DAY_SECONDS" ]; then
                                                                                                                                               while true; do
                                                                                                                                                     read -rp "Branch '$BRANCH' was last committed to less than a day ago. Delete it? [y/N] " yn
                                                                                                                                                           case $yn in
                                                                                                                                                                   [Yy]* ) DELETE=1; break;;
                                                                                                                                                                           [Nn]*|"" ) DELETE=0; break;;
                                                                                                                                                                                   * ) echo "Please answer yes or no.";;
                                                                                                                                                                                         esac
                                                                                                                                                                                             done
                                                                                                                                                                                               else
                                                                                                                                                                                                   DELETE=1
                                                                                                                                                                                                     fi

                                                                                                                                                                                                       # --- Delete (or print if dry run) ---
                                                                                                                                                                                                         if [ "$DELETE" -eq 1 ]; then
                                                                                                                                                                                                             if [ "$DRY_RUN" -eq 1 ]; then
                                                                                                                                                                                                                   echo "[Dry run] Would delete branch: $BRANCH"
                                                                                                                                                                                                                       else
                                                                                                                                                                                                                             echo "Deleting branch: $BRANCH"
                                                                                                                                                                                                                                   git branch -D "$BRANCH"
                                                                                                                                                                                                                                       fi
                                                                                                                                                                                                                                         else
                                                                                                                                                                                                                                             echo "Keeping branch: $BRANCH"
                                                                                                                                                                                                                                               fi

                                                                                                                                                                                                                                               done
																													       echo "Done."
