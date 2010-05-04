require 'rake'

desc "Check if the local repository has changes to be committed or pushed"
task :git_check_local do
    puts "* Checking GIT repository status..."

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

desc "Check if the remote repository has changes to be pulled"
task :git_check_remote do
    # STEP 2: check the remote changes
    # download the remote chenges
    puts "* Executing 'git fetch'..."
    sh "git fetch"

    out = `git log HEAD..origin`

    if $?.exitstatus != 0
	puts "ERROR: 'git log HEAD..origin' failed"
	fail
    end

    if !out.empty?
	puts "\nERROR: The remote repository has these changes:\n\n"
	puts out
	puts "\nUse 'git pull' to sychronize the repositories.\n"
	fail
    end

    # TODO FIXME: check if VERSION tag exists

    puts '* GIT check OK'
end

desc "Check if the local and remote GIT repositories are in sync"
task :git_check => [ :git_check_local, :git_check_remote ]
# multitask would confuse the output
