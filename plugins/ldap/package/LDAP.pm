package YaPI::LDAP;

use strict;
use YaST::YCP qw(:LOGGING);
use YaPI;
use Data::Dumper;

textdomain ("users");

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

y2internal ("-------- args: ", Dumper ($args));

    # transform integers to real booleans
    if (defined $args->{"start_ldap"}) {
	$args->{"start_ldap"}	= YaST::YCP::Boolean ($args->{"start_ldap"});
    }
    if (defined $args->{"ldap_tls"}) {
	$args->{"ldap_tls"}	= YaST::YCP::Boolean ($args->{"ldap_tls"});
    }

y2internal ("-------- args: ", Dumper ($args));

    Progress->set (0);
    Ldap->Read ();
    Ldap->Import ($args);
    Ldap->Write (undef);
    return $ret;
}

