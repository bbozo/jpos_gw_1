class IsoMessage

  require 'pry'

  ISO_MESSAGE_FORMATS_PATH = "#{::Rails.root}/config/iso_message_formats"

  java_import Java::java::io::IOException;
  java_import Java::org::jpos::iso::ISOException;
  java_import Java::org::jpos::iso::ISOMsg;
  java_import Java::org::jpos::iso::packager::GenericPackager;

  attr_accessor :message_format
  attr_accessor :msg
  attr_accessor :raw_msg
  attr_accessor :iso_msg
  
  def initialize(options = {})
    self.raw_msg = options[:raw_msg]    if options[:raw_msg]
    self.iso_msg = options[:iso_msg]    if options[:iso_msg]
    self.msg     = options[:msg] || {}  if options[:msg]
    
    self
  end
  
  # expects raw java byte array arg
  def raw_msg=(arg)
    tmp = iso_msg_factory
    tmp.unpack arg
    
    self.iso_msg = tmp
    
    arg
  end
  
  # expect ISOMsg arg
  def iso_msg=(arg)
    puts arg.class.to_s
    self.msg = {}
    self.msg[:mti]    = arg.mti
    self.msg[:header] = arg.header if arg.header
    
    (1..arg.max_field).each do |field|
      self.msg[field] = arg.value(field) if arg.has_field? field
    end
    
    arg
  end
  
  def raw_msg
    return nil unless ready_to_build_iso_msg?
    Raw.new iso_msg_factory.pack
  end
  
  def iso_msg
    iso_msg_factory
  end
  
  # just an example factory method
  def self.example_iso
    self.new(:msg => {
      :mti => '0200',
      3 => '201234',
      4 => '10000',
      7 => '110722180',
      11 => '123456',
      44 => 'A5DFGR',
      105 => "ABCDEFGHIJ 1234567890"
    })
  end
  
  # FIXME: reinventing the wheel? I can't believe I couldn't easily find
  # a simple wrapper class for java's byte[] primitive
  class Raw
  
    attr_accessor :raw
  
    def initialize(java_byte_array)
      self.raw = java_byte_array
    end
    
    def to_s
      String.from_java_bytes self.raw
    end
    
    alias_method :to_raw, :raw
  
  end
  
  #private
  
  def message_format
    :basic
  end
  
  def ready_to_build_iso_msg?
    @msg and not @msg.empty?
  end
  
  # factory method for generating ISOMsg instances w implemented housekeeping
  def iso_msg_factory(options = {})
    populate_from_msg = options[:populate_from_msg] ||= true
   
    rv = ISOMsg.new
    rv.packager = new_packager_for(message_format)
    
    populate_iso_msg! rv if populate_from_msg
    
    rv
  end
  
  def iso_message_format_path message_format
    "#{ISO_MESSAGE_FORMATS_PATH}/#{message_format}.xml"
  end
  
  def new_packager_for message_format
    GenericPackager.new iso_message_format_path(message_format)
  end
  
  def populate_iso_msg! rv_iso_msg, msg = self.msg
    if ready_to_build_iso_msg?
      rv_iso_msg.mti = self.msg[:mti].to_s
      
      self.msg.clone.reject{|k,v| not k.is_a? Fixnum}.each do |k,v|
        rv_iso_msg.set k, v
      end
    end  
  end

end
