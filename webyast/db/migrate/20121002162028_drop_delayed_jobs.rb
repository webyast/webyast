class DropDelayedJobs < ActiveRecord::Migration
  def self.up
    remove_index :delayed_jobs, :locked_by
    drop_table :delayed_jobs
  end

  def self.down
    create_table "delayed_jobs" do |t|
      t.integer  "priority",   :default => 0
      t.integer  "attempts",   :default => 0
      t.text     "handler"
      t.string   "last_error"
      t.datetime "run_at"
      t.datetime "locked_at"
      t.datetime "failed_at"
      t.string   "locked_by"
      t.datetime "created_at",  :null => false
      t.datetime "updated_at",  :null => false
      t.string   "queue"
    end

    add_index "delayed_jobs", ["locked_by"], :name => "index_delayed_jobs_on_locked_by"
  end
end
