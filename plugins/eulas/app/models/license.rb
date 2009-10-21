require "yast/config_file"
require "exceptions"

# = Representation of EULA
# used for loading license data from disk, serializing to xml and json and saving
class License

  # name of the license
  attr_reader :name
  # hash of languages, which are available
  attr_reader :langs_hash
  # list of languages, which are available
  attr_reader :langs_list
  # text of the eula
  attr_reader :text
  # language, of the current eula translation
  attr_reader :text_lang
  # some licenses only need to be show and user doesn't have to change the radio button to "accept"
  attr_reader :only_show
  # true, is this license was already accepted
  attr_accessor :accepted

  VAR_DIR       = File.join(Paths::VAR,"eulas")
  RESOURCES_DIR = File.join(Paths::DATAS,"eulas")

  ##
  # Create a license object using the name of the license.
  # @raise [CorruptedFileException,NotADirException] in case the license files structure is not as expected.
  # @param [String] name the name of the license
  # @return [String] license object with no license text loaded
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
  
  ##
  # Search for a license using its index in config file
  # @param [String] id index into the list of licenses, will be transformed into int
  # @return [String] license object with default (en) text loaded
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

  ##
  # List of all known license names.
  # @raise [CorruptedFileException] in case of malformed config file (eulas.yml)
  # @return [[String]] list of license names
  def self.license_names
    config = YaST::ConfigFile.new(:eulas)
    begin
      config["licenses"] || []
    rescue YaST::ConfigFile::NotFoundError
      [] # treat absense or corruption of eulas.yml as "no eulas"
    rescue Exception
      raise CorruptedFileException.new config.path
    end
  end

  ##
  # Create all license objects without loading the texts.
  # @return [Licenses] list of licenses capable of to_xml and to_json
  def self.find_all
    Licenses.new license_names.collect{|ln| new ln}
  end

  ##
  # Find out if all licenses have already been accepted
  # @return [Boolean] true if all licenses were accepted or if there were no licenses
  def self.all_accepted?
    find_all.collect{|license| license.accepted}.inject(true){|a,b| a and b}
  end

  ##
  # Save a license. Only "accepted" attribute is saved.
  # @return [nil]
  def save
    if @accepted then
      FileUtils.touch File.join(VAR_DIR, "accepted-licenses",self.name)
    end
  end

  ##
  # Serialize to xml representation
  # @option options [Builder::XmlMarkup] :builder parent xml-builder
  # @option options [Boolean]            :skip_instruct whether xml document header should be skipped
  # @return [String] xml representation of license
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

  ##
  # Serialize to json representation
  # @return [String] json representation of license
  def to_json()
    hash = Hash.from_xml(to_xml())
    hash.to_json
  end

  private

  ##
  # Digg license language out of license translation file name
  # @param [String] filename filename of the license translation
  # @return [String,nil] lang code of the translation. Can return nil in case regexp fails.
  def dig_lang(filename)
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

  ##
  # Parse lang codes out of directory with license translations
  # @param [String] path path to the directory with license translations
  # @return [[String]] list of lang codes
  def parse_license_dir(path)
    dir = Dir.new path
    dir.collect{|d| dig_lang d}.compact.sort
  end

  ##
  # Search for the locale code in translation codes, which we know of. In case the full locale is not
  # found, the lang code is tried. English is the default in case all attempts fail.
  # @param [String] lang lang or locale code of the desired license translation
  # @return [String] lang or locale code which is available
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

  ##
  # Load license translation from disk
  # @raise [CorruptedFileException] in case license translation name does not exist
  # @param [String] lang lang or locale code of the desired license translation
  # @return [nil] @text and @text_lang instance variables are set
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


end

# = Representation of list of EULAs
# used for serializing a list of licenses into xml and json
class Licenses < Array
  ##
  # Serialize to xml
  # @option options [Builder::XmlMarkup] :builder parent xml-builder
  # @option options [Boolean]            :skip_instruct whether xml document header should be skipped
  def to_xml( options = {} )
    xml = options[:builder] ||= Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]
    xml.eulas(:type => :array) do
      each {|eula| eula.to_xml(:builder => xml, :skip_instruct => true)}
    end
  end

  ##
  # Serialize to json representation
  # @return [String] json representation of license
  def to_json
    Hash.from_xml(to_xml).to_json
  end
end
