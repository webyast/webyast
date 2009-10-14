# = RegistrationConfiguration controller
# Provides access to the configuration of the registration system
#class Registration::ConfigurationController < ApplicationController
class ConfigurationController < ApplicationController

  before_filter :login_required

  def update
# FIXME remove static certificate file after testing!!
newca="-----BEGIN CERTIFICATE-----
MIID5TCCAs2gAwIBAgIEOeSXnjANBgkqhkiG9w0BAQUFADCBgjELMAkGA1UEBhMC
VVMxFDASBgNVBAoTC1dlbGxzIEZhcmdvMSwwKgYDVQQLEyNXZWxscyBGYXJnbyBD
ZXJ0aWZpY2F0aW9uIEF1dGhvcml0eTEvMC0GA1UEAxMmV2VsbHMgRmFyZ28gUm9v
dCBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkwHhcNMDAxMDExMTY0MTI4WhcNMjEwMTE0
MTY0MTI4WjCBgjELMAkGA1UEBhMCVVMxFDASBgNVBAoTC1dlbGxzIEZhcmdvMSww
KgYDVQQLEyNXZWxscyBGYXJnbyBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eTEvMC0G
A1UEAxMmV2VsbHMgRmFyZ28gUm9vdCBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkwggEi
MA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDVqDM7Jvk0/82bfuUER84A4n13
5zHCLielTWi5MbqNQ1mXx3Oqfz1cQJ4F5aHiidlMuD+b+Qy0yGIZLEWukR5zcUHE
SxP9cMIlrCL1dQu3U+SlK93OvRw6esP3E48mVJwWa2uv+9iWsWCaSOAlIiR5NM4O
JgALTqv9i86C1y8IcGjBqAr5dE8Hq6T54oN+J3N0Prj5OEL8pahbSCOz6+MlsoCu
ltQKnMJ4msZoGK43YjdeUXWoWGPAUe5AeH6orxqg4bB4nVCMe+ez/I4jsNtlAHCE
AQgAFG5Uhpq6zPk3EPbg3oQtnaSFN9OH4xXQwReQfhkhahKpdv0SAulPIV4XAgMB
AAGjYTBfMA8GA1UdEwEB/wQFMAMBAf8wTAYDVR0gBEUwQzBBBgtghkgBhvt7hwcB
CzAyMDAGCCsGAQUFBwIBFiRodHRwOi8vd3d3LndlbGxzZmFyZ28uY29tL2NlcnRw
b2xpY3kwDQYJKoZIhvcNAQEFBQADggEBANIn3ZwKdyu7IvICtUpKkfnRLb7kuxpo
7w6kAOnu5+/u9vnldKTC2FJYxHT7zmu1Oyl5GFrvm+0fazbuSCUlFLZWohDo7qd/
0D+j0MNdJu4HzMPBJCGHHt8qElNvQRbn7a6U+oxy+hNH8Dx+rn0ROhPs7fpvcmR7
nX1/Jv16+yWt6j4pf0zjAFcysLPp7VMX2YuyFA4w6OXVE8Zkr8QA1dhYJPz1j+zx
x32l2w8n0cbyQIjmH/ZhqPRCyLk306m+LFZ4wnKbWV01QIroTmMatukgalHizqSQ
33ZwmVxwQ023tqcZZE6St8WRPH9IFmV7Fv3L/PvZ1dZPIWU7Sn9Ho/s=
-----END CERTIFICATE-----
"

    # PUT
    puts params.inspect
    @registration = Registration.new( { } )
    @registration.set_config 'https://static.test.server/test/path', newca
    render :show
  end

  def show
    # do not run registration, only get the config
    @registration = Registration.new( { } )
    @registration.get_config
  end

  def index
    # same as show
    show
  end

end
