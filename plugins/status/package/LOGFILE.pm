package YaPI::LOGFILE;

use strict;
use YaST::YCP qw(:LOGGING);
use YaPI;
use Data::Dumper;

# ------------------- imported modules
YaST::YCP::Import ("Directory");
YaST::YCP::Import ("FileUtils");
YaST::YCP::Import ("SCR");
# -------------------------------------

our $VERSION            = '1.0.0';
our @CAPABILITIES       = ('SLES11');
our %TYPEINFO;

my $logs_file	= "/etc/webyast/vendor/logs.yml";

my $error_message		= "";

# log error message and fill it into $error_message variable
sub report_error {
  $error_message	= shift;
  y2error ($error_message);
}

# parse the file with custom services and return the hash describing the file
sub parse_logs_file {

  if (!FileUtils->Exists ($logs_file)) {
    report_error ("$logs_file file not present");
    return {};
  }

  if (!FileUtils->Exists (Directory->moduledir()."/YML.rb")) {
    report_error ("YML.rb not present, cannot parse config file");
    return {};
  }
  
  YaST::YCP::Import ("YML");

  my $parsed = YML->parse ($logs_file);

  if (!defined $parsed || ref ($parsed) ne "HASH") {
    report_error ("custom services file could not be read");
    return {};
  }
  return $parsed;
}

BEGIN{$TYPEINFO{Read} = ["function",
    [ "map", "string", "any"],
    "string", "integer"];
}
sub Read {

  my $self	= shift;
  my $name	= shift;
  my $lines	= shift;

  my $parsed	= parse_logs_file ();

  my $ret	= {
      "stdout"	=> "",
      "stderr"	=> "failure",
      "exit"	=> 255
  };

  if (%$parsed) {
    my $log_file	= $parsed->{$name};
    if (!defined $log_file || ref ($log_file) ne "HASH" || ! %$log_file) {
	report_error ("$name not defined or empty in config file");
	$ret->{"stderr"}	= $error_message;
	return $ret;
    }
    my $path	= $log_file->{"path"};
    if (!$path) {
	report_error ("Path not defined for $name");
	$ret->{"stderr"}	= $error_message;
	return $ret;
    }
    $lines	= 50 if !defined $lines;
    $ret	= SCR->Execute (".target.bash_output", "tail -n $lines $path");
  }
  return $ret;

}
1;
