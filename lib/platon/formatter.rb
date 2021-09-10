module Platon
  class Formatter

    UNITS = {
      'von':          1,
      'kvon':         1000,
      'mvon':         1000000,
      'gvon':         1000000000,  ## 10 ** 9
      'microatp':     1000000000000,
      'milliatp':     1000000000000000,
      'atp':          1000000000000000000, ## 10 ** 18
      'katp':         1000000000000000000000,
      'matp':         1000000000000000000000000,
      'gatp':         1000000000000000000000000000,
      'tatp':         1000000000000000000000000000000
    }

    def valid_address?(address_string)
      address = address_string.gsub(/^0x/,'')
      return false if address == "0000000000000000000000000000000000000000"
      return false if address.length != 40
      return !(address.match(/[0-9a-fA-F]+/).nil?)
    end

    def from_bool(boolval)
      return nil if boolval.nil?
      boolval ? "1" : "0"
    end

    def to_bool(hexstring)
      return nil if hexstring.nil?
      (hexstring == "0000000000000000000000000000000000000000000000000000000000000001")
    end

    def to_ascii(hexstring)
      return nil if hexstring.nil?
      hexstring.gsub(/^0x/,'').scan(/.{2}/).collect {|x| x.hex}.pack("c*")
    end

    def to_utf8(hexstring)
      return nil if hexstring.nil?
      hexstring.gsub(/^0x/,'').scan(/.{2}/).collect {|x| x.hex}.pack("U*").delete("\u0000")
    end

    def from_ascii(ascii_string)
      return nil if ascii_string.nil?
      ascii_string.unpack('H*')[0]
    end

    def from_utf8(utf8_string)
      return nil if utf8_string.nil?
      utf8_string.force_encoding('UTF-8').split("").collect {|x| x.ord.to_s(16).rjust(2, '0')}.join("")
    end

    def to_address(hexstring)
      return "0x0000000000000000000000000000000000000000" if hexstring.nil?
      "0x" + hexstring[-40..-1]
    end

    def to_von(amount, unit = "atp") #TODO
      return nil if amount.nil?
      BigDecimal(UNITS[unit.to_sym] * amount, 16).to_s.to_i rescue nil
    end

    def from_von(amount, unit = "atp") #TODO
      return nil if amount.nil?
      (BigDecimal(amount, 16) / BigDecimal(UNITS[unit.to_sym], 16)).to_s rescue nil
    end

    def to_gvon(amount, unit = "gvon") 
      return nil if amount.nil?
      BigDecimal(UNITS[unit.to_sym] * amount, 16).to_s.to_i rescue nil
    end

    def from_gvon(amount, unit = "gvon") 
      return nil if amount.nil?
      (BigDecimal(amount, 16) / BigDecimal(UNITS[unit.to_sym], 16)).to_s rescue nil
    end

    def from_address(address)
      return "0x0000000000000000000000000000000000000000" if address.nil?
      address.gsub(/^0x/,'').rjust(64, "0")
    end

    def to_param(string)
      string.ljust(64, '0')
    end

    def from_input(string)
      string[10..-1].scan(/.{64}/)
    end

    def to_twos_complement(number)
      (number & ((1 << 256) - 1)).to_s(16)
    end

    def to_int(hexstring)
      return nil if hexstring.nil?
      (hexstring.gsub(/^0x/,'')[0..1] == "ff") ? (hexstring.hex - (2 ** 256)) : hexstring.hex
    end

    def get_base_type(typename)
      typename.gsub(/\d+/,'')
    end

    def from_payload(args)
      converter = "output_to_#{self.get_base_type(args[0])}".to_sym
      self.send(converter, args[1])
    end

    def output_to_address(bytes)
      self.to_address(bytes)
    end

    def output_to_bytes(bytes)
      self.to_utf8(bytes)
    end

    def output_to_string(bytes)
      self.to_utf8(bytes)
    end

    def output_to_uint(bytes)
      self.to_int(bytes)
    end

    def output_to_int(bytes)
      self.to_int(bytes)
    end

    def output_to_bool(bytes)
      self.to_bool(bytes.gsub(/^0x/,''))
    end

    def to_output(args)
      converter = "output_to_#{self.get_base_type(args[0])}".to_sym
      self.send(converter, args[1])
    end

  end

end
