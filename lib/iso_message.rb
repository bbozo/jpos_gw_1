class IsoMessage

  ISO_MESSAGE_FORMATS_PATH = "#{::Rails.root}/config/iso_message_formats"

  java_import Java::java::io::IOException;
  java_import Java::org::jpos::iso::ISOException;
  java_import Java::org::jpos::iso::ISOMsg;
  java_import Java::org::jpos::iso::packager::GenericPackager;

  attr_accessor :message_format
  attr_accessor :msg
  
  def initialize(options = {})
    self.msg = options[:msg] || {}
    self.message_format = options[:message_format] || :basic
  end

  def iso_msg(format = message_format)
    packager = new_packager_for format
    
    iso_msg = ISOMsg.new
    iso_msg.packager = packager
    
    iso_msg.mti = self.msg[:mti].to_s
    
    self.msg.clone.reject{|k,v| not k.is_a? Fixnum}.each do |k,v|
      iso_msg.set k, v
    end
    
    iso_msg
  end
  
  def raw_msg
    Raw.new iso_msg.pack
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
  
  end
  
  private
  
  def iso_message_format_path format = message_format
    "#{ISO_MESSAGE_FORMATS_PATH}/#{format}.xml"
  end
  
  def new_packager_for format = message_format
    GenericPackager.new iso_message_format_path(format)
  end

end
