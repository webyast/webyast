require 'rake'

desc "Check if the local and remote GIT repositories are in sync"
task :git_check do
    puts "* Checking GIT repository status..."

    # STEP 1: check the local changes
    # run 'git status' command to get the current status of the repository
    out = `git status`

    # exit status 0 indicates uncommitted changes
    if $?.exitstatus == 0
	puts "ERROR: Uncommitted changes found:\n\n"
	puts out
	puts "\nUse 'git commit -a' and 'git push' to commit the changes to the remote server.\n"
	exit 1
    end

    # Check the unpushed changes
    if out =~ /Your branch is ahead of '.*' by .* commit/
	puts "ERROR: The local repository has these changes:\n\n"
	puts `git log origin..HEAD`
	puts "\nUse 'git push' to push the local changes to the remote repository.\n"
	exit 1
    end

    # check changes in the index
    if out =~ /new file:/
	puts "ERROR: there is a new uncommited file"
	puts "\nUse 'git commit' and 'git push' to commit the changes to the remote server.\n"
	exit 1
    end

    if out =~ /modified:/
	puts "ERROR: there is an uncommited change"
	puts "\nUse 'git commit' and 'git push' to commit the changes to the remote server.\n"
	exit 1
    end

    # STEP 2: check the remote changes
    # download the remote chenges
    puts "* Executing 'git fetch'..."
    `git fetch`

    if $?.exitstatus != 0
	puts "ERROR: 'git fetch' failed"
	exit 1
    end

    out = `git log HEAD..origin`

    if $?.exitstatus != 0
	puts "ERROR: 'git log HEAD..origin' failed"
	exit 1
    end

    if !out.empty?
	puts "\nERROR: The remote repository has these changes:\n\n"
	puts out
	puts "\nUse 'git pull' to sychronize the repositories.\n"
	exit 1
    end

    # TODO FIXME: check if VERSION tag exists

    puts '* GIT check OK'
end

