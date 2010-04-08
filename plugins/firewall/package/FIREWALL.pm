package YaPI::FIREWALL;

use strict;
use YaST::YCP qw(:LOGGING);
use YaPI;
use Data::Dumper;

# --------------- imported modules
YaST::YCP::Import ("SuSEFirewall");
YaST::YCP::Import ("SuSEFirewallServices");
YaST::YCP::Import ("Mode");
# --------------------------------

our $VERSION            = '1.0.0';
our @CAPABILITIES       = ('SLES11');
our %TYPEINFO;

# Return a boolean value indicating, whether a firewall is running and
# a list of services with their translated name and a boolean value indicating whether
# they should be allowed or not (in the external zone).
BEGIN{$TYPEINFO{Read} = ["function", ["map", "string", "any"]];
}

sub Read {
  my $self = shift;
  SuSEFirewall->ResetReadFlag();
  SuSEFirewall->Read();
  my $status  = YaST::YCP::Boolean( SuSEFirewall->GetEnableService () );
  my $known_services = SuSEFirewallServices->GetSupportedServices();
  my @service_ids = keys %$known_services;
  my $service_zones = SuSEFirewall->GetServices(\@service_ids);
  my $mkService = mkServiceGenerator($known_services, $service_zones, "EXT");
  my @services = map($mkService->($_),@service_ids);
  y2milestone "YaPI::FIREWALL::mkService -> '".($mkService->($service_ids[0]))."'";
  my %ret = ('use_firewall' => $status, 
             'fw_services'  => \@services
            );
  return \%ret;
}

sub mkServiceGenerator {
  my($service_names,$service_zones,$zone) = @_;
  my $generator = sub { my $service_id = shift;
                       { 'id'      => $service_id,
                         'name'    => $service_names->{$service_id},
                         'allowed' => YaST::YCP::Boolean( $service_zones->{$service_id}->{$zone} )
                       }
                      };
  return $generator;
}

#  Write firewall settings
#  { "use_firewall" => 1,
#    "fw_services"     => [ { "id"      => "service:lighttpd-ssl",
#                          "allowed" => 1 },
#                        { "id"      => "service:samba-client",
#                          "allowed" => 0 }
#                      ]
#  }
#  Return structure
#  { "result" => YaST::YCP::Boolean(1),
#    "error"  => "error string"
#  }
BEGIN{$TYPEINFO{Write} = [ "function", 
                          ["map","string","any"], 
                          ["map","string","any"]]}
sub Write {
  my $self     = shift;
  my $settings = shift;
  y2milestone("YaPI::FIREWALL::Write - setting Mode::_test to none");
  Mode->testMode();
  Mode->SetTest("none");
  y2milestone("YaPI::FIREWALL::Write - settings", Dumper($settings));
  SuSEFirewall->SetEnableService ( $settings->{"use_firewall"} );
  SuSEFirewall->SetStartService ( $settings->{"use_firewall"} );
  my @allowed_services = map {$_ ->{"id"}} (grep { $_->{"allowed"}} @{$settings->{"fw_services"}} );
  my @forbidden_services = map {$_->{"id"}} (grep { ! $_->{"allowed"} } @{$settings->{"fw_services"}});
  y2milestone("YaPI::FIREWALL::Write - allowing services", Dumper(\@allowed_services));
  y2milestone("YaPI::FIREWALL::Write - forbidding services", Dumper(\@forbidden_services));
  SuSEFirewall->SetServicesForZones( \@allowed_services, ["EXT"], 1 );
  SuSEFirewall->SetServicesForZones( \@forbidden_services, ["EXT"], 0 );
  my $result = SuSEFirewall->Write();
  # SetServicesForZones should return boolean result according to description, but in code it never does.
  return {"saved_ok" => YaST::YCP::Boolean($result), "error"=>""};
}
