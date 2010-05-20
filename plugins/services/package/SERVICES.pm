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

package YaPI::SERVICES;

use strict;
use YaST::YCP qw(:LOGGING);
use YaPI;
use Data::Dumper;

# ------------------- imported modules
YaST::YCP::Import ("Directory");
YaST::YCP::Import ("FileUtils");
YaST::YCP::Import ("Package");
YaST::YCP::Import ("Progress");
YaST::YCP::Import ("Service");
YaST::YCP::Import ("SCR");
YaST::YCP::Import ("Report");
YaST::YCP::Import ("RunlevelEd");
# -------------------------------------

our $VERSION            = '1.0.0';
our @CAPABILITIES       = ('SLES11');
our %TYPEINFO;

my $custom_services_file	= "/etc/webyast/custom_services.yml";

my $error_message		= "";

# check for key presence in given list
sub contains {
    my ( $list, $key, $ignorecase ) = @_;
    if ( $ignorecase ) {
        if ( grep /^$key$/i, @{$list} ) {
            return 1;
        }
    } else {
        if ( grep /^$key$/, @{$list} ) {
            return 1;
        }
    }
    return 0;
}

# log error message and fill it into $error_message variable
sub report_error {
  $error_message	= shift;
  y2error ($error_message);
}

# parse the file with custom services and return the hash describing the file
sub parse_custom_services {

  if (!FileUtils->Exists ($custom_services_file)) {
    report_error ("$custom_services_file file not present");
    return {};
  }

  if (!Package->Installed ("yast2-ruby-bindings")) {
    report_error ("yast2-ruby-bindings not installed, cannot read custom services");
    return {};
  }

  if (!FileUtils->Exists (Directory->moduledir()."/YML.rb")) {
    report_error ("YML.rb not present, cannot parse config file");
    return {};
  }
  
  YaST::YCP::Import ("YML");

  my $parsed = YML->parse ($custom_services_file);

  if (!defined $parsed || ref ($parsed) ne "HASH") {
    report_error ("custom services file could not be read");
    return {};
  }
  return $parsed;
}

# read the list of custom services and return the information about them
# if requested, read the status of services
sub read_custom_services {

  my $args	= shift;
  my @ret	= ();
  my $services	= parse_custom_services ();
  foreach my $name (keys %$services) {
    my $s      = {
	"name"		=> $name
    };
    $s->{"description"}	= ($services->{$name}{"description"} || "") if $args->{"description"} || 0;
    $s->{"shortdescription"}= ($services->{$name}{"shortdescription"} || "") if $args->{"shortdescription"} || 0;

    # read list of available commands, it may be limited for 'custom service'
    my @commands	= ();
    foreach my $key (keys %{$services->{$name}}) {
	if (contains (["start","stop","restart","reload","try-restart"], $key, 1)) {
	    push @commands, $key;
	}
    }
    $s->{"commands"}	= \@commands;

    if ($args->{"read_status"} || 0)
    {
	my $cmd	= $services->{$name}{"status"};
	if (!$cmd) {
	    report_error ("status script for $name not defined or empty");
	    next;
	}
	my $out     = SCR->Execute (".target.bash_output", $cmd);
	$s->{"status"}	= $out->{"exit"};
    }

    push @ret, $s;
  }
  return \@ret;
}

# read infomation about custom service and execute given command with it
sub execute_custom_script {

  my $name	= shift;
  my $action	= shift;
  my $services	= parse_custom_services ();
  my $ret	= {
      "stdout"	=> "",
      "stderr"	=> "failure",
      "exit"	=> 255
  };

  if (%$services) {
    my $service	= $services->{$name};
    if (!defined $service || ref ($service) ne "HASH" || ! %$service) {
	report_error ("service $name not defined or empty in config file");
	$ret->{"stderr"}	= $error_message;
	return $ret;
    }
    my $cmd	= $services->{$name}{$action};
    if (!$cmd) {
	report_error ("'$action' script for $name not defined or empty");
	$ret->{"stderr"}	= $error_message;
	return $ret;
    }
    $ret	= SCR->Execute (".target.bash_output", $cmd);
  }
  return $ret;
}

# Return the list of services enabled in given runlevel, or even all available.
#
# Parameter is an argument map with possible keys:
#	"service"	: if defined, only the status of _this given service_ will be returned (= list with one item)
# 	"runlevel" 	: integer; if not defined, current runlevel will be used
#	"read_status"	: if true, service status will be queried and returned for each service
#	"custom"	: if true, custom services (defined in config file) will be read (otherwise list of init.d services)
#	"description"	: if true, read the description of each service
#	"only_enabled"	: if true, return only list of services enabled in given runlevel
#		- neither "start_runlevels", nor "enabled" key will be part of resulting maps
#	"start_runlevels" if true, each service's result map will contain list of runlevels where it is started
#		- if not present (or false), "enabled" key with boolean value will be returned instead
#	"filter"	: list of strings; defines filtered list of services that should be returned
# @returns array of hashes
BEGIN{$TYPEINFO{Read} = ["function",
    ["list", [ "map", "string", "any"]],
    ["map", "string", "any"]];
}
sub Read {

  my $self	= shift;
  my $args	= shift;
  my @ret	= ();
  my $runlevel	= $args->{"runlevel"} || "";

  $runlevel	= SCR->Read (".init.scripts.current_runlevel") unless ($runlevel);

  unless ($runlevel) {
    $runlevel  = SCR->Read (".init.scripts.default_runlevel");
    y2warning ("current runlevel not available, using default ('$runlevel')");
  }

  my @filter	= ();
  @filter	= @{$args->{"filter"}} if defined $args->{"filter"};
  my $filter_map= {};
  foreach my $s (@filter) {
      $filter_map->{$s}	= 1;
  }

  # only read status of one service if the name was given
  if ($args->{"service"} || "") {
    my $name	= $args->{"service"} || "";
    my $exec	= $self->Execute ({
	"name" 		=> $name,
	"action"	=> "status",
	"only_execute"	=> 1,
	"only_this"	=> 1,
	"custom"	=> $args->{"custom"} || 0
    });
    my $s	= {
	"name"  	=> $name,
	"status"	=> $exec->{"exit"} || 0,
	# custom service is always 'enabled' (in fact, we can't check)
	"enabled"	=> ($args->{"custom"} || 0) || YaST::YCP::Boolean (Service->Enabled ($name))
    };
    push @ret, $s;
    return \@ret;
  }

  # read only custom services
  if ($args->{"custom"} || 0) {
    return read_custom_services ($args);
  }

  if ($args->{"only_enabled"}) {
    # generate the output list
    foreach my $name (@{Service->EnabledServices ($runlevel)}) {
	next if (@filter && !defined $filter_map->{$name}); # should not be returned
	my $s      = {
	    "name"		=> $name,
	};
	$s->{"status"}	= Service->Status ($name) if ($args->{"read_status"} || 0);
	if (($args->{"description"} || 0) || ($args->{"shortdescription"} || 0)) {
	    my $info	= Service->Info ($name);
	    $s->{"description"}	= ($info->{"description"} || "") if $args->{"description"} || 0;
	    $s->{"shortdescription"}= ($info->{"shortdescription"} || "") if $args->{"shortdescription"} || 0;
	}
	push @ret, $s;
    }
  }
  else {
    my $progress_orig   = Progress->set (0);
    Report->DisplayErrors (0, 0);
    RunlevelEd->Read ();
    my $full_services	= RunlevelEd->services ();
    while (my ($name, $info) = each %$full_services) {

	next if (@filter && !defined $filter_map->{$name}); # should not be returned
	next if (contains ($info->{"defstart"} || [], "B", 1));

	my $s      = {
	    "name"		=> $name
	};

	if ($args->{"start_runlevels"} || 0) {
	    $s->{"start_runlevels"}	= $info->{"start"} || [];
	}
	else {
	    my $start		= $info->{"start"} || [];
	    # for "B" check, see RunlevelEd::StartContainsImplicitly
	    $s->{"enabled"}	= YaST::YCP::Boolean (contains ($start, $runlevel, 1) || contains ($start, "B", 1));
	}
	# return start and stop dependencies for each service
	if ($args->{"dependencies"} || 0) {
	    my @required_for_start	= ();
	    # filter out services started on boot by default:
	    foreach my $rq (@{RunlevelEd->ServiceDependencies ($name, 1)}) {
		my $start	= $full_services->{$rq}{"start"} || [];
		push @required_for_start, $rq unless contains ($start, "B", 1);
	    }
	    $s->{"required_for_start"}	= \@required_for_start;
	    $s->{"required_for_stop"}	= RunlevelEd->ServiceDependencies ($name, 0);
	}
	$s->{"status"}		= Service->Status ($name) if ($args->{"read_status"} || 0);
	$s->{"description"}	= ($info->{"description"} || "") if $args->{"description"} || 0;
	$s->{"shortdescription"}= ($info->{"shortdescription"} || "") if $args->{"shortdescription"} || 0;
	push @ret, $s;
    }
    Progress->set ($progress_orig);
  }

  return \@ret;
}

# Return the status of given service 
# return value is the exit code of status function
BEGIN{$TYPEINFO{Get} = ["function",
    "integer", "string" ];
}
sub Get {

  my $self	= shift;
  my $name	= shift;

  return Service->Status ($name);
}

# Executes an action (e.g. "restart") with given service
# If the action is start or stop, it will also enable (resp. disable)
# the service for current runlevel.
#
# parameter is a map where "name" is service name, "action" means what to do
# - if "only_execute" key is present, do not continue with enabling/disabling
# - if action is "enable" or "disable", only enables/disables service
# - if "custom" key is present (with true value), indicates custom service, which
# has special handling. Also, custom service will not be enabled/disabled.
#
# return value is map with "exit", "stdout" and "stderr" keys
BEGIN{$TYPEINFO{Execute} = ["function",
    [ "map", "string", "any"],
    [ "map", "string", "any"]];
}
sub Execute {

  my $self	= shift;

  my $args	= shift;
  my $name	= $args->{"name"} || "";
  my $action	= $args->{"action"} || "";
  my $ret	= {};

  y2debug ("Execute args: ", Dumper ($args));

  # no enable/disable
  my $only_execute 	= $args->{"only_execute"} || 0;
  # do not solve dependencies
  my $only_this 	= $args->{"only_this"} || 0;

  # just a shurtcut, so Execute function can be used for Enable only
  return $self->Enable ($args) if ($action eq "enable" || $action eq "disable");

  # custom service has special handling
  if ($args->{"custom"} || 0) {
    return execute_custom_script ($name, $action);
  }
  # only handle given service, not dependencies
  elsif ($only_this) {
    $ret = Service->RunInitScriptOutput ($name, $action);
    unless ($only_execute) {
	if (($ret->{"exit"} || 0) ne 0) {
	    y2error ("action '$action' failed");
	    return $ret;
	}
	if ($action eq "start") {
	    $args->{"action"}	= "enable";
	}
	else {
	    $args->{"action"}	= "disable";
	}
	return $self->Enable ($args);
    }
  }
  # full action: start/stop and enable/disable required service
  else {
    my $progress_orig   = Progress->set (0);
    RunlevelEd->Read ();
    Progress->set ($progress_orig);

    my $full_services	= RunlevelEd->services ();
    my $runlevel	= RunlevelEd->GetCurrentRunlevel ();

    if ($runlevel eq "unknown") {
	$runlevel        = RunlevelEd->GetDefaultRunlevel ();
	y2warning ("current runlevel not available, using default ('$runlevel')");
    }

    # in fact, this may mean "start & enable" (depends on $only_execute)
    my $start		= ($action eq "start") || ($action eq "restart");

    # list of runlevels where the service should be enabled
    my $rls = $start? ($full_services->{$name}{"defstart"} || []) : undef;

    # list of dependencies
    my $dep_s	= RunlevelEd->ServiceDependencies ($name, $start);

    # filtered list; unfortunatelly it does not really check for current status
    $dep_s	= RunlevelEd->FilterAlreadyDoneServices ($dep_s, $rls, $start, 1, 1);

    my $enable_args	= {
	"action"	=> ($action eq "start") ? "enable" : "disable",
	# we're solving dependencies here, so no need to do it in Enable call again
	"only_this"	=> 1
    };

    foreach my $s (@$dep_s) {
	# check if service is not already running
	my $status	= Service->Status ($s);
	# action for required service: when restarting selected, only start required ones
	my $req_action	= ($action eq "restart") ? "start" : $action;
	if (($start && $status != 0) || ($status == 0 && !$start)) {
	    # RunInitScriptWithTimeOut would be better, but does not return stderr
	    $ret	= Service->RunInitScriptOutput ($s, $req_action);
	}
	if (($ret->{"exit"} || 0) ne 0) {
	    y2error ("action '$req_action' for service '$s' failed");
	    return $ret;
	}
	next if $only_execute;

	my $startlist		= $full_services->{$s}{"start"} || [];
	my $service_enabled	= contains ($startlist, $runlevel, 1) || contains ($startlist, "B", 1);
	if (($start && !$service_enabled) || (!$start && $service_enabled)) {
	    $enable_args->{"name"}	= $s;
	    $ret	= $self->Enable ($enable_args);
	}
	if (($ret->{"exit"} || 0) ne 0) {
	    y2error ("insserv call for service '$s' failed");
	    return $ret;
	}
    }
    # now, finally start/stop our service...
    $ret	= Service->RunInitScriptOutput ($name, $action);
    if (($ret->{"exit"} || 0) ne 0) {
	y2error ("action '$action' for service '$name' failed");
	return $ret;
    }
    return $ret if $only_execute;
    # ... and enable/disable it
    $enable_args->{"name"}      = $name;
    $ret	= $self->Enable ($enable_args);
  }
  return $ret;
}

# Enable/Disable given service in current runlevel
# parameter is a map where "name" is service name, "action" means what to do
# return value is map with "exit", "stdout" and "stderr" keys
BEGIN{$TYPEINFO{Enable} = ["function",
    [ "map", "string", "any"],
    [ "map", "string", "any"]];
}
sub Enable {

  my $self	= shift;
  my $args	= shift;
  my $name	= $args->{"name"} || "";
  my $action	= $args->{"action"} || "";
  my $ret	= {
      "stdout"	=> "",
      "stderr"	=> "",
      "exit"	=> 0
  };
  # do not solve dependencies
  my $only_this 	= $args->{"only_this"} || 0;

  y2debug ("Enable args: ", Dumper ($args));

  # enable/disable with dependencies
  unless ($only_this) {
    my $progress_orig   = Progress->set (0);
    Report->DisplayErrors (0, 0);
    RunlevelEd->Read ();
    my $exit	= 0;
    if ($action eq "enable") {
	$exit	= RunlevelEd->ServiceInstall ($name, undef);
	if ($exit == 1) {
	    $ret->{"stderr"}	= "Failed to enable service $name.";
	    $ret->{"stdout"}	= $name;
	    $ret->{"exit"}	= 1000;
	}
    } elsif ($action eq "disable") {
	$exit	= RunlevelEd->ServiceRemove ($name, undef);
	if ($exit == 1) {
	    $ret->{"stderr"}	= "Failed to disable service $name.";
	    $ret->{"stdout"}	= $name;
	    $ret->{"exit"}	= 2000;
	}
    }
    unless (RunlevelEd->Write ()) {
	$ret->{"stderr"}	= "Failed during writing runlevel settings.";
	$ret->{"exit"}		= 3000;
    }
    Progress->set ($progress_orig);
    return $ret;
  }

  if ($action eq "enable") {
    unless (Service->Enable ($name)) {
	$ret->{"stderr"}	= "Failed to enable service $name.";
	$ret->{"stdout"}	= $name;
	$ret->{"exit"}		= 1000;
    }
  }
  elsif ($action eq "disable") {
    unless (Service->Disable ($name)) {
	$ret->{"stderr"}	= "Failed to disable service $name.";
	$ret->{"stdout"}	= $name;
	$ret->{"exit"}		= 2000;
    }
  }
  else {
    $ret->{"stderr"}	= "Unknown action '$action'";
    $ret->{"exit"}		= 3;
  }
  return  $ret;
}

1;
