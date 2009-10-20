require "yast/config_file"
require "exceptions"

class License

  # :name      - name of the license
  # :langs_hash- hash of languages, which are available
  # :langs_list- dtto
  # :text      - actual text of the eula
  # :text_lang - language, of the current eula translation
  # :only_show - some licenses only need to be show and user doesn't have to change the radio button to "accept"
  # :accepted  - whether this license was already accepted

  attr_accessor :name, :langs_hash, :langs_list, :accepted, :text, :text_lang, :only_show

  VAR_DIR       = File.join(Paths::VAR,"eulas")
  RESOURCES_DIR = File.join(Paths::DATAS,"eulas")

  def dig_lang(line)
    r = Regexp.new('license(?:\.(\w+))?\.txt')
    match = r.match(line)
    if match.nil? then
      nil
    else
      if match[1].nil? then
        'en'
      else
        match[1]
      end
    end
  end

  def parse_license_dir(path)
    dir = Dir.new path
    dir.collect{|d| dig_lang d}.compact.sort
  end

  def initialize(name)
    license_dir = File.join(RESOURCES_DIR, 'licenses', name)
    @langs_hash = Hash.new
    begin
      @langs_list = parse_license_dir(license_dir).sort
      @langs_list.each do |lang_str|
        @langs_hash[lang_str] = lang_str
        # allow usage of language code only (instead of full locale)
        if lang_str.include? "_" then
          @langs_hash[lang_str.split("_")[0]] = lang_str
        end
      end
      # some licenses only need to be shown (see opensuse licensing thingy)
      @only_show = File.exists? File.join(license_dir, "no-acceptance-needed")
      @accepted  = File.exists? File.join(VAR_DIR, "accepted-licenses",name)
    rescue Errno::ENOENT, Errno::EACCES
      raise CorruptedFileException.new license_dir
    rescue Errno::ENOTDIR
      raise NotADirException.new license_dir
    end
    @name  = name
  end

  def self.find(id)
    name = license_names[id.to_i-1] # let ids in find start from 1
    if name.nil? then
      nil
    else
      license = new name
      # lets be sure, that @text and @text_lang is never nil
      license.load_text "en"
      license
    end
  end

  def self.license_names
    begin
      config = YaST::ConfigFile.new(:eulas)
      config["licenses"] || []
    rescue Exception => e
      [] # treat absense or corruption of eulas.yml as "no eulas"
    end
  end

  def self.find_all
    Licenses.new license_names.collect{|ln| new ln}
  end

  def self.all_accepted?
    find_all.collect{|license| license.accepted}.inject(true){|a,b| a and b}
  end

  def save
    if @accepted then
      FileUtils.touch File.join(VAR_DIR, "accepted-licenses",self.name)
    end
  end

  def make_lang_acceptable(lang)
    # lets see if we know this exact locale
    if @langs_hash.has_key? lang then
      lang
    else
      # what about the language at least ? Can we use language from locale name?
      if lang.include? "_" then
        lang = lang.split("_")[0]
        if not @langs_hash.has_key? lang then 
          # use english as fallback
          # lang is usually taken from locale. It is ok to have some exotic locale and show english license.
          # no exception is raised
          "en"
        else
          lang
        end
      else
        "en"
      end
    end
  end

  def load_text(lang)
    lang = make_lang_acceptable lang
    if lang != @text_lang then
      lang_str = (lang == 'en') ? "" : "."+@langs_hash[lang]
      license_filename = File.join(RESOURCES_DIR, 'licenses', self.name, 'license' + lang_str + ".txt")
      begin 
        @text = File.open(license_filename).read
        @text_lang = lang
      rescue Errno::ENOENT, Errno::EACCES
        raise CorruptedFileException.new license_filename
      end
    end
  end

  def to_xml( options = {} )
    xml = options[:builder] ||= Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]

    xml.eula do
      xml.name @name
      xml.accepted(@accepted, {:type => "boolean"})
      xml.only_show(@only_show, {:type => "boolean"})
      xml.available_langs({:type => "array"}) do
        @langs_list.each do |lang| 
          xml.available_lang lang
        end
      end
      xml.text_lang @text_lang
      xml.text @text
    end
  end

  def to_json( options = {} )
    hash = Hash.from_xml(to_xml())
    hash.to_json
  end

end

class Licenses < Array
  def to_xml( options = {} )
    xml = options[:builder] ||= Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]
    xml.eulas(:type => :array) do
      each {|eula| eula.to_xml(:builder => xml, :skip_instruct => true)}
    end
  end

  def to_json
    Hash.from_xml(to_xml).to_json
  end
end
