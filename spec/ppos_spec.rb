# frozen_string_literal: true
require 'spec_helper'

describe Platon::Ppos do

    let (:key) {Platon::Key.new priv:"8144900eb9c7bc78dc376fda1be88a4e3e3fb8624cf545ef3a6d7ec73e2cb082"}
    let (:client) { Platon::Client.new("alayadev") }



    shared_examples "json rpc method" do |request|
      let (:response) { '{"id":1, "jsonrpc":"2.0", "result": ""}' }
      it "is called as expected, OK" do
        
        allow(client).to receive(:platon_get_transaction_count).and_return(0)
        expect(client).to receive(:send_single).once.with(request.to_json).and_return(response)
        subject
      end
    end

    describe ".create_staking" do
      subject { 
        client.ppos.create_staking(
          key,
          0,
          key.bech32_address,
          "9d3f5a4d80a4b5b89df5ad7dadd1ef0e54854decfd5c4b808d064d4e73374e9848ac6b02bc651e9ea15f184b2a4317ea50424402670799bb0910cafeb7323f4d",
          "", 
          "hello-dposclub",
          "https://www.baidu.com",
          "integration-node1-details",
          100000,
          8888,
          65536,
          "0x7f4d68fb9f100aff45b9c4730c102973ca7bd63d262c2707bb3e8b18ead2865272c1b4ed23de9bfd13ebb41b3562969cfdafc303e070c4b71723c997a8c53fbd01",
          "69365262afd3c8a6971db4f8a97a0dec049b83a85905f41429c45635de483e03f058f7ae4befb592f391fa49f68a970581a3ab4688baf9eaa6c5d0bf3e80669536ac44c91db0bacc88379ccbb33561e08f03b722ef0f296a94c06873f7b71a06",
          "ce36b2fd6d6d76cf3a7a35e77455b3cae261568454027bbb4c28268d3c5cc16f9f6e56ca9f44c723d3181011bd31d50e39437776c474708b02ffabf088d79a1f" 
        )
      }
      # it_behaves_like "json rpc method", {:jsonrpc=>"2.0", :method=>"platon_getTransactionCount", :params=>["atp1tfm3e44jwdjmelcc9yacus700wcts0zhgw6425", "pending"], :id=>1}
    end

    describe ".cancel_staking" do
      subject { client.ppos.cancel_staking(key,"9d3f5a4d80a4b5b89df5ad7dadd1ef0e54854decfd5c4b808d064d4e73374e9848ac6b02bc651e9ea15f184b2a4317ea50424402670799bb0910cafeb7323f4d") }
      # it_behaves_like "json rpc method", {:jsonrpc=>"2.0", :method=>"platon_getTransactionCount", :params=>["atp1tfm3e44jwdjmelcc9yacus700wcts0zhgw6425", "pending"], :id=>1}
    end

    describe ".update_staking_info" do
      subject { client.ppos.update_staking_info(
        key,
        key.bech32_address,
        "9d3f5a4d80a4b5b89df5ad7dadd1ef0e54854decfd5c4b808d064d4e73374e9848ac6b02bc651e9ea15f184b2a4317ea50424402670799bb0910cafeb7323f4d",
        8866,
        "",
        "hi-new-name-dpos",
        "https://baidu.com",
        "integration-node2-details"
        ) }
      # it_behaves_like "json rpc method", {:jsonrpc=>"2.0", :method=>"platon_getTransactionCount", :params=>["atp1tfm3e44jwdjmelcc9yacus700wcts0zhgw6425", "pending"], :id=>1}
    end

    describe ".add_staking" do
      subject { client.ppos.add_staking(key,
        "9d3f5a4d80a4b5b89df5ad7dadd1ef0e54854decfd5c4b808d064d4e73374e9848ac6b02bc651e9ea15f184b2a4317ea50424402670799bb0910cafeb7323f4d",
        0,
        20
      ) }
      # it_behaves_like "json rpc method", {:jsonrpc=>"2.0", :method=>"platon_getTransactionCount", :params=>["atp1tfm3e44jwdjmelcc9yacus700wcts0zhgw6425", "pending"], :id=>1}
    end

    describe ".get_node_delegate_info" do
      subject { client.ppos.get_node_delegate_info("0x48f9ebd7559b7849f80e00d89d87fb92604c74a541a7d76fcef9f2bcc67043042dfab0cfbaeb5386f921208ed9192c403f438934a0a39f4cad53c55d8272e5fb") }
      it_behaves_like "json rpc method", {:jsonrpc=>"2.0", :method=>"platon_call", :params=>[{"data"=>"0xf84883820451b842b84048f9ebd7559b7849f80e00d89d87fb92604c74a541a7d76fcef9f2bcc67043042dfab0cfbaeb5386f921208ed9192c403f438934a0a39f4cad53c55d8272e5fb", "to"=>"atp1zqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqzfyslg3"}, "latest"], :id=>1}
    end

    describe ".get_block_reward" do
      subject { client.ppos.get_block_reward }
      it_behaves_like "json rpc method", {:jsonrpc=>"2.0", :method=>"platon_call", :params=>[{"data"=>"0xc4838204b0", "to"=>"atp1zqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqzfyslg3"}, "latest"], :id=>1}
    end


    describe ".get_staking_reward" do
      subject { client.ppos.get_staking_reward }
      it_behaves_like "json rpc method", {:jsonrpc=>"2.0", :method=>"platon_call", :params=>[{"data"=>"0xc4838204b1", "to"=>"atp1zqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqzfyslg3"}, "latest"], :id=>1}
    end

    describe ".get_round_validators" do
      subject { client.ppos.get_round_validators }
      it_behaves_like "json rpc method", {:jsonrpc=>"2.0", :method=>"platon_call", :params=>[{"data"=>"0xc48382044d", "to"=>"atp1zqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqzfyslg3"}, "latest"], :id=>1}
    end

    describe ".get_epoch_validators" do
      subject { client.ppos.get_epoch_validators }
      it_behaves_like "json rpc method", {:jsonrpc=>"2.0", :method=>"platon_call", :params=>[{"data"=>"0xc48382044c", "to"=>"atp1zqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqzfyslg3"}, "latest"], :id=>1}
    end

    describe ".get_current_candidates" do
      subject { client.ppos.get_current_candidates }
      it_behaves_like "json rpc method", {:jsonrpc=>"2.0", :method=>"platon_call", :params=>[{"data"=>"0xc48382044e", "to"=>"atp1zqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqzfyslg3"}, "latest"], :id=>1}
    end
    describe ".get_node_delegate_info" do
      subject { client.ppos.get_node_delegate_info("0x48f9ebd7559b7849f80e00d89d87fb92604c74a541a7d76fcef9f2bcc67043042dfab0cfbaeb5386f921208ed9192c403f438934a0a39f4cad53c55d8272e5fb") }
      it_behaves_like "json rpc method", {:jsonrpc=>"2.0", :method=>"platon_call", :params=>[{"data"=>"0xf84883820451b842b84048f9ebd7559b7849f80e00d89d87fb92604c74a541a7d76fcef9f2bcc67043042dfab0cfbaeb5386f921208ed9192c403f438934a0a39f4cad53c55d8272e5fb", "to"=>"atp1zqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqzfyslg3"}, "latest"], :id=>1}
    end
    describe ".delegate" do
      subject { client.ppos.delegate(key,0,"0x62f537293042326df6637a38319c3cb7abd032554137a800c25c29f0e07287407f96df7601b7b00d1c0c9b26a3eedffd3397af470ba564298e047c450202cfd2",10*10**18) }
      # it_behaves_like "json rpc method", {:jsonrpc=>"2.0", :method=>"platon_getTransactionCount", :params=>["atp1tfm3e44jwdjmelcc9yacus700wcts0zhgw6425", "pending"], :id=>1}
    end
    describe ".reduce_delegate" do
      subject { client.ppos.reduce_delegate(key,453063,"62f537293042326df6637a38319c3cb7abd032554137a800c25c29f0e07287407f96df7601b7b00d1c0c9b26a3eedffd3397af470ba564298e047c450202cfd2",10*10**18) }
      # it_behaves_like "json rpc method", {:jsonrpc=>"2.0", :method=>"platon_getTransactionCount", :params=>["atp1tfm3e44jwdjmelcc9yacus700wcts0zhgw6425", "pending"], :id=>1}
    end

    describe ".withdraw_delegate_reward" do
      subject { client.ppos.withdraw_delegate_reward key }
      # it_behaves_like "json rpc method", {:jsonrpc=>"2.0", :method=>"platon_getTransactionCount", :params=>["atp1tfm3e44jwdjmelcc9yacus700wcts0zhgw6425", "pending"], :id=>1}
    end

    describe ".get_delegate_nodeids_by_addr" do
      subject { client.ppos.get_delegate_nodeids_by_addr(key.bech32_address) }
      it_behaves_like "json rpc method", {:jsonrpc=>"2.0", :method=>"platon_call", :params=>[{"data"=>"0xda8382044f95945a771cd6b27365bcff18293b8e43cf7bb0b83c57", "to"=>"atp1zqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqzfyslg3"}, "latest"], :id=>1}
    end

    describe ".get_delegate_reward" do
      subject { client.ppos.get_delegate_reward(key.bech32_address) }
      it_behaves_like "json rpc method", {:jsonrpc=>"2.0", :method=>"platon_call", :params=>[{"data"=>"0xdc838213ec95945a771cd6b27365bcff18293b8e43cf7bb0b83c5781c0", "to"=>"atp1zqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqxxwje8t"}, "latest"], :id=>1}
    end

    describe ".submit_proposal" do
      subject { client.ppos.submit_proposal(key,"9d3f5a4d80a4b5b89df5ad7dadd1ef0e54854decfd5c4b808d064d4e73374e9848ac6b02bc651e9ea15f184b2a4317ea50424402670799bb0910cafeb7323f4d","1",{gas_price:(1.5 * 10**15).to_i,gas_limit:350000}) }
      # it_behaves_like "json rpc method", {:jsonrpc=>"2.0", :method=>"platon_getTransactionCount", :params=>["atp1tfm3e44jwdjmelcc9yacus700wcts0zhgw6425", "pending"], :id=>1}
    end
end
