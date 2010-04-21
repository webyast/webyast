#--
# Copyright (c) 2009-2010 Novell, Inc.
# 
# All Rights Reserved.
# 
# This program is free software; you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License
# as published by the Free Software Foundation.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, contact Novell, Inc.
# 
# To contact Novell about this file by physical or electronic mail,
# you may find current contact information at www.novell.com
#++

# A wrapper to call YaPI::MailServer
# Used to get more understandable function names, policies,
# and to prevent returning nil values which cannot get through dbus.
package YaPI::MailSettings;

use strict;
use ycp;
use YaPI;
use Data::Dumper;

our %TYPEINFO;

YaST::YCP::Import ("FileUtils");
YaST::YCP::Import ("Mail");
YaST::YCP::Import ("Progress");
YaST::YCP::Import ("SCR");

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
    return "Error restarting service(s)." unless Mail->WriteServices ();

    my $symlink	= "/etc/sysconfig/network/if-up.d/postfix-update-hostname";

    if ($smtp_server && !FileUtils->Exists ($symlink)) {
	# link to dhcpcd hook that should update mail domain (bnc#559145)
	y2milestone ("creating symlink '$symlink'");
	SCR->Execute (".target.symlink",
	"/etc/sysconfig/network/scripts/postfix-update-hostname", $symlink);

	my $out	= SCR->Execute (".target.bash_output", "ip r|grep default|cut -d' ' -f5");
	my $name= $out->{"stdout"} || "";
	if ($name) {
	    chomp $name;
	    y2milestone ("executing '$symlink $name -o dhcp'...");
	    SCR->Execute (".target.bash", "$symlink $name -o dhcp");
	}
    }
    elsif (FileUtils->Exists ($symlink) && !$smtp_server) {
	y2milestone ("removing symlink '$symlink'");
	SCR->Execute (".target.remove", $symlink);
    }
    
    return "";
}

1;
