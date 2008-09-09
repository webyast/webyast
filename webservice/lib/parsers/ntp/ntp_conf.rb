class Parsers::Ntp::NtpConf
  def parse( location )
    @opthash = Hash.new
    @servers = Hash.new
    @opthash[:id] = location
    @opthash[:location] = location

    IO.foreach( location ) { |line|
      case line

        when /^server\s+(\S+)/
          cserver = @servers[$1]
          if ( ! cserver )
            cserver = @servers[$1] = Hash.new
          end
          cserver[:id] = $1
          cserver[:address] = $1

        when /^fudge\s+(\S+)\s+(.*)/
          cserver = @servers[$1]
          if ( ! cserver )
            cserver = @servers[$1] = Hash.new
          end
          #cserver = Hash.new
          #@servers.push( cserver )
          cserver[:id] = $1
          cserver[:fudge] = $2

        when /^driftfile\s+(\S+)/
          @opthash[:driftfile] = $1

        when /^logfile\s+(\S+)/
          @opthash[:logfile] = $1

      end
    }
  end

  def to_xml
    out = String.new
    out << '<config>'
    @opthash.each do |key,value|
      out << '<' << key.to_s << '>'
      out << value
      out << '</' << key.to_s << '>'
    end
    out << '<servers>'
    @servers.each do |x,server|
      out << '<server>'
      server.each do |skey,svalue|
        out << '<' << skey.to_s << '>'
        out << svalue
        out << '</' << skey.to_s << '>'
      end
      out << '</server>'
    end
    out << '</servers>'
    out << '</config>'
    return out
  end

end