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

package YaPI::NTP;

use strict;
use YaPI;
use YaST::YCP qw(:LOGGING);

our %TYPEINFO;

BEGIN{$TYPEINFO{Synchronize} = ["function","string",
    "boolean","string"];
}
sub Synchronize {
  my $self = shift;
  my $use_utc = shift;
  my $new_server = shift;
  my $out = undef;
  my $servers = GetServers();
  if ($new_server ne ""){
    my @srvs = split(',',$new_server);
    $servers = \@srvs;
  }

  foreach my $server (@{$servers}){
    # -r: set the system time
    # -P no: do not ask if time difference is too large
    # -c 1 -d 15: delay 15s, only one try (bnc#442287)
    $out = `/usr/sbin/sntp -c 3 -d 15 -r -P no '$server' 2>&1`;
    last if ($?==0);
    $out = "Error for server $server: $out";
    y2warning($out);
  }
  return "NOSERVERS" unless (defined ($out));
  return $out unless $?==0;
  my $local = "--utc";
  unless ($use_utc) {
    $local = "--localtime";
  }
  my $ret = `/sbin/hwclock $local --systohc 2>&1`;
  y2milestone("hwclock returns $?: $ret");
  if ($? == 0){
    if ($new_server ne "")
    {
      `sed -i 's|^[:space:]*NETCONFIG_NTP_STATIC_SERVERS=.*\$|NETCONFIG_NTP_STATIC_SERVERS="$new_server"|' /etc/sysconfig/network/config `;
      `netconfig update -m ntp`; #update ntp confiration immediatelly bnc#589303
    }
    return "OK";
  }
  return $out.$ret;
}

sub GetServers {
  my $self = shift;
  my $servers = `grep "^[:space:]*NETCONFIG_NTP_STATIC_SERVERS" /etc/sysconfig/network/config | sed 's/.*="\\(.*\\)"/\\1/'`;
  my @serv = split(/\s+/,$servers);
  return \@serv;
}

1;
#print join(",",@{GetServers()});
