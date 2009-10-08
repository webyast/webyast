class RailsParent
  
  def RailsParent.parent
    parent = ENV["RAILS_PARENT"]
    unless parent
      parent = File.expand_path(File.join('..','..','..', 'webservice'), File.dirname(__FILE__))
      unless File.directory?( parent || "" )
	$stderr.puts "Nope: #{parent}\nPlease set RAILS_PARENT environment"
	exit 1
      end
    end
    parent
  end
  
end
