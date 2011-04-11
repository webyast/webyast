require 'ostruct'
begin ; require 'active_record' ; rescue LoadError; require 'rubygems'; require 'active_record'; end

require File.join( File.dirname(__FILE__), "acts_as_static_record" )
require File.join( File.dirname(__FILE__), "static_active_record_context" )
