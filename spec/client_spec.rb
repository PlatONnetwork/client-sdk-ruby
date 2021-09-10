# frozen_string_literal: true
require 'spec_helper'

describe Platon::Client do

    let (:client) { Platon::Client.new(:alayadev) }
    let (:key1) {Platon::Key.new}
    let (:key2) {Platon::Key.new}


    describe '.encode_params' do
      let (:params) { [true, false, 0, 12345, '0x7d84abf0f241b10927b567bd636d95fa9f66ae34', '0x4d5e07d4057dd0c3849c2295d20ee1778fc29d69150e8d75a07207347dce17fa', '0x7d84abf0f241b10927b567bd636d95fa9f66ae34'] }
      let (:expected) { [true, false, '0x0', '0x3039', '0x7d84abf0f241b10927b567bd636d95fa9f66ae34', '0x4d5e07d4057dd0c3849c2295d20ee1778fc29d69150e8d75a07207347dce17fa', '0x7d84abf0f241b10927b567bd636d95fa9f66ae34'] }
      subject { client.encode_params(params) }
      it { is_expected.to eq expected}
    end

    shared_examples "json rpc method" do |request|
      let (:response) { '{"id":1, "jsonrpc":"2.0", "result": ""}' }
      it "is called as expected, OK" do
        expect(client).to receive(:send_single).once.with(request.to_json).and_return(response)
        subject
      end
    end

    describe "transfer" do
      subject {client.transfer(key1, key2.bech32_address, 10**16)}
      # 
    end

    describe ".web3_client_version" do
      subject { client.web3_client_version }
      it_behaves_like "json rpc method", {"jsonrpc":"2.0","method":"web3_clientVersion","params":[],"id":1}
    end

    describe ".net_version" do
      subject { client.net_version }
      it_behaves_like "json rpc method", {"jsonrpc":"2.0","method":"net_version","params":[],"id":1}
    end

    describe ".platon_protocol_version" do
      subject { client.platon_protocol_version }
      it_behaves_like "json rpc method", {"jsonrpc":"2.0","method":"platon_protocolVersion","params":[],"id":1}
    end

    describe ".net_listening" do
      subject { client.net_listening }
      it_behaves_like "json rpc method", {:jsonrpc=>"2.0", :method=>"net_listening", :params=>[], :id=>1}
    end

    describe ".net_peer_count" do
      subject { client.net_peer_count }
      it_behaves_like "json rpc method", {:jsonrpc=>"2.0", :method=>"net_peerCount", :params=>[], :id=>1}
    end
    
    describe ".platon_syncing" do
      subject { client.platon_syncing }
      it_behaves_like "json rpc method", {:jsonrpc=>"2.0", :method=>"platon_syncing", :params=>[], :id=>1}
    end

    describe ".platon_gas_price" do
      subject { client.platon_gas_price }
      it_behaves_like "json rpc method", {:jsonrpc=>"2.0", :method=>"platon_gasPrice", :params=>[], :id=>1}
    end

    describe ".shh_new_identity" do
      subject { client.shh_new_identity }
      it_behaves_like "json rpc method", {"jsonrpc":"2.0","method":"shh_newIdentity","params":[],"id":1}
    end

    describe ".platon_call" do
      subject { client.platon_call({to: "atp180fqd6cxtwnpups3qa53lnhvuwh8g9x9msvely"},"latest") }
      it_behaves_like "json rpc method", {"jsonrpc":"2.0","method":"platon_call","params":[{to: "atp180fqd6cxtwnpups3qa53lnhvuwh8g9x9msvely"}, "latest"], "id":1}
    end

    describe ".platon_get_balance" do
      subject { client.platon_get_balance("atp180fqd6cxtwnpups3qa53lnhvuwh8g9x9msvely","latest") }
      it_behaves_like "json rpc method", {"jsonrpc":"2.0","method":"platon_getBalance","params":["atp180fqd6cxtwnpups3qa53lnhvuwh8g9x9msvely", "latest"],"id":1}
    end


    describe ".get_nonce" do
      let (:request) { {"jsonrpc":"2.0","method":"platon_getTransactionCount","params":["atp180fqd6cxtwnpups3qa53lnhvuwh8g9x9msvely", "pending"],"id":1} }
      let (:response) { '{"jsonrpc":"2.0","result":"0xd30beea08891180","id":1}' }
      it "returns chain no" do
        expect(client).to receive(:send_single).once.with(request.to_json).and_return(response)
        expect(client.get_nonce("atp180fqd6cxtwnpups3qa53lnhvuwh8g9x9msvely")). to eq 950469433750000000
      end
    end


    describe ".platon_send_transaction" do
      subject { client.platon_send_transaction({
        "from": "atp1zdpu5f55gxurfzgkn8tgc7pwwl34jquf5twpyn",
        "to": "atp1h5dx7v9qgf40mctz5cm76kl4ap5lmau759ap70",
        "gas": "0x76c0", # 30400,
        "gasPrice": "0x9184e72a000", # 10000000000000
        "value": "0x9184e72a", # 2441406250
        "data": "0xd46e8dd67c5d32be8d46e8dd67c5d32be8058bb8eb970870f072445675058bb8eb970870f072445675"
        }) 
      }
      it_behaves_like "json rpc method", {:jsonrpc=>"2.0", :method=>"platon_sendTransaction", :params=>[{:from=>"atp1zdpu5f55gxurfzgkn8tgc7pwwl34jquf5twpyn", :to=>"atp1h5dx7v9qgf40mctz5cm76kl4ap5lmau759ap70", :gas=>"0x76c0", :gasPrice=>"0x9184e72a000", :value=>"0x9184e72a", :data=>"0xd46e8dd67c5d32be8d46e8dd67c5d32be8058bb8eb970870f072445675058bb8eb970870f072445675"}], :id=>1}
    end

    describe ".platon_estimate_gas" do
      subject { 
        client.platon_estimate_gas({
        "from": "atp1zdpu5f55gxurfzgkn8tgc7pwwl34jquf5twpyn",
        "to": "atp1h5dx7v9qgf40mctz5cm76kl4ap5lmau759ap70",
        "gasPrice": "0x9184e72a000", # 10000000000000
        "value": "0x9184e72a", # 2441406250
        "data": "0xd46e8dd67c5d32be8d46e8dd67c5d32be8058bb8eb970870f072445675058bb8eb970870f072445675"
        })
      }
      it_behaves_like "json rpc method", {:jsonrpc=>"2.0", :method=>"platon_estimateGas", :params=>[{:from=>"atp1zdpu5f55gxurfzgkn8tgc7pwwl34jquf5twpyn", :to=>"atp1h5dx7v9qgf40mctz5cm76kl4ap5lmau759ap70", :gasPrice=>"0x9184e72a000", :value=>"0x9184e72a", :data=>"0xd46e8dd67c5d32be8d46e8dd67c5d32be8058bb8eb970870f072445675058bb8eb970870f072445675"}], :id=>1}
    end

    describe ".platon_get_transaction_receipt" do
      subject { client.platon_get_transaction_receipt("0x11b3640628b0a8b28fa9e7aa20f70962b9dd6eecc9d8c8521af3f4898cc3b88c") }
      it_behaves_like "json rpc method", {:jsonrpc=>"2.0", :method=>"platon_getTransactionReceipt", :params=>["0x11b3640628b0a8b28fa9e7aa20f70962b9dd6eecc9d8c8521af3f4898cc3b88c"], :id=>1}
    end

end
