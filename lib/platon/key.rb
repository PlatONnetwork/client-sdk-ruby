module Platon
  class Key
    autoload :Decrypter, 'platon/key/decrypter'
    autoload :Encrypter, 'platon/key/encrypter'

    attr_reader :private_key, :public_key

    def self.encrypt(key, password,options={})
      key = new(priv: key) unless key.is_a?(Key)

      Encrypter.perform key.private_hex, password ,options
    end

    def self.decrypt(data, password)
      priv = Decrypter.perform data, password
      new priv: priv
    end

    def self.encrypt_and_save(key,password,options={})
      encrypted_key_info = encrypt(key,password,options)
      ## PlatON似乎打算兼容以太地址, 暂时默认以 0x 地址命名 
      keypath = options[:keypath]
      if keypath==nil || keypath=="" 
        address = key.address
        dirname = "#{ENV['HOME']}/.platon/keystore/"
        FileUtils.mkdir_p(dirname) unless Dir.exists?(dirname)
        File.write File.join(dirname, "#{key.address}.json") , encrypted_key_info
      else
        File.write keypath , encrypted_key_info
      end
      return encrypted_key_info
    end

    def self.list_wallets(options={})
      keypath = options[:keypath]
      if keypath==nil || keypath=="" 
        Dir.glob("#{ENV['HOME']}/.platon/keystore/*").select { |e| File.file? e }
      else
        Dir.glob(keypath + "/*").select { |e| File.file? e }
      end
    end

    def self.personal_recover(message, signature)
      bin_signature = Utils.hex_to_bin(signature).bytes.rotate(-1).pack('c*')
      OpenSsl.recover_compact(Utils.keccak256(Utils.prefix_message(message)), bin_signature)
    end

    def initialize(priv: nil)
      @private_key = MoneyTree::PrivateKey.new key: priv
      @public_key = MoneyTree::PublicKey.new private_key, compressed: false
    end

    def private_hex
      private_key.to_hex
    end

    def public_bytes
      public_key.to_bytes
    end

    def public_hex
      public_key.to_hex
    end

    def address
      Utils.public_key_to_address public_hex
    end

    def bech32_address(hrp:"lat")
      Utils.to_bech32_address(hrp,address)
    end
    alias_method :to_address, :address

    def sign(message)
      sign_hash message_hash(message)
    end

    def sign_hash(hash)
      loop do
        signature = OpenSsl.sign_compact hash, private_hex, public_hex
        return signature if valid_s? signature
      end
    end

    def verify_signature(message, signature)
      hash = message_hash(message)
      public_hex == OpenSsl.recover_compact(hash, signature)
    end

    def personal_sign(message)
      Utils.bin_to_hex(sign(Utils.prefix_message(message)).bytes.rotate(1).pack('c*'))
    end


    private

    def message_hash(message)
      Utils.keccak256 message
    end

    def valid_s?(signature)
      s_value = Utils.v_r_s_for(signature).last
      s_value <= Secp256k1::N/2 && s_value != 0
    end

  end
end
