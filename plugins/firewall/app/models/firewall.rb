class Firewall < BaseModel::Base

  def initialize()
    @status   = true # firewall is on
    @services = [ {:id      => 'lighttpd',
                   :name    => 'lighttpd',
                   :allowed => true 
                  },
                  {:id      => 'nfs_client',
                   :name    => 'NFS Client',
                   :allowed => true
                  },
                  {:id      => 'sshd',
                   :name    => 'Secure Shell Server',
                   :allowed => true
                  },
                  {:id      => 'vnc',
                   :name    => 'VNC',
                   :allowed => false
                  }
                ]
  end
                 
  def self.find
    Firewall.new()
  end

  alias old_to_xml to_xml
  def to_xml(options = {} )
    xml = options[:builder] ||= Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]

    xml.firewall do
      xml.status({:type => "boolean"}, @status)
      xml.services ({:type => "array"}) do
        @services.each do |service|
          xml.service do
            xml.id     service[:id]
            xml.name   service[:name]
            xml.allowed({:type => "boolean"}, service[:allowed])
          end
        end
      end
    end
  end
end
