require "user.rb"

class UsersJob
  def perform
    puts "************ GET USERS ************"
    @users = User.find_all
    puts "USERS #{@users.inspect}"
  end
end