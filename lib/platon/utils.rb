module Platon
  module Utils

    extend self

    def normalize_address(address)
      if address.nil? || address == ''
        ''
      elsif address.size == 40
        hex_to_bin address
      elsif address.size == 42 && address[0..1] == '0x' 
        hex_to_bin address[2..-1]
      else
        address
      end
    end

    def bin_to_hex(string)
      RLP::Utils.encode_hex string
    end

    def hex_to_bin(string)
      RLP::Utils.decode_hex remove_hex_prefix(string)
    end

    def base256_to_int(str)
      RLP::Sedes.big_endian_int.deserialize str.sub(/\A(\x00)+/, '')
    end

    def int_to_base256(int)
      RLP::Sedes.big_endian_int.serialize int
    end

    def v_r_s_for(signature)
      [
        signature[0].bytes[0],
        Utils.base256_to_int(signature[1..32]),
        Utils.base256_to_int(signature[33..65]),
      ]
    end

    def prefix_hex(hex)
      hex.match(/\A0x/) ? hex : "0x#{hex}"
    end

    def remove_hex_prefix(s)
      s[0,2] == '0x' ? s[2..-1] : s 
    end

    def bin_to_prefixed_hex(binary)
      prefix_hex bin_to_hex(binary)
    end

    def prefix_message(message)
      "\x19Platon Signed Message:\n#{message.length}#{message}"
      # "\x19Ethereum Signed Message:\n#{message.length}#{message}"
    end

    def public_key_to_address(hex)
      bytes = hex_to_bin(hex)
      address_bytes = Utils.keccak256(bytes[1..-1])[-20..-1]
      format_address bin_to_prefixed_hex(address_bytes)
    end

    # bech32 address to bin
    def bech32_to_bin(bech32Address)
      address = decode_bech32_address(bech32Address)
      hex_to_bin address
    end

    def is_bech32_address?(bech32Address)
      return false if bech32Address.length != 42
      hrp,data,spec = Bech32.decode bech32Address
      return false if data == nil
      return true
    end


    #  Resolve the bech32 address
    # 
    #  @method decode_bech32_address
    #  @param {String} bech32Address
    #  @return {String} formatted address
    #  eg: Platon::Utils.decode_bech32_address("atp1kh9dktnszj04zn6d8ae9edhqfmt4awx94n6h4m")
    def decode_bech32_address(bech32Address)
      if is_bech32_address?(bech32Address) ## is_bech32_address? ## TODO
        
        segwit_addr = SegwitAddr.new(bech32Address)
        address = segwit_addr.to_script_pubkey
        if address
          return "0x" + address
        end
      end
      return ''
    end
 
     # Transforms given string to bech32 address
     #
     # @method to_bech32_address
     # @param {String} hrp
     # @param {String} address
     # @return {String} formatted bech32 address

    # Platon::Utils.to_bech32_address("atp","0xb5cadb2e70149f514f4d3f725cb6e04ed75eb8c5")
    def to_bech32_address(hrp,address)
      if true ## isAddress
        segwit_addr = SegwitAddr.new
        segwit_addr.hrp = hrp
        segwit_addr.script_pubkey = remove_hex_prefix(address)  ## remove 0x
        segwit_addr.addr
      end
    end

    def sha256(x)
      Digest::SHA256.digest x
    end

    def keccak256(x)
      Digest::SHA3.new(256).digest(x)
    end

    def keccak512(x)
      Digest::SHA3.new(512).digest(x)
    end

    def keccak256_rlp(x)
      keccak256 RLP.encode(x)
    end

    def ripemd160(x)
      Digest::RMD160.digest x
    end

    def hash160(x)
      ripemd160 sha256(x)
    end

    def zpad(x, l)
      lpad x, BYTE_ZERO, l
    end

    def zunpad(x)
      x.sub(/\A\x00+/, '')
    end

    def zpad_int(n, l=32)
      zpad encode_int(n), l
    end

    def zpad_hex(s, l=32)
      zpad decode_hex(s), l
    end

    def valid_address?(address)
      Address.new(address).valid?
    end

    def format_address(address)
      Address.new(address).checksummed
    end



    private

    def lpad(x, symbol, l)
      return x if x.size >= l
      symbol * (l - x.size) + x
    end

    def encode_int(n)
      unless n.is_a?(Integer) && n >= 0 && n <= UINT_MAX
        raise ArgumentError, "Integer invalid or out of range: #{n}"
      end

      int_to_base256 n
    end

  end
end
