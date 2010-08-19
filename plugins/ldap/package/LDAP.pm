package YaPI::LDAP;

use strict;
use YaST::YCP qw(:LOGGING);
use YaPI;
use Data::Dumper;

# ------------------- imported modules
YaST::YCP::Import ("Ldap");
YaST::YCP::Import ("Progress");
# -------------------------------------

our $VERSION		= '1.0.0';
our @CAPABILITIES 	= ('SLES11');
our %TYPEINFO;

=item *
C<$hash Read ();>

Returns the LDAP client configuration

=cut

BEGIN{$TYPEINFO{Read} = ["function",
    [ "map", "string", "any" ]];
}
sub Read {

    my $self	= shift;

    Progress->set (0);
    Ldap->Read (); #FIXME path to pam-config not known?
    my $export	= Ldap->Export ();

    return $export;
}

=item *
C<$string Write ($argument_hash);>

Write LDAP configuration
    
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
    Ldap->Read ();

    # transform integers to real booleans
    if (defined $args->{"start_ldap"}) {
	Ldap->start (YaST::YCP::Boolean ($args->{"start_ldap"}));
    }
    if (defined $args->{"ldap_tls"}) {
	Ldap->ldap_tls (YaST::YCP::Boolean ($args->{"ldap_tls"}));
    }

    Ldap->server ($args->{"ldap_server"}) if defined $args->{"ldap_server"};
    if (defined $args->{"ldap_domain"}) {
	my $base_dn	= $args->{"ldap_domain"} || "";
	Ldap->SetBaseDN ($base_dn);
	Ldap->nss_base_passwd ($base_dn);
	Ldap->nss_base_shadow ($base_dn);
	Ldap->nss_base_group ($base_dn);
    }

    Ldap->modified (1);
    Ldap->openldap_modified (1);

    Ldap->Write (undef);
    return $ret;
}

