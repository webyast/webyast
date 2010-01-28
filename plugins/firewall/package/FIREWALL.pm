package YaPI::FIREWALL;

use strict;
use YaST::YCP qw(:LOGGING);
use YaPI;
use Data::Dumper;

# --------------- imported modules
YaST::YCP::Import ("SuSEFirewall");
# --------------------------------

# Return a boolean value indicating, whether a firewall should run
BEGIN{$TYPEINFO{Read} = ["function", "boolean"];
}

sub Read {

  my $self = shift;
  my $ret  = (@{SuSEFirewall->GetEnableService ()})
  return \$ret;
}
