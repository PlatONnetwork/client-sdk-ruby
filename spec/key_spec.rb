# frozen_string_literal: true
describe Platon::Key, type: :model do
  let(:priv) { nil }
  subject(:key) { Platon::Key.new priv: priv }

  describe "#initialize" do
    it "returns a key with a new private key" do
      key1 = Platon::Key.new
      key2 = Platon::Key.new

      expect(key1.private_hex).not_to eq(key2.private_hex)
      expect(key1.public_hex).not_to eq(key2.public_hex)
    end

    it "regenerates an old private key" do
      key1 = Platon::Key.new
      key2 = Platon::Key.new priv: key1.private_hex

      expect(key1.private_hex).to eq(key2.private_hex)
      expect(key1.public_hex).to eq(key2.public_hex)
    end
  end

  describe ".sign" do
    let(:message) { "Hi PlatON" }

    it "signs a message so that the public key is recoverable" do
      10.times do
        signature = key.sign message
        expect(key.verify_signature message, signature).to be_truthy
        s_value = Platon::Utils.v_r_s_for(signature).last
        expect(s_value).to be < (Platon::Secp256k1::N/2)
      end
    end
  end

  describe ".personal_sign" do
    let(:message) { "Hi PlatON" }

    it "signs a message so that the public key can be recovered with personal_recover" do
      10.times do
        signature = key.personal_sign message
        expect(Platon::Key.personal_recover message, signature).to eq(key.public_hex)
      end
    end
  end

  describe ".personal_recover" do
    let(:message) { "hello" }
    let(:signature) { "873e7532c3cd89730dc222649238a555330ffb472e6cca2ed3f696b204c96ece744e9c19ecda133909f4cc9eae65293b2973309a0b37733df8d44194d1df32de1c" }
    let(:public_hex) { "04c2a0039f03740b924d0074f7dc09edad415d1ddff1515d7c4d4102216f46777298a85b258793bad22c7454e2c147aef515d93aad603109f4961e5d9363371589" }

    it "it can recover a public key from a signature generated with web3/Samurai" do
      10.times do
        expect(Platon::Key.personal_recover message, signature).to eq(public_hex)
      end
    end
  end

  describe ".verify_signature" do
    let(:priv) { '8144900eb9c7bc78dc376fda1be88a4e3e3fb8624cf545ef3a6d7ec73e2cb082' }
    let(:signature) { Platon::Utils.hex_to_bin "1c8320d8042e6f3c184091056316fee99ac5f68565b35f6bfcfad7e15201b1937a7d8f82f39148dc6975c2749bafa4ab6315dea5a4c6cb9e69300b315689689a5d" }
    let(:message) { "hello" }

    it "signs a message so that the public key is recoverable" do
      expect(key.verify_signature message, signature).to be_truthy
    end

    context "when the signature matches another public key" do
      let(:other_priv) { '26bb00be256b04d4e7122bd18915143679312fdc1f521f3ae97fd99863919e01' }
      let(:signature) { Platon::Utils.hex_to_bin "873e7532c3cd89730dc222649238a555330ffb472e6cca2ed3f696b204c96ece744e9c19ecda133909f4cc9eae65293b2973309a0b37733df8d44194d1df32de1c" }

      it "does not verify the signature" do
        expect(key.verify_signature message, signature).to be_falsy
      end
    end

    context "when the signature does not match any public key" do
      let(:signature) { Platon::Utils.hex_to_bin "1b21a66b" }

      it "signs a message so that the public key is recoverable" do
        expect(key.verify_signature message, signature).to be_falsy
      end
    end
  end

  describe ".address" do
    subject { key.address }
    let(:priv) { 'c3a4349f6e57cfd2cbba275e3b3d15a2e4cf00c89e067f6e05bfee25208f9cbb' }
    it { is_expected.to eq('0x759b427456623a33030bbC2195439C22A8a51d25') }
    it { is_expected.to eq(key.to_address) }
  end

  describe ".bech32_address" do 
    let(:priv) { 'c3a4349f6e57cfd2cbba275e3b3d15a2e4cf00c89e067f6e05bfee25208f9cbb' }

    it "convert to bech32 address" do 
      expect(key.bech32_address(hrp:"atp")).to eq("atp1wkd5yazkvgarxqcthsse2suuy25228f9gvlz68")
    end
  end

  describe ".encrypt/.decrypt" do

    let(:password) { SecureRandom.base64 }
    let(:key) { Platon::Key.new }

    it "reads and writes keys in the Platon Secret Storage definition" do
      encrypted = Platon::Key.encrypt key, password
      decrypted = Platon::Key.decrypt encrypted, password

      expect(key.address).to eq(decrypted.address)
      expect(key.public_hex).to eq(decrypted.public_hex)
      expect(key.private_hex).to eq(decrypted.private_hex)
    end
  end

end
