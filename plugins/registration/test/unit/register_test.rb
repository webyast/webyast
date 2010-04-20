require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'test/unit'
require "yast_service"
require 'mocha'

class RegisterTest < ActiveSupport::TestCase

  CONTEXT =  {"forcereg"=>["s", "1"],
              "logfile"=>["s", "/root/.suse_register.log"],
              "restoreRepos"=>["s", "1"],
              "nooptional"=>["s", "0"],
              "yastcall"=>["s", "1"],
              "nohwdata"=>["s", "0"],
              "debug"=>["s", "2"],
              "norefresh"=>["s", "1"]}

  ARGUMENTS = {}

  RESPONSE_CONFIG_REGISTERED =  {"regserverurl"=>"https://secure-www.novell.com/center/regsvc/", "guid"=>"773093306c1a47069b73c04037a23f56", "regserverca"=>""}
  RESPONSE_CONFIG_UNREGISTERED =  {"regserverurl"=>"https://secure-www.novell.com/center/regsvc/", "guid"=>nil, "regserverca"=>""}

  RESPONSE_SUCCESS_XML = '<?xml version="1.0" encoding="UTF-8"?>

<registration>
  <changedservices type="array">
    <changedservice>
      <name>nu_novell_com</name>
      <url>https://nu.novell.com</url>
      <type>nu</type>
      <alias>nu_novell_com</alias>
      <catalogs>
        <catalog type="array">
          <catalog>
            <name>SLES11-SP1-Pool</name>
            <alias>nu_novell_com:SLES11-SP1-Pool</alias>
            <status>added</status>
          </catalog>
          <catalog>
            <name>SLES11-SP1-Updates</name>
            <alias>nu_novell_com:SLES11-SP1-Updates</alias>
            <status>added</status>
          </catalog>
        </catalog>
      </catalogs>
      <status>added</status>
    </changedservice>
  </changedservices>
  <guid>773093306c1a47069b73c04037a23f56</guid>
  <arguments>
    <argument type="array">
      <argument>
        <name>netcard</name>
        <value>15: PCI 11.0: 0200 Ethernet controller
  [Created at pci.318]
  UDI: /org/freedesktop/Hal/devices/pci_8086_100f
  Unique ID: rBUF.cRsDHMZdo50
  SysFS ID: /devices/pci0000:00/0000:00:11.0
  SysFS BusID: 0000:00:11.0
  Hardware Class: network
  Model: "VMWare Abstract PRO/1000 MT Single Port Adapter"
  Vendor: pci 0x8086 "Intel Corporation"
  Device: pci 0x100f "82545EM Gigabit Ethernet Controller (Copper)"
  SubVendor: pci 0x15ad "VMWare, Inc."
  SubDevice: pci 0x0750 "Abstract PRO/1000 MT Single Port Adapter"
  Revision: 0x02
  Driver: "e1000"
  Driver Modules: "e1000"
  Device File: eth0
  Memory Range: 0xf0420000-0xf043ffff (rw,non-prefetchable)
  I/O Ports: 0xd040-0xd047 (rw)
  IRQ: 17 (38638693 events)
  HW Address: 08:00:27:d9:d6:80
  Link detected: yes
  Module Alias: "pci:v00008086d0000100Fsv000015ADsd00000750bc02sc00i00"
  Driver Info #0:
    Driver Status: e1000 is active
    Driver Activation Cmd: "modprobe e1000"
  Config Status: cfg=no, avail=yes, need=no, active=unknown</value>
      </argument>
      <argument>
        <name>sound</name>
        <value></value>
      </argument>
      <argument>
        <name>regcode-sles</name>
        <value>valid-regcode</value>
      </argument>
      <argument>
        <name>disk</name>
        <value>10: IDE 00.0: 10600 Disk
  [Created at block.243]
  UDI: /org/freedesktop/Hal/devices/storage_serial_SATA_VBOX_HARDDISK_VB408498e8_112ba834
  Unique ID: 3OOL.PS7tnFgYNYA
  Parent ID: mnDB.V_9AHXukieF
  SysFS ID: /class/block/sda
  SysFS BusID: 0:0:0:0
  SysFS Device Link: /devices/pci0000:00/0000:00:01.1/host0/target0:0:0/0:0:0:0
  Hardware Class: disk
  Model: "VBOX HARDDISK"
  Vendor: "VBOX"
  Device: "HARDDISK"
  Revision: "1.0"
  Serial ID: "VB408498e8-112ba834"
  Driver: "ata_piix", "sd"
  Driver Modules: "ata_piix"
  Device File: /dev/sda
  Device Files: /dev/sda, /dev/disk/by-id/scsi-SATA_VBOX_HARDDISK_VB408498e8-112ba834, /dev/disk/by-id/ata-VBOX_HARDDISK_VB408498e8-112ba834, /dev/disk/by-path/pci-0000:00:01.1-scsi-0:0:0:0
  Device Number: block 8:0-8:15
  BIOS id: 0x80
  Geometry (Logical): CHS 2091/255/63
  Size: 33593344 sectors a 512 bytes
  Geometry (BIOS EDD): CHS 33326/16/63
  Size (BIOS EDD): 33593344 sectors
  Geometry (BIOS Legacy): CHS 1024/255/63
  Config Status: cfg=new, avail=yes, need=no, active=unknown
  Attached to: #4 (IDE interface)</value>
      </argument>
      <argument>
        <name>moniker</name>
        <value>nix</value>
      </argument>
      <argument>
        <name>platform</name>
        <value>x86_64</value>
      </argument>
      <argument>
        <name>hostname</name>
        <value>g136</value>
      </argument>
      <argument>
        <name>gfxcard</name>
        <value>12: PCI 02.0: 0300 VGA compatible controller (VGA)
  [Created at pci.318]
  UDI: /org/freedesktop/Hal/devices/pci_80ee_beef
  Unique ID: _Znp.mHjpIGaFQV1
  SysFS ID: /devices/pci0000:00/0000:00:02.0
  SysFS BusID: 0000:00:02.0
  Hardware Class: graphics card
  Model: "InnoTek Systemberatung VirtualBox Graphics Adapter"
  Vendor: pci 0x80ee "InnoTek Systemberatung GmbH"
  Device: pci 0xbeef "VirtualBox Graphics Adapter"
  Memory Range: 0xe0000000-0xe0ffffff (rw,prefetchable)
  I/O Ports: 0x3c0-0x3df (rw)
  Module Alias: "pci:v000080EEd0000BEEFsv00000000sd00000000bc03sc00i00"
  Config Status: cfg=new, avail=yes, need=no, active=unknown

Primary display adapter: #12</value>
      </argument>
      <argument>
        <name>email</name>
        <value>jdsn@novell.com</value>
      </argument>
      <argument>
        <name>processor</name>
        <value>x86_64</value>
      </argument>
      <argument>
        <name>ostarget-bak</name>
        <value>"SUSE Linux Enterprise Server 11 (x86_64)"</value>
      </argument>
      <argument>
        <name>isdn</name>
        <value></value>
      </argument>
      <argument>
        <name>installed-langs</name>
        <value>en_US</value>
      </argument>
      <argument>
        <name>dsl</name>
        <value></value>
      </argument>
      <argument>
        <name>cpu</name>
        <value>01: None 00.0: 10103 CPU
  [Created at cpu.301]
  Unique ID: rdCR.j8NaKXDZtZ6
  Hardware Class: cpu
  Arch: X86-64
  Vendor: "GenuineIntel"
  Model: 6.37.2 "Intel(R) Core(TM) i5 CPU         650  @ 3.20GHz"
  Features: fpu,vme,de,pse,tsc,msr,pae,mce,cx8,apic,sep,mtrr,pge,mca,cmov,pat,pse36,clflush,mmx,fxsr,sse,sse2,syscall,nx,lm,constant_tsc,up,rep_good,pni,monitor,lahf_lm
  Clock: 3187 MHz
  BogoMips: 6374.69
  Config Status: cfg=new, avail=yes, need=no, active=unknown</value>
      </argument>
      <argument>
        <name>ostarget</name>
        <value>sle-11-x86_64</value>
      </argument>
      <argument>
        <name>memory</name>
        <value>01: None 00.0: 10102 Main Memory
  [Created at memory.61]
  Unique ID: rdCR.CxwsZFjVASF
  Hardware Class: memory
  Model: "Main Memory"
  Memory Range: 0x00000000-0x17ccdfff (rw)
  Memory Size: 384 MB
  Config Status: cfg=new, avail=yes, need=no, active=unknown</value>
      </argument>
      <argument>
        <name>cpu-count</name>
        <value>CPUSockets: 1</value>
      </argument>
      <argument>
        <name>timezone</name>
        <value>Europe/Berlin</value>
      </argument>
      <argument>
        <name>tape</name>
        <value></value>
      </argument>
      <argument>
        <name>secret</name>
        <value>ceb332a681be46fcb1f9c54f56dcd297</value>
      </argument>
      <argument>
        <name>sys</name>
        <value>02: None 00.0: 10107 System
  [Created at sys.63]
  Unique ID: rdCR.n_7QNeEnh23
  Hardware Class: system
  Model: "System"
  Formfactor: "unknown"
  Driver Info #0:
    Driver Status: thermal,fan are not active
    Driver Activation Cmd: "modprobe thermal; modprobe fan"
  Config Status: cfg=new, avail=yes, need=no, active=unknown</value>
      </argument>
      <argument>
        <name>scsi</name>
        <value>08: SCSI 100.0: 10602 CD-ROM (DVD)
  [Created at block.247]
  UDI: /org/freedesktop/Hal/devices/storage_model_CD_ROM
  Unique ID: KD9E.bdbWQaKnov0
  Parent ID: mnDB.V_9AHXukieF
  SysFS ID: /class/block/sr0
  SysFS BusID: 1:0:0:0
  SysFS Device Link: /devices/pci0000:00/0000:00:01.1/host1/target1:0:0/1:0:0:0
  Hardware Class: cdrom
  Model: "VBOX CD-ROM"
  Vendor: "VBOX"
  Device: "CD-ROM"
  Revision: "1.0"
  Driver: "ata_piix", "sr"
  Driver Modules: "ata_piix"
  Device File: /dev/sr0 (/dev/sg1)
  Device Files: /dev/sr0, /dev/scd0, /dev/disk/by-path/pci-0000:00:01.1-scsi-1:0:0:0, /dev/cdrom, /dev/dvd
  Device Number: block 11:0 (char 21:1)
  Features: DVD
  Config Status: cfg=new, avail=yes, need=no, active=unknown
  Attached to: #3 (IDE interface)
  Drive Speed: 32</value>
      </argument>
    </argument>
  </arguments>
  <exitcode>0</exitcode>
  <id nil="true"></id>
  <status>finished</status>
  <options>
    <debug type="integer">2</debug>
  </options>
</registration>'


RESPONSE_SUCCESS = {"changedservices"=>[ {"name"=>"nu_novell_com", "url"=>"https://nu.novell.com", "type"=>"nu", "alias"=>"nu_novell_com",
"catalogs"=>{"catalog"=>[ {"name"=>"SLES11-SP1-Pool", "alias"=>"nu_novell_com:SLES11-SP1-Pool", "status"=>"added"}, {"name"=>"SLES11-SP1-Updates", "alias"=>"nu_novell_com:SLES11-SP1-Updates", "status"=>"added"}]}, "status"=>"added"}],
"guid"=>"773093306c1a47069b73c04037a23f29",
"arguments"=>{"argument"=>[ {"name"=>"netcard", "value"=>"15: PCI 11.0: 0200 Ethernet controller\r\n  [Created at pci.318]\r\n  UDI: /org/freedesktop/Hal/devices/pci_8086_100f\r\n  Unique ID: rBUF.cRsDHMZdo50\r\n  SysFS ID: /devices/pci0000:00/0000:00:11.0\r\n  SysFS BusID: 0000:00:11.0\r\n  Hardware Class: network\r\n  Model: \"VMWare Abstract PRO/1000 MT Single Port Adapter\"\r\n  Vendor: pci 0x8086 \"Intel Corporation\"\r\n  Device: pci 0x100f \"82545EM Gigabit Ethernet Controller (Copper)\"\r\n  SubVendor: pci 0x15ad \"VMWare, Inc.\"\r\n  SubDevice: pci 0x0750 \"Abstract PRO/1000 MT Single Port Adapter\"\r\n  Revision: 0x02\r\n  Driver: \"e1000\"\r\n  Driver Modules: \"e1000\"\r\n  Device File: eth0\r\n  Memory Range: 0xf0420000-0xf043ffff (rw,non-prefetchable)\r\n  I/O Ports: 0xd040-0xd047 (rw)\r\n  IRQ: 17 (38638693 events)\r\n  HW Address: 08:00:27:d9:d6:80\r\n  Link detected: yes\r\n  Module Alias: \"pci:v00008086d0000100Fsv000015ADsd00000750bc02sc00i00\"\r\n  Driver Info #0:\r\n    Driver Status: e1000 is active\r\n    Driver Activation Cmd: \"modprobe e1000\"\r\n  Config Status: cfg=no, avail=yes, need=no, active=unknown"},
{"name"=>"sound", "value"=>""}, {"name"=>"regcode-sles", "value"=>"valid-regcode"}, {"name"=>"disk", "value"=>"10: IDE 00.0: 10600 Disk\r\n  [Created at block.243]\r\n  UDI: /org/freedesktop/Hal/devices/storage_serial_SATA_VBOX_HARDDISK_VB408498e8_112ba834\r\n  Unique ID: 3OOL.PS7tnFgYNYA\r\n  Parent ID: mnDB.V_9AHXukieF\r\n  SysFS ID: /class/block/sda\r\n  SysFS BusID: 0:0:0:0\r\n  SysFS Device Link: /devices/pci0000:00/0000:00:01.1/host0/target0:0:0/0:0:0:0\r\n  Hardware Class: disk\r\n  Model: \"VBOX HARDDISK\"\r\n  Vendor: \"VBOX\"\r\n  Device: \"HARDDISK\"\r\n  Revision: \"1.0\"\r\n  Serial ID: \"VB408498e8-112ba834\"\r\n  Driver: \"ata_piix\", \"sd\"\r\n  Driver Modules: \"ata_piix\"\r\n  Device File: /dev/sda\r\n  Device Files: /dev/sda, /dev/disk/by-id/scsi-SATA_VBOX_HARDDISK_VB408498e8-112ba834, /dev/disk/by-id/ata-VBOX_HARDDISK_VB408498e8-112ba834, /dev/disk/by-path/pci-0000:00:01.1-scsi-0:0:0:0\r\n  Device Number: block 8:0-8:15\r\n  BIOS id: 0x80\r\n  Geometry (Logical): CHS 2091/255/63\r\n  Size: 33593344 sectors a 512 bytes\r\n  Geometry (BIOS EDD): CHS 33326/16/63\r\n  Size (BIOS EDD): 33593344 sectors\r\n  Geometry (BIOS Legacy): CHS 1024/255/63\r\n  Config Status: cfg=new, avail=yes, need=no, active=unknown\r\n  Attached to: #4 (IDE interface)"},
{"name"=>"moniker", "value"=>"nix"}, {"name"=>"platform", "value"=>"x86_64"}, {"name"=>"hostname", "value"=>"g136"}, {"name"=>"gfxcard", "value"=>"12: PCI 02.0: 0300 VGA compatible controller (VGA)\r\n  [Created at pci.318]\r\n  UDI: /org/freedesktop/Hal/devices/pci_80ee_beef\r\n  Unique ID: _Znp.mHjpIGaFQV1\r\n  SysFS ID: /devices/pci0000:00/0000:00:02.0\r\n  SysFS BusID: 0000:00:02.0\r\n  Hardware Class: graphics card\r\n  Model: \"InnoTek Systemberatung VirtualBox Graphics Adapter\"\r\n  Vendor: pci 0x80ee \"InnoTek Systemberatung GmbH\"\r\n  Device: pci 0xbeef \"VirtualBox Graphics Adapter\"\r\n  Memory Range: 0xe0000000-0xe0ffffff (rw,prefetchable)\r\n  I/O Ports: 0x3c0-0x3df (rw)\r\n  Module Alias: \"pci:v000080EEd0000BEEFsv00000000sd00000000bc03sc00i00\"\r\n  Config Status: cfg=new, avail=yes, need=no, active=unknown\r\n\r\nPrimary display adapter: #12"}, {"name"=>"email", "value"=>"jdsn@novell.com"},
{"name"=>"processor", "value"=>"x86_64"}, {"name"=>"ostarget-bak", "value"=>"\"SUSE Linux Enterprise Server 11 (x86_64)\""}, {"name"=>"isdn", "value"=>""}, {"name"=>"installed-langs", "value"=>"en_US"}, {"name"=>"dsl", "value"=>""}, {"name"=>"cpu", "value"=>"01: None 00.0: 10103 CPU\r\n  [Created at cpu.301]\r\n  Unique ID: rdCR.j8NaKXDZtZ6\r\n  Hardware Class: cpu\r\n  Arch: X86-64\r\n  Vendor: \"GenuineIntel\"\r\n  Model: 6.37.2 \"Intel(R) Core(TM) i5 CPU         650  @ 3.20GHz\"\r\n  Features: fpu,vme,de,pse,tsc,msr,pae,mce,cx8,apic,sep,mtrr,pge,mca,cmov,pat,pse36,clflush,mmx,fxsr,sse,sse2,syscall,nx,lm,constant_tsc,up,rep_good,pni,monitor,lahf_lm\r\n  Clock: 3187 MHz\r\n  BogoMips: 6374.69\r\n  Config Status: cfg=new, avail=yes, need=no, active=unknown"}, {"name"=>"ostarget", "value"=>"sle-11-x86_64"}, {"name"=>"memory", "value"=>"01: None 00.0: 10102 Main Memory\r\n  [Created at memory.61]\r\n  Unique ID: rdCR.CxwsZFjVASF\r\n  Hardware Class: memory\r\n  Model: \"Main Memory\"\r\n  Memory Range: 0x00000000-0x17ccdfff (rw)\r\n  Memory Size: 384 MB\r\n  Config Status: cfg=new, avail=yes, need=no, active=unknown"}, {"name"=>"cpu-count", "value"=>"CPUSockets: 1"}, {"name"=>"timezone", "value"=>"Europe/Berlin"}, {"name"=>"tape", "value"=>""},
{"name"=>"secret", "value"=>"asecretpassphrase"}, {"name"=>"sys", "value"=>"02: None 00.0: 10107 System\r\n  [Created at sys.63]\r\n  Unique ID: rdCR.n_7QNeEnh23\r\n  Hardware Class: system\r\n  Model: \"System\"\r\n  Formfactor: \"unknown\"\r\n  Driver Info #0:\r\n    Driver Status: thermal,fan are not active\r\n    Driver Activation Cmd: \"modprobe thermal; modprobe fan\"\r\n  Config Status: cfg=new, avail=yes, need=no, active=unknown"}, {"name"=>"scsi", "value"=>"08: SCSI 100.0: 10602 CD-ROM (DVD)\r\n  [Created at block.247]\r\n  UDI: /org/freedesktop/Hal/devices/storage_model_CD_ROM\r\n  Unique ID: KD9E.bdbWQaKnov0\r\n  Parent ID: mnDB.V_9AHXukieF\r\n  SysFS ID: /class/block/sr0\r\n  SysFS BusID: 1:0:0:0\r\n  SysFS Device Link: /devices/pci0000:00/0000:00:01.1/host1/target1:0:0/1:0:0:0\r\n  Hardware Class: cdrom\r\n  Model: \"VBOX CD-ROM\"\r\n  Vendor: \"VBOX\"\r\n  Device: \"CD-ROM\"\r\n  Revision: \"1.0\"\r\n  Driver: \"ata_piix\", \"sr\"\r\n  Driver Modules: \"ata_piix\"\r\n  Device File: /dev/sr0 (/dev/sg1)\r\n  Device Files: /dev/sr0, /dev/scd0, /dev/disk/by-path/pci-0000:00:01.1-scsi-1:0:0:0, /dev/cdrom, /dev/dvd\r\n  Device Number: block 11:0 (char 21:1)\r\n  Features: DVD\r\n  Config Status: cfg=new, avail=yes, need=no, active=unknown\r\n  Attached to: #3 (IDE interface)\r\n  Drive Speed: 32"}]}, "exitcode"=>"0", "id"=>nil, "status"=>"finished", "options"=>{"debug"=>2}}



  RESPONSE_MISSING =
{"manualurl"=>"https://secure-www.novell.com/center/regsvc-1.0/?lang=en-US&guid=773093306c1a47069b73c04037a23f29&command=interactive", "errorcode"=>"0", "exitcode"=>"4", "readabletext"=>"<pre>* Activation code for SUSE Linux Enterprise Server 11 SP1 (mandatory)\n</pre><p>To register your product manually, use the following URL:</p>\n<pre>https://secure-www.novell.com/center/regsvc-1.0/?lang=en-US&guid=773093306c1a47069b73c04037a23f29&command=interactive</pre>\n\n<p>Information on Novell's Privacy Policy:<br>\nSubmit information to help you manage your registered systems.</p>\n<p><a href=\"http://www.novell.com/company/policies/privacy/textonly.html\">http://www.novell.com/company/policies/privacy/textonly.html</a></p>\n", "missinginfo"=>"Missing Information", "missingarguments"=>"<missingarguments>\n  <cpu description=\"CPU details\" flag=\"a\" kind=\"optional\" value=\"01: None 00.0: 10103 CPU\n  [Created at cpu.301]\n  Unique ID: rdCR.j8NaKXDZtZ6\n  Hardware Class: cpu\n  Arch: Intel\n  Vendor: &quot;GenuineIntel&quot;\n  Model: 15.4.1 &quot;Intel(R) Pentium(R) 4 CPU 3.20GHz&quot;\n  Features: fpu,vme,de,pse,tsc,msr,pae,mce,cx8,apic,sep,mtrr,pge,mca,cmov,pat,pse36,clflush,dts,acpi,mmx,fxsr,sse,sse2,ss,constant_tsc,up,pebs,bts,tsc_reliable,pni\n  Clock: 3215 MHz\n  BogoMips: 6431.44\n  Cache: 1024 kb\n  Config Status: cfg=new, avail=yes, need=no, active=unknown\" />\n  <cpu-count description=\"CPU count\" flag=\"a\" kind=\"optional\" value=\"CPUSockets: 1\n\" />\n  <disk description=\"Disk details\" flag=\"a\" kind=\"optional\" value=\"10: SCSI 00.0: 10600 Disk\n  [Created at block.243]\n  UDI: /org/freedesktop/Hal/devices/storage_model_VMware_Virtual_S\n  Unique ID: R7kM.nTPZhtpisM9\n  Parent ID: 37TO.aKyVvDuS0sA\n  SysFS ID: /class/block/sda\n  SysFS BusID: 0:0:0:0\n  SysFS Device Link: /devices/pci0000:00/0000:00:10.0/host0/target0:0:0/0:0:0:0\n  Hardware Class: disk\n  Model: &quot;VMware Virtual S&quot;\n  Vendor: &quot;VMware,&quot;\n  Device: &quot;VMware Virtual S&quot;\n  Revision: &quot;1.0&quot;\n  Driver: &quot;mptspi&quot;, &quot;sd&quot;\n  Driver Modules: &quot;mptspi&quot;\n  Device File: /dev/sda (/dev/sg0)\n  Device Files: /dev/sda, /dev/disk/by-path/pci-0000:00:10.0-scsi-0:0:0:0\n  Device Number: block 8:0-8:15 (char 21:0)\n  BIOS id: 0x80\n  Geometry (Logical): CHS 2091/255/63\n  Size: 33593344 sectors a 512 bytes\n  Geometry (BIOS EDD): CHS 2091/255/63\n  Size (BIOS EDD): 33593344 sectors\n  Geometry (BIOS Legacy): CHS 1024/255/63\n  Config Status: cfg=new, avail=yes, need=no, active=unknown\n  Attached to: #8 (SCSI storage controller)\" />\n  <dsl description=\"DSL details\" flag=\"a\" kind=\"optional\" value=\"\" />\n  <gfxcard description=\"Graphics card details\" flag=\"a\" kind=\"optional\" value=\"15: PCI 0f.0: 0300 VGA compatible controller (VGA)\n  [Created at pci.318]\n  UDI: /org/freedesktop/Hal/devices/pci_15ad_405\n  Unique ID: _+Pw.jBKePf3JQB5\n  SysFS ID: /devices/pci0000:00/0000:00:0f.0\n  SysFS BusID: 0000:00:0f.0\n  Hardware Class: graphics card\n  Model: &quot;VMware VMWARE0405&quot;\n  Vendor: pci 0x15ad &quot;VMware, Inc.&quot;\n  Device: pci 0x0405 &quot;VMWARE0405&quot;\n  SubVendor: pci 0x15ad &quot;VMware, Inc.&quot;\n  SubDevice: pci 0x0405 \n  I/O Ports: 0x1070-0x107f (rw)\n  Memory Range: 0xf0000000-0xf7ffffff (rw,non-prefetchable)\n  Memory Range: 0xe8000000-0xe87fffff (rw,non-prefetchable)\n  Memory Range: 0x20010000-0x20017fff (ro,prefetchable,disabled)\n  I/O Ports: 0x3c0-0x3df (rw)\n  Module Alias: &quot;pci:v000015ADd00000405sv000015ADsd00000405bc03sc00i00&quot;\n  Driver Info #0:\n    XFree86 v4 Server Module: vmware\n  Config Status: cfg=new, avail=yes, need=no, active=unknown\n\nPrimary display adapter: #15\" />\n  <hostname description=\"Hostname\" flag=\"a\" kind=\"optional\" value=\"linux-nsn2\" />\n  <installed-langs description=\"Installed languages\" flag=\"a\" kind=\"optional\" value=\"en_US\" />\n  <isdn description=\"ISDN details\" flag=\"a\" kind=\"optional\" value=\"\" />\n  <memory description=\"Memory\" flag=\"a\" kind=\"optional\" value=\"01: None 00.0: 10102 Main Memory\n  [Created at memory.66]\n  Unique ID: rdCR.CxwsZFjVASF\n  Hardware Class: memory\n  Model: &quot;Main Memory&quot;\n  Memory Range: 0x00000000-0x1f227fff (rw)\n  Memory Size: 512 MB\n  Config Status: cfg=new, avail=yes, need=no, active=unknown\" />\n  <netcard description=\"Network card data\" flag=\"a\" kind=\"optional\" value=\"17: PCI 11.0: 0200 Ethernet controller\n  [Created at pci.318]\n  UDI: /org/freedesktop/Hal/devices/pci_8086_100f\n  Unique ID: rBUF.5dU8kR7eh2C\n  SysFS ID: /devices/pci0000:00/0000:00:11.0\n  SysFS BusID: 0000:00:11.0\n  Hardware Class: network\n  Model: &quot;VMware PRO/1000 MT Single Port Adapter&quot;\n  Vendor: pci 0x8086 &quot;Intel Corporation&quot;\n  Device: pci 0x100f &quot;82545EM Gigabit Ethernet Controller (Copper)&quot;\n  SubVendor: pci 0x15ad &quot;VMware, Inc.&quot;\n  SubDevice: pci 0x0750 &quot;PRO/1000 MT Single Port Adapter&quot;\n  Revision: 0x01\n  Driver: &quot;e1000&quot;\n  Driver Modules: &quot;e1000&quot;\n  Device File: eth0\n  Memory Range: 0xe8820000-0xe883ffff (rw,non-prefetchable)\n  Memory Range: 0xe8800000-0xe880ffff (rw,non-prefetchable)\n  I/O Ports: 0x1400-0x143f (rw)\n  Memory Range: 0x20000000-0x2000ffff (ro,prefetchable,disabled)\n  IRQ: 18 (1643251 events)\n  HW Address: 00:0c:29:39:d3:a7\n  Link detected: yes\n  Module Alias: &quot;pci:v00008086d0000100Fsv000015ADsd00000750bc02sc00i00&quot;\n  Driver Info #0:\n    Driver Status: e1000 is active\n    Driver Activation Cmd: &quot;modprobe e1000&quot;\n  Config Status: cfg=no, avail=yes, need=no, active=unknown\" />\n  <ostarget description=\"Target operating system identifier\" flag=\"a\" kind=\"mandatory\" value=\"sle-11-i586\" />\n  <ostarget-bak description=\"Target operating system identifier\" flag=\"a\" kind=\"mandatory\" value=\"&quot;SUSE Linux Enterprise Server 11 (i586)&quot;\" />\n  <platform description=\"Hardware platform type\" flag=\"i\" kind=\"mandatory\" value=\"i386\" />\n  <processor description=\"Processor type\" flag=\"i\" kind=\"mandatory\" value=\"i686\" />\n  <regcode-sles description=\"Activation code for SUSE Linux Enterprise Server 11 SP1\" flag=\"m\" kind=\"mandatory\" value=\"\" />\n  <scsi description=\"SCSI device data\" flag=\"a\" kind=\"optional\" value=\"09: SCSI 00.0: 10600 Disk\n  [Created at block.243]\n  UDI: /org/freedesktop/Hal/devices/storage_model_VMware_Virtual_S\n  Unique ID: R7kM.nTPZhtpisM9\n  Parent ID: 37TO.aKyVvDuS0sA\n  SysFS ID: /class/block/sda\n  SysFS BusID: 0:0:0:0\n  SysFS Device Link: /devices/pci0000:00/0000:00:10.0/host0/target0:0:0/0:0:0:0\n  Hardware Class: disk\n  Model: &quot;VMware Virtual S&quot;\n  Vendor: &quot;VMware,&quot;\n  Device: &quot;VMware Virtual S&quot;\n  Revision: &quot;1.0&quot;\n  Driver: &quot;mptspi&quot;, &quot;sd&quot;\n  Driver Modules: &quot;mptspi&quot;\n  Device File: /dev/sda (/dev/sg0)\n  Device Files: /dev/sda, /dev/disk/by-path/pci-0000:00:10.0-scsi-0:0:0:0\n  Device Number: block 8:0-8:15 (char 21:0)\n  BIOS id: 0x80\n  Geometry (Logical): CHS 2091/255/63\n  Size: 33593344 sectors a 512 bytes\n  Config Status: cfg=new, avail=yes, need=no, active=unknown\n  Attached to: #7 (SCSI storage controller)\" />\n  <secret description=\"ZMD secret\" flag=\"a\" kind=\"mandatory\" value=\"3e21670bc1f945e4b457d26ed8c76fab\" />\n  <sound description=\"Sound card data\" flag=\"a\" kind=\"optional\" value=\"\" />\n  <sys description=\"System information\" flag=\"a\" kind=\"optional\" value=\"02: None 00.0: 10107 System\n  [Created at sys.63]\n  Unique ID: rdCR.JOGZkKqWqL3\n  Hardware Class: system\n  Model: &quot;VMware&quot;\n  Device: &quot;VMware&quot;\n  Formfactor: &quot;unknown&quot;\n  Driver Info #0:\n    Driver Status: thermal,fan are not active\n    Driver Activation Cmd: &quot;modprobe thermal; modprobe fan&quot;\n  Config Status: cfg=new, avail=yes, need=no, active=unknown\" />\n  <tape description=\"Tape storage\" flag=\"a\" kind=\"optional\" value=\"\" />\n  <timezone description=\"Timezone\" flag=\"i\" kind=\"mandatory\" value=\"Europe/Berlin\" />\n</missingarguments>\n"}

  def setup
  end

  def stub_config_registered
    YastService.stubs(:Call).with("YSR::getregistrationconfig").returns(RESPONSE_CONFIG_REGISTERED)
  end

  def stub_config_unregistered
    YastService.stubs(:Call).with("YSR::getregistrationconfig").returns(RESPONSE_CONFIG_UNREGISTERED)
  end

  def setup_missing_arguments
    stub_config_unregistered
    YastService.stubs(:Call).with("YSR::statelessregister", CONTEXT, ARGUMENTS ).returns(RESPONSE_MISSING)
  end

  def setup_registration_success
    stub_config_registered
    YastService.stubs(:Call).with("YSR::statelessregister", CONTEXT, ARGUMENTS ).returns(RESPONSE_SUCCESS)
  end

  def test_getter
    setup_registration_success
    register = Register.new()
    ret = register.find
    assert_equal("773093306c1a47069b73c04037a23f56", ret["guid"])
    assert_equal("https://secure-www.novell.com/center/regsvc/", ret["regserverurl"])
    assert_equal("773093306c1a47069b73c04037a23f56", register.guid)
    assert_equal("https://secure-www.novell.com/center/regsvc/", register.registrationserver)
  end

  def test_is_registered
    setup_registration_success
    register = Register.new()
    assert_equal(true, register.is_registered?)
    assert_equal(0,register.register)
  end

  def test_is_not_registered
    setup_missing_arguments
    register = Register.new()
    assert_equal(false, register.is_registered?)
    assert_equal(4,register.register) #missing argument
  end

  def test_xml
    setup_missing_arguments
    register = Register.new()
    assert_equal(4,register.register) #missing argument
    response = Hash.from_xml(register.to_xml)
    assert_equal(nil, response["registration"]["guid"])
    assert_equal("4", response["registration"]["exitcode"])
    assert_equal([{"kind"=>"optional", "name"=>"isdn", "flag"=>"a", "value"=>nil}, {"kind"=>"mandatory", "name"=>"ostarget", "flag"=>"a", "value"=>"sle-11-i586"}, {"kind"=>"optional", "name"=>"cpu-count", "flag"=>"a", "value"=>"CPUSockets: 1\n"}, {"kind"=>"optional", "name"=>"sys", "flag"=>"a", "value"=>"02: None 00.0: 10107 System\n  [Created at sys.63]\n  Unique ID: rdCR.JOGZkKqWqL3\n  Hardware Class: system\n  Model: \"VMware\"\n  Device: \"VMware\"\n  Formfactor: \"unknown\"\n  Driver Info #0:\n    Driver Status: thermal,fan are not active\n    Driver Activation Cmd: \"modprobe thermal; modprobe fan\"\n  Config Status: cfg=new, avail=yes, need=no, active=unknown"}, {"kind"=>"mandatory", "name"=>"ostarget-bak", "flag"=>"a", "value"=>"\"SUSE Linux Enterprise Server 11 (i586)\""}, {"kind"=>"optional", "name"=>"memory", "flag"=>"a", "value"=>"01: None 00.0: 10102 Main Memory\n  [Created at memory.66]\n  Unique ID: rdCR.CxwsZFjVASF\n  Hardware Class: memory\n  Model: \"Main Memory\"\n  Memory Range: 0x00000000-0x1f227fff (rw)\n  Memory Size: 512 MB\n  Config Status: cfg=new, avail=yes, need=no, active=unknown"}, {"kind"=>"optional", "name"=>"tape", "flag"=>"a", "value"=>nil}, {"kind"=>"optional", "name"=>"netcard", "flag"=>"a", "value"=>"17: PCI 11.0: 0200 Ethernet controller\n  [Created at pci.318]\n  UDI: /org/freedesktop/Hal/devices/pci_8086_100f\n  Unique ID: rBUF.5dU8kR7eh2C\n  SysFS ID: /devices/pci0000:00/0000:00:11.0\n  SysFS BusID: 0000:00:11.0\n  Hardware Class: network\n  Model: \"VMware PRO/1000 MT Single Port Adapter\"\n  Vendor: pci 0x8086 \"Intel Corporation\"\n  Device: pci 0x100f \"82545EM Gigabit Ethernet Controller (Copper)\"\n  SubVendor: pci 0x15ad \"VMware, Inc.\"\n  SubDevice: pci 0x0750 \"PRO/1000 MT Single Port Adapter\"\n  Revision: 0x01\n  Driver: \"e1000\"\n  Driver Modules: \"e1000\"\n  Device File: eth0\n  Memory Range: 0xe8820000-0xe883ffff (rw,non-prefetchable)\n  Memory Range: 0xe8800000-0xe880ffff (rw,non-prefetchable)\n  I/O Ports: 0x1400-0x143f (rw)\n  Memory Range: 0x20000000-0x2000ffff (ro,prefetchable,disabled)\n  IRQ: 18 (1643251 events)\n  HW Address: 00:0c:29:39:d3:a7\n  Link detected: yes\n  Module Alias: \"pci:v00008086d0000100Fsv000015ADsd00000750bc02sc00i00\"\n  Driver Info #0:\n    Driver Status: e1000 is active\n    Driver Activation Cmd: \"modprobe e1000\"\n  Config Status: cfg=no, avail=yes, need=no, active=unknown"}, {"kind"=>"mandatory", "name"=>"timezone", "flag"=>"i", "value"=>"Europe/Berlin"}, {"kind"=>"optional", "name"=>"scsi", "flag"=>"a", "value"=>"09: SCSI 00.0: 10600 Disk\n  [Created at block.243]\n  UDI: /org/freedesktop/Hal/devices/storage_model_VMware_Virtual_S\n  Unique ID: R7kM.nTPZhtpisM9\n  Parent ID: 37TO.aKyVvDuS0sA\n  SysFS ID: /class/block/sda\n  SysFS BusID: 0:0:0:0\n  SysFS Device Link: /devices/pci0000:00/0000:00:10.0/host0/target0:0:0/0:0:0:0\n  Hardware Class: disk\n  Model: \"VMware Virtual S\"\n  Vendor: \"VMware,\"\n  Device: \"VMware Virtual S\"\n  Revision: \"1.0\"\n  Driver: \"mptspi\", \"sd\"\n  Driver Modules: \"mptspi\"\n  Device File: /dev/sda (/dev/sg0)\n  Device Files: /dev/sda, /dev/disk/by-path/pci-0000:00:10.0-scsi-0:0:0:0\n  Device Number: block 8:0-8:15 (char 21:0)\n  BIOS id: 0x80\n  Geometry (Logical): CHS 2091/255/63\n  Size: 33593344 sectors a 512 bytes\n  Config Status: cfg=new, avail=yes, need=no, active=unknown\n  Attached to: #7 (SCSI storage controller)"}, {"kind"=>"optional", "name"=>"dsl", "flag"=>"a", "value"=>nil}, {"kind"=>"optional", "name"=>"sound", "flag"=>"a", "value"=>nil}, {"kind"=>"optional", "name"=>"hostname", "flag"=>"a", "value"=>"linux-nsn2"}, {"kind"=>"optional", "name"=>"cpu", "flag"=>"a", "value"=>"01: None 00.0: 10103 CPU\n  [Created at cpu.301]\n  Unique ID: rdCR.j8NaKXDZtZ6\n  Hardware Class: cpu\n  Arch: Intel\n  Vendor: \"GenuineIntel\"\n  Model: 15.4.1 \"Intel(R) Pentium(R) 4 CPU 3.20GHz\"\n  Features: fpu,vme,de,pse,tsc,msr,pae,mce,cx8,apic,sep,mtrr,pge,mca,cmov,pat,pse36,clflush,dts,acpi,mmx,fxsr,sse,sse2,ss,constant_tsc,up,pebs,bts,tsc_reliable,pni\n  Clock: 3215 MHz\n  BogoMips: 6431.44\n  Cache: 1024 kb\n  Config Status: cfg=new, avail=yes, need=no, active=unknown"}, {"kind"=>"mandatory", "name"=>"secret", "flag"=>"a", "value"=>"3e21670bc1f945e4b457d26ed8c76fab"}, {"kind"=>"mandatory", "name"=>"processor", "flag"=>"i", "value"=>"i686"}, {"kind"=>"optional", "name"=>"installed-langs", "flag"=>"a", "value"=>"en_US"}, {"kind"=>"optional", "name"=>"gfxcard", "flag"=>"a", "value"=>"15: PCI 0f.0: 0300 VGA compatible controller (VGA)\n  [Created at pci.318]\n  UDI: /org/freedesktop/Hal/devices/pci_15ad_405\n  Unique ID: _+Pw.jBKePf3JQB5\n  SysFS ID: /devices/pci0000:00/0000:00:0f.0\n  SysFS BusID: 0000:00:0f.0\n  Hardware Class: graphics card\n  Model: \"VMware VMWARE0405\"\n  Vendor: pci 0x15ad \"VMware, Inc.\"\n  Device: pci 0x0405 \"VMWARE0405\"\n  SubVendor: pci 0x15ad \"VMware, Inc.\"\n  SubDevice: pci 0x0405 \n  I/O Ports: 0x1070-0x107f (rw)\n  Memory Range: 0xf0000000-0xf7ffffff (rw,non-prefetchable)\n  Memory Range: 0xe8000000-0xe87fffff (rw,non-prefetchable)\n  Memory Range: 0x20010000-0x20017fff (ro,prefetchable,disabled)\n  I/O Ports: 0x3c0-0x3df (rw)\n  Module Alias: \"pci:v000015ADd00000405sv000015ADsd00000405bc03sc00i00\"\n  Driver Info #0:\n    XFree86 v4 Server Module: vmware\n  Config Status: cfg=new, avail=yes, need=no, active=unknown\n\nPrimary display adapter: #15"}, {"kind"=>"optional", "name"=>"disk", "flag"=>"a", "value"=>"10: SCSI 00.0: 10600 Disk\n  [Created at block.243]\n  UDI: /org/freedesktop/Hal/devices/storage_model_VMware_Virtual_S\n  Unique ID: R7kM.nTPZhtpisM9\n  Parent ID: 37TO.aKyVvDuS0sA\n  SysFS ID: /class/block/sda\n  SysFS BusID: 0:0:0:0\n  SysFS Device Link: /devices/pci0000:00/0000:00:10.0/host0/target0:0:0/0:0:0:0\n  Hardware Class: disk\n  Model: \"VMware Virtual S\"\n  Vendor: \"VMware,\"\n  Device: \"VMware Virtual S\"\n  Revision: \"1.0\"\n  Driver: \"mptspi\", \"sd\"\n  Driver Modules: \"mptspi\"\n  Device File: /dev/sda (/dev/sg0)\n  Device Files: /dev/sda, /dev/disk/by-path/pci-0000:00:10.0-scsi-0:0:0:0\n  Device Number: block 8:0-8:15 (char 21:0)\n  BIOS id: 0x80\n  Geometry (Logical): CHS 2091/255/63\n  Size: 33593344 sectors a 512 bytes\n  Geometry (BIOS EDD): CHS 2091/255/63\n  Size (BIOS EDD): 33593344 sectors\n  Geometry (BIOS Legacy): CHS 1024/255/63\n  Config Status: cfg=new, avail=yes, need=no, active=unknown\n  Attached to: #8 (SCSI storage controller)"}, {"kind"=>"mandatory", "name"=>"regcode-sles", "flag"=>"m", "value"=>nil}, {"kind"=>"mandatory", "name"=>"platform", "flag"=>"i", "value"=>"i386"}],
                 response["registration"]["missingarguments"])
    assert_equal("missinginfo", response["registration"]["status"])
  end

  def test_json
    setup_missing_arguments
    register = Register.new()
    assert_equal(4,register.register) #missing argument
    assert_not_nil(register.to_json)
  end

end
