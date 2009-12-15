package YaPI::NTP;

use strict;
use YaPI;
use YaST::YCP qw(:LOGGING);

our %TYPEINFO;

BEGIN{$TYPEINFO{Synchronize} = ["function","boolean"
    "string"];
}
sub Synchronize {
  my $self = shift;
  my $use_utc = shift;
  my $servers = getServers();
  my $out = undef;

  foreach my $server (@{$servers}){
    # -r: set the system time
    # -P no: do not ask if time difference is too large
    # -c 1 -d 15: delay 15s, only one try (bnc#442287)
    $out = `/usr/sbin/sntp -c 1 -d 15 -r -P no '$server' 2>&1`;
    last if ($?==0);
    $out = "Error for server $server: $out";
    y2warning($out);
  }
  return "NOSERVERS" unless (defined ($out));
  my $local = "--utc"
  unless $use_utc {
    my $local = "--localtime"
  }
  my $ret = `/sbin/hwclock $local --systohc`;
  y2milestone("hwclock returns $?: $ret");
  if ($? == 0){
    return "OK";
  }
  return $out.$ret;
}

BEGIN{$TYPEINFO{Available} = ["function",
    "boolean"];
}
sub Available {
  my $self = shift;
  return ((scalar @{getServers()}) != 0) && (getServers()->[0] ne "")
}


sub getServers {
  my $servers = `grep "^[:space:]*NETCONFIG_NTP_STATIC_SERVERS" /etc/sysconfig/network/config | sed 's/.*="\\(.*\\)"/\\1/'`;
  my @serv = split(/\s+/,$servers);
  return \@serv;
}

1;
