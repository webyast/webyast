package YaPI::ActiveDirectory;

use strict;
use YaST::YCP qw(:LOGGING);
use YaPI;
use Data::Dumper;

# ------------------- imported modules
YaST::YCP::Import ("Progress");
YaST::YCP::Import ("Samba");
YaST::YCP::Import ("SambaAD");
YaST::YCP::Import ("SambaConfig");
YaST::YCP::Import ("SambaNetJoin");
# -------------------------------------

our $VERSION		= '1.0.0';
our @CAPABILITIES 	= ('SLES11');
our %TYPEINFO;

=item *
C<$hash Read ();>

Returns the Samba client configuration

Can return different kind of result, based on passed arguments:
-  if "check_membership" key is present in argument hash, check if the machine
      is member of given domain (the string value of check_membership key);
      if domain is empty, the one saved in samba config file will be checked

=cut

BEGIN{$TYPEINFO{Read} = ["function",
    [ "map", "string", "any" ],
    [ "map", "string", "any" ]];
}
sub Read {

    my $self	= shift;
    my $args	= shift;
    my $ret	= {};

    Progress->set (0);
    Samba->Read ();

    # only check for domain membership
    if (defined ($args->{"check_membership"})) {
	my $domain	= $args->{"check_membership"} || SambaConfig->GlobalGetStr("workgroup", "");

	SambaAD->ReadADS ($domain);
	SambaAD->ReadRealm () if (SambaAD->ADS ());

	$ret->{"result"}	= YaST::YCP::Boolean (SambaNetJoin->Test ($domain));
	return $ret;
    }

    my $export	= Samba->Export ();

    $ret->{"workgroup"}	= $export->{"global"}{"workgroup"} || "";
    $ret->{"winbind"}	= $export->{"winbind"} || "0";
    $ret->{"mkhomedir"}	= Samba->mkhomedir();
# TODO try to find AD domain as with YaST?
# TODO check the 'joined' status here? (takes time!!!)
    return $ret;
}

=item *
C<$string Write ($argument_hash);>

Write Samba configuration
    
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
# Samba->Write,  SambaAD::ADS must be set to save AD settings (e.g. Kerberos)
    return $ret;
}

BEGIN{$TYPEINFO{Join} = ["function",
    "integer",
    [ "map", "string", "any" ]];
}
sub Join {

    my $self	= shift;
    my $args	= shift;
    my $ret	= 0;
# use SambaNetJoin->Join
    return $ret;
}
