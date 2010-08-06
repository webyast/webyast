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
	my $domain	= $args->{"check_membership"} || Samba->GetWorkgroupOrRealm ();

	SambaAD->ReadADS ($domain);
	if (SambaAD->ADS ()) {
	    $domain = SambaAD->GetWorkgroup ($domain);
	    SambaAD->ReadRealm ();

	    # return the parts that could be omited later, like AD server, workgroup, realm?
	    $ret->{"ads"}	= SambaAD->ADS ();
	    $ret->{"workgroup"}	= $domain;
	    $ret->{"realm"}     = SambaAD->Realm ();
	}

	$ret->{"result"}	= YaST::YCP::Boolean (SambaNetJoin->Test ($domain));
	return $ret;
    }

    $ret->{"domain"}	= Samba->GetWorkgroupOrRealm ();
    $ret->{"winbind"}	= Samba->GetWinbind ();
    $ret->{"mkhomedir"}	= Samba->mkhomedir();
    return $ret;
}

=item *
C<$string Write ($argument_hash);>

Write Samba configuration or join AD domain
    
Returns error map, empty means success

=cut

BEGIN{$TYPEINFO{Write} = ["function",
    [ "map", "string", "any" ],
    [ "map", "string", "any" ]];
}
sub Write {

    my $self	= shift;
    my $args	= shift;
    my $ret	= {};

    Progress->set (0);
    Samba->Read ();

    # try to join AD domain when credentials are present
    if ($args->{"administrator"}) {
	$ret	= $args->{"leave"} ? $self->Leave ($args) : $self->Join ($args);
	if ($ret->{"join_error"}) {
	    y2warning ("join failed, ending write");
	    return $ret;
	}
    	elsif ($ret->{"leave_error"}) {
	    y2warning ("leave failed, ending write");
	    return $ret;
	}
    }

    my $domain	= $args->{"domain"} || Samba->GetWorkgroupOrRealm ();

    # - after join, AD data are already read
    # - do not do the reads when only disabling
    if ((! $args->{"administrator"}) && ($args->{"winbind"} || 0)) {
	if ($args->{"ads"}) {
	    SambaAD->SetADS ($args->{"ads"});
	}
	else {
	    SambaAD->ReadADS ($domain);
	}

	# work group = "Pre-Win2k Domain"
	if ($args->{"workgroup"}) {
	    $domain	= $args->{"workgroup"};
	}
	else {
	    $domain = SambaAD->GetWorkgroup ($domain);
	}
	Samba->SetWorkgroup ($domain);

	if ($args->{"realm"}) {
	    SambaAD->SetRealm ($args->{"realm"});
	}
	else {
	    SambaAD->ReadRealm ();
	}
    }

    Samba->SetWinbind ($args->{"winbind"} || 0) if (defined $args->{"winbind"});;
    Samba->SetMkHomeDir ($args->{"mkhomedir"} || 0) if (defined $args->{"mkhomedir"});

    $ret->{"write_error"}	= 1 unless Samba->Write (0);

    return $ret;
}

# Join given AD domain
# Argument map must contain domain and administrator credentials
# It may contain information about workgroup (short name), AD server and realm
BEGIN{$TYPEINFO{Join} = ["function",
    [ "map", "string", "any" ],
    [ "map", "string", "any" ]];
}
sub Join {

    my $self	= shift;
    my $args	= shift;
    my $ret	= {};

    my $domain	= $args->{"domain"} || Samba->GetWorkgroupOrRealm ();


    if ($args->{"ads"}) {
	SambaAD->SetADS ($args->{"ads"});
    }
    else {
	SambaAD->ReadADS ($domain);
    }

    # work group = "Pre-Win2k Domain"
    if ($args->{"workgroup"}) {
	$domain	= $args->{"workgroup"};
    }
    else {
	$domain = SambaAD->GetWorkgroup ($domain);
    }
    Samba->SetWorkgroup ($domain);

    if ($args->{"realm"}) {
	SambaAD->SetRealm ($args->{"realm"});
    }
    else {
	SambaAD->ReadRealm ();
    }

    my $result = SambaNetJoin->Join ($domain, "member", $args->{"administrator"}, $args->{"password"} || "", $args->{"machine"});
    $ret->{"join_error"}	= $result if $result;
    return $ret;
}

# Leave current AD domain
# Argument map must contain administrator credentials
BEGIN{$TYPEINFO{Leave} = ["function",
    [ "map", "string", "any" ],
    [ "map", "string", "any" ]];
}
sub Leave {

    my $self	= shift;
    my $args	= shift;
    my $ret	= {};

    # domain is currently not used in leave command
    my $domain	= $args->{"domain"} || Samba->GetWorkgroupOrRealm ();

    my $result = SambaNetJoin->Leave ($domain, $args->{"administrator"}, $args->{"password"} || "");
    $ret->{"leave_error"}	= $result if $result;
    return $ret;
}
