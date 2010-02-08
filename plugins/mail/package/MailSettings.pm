# A wrapper to call YaPI::MailServer
# Used to get more understandable function names, policies,
# and to prevent returning nil values which cannot get through dbus.
package YaPI::MailSettings;

use strict;
use ycp;
use YaPI;
use Data::Dumper;

our %TYPEINFO;

YaST::YCP::Import ("Mail");
YaST::YCP::Import ("Progress");

# Read part of mail configuration: SMTP server and authentication details
# Uses Mail.ycp API
# returns hash with keys smtp_server, user, password, TLS
BEGIN { $TYPEINFO{Read}  =["function", ["map", "string", "any" ]]; }
sub Read {

    my $progress_orig	= Progress->set (0);
    Mail->Read (undef);
    Progress->set ($progress_orig);

    my $ex		= Mail->Export ();
    my $smtp_auth	= {};
    $smtp_auth		= $ex->{"smtp_auth"}[0] if defined $ex->{"smtp_auth"} && ref ($ex->{"smtp_auth"}) eq "ARRAY";

    return {
	"smtp_server"	=> $ex->{"outgoing_mail_server"} || "",
	"user"		=> $smtp_auth->{"user"} || "",
	"password"	=> $smtp_auth->{"password"} || "",
	"TLS"		=> $ex->{"smtp_use_TLS"} || "no"
    }
}

# Writes simple mail configuration: SMTP server and authentication details
# parameters: hash with keys smtp_server, user, password, TLS
# returns error message 
BEGIN { $TYPEINFO{Write}  =["function", "string", ["map", "string", "any" ]]; }
sub Write {

    my $self		= shift;
    my $settings	= shift;
    my $ret		= "";

    my $smtp_server	= $settings->{"smtp_server"} || "";
    my @smtp_auth	= ();
    if (($settings->{"user"} || "") ne "") {
	push @smtp_auth, {
	    "server"		=> $smtp_server,
	    "user"		=> $settings->{"user"} || "",
	    "password"		=> $settings->{"password"} || ""
	};
    }
    Mail->Import ({
	"mta"			=> "postfix",
	"connection_type"	=> "permanent",
	"postfix_mda"		=> "local",
	"outgoing_mail_server"	=> $smtp_server,
	"smtp_auth"		=> \@smtp_auth,
	"smtp_use_TLS"		=> $settings->{"TLS"} || "no"
    });
    Mail->WriteGeneral ();
    Mail->WriteSmtpAuth ();
    return "Error writing config file(s)." unless Mail->WriteFlush ();
    return "Error running SuSEconfig." unless Mail->WriteSuSEconfig ();
    Mail->WriteServices (); # return value could be broken, bnc#577932
    
    return "";
}

1;
