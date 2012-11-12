#--
# Copyright (c) 2012 Novell, Inc.
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

package YaPI::MirrorCredentials;

use strict;
use YaST::YCP qw(:LOGGING);
use YaPI;
use XML::Simple;

our $VERSION		= '1.0.0';
our %TYPEINFO;


# location of the credentials
my $cred_file = "/var/lib/suseRegister/mirror-credentials.xml";

# return the default mirroring credentials file name
BEGIN{ $TYPEINFO{CredFile} = ["function", "string"]; }
sub CredFile {
    my ($self) = @_;
    return $cred_file;
}

# parse the requested mirror credentials XML file, convert the XML file into a map
BEGIN{ $TYPEINFO{ReadFile} = ["function", ["map","any","any"], "string"]; }
sub ReadFile {
    my $file = shift;

    # create XML parser
    my $parser = new XML::Simple;

    # parse the file
    y2milestone("Reading credentials file: $file");
    my $data = $parser->XMLin($file);

    return $data;
}

# parse the default mirror credential XML file
BEGIN{ $TYPEINFO{Read} = ["function", ["map","any","any"]]; }
sub Read {
    my ($self) = @_;
    return ReadFile($cred_file);
}


1
