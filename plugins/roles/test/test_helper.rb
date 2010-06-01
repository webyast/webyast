# find the rails parent
require File.join(File.dirname(__FILE__), '..', 'config', 'rails_parent')
require File.join(RailsParent.parent, "test","test_helper")

class FakeDbus
	attr_reader :last_perms, :last_user
	def revoke(perms,user)
		@last_perms = perms
		@last_user = user
	end

	def grant(perms,user)
		revoke perms,user
	end
end

