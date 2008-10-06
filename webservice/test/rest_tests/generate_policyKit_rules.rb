#!/usr/bin/ruby

IO.foreach( "<inputfile>" ) { |line|

line = line.chomp

puts"  <action id=\"org.opensuse.yast.webservice.read-yastmodule-#{line}\">"
puts"    <description>Reading parameters of YaST module \"#{line}\"</description>"
puts"    <message>Authentication is required to get YaST #{line} parameters</message>"
puts"    <defaults>"
puts"      <allow_inactive>no</allow_inactive>"
puts"      <allow_active>no</allow_active>"
puts"    </defaults>"
puts"  </action>"
puts"  <action id=\"org.opensuse.yast.webservice.run-yastmodule-#{line}\">"
puts"    <description>Permission to run YaST module \"#{line}\"</description>"
puts"    <message>Authentication is required to run YaST module \"#{line}\"</message>"
puts"    <defaults>"
puts"      <allow_inactive>no</allow_inactive>"
puts"      <allow_active>no</allow_active>"
puts"    </defaults>"
puts"  </action>"

}


