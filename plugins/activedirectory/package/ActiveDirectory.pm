package YaPI::ActiveDirectory;

use strict;
use YaST::YCP qw(:LOGGING);
use YaPI;
use Data::Dumper;

# ------------------- imported modules
YaST::YCP::Import ("Progress");
YaST::YCP::Import ("Samba");
YaST::YCP::Import ("SambaAD");
YaST::YCP::Import ("SambaNetJoin");
# -------------------------------------

our $VERSION		= '1.0.0';
our @CAPABILITIES 	= ('SLES11');
our %TYPEINFO;

=item *
C<$hash Read ();>

Returns the Samba client configuration

=cut

BEGIN{$TYPEINFO{Read} = ["function",
    [ "map", "string", "any" ]];
}
sub Read {

    my $self	= shift;

    Progress->set (0);
    Samba->Read ();
    my $export	= Samba->Export ();

# FIXME do not export whole map, we do not need it
    my $ret	= {};
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
