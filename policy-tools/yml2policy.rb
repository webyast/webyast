require 'yaml'
require 'rexml/document'

def addhash element, h
  h.each do |k,v|
    e = REXML::Element.new(k)
    # Hmm, http://www.postal-code.com/mrhappy/blog/2007/02/01/ruby-comparing-an-objects-class-in-a-case-statement/
    # Violates POLS
    case v
    when String
      e.text = v
    when TrueClass
      e.text = "yes"
    when FalseClass
      e.text = "no"
    when Hash
      addhash e, v
    else
      raise "Can't handle #{v.class}"
    end
    element << e
  end
end

xml = REXML::Document.new
xml << REXML::XMLDecl.new(REXML::XMLDecl::DEFAULT_VERSION, REXML::XMLDecl::DEFAULT_ENCODING)
dt = REXML::DocType.new(["policyconfig", REXML::DocType::PUBLIC, "-//freedesktop//DTD PolicyKit Policy Configuration 1.0//EN", "http://www.freedesktop.org/standards/PolicyKit/1.0/policyconfig.dtd"])
xml << dt

policy = REXML::Element.new("policyconfig")
vendor = REXML::Element.new("vendor")
vendor.text = "Novell, Inc."
policy << vendor
vendor_url = REXML::Element.new("vendor_url")
vendor_url.text = "http://www.novell.com"
policy << vendor_url


yml = YAML::load($stdin)

yml.each do |id,parms|
  a = REXML::Element.new("action")
  a.add_attribute("id", id)
  addhash( a, parms )
  policy << a
end

xml << policy

# pretty-print XML
xml.write($stdout,2)
puts