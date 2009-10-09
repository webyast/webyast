# A wrapper to call YaPI::MailServer
# Used to get more understandable function names, policies,
# and to prevent returning nil values which cannot get through dbus.
package YaPI::MailSettings;

use strict;
use ycp;
#use YaST::YCP;
use YaPI;
use Data::Dumper;

our %TYPEINFO;

YaST::YCP::Import ("YaPI::MailServer");

# wrapper for MailServer::ReadGlobalSettings
BEGIN { $TYPEINFO{Read}  =["function", ["map", "string", "any" ]]; }
sub Read {

    my $global_settings	= YaPI::MailServer->ReadGlobalSettings ("");

    # check for nil values...
    while (my ($key, $value) = each %{$global_settings}) {
	if (!defined $value) {
	    $global_settings->{$key}	= "";
	    y2warning ("value for key $key not defined!");
	}
    }
    return $global_settings;
}

# wrapper for MailServer::WriteGlobalSettings
# returns value is error message 
BEGIN { $TYPEINFO{Write}  =["function", "string", ["map", "string", "any" ]]; }
sub Write {

    my $self		= shift;
    my $settings	= shift;
    my $ret		= "";

    if (!defined YaPI::MailServer->WriteGlobalSettings ($settings, "")) {
	my $error	= YaPI->Error ();
	$ret		=  $error->{'summary'} || "";
    }
    return $ret;
}

1;
