package YaPI::NTP;

use strict;
use YaPI;

BEGIN{$TYPEINFO{Synchronize} = ["function",
    "string","string"];
sub Synchronize {
  my $self = shift;
  my $server = shift;

  # -r: do set the system time
  # -P no: do not ask if time difference is too large
  # -c 1 -d 15: delay 15s, only one try (bnc#442287)
  $out = `/usr/sbin/sntp -c 1 -d 15 -r -P no '$server' 2>&1`
  if ($?){
    return $out;
  } else {
    return "OK"
  }
}
