
# class for periodicaly removing expired auth token from database
class ExpireAuthTokenJob

  def perform
    Rails.logger.info "Removing expired authentication tokens..."
    # reset authentication_token in all Accounts updated long time ago
    # Devise.timeout_in is set in initializers/devise.rb
    Account.where(["authentication_token is NOT NULL AND updated_at < ?", Devise.timeout_in.ago]).update_all(:authentication_token => nil)
  end

  # success hook - started when the job successfuly finishes
  def success(job)
    # enqueue itself to run after 5 minutes again
    Delayed::Job.enqueue ExpireAuthTokenJob.new, :run_at => 5.minutes.from_now
  end

end
