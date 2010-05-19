require 'rake'

desc "Check if the local repository has changes to be committed or pushed or merged with remote"
task :git_check do
    puts "* Checking GIT repository status..."
    puts "* Executing 'git fetch'..."
    sh "git fetch"

    # STEP 1: check the local changes
    # run 'git status' command to get the current status of the repository
    out = `git status`

    # Check the unpushed changes
    if out =~ /Your branch is ahead of '.*' by .* commit/
	puts "ERROR: The local repository has these changes:\n\n"
	puts `git log origin..HEAD`
	puts "\nUse 'git push' to push the local changes to the remote repository.\n"
	fail
    end

    if out =~ /Your branch is behind '.*' by .* commit/
	puts "ERROR: The remote repository has some changes.\n"
	puts "\nUse 'git pull --rebase' to include newest changes into the local repository.\n"
	fail

    end
    # check changes in the index
    if out =~ /new file:/
	puts "ERROR: there is a new uncommited file"
	puts "\nUse 'git commit' and 'git push' to commit the changes to the remote server.\n"
	fail
    end

    if out =~ /modified:/
	puts "ERROR: there is an uncommited change"
	puts out
	puts "\nUse 'git commit' and 'git push' to commit the changes to the remote server.\n"
	fail
    end
end
