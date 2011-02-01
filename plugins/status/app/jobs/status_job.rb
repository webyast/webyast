require 'graph'

class StatusJob
  def perform
    puts "************ GET GRAPH ************"
    Rails.logger.error(Graph.find(:all, true || false, {:background => false}))
    
    @graph = Graph.find(:all, true || false, {:background => false})
    puts "GRAPHS #{@graph.inspect}"
  end
end