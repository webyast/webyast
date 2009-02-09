#
# policy2yml.rb
#
# Converts PolicyKit policy XML representation to YaML
#
# e.g. from
#
# 

require 'yaml'
require 'rexml/document'

def element2hash element
  res = Hash.new
  element.each_element do |child|
    k = child.name
    if child.has_elements?
      v = element2hash child
    else
      v = child.text
    end
    res[k] = v
  end
  res
end

doc = REXML::Document.new($stdin)

root = doc.root

raise "Not a PolicyKit policy" unless root.name == "policyconfig"

yml = Hash.new

root.each_element_with_attribute("id") do |element|
  next unless element.name == "action"
  k = element.attribute('id')
  v = element2hash element
  yml[k.to_s] = v
end

puts yml.to_yaml
