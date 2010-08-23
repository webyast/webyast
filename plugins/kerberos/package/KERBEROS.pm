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

package YaPI::KERBEROS;

use strict;
use YaST::YCP qw(:LOGGING);
use YaPI;
use Data::Dumper;

# ------------------- imported modules
YaST::YCP::Import ("Kerberos");
YaST::YCP::Import ("Progress");
# -------------------------------------

our $VERSION		= '1.0.0';
our @CAPABILITIES 	= ('SLES11');
our %TYPEINFO;

=item *
C<$hash Read ();>

Returns the Kerberos client configuration

=cut

BEGIN{$TYPEINFO{Read} = ["function",
    [ "map", "string", "any" ],
    [ "map", "string", "any" ]];
}
sub Read {

    my $self	= shift;
    my $args	= shift;

    Progress->set (0);
    Kerberos->Read ();
    my $export	= Kerberos->Export ();

    if ($args->{"full_export"}) {
	return $export;
    }
    return {
	"default_realm"	=> $export->{"kerberos_client"}{"default_realm"} || "",
	"default_domain"=> $export->{"kerberos_client"}{"default_domain"} || "",
	"kdc"		=> $export->{"kerberos_client"}{"kdc_server"} || "",
	"use_kerberos"	=> $export->{"pam_login"}{"use_kerberos"},
	"dns_used"	=> Kerberos->dns_used ()
    };
}

=item *
C<$string Write ($argument_hash);>

Write Kerberos configuration
    
Returns error code, 0 is success

=cut

BEGIN{$TYPEINFO{Write} = ["function",
    "integer",
    [ "map", "string", "any" ]];
}
sub Write {

    my $self	= shift;
    my $args	= shift;
    my $ret	= 0;


    Progress->set (0);
    Kerberos->Read ();

    if (defined $args->{"use_kerberos"}) {
	Kerberos->use_pam_krb ($args->{"use_kerberos"});
	Kerberos->pam_modified (1);
    }
    if (defined $args->{"dns_used"}) {
	Kerberos->dns_used ($args->{"dns_used"});
    }
    Kerberos->default_domain ($args->{"default_domain"} || "") if defined $args->{"default_domain"};
    Kerberos->default_realm ($args->{"default_realm"} || "") if defined $args->{"default_realm"};
    Kerberos->kdc ($args->{"kdc"} || "") if defined $args->{"kdc"};

    Kerberos->modified (1);

    Kerberos->Write ();
    return $ret;
}

