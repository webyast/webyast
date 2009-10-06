# = Registration model
# Provides methods to call the registration in a RESTful environment.
# The main goal is to provide easy access to the registration workflow,
# the caller must interpret the result and maybe call it again with 
# changed values.
class Registration
  @reg = ''

  def initialize(str)
    @reg = str
  end

  def to_xml
    return "<regtest>#{ @reg.to_s }</regtest>"
  end

end
