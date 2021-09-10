module Platon
  class Ppos

  	PARAMS_ORDER = {
	    "1000"=> ['typ', 'benefitAddress', 'nodeId', 'externalId', 'nodeName', 'website', 'details', 'amount', 'rewardPer', 'programVersion', 'programVersionSign', 'blsPubKey', 'blsProof'],
	    "1001"=> ['benefitAddress', 'nodeId', 'rewardPer', 'externalId', 'nodeName', 'website', 'details'],
	    "1002"=> ['nodeId', 'typ', 'amount'],
	    "1003"=> ['nodeId'],
	    "1004"=> ['typ', 'nodeId', 'amount'],
	    "1005"=> ['stakingBlockNum', 'nodeId', 'amount'],
	    "1100"=> [],
	    "1101"=> [],
	    "1102"=> [],
	    "1103"=> ['addr'],
	    "1104"=> ['stakingBlockNum', 'delAddr', 'nodeId'],
	    "1105"=> ['nodeId'],
	    "1200"=> [],
	    "1201"=> [],
	    "1202"=> [],

	    "2000"=> ['verifier', 'pIDID'],
	    "2001"=> ['verifier', 'pIDID', 'newVersion', 'endVotingRounds'],
	    "2002"=> ['verifier', 'pIDID', 'module', 'name', 'newValue'],
	    "2005"=> ['verifier', 'pIDID', 'endVotingRounds', 'tobeCanceledProposalID'],
	    "2003"=> ['verifier', 'proposalID', 'option', 'programVersion', 'versionSign'],
	    "2004"=> ['verifier', 'programVersion', 'versionSign'],
	    "2100"=> ['proposalID'],
	    "2101"=> ['proposalID'],
	    "2102"=> [],
	    "2103"=> [],
	    "2104"=> ['module', 'name'],
	    "2105"=> ['proposalID', 'blockHash'],
	    "2106"=> ['module'],

	    "3000"=> ['typ', 'data'],
	    "3001"=> ['typ', 'addr', 'blockNumber'],

	    "4000"=> ['account', 'plan'],
	    "4100"=> ['account'],

	    "5000"=> [],
	    "5100"=> ['address', 'nodeIDs']
		}

  	def initialize(client)
  		@client = client
  	end

  	def params_to_data(params)  #params should be Array
  		arr =params.map{|param| RLP.encode(param)}
  		rlpData = "0x"+RLP.encode(arr).unpack("H*").first
  	end

  	def obj_to_params(params)
  		return params if params.instance_of?(Array)
  		pars = [params["funcType"]]
  		order = PARAMS_ORDER[params["funcType"].to_s]
  		order.each do |key|
  			pars << params[key]
  		end
  		return pars
  	end

  	def funcType_to_address(funcType)
    	case funcType
    	when 1000...2000
    		return "0x1000000000000000000000000000000000000002"
    	when 2000...3000
    		return "0x1000000000000000000000000000000000000005"
    	when 3000...4000
    		return "0x1000000000000000000000000000000000000004"
    	when 4000...5000
    		return "0x1000000000000000000000000000000000000001"
    	when 5000...6000
    		return "0x1000000000000000000000000000000000000006"
    	end
  	end

  	def funcType_to_bech32(hrp,funcType)  ### TODO!!!
  		case funcType
    	when 1000...2000
    		return Utils.to_bech32_address(hrp,"0x1000000000000000000000000000000000000002")
    	when 2000...3000
    		return Utils.to_bech32_address(hrp,"0x1000000000000000000000000000000000000005")
    	when 3000...4000
    		return Utils.to_bech32_address(hrp,"0x1000000000000000000000000000000000000004")
    	when 4000...5000
    		return Utils.to_bech32_address(hrp,"0x1000000000000000000000000000000000000001")
    	when 5000...6000
    		return Utils.to_bech32_address(hrp,"0x1000000000000000000000000000000000000006")
    	end
  	end

  	def ppos_hex_to_obj(hex_str)
  		hex_str = hex_str.downcase.start_with?("0x") ? hex_str[2..-1] : hex_str
  		str = JSON.parse([hex_str].pack("H*")) rescue ""
  		if(str["Data"].instance_of?(String))
  			str["Data"] = JSON.parse(str["Data"]) rescue ""
  		end
  		return str
  	end

   	def call(params,block_param="latest") ##注意:个别参数需提前 hex_to_bin
  		begin
  			rawTx = {}
  			params = obj_to_params(params)

  			rawTx["data"] = params_to_data(params)
  			rawTx["to"] = funcType_to_bech32(@client.hrp,params[0])
  			data = @client.platon_call(rawTx,block_param)

  			return ppos_hex_to_obj(data)

  		rescue Exception => e
  			# puts "ppos call error :#{e}"
  			puts e.backtrace
  		end
  	end

  	def send(key,params,other=nil)
  		raise ArgumentError, "key or chain_id is not exist." if key == nil || @client.chain_id == nil

      begin

        rawTx = {
          from:key.address,
          to: funcType_to_address(params[0]),
          data: params_to_data(obj_to_params(params)),
          nonce: @client.get_nonce(key.bech32_address(hrp:@client.hrp)),
          gas_limit: (other && other[:gas_limit])|| @client.gas_limit,
          gas_price: (other && other[:gas_price]) || @client.gas_price,
          chain_id: @client.chain_id,
          value:0
        }
        # p rawTx
        tx = Platon::Tx.new(rawTx)
        tmp = tx.sign key
        # p tmp
        @client.platon_send_raw_transaction(tx.hex)
  
      rescue Exception => e
        # puts "ppos send error :#{e}"
        puts e.backtrace
      end


  	end

  	def create_staking(key,typ,benefit_address,node_id,external_id,node_name,website,details,amount,reward_per,program_version,program_version_sign,bls_pub_key,bls_proof)  #(1000)
      send key,[1000,
          typ,
          Utils.bech32_to_bin(benefit_address),
          Utils.hex_to_bin(node_id),
          Utils.hex_to_bin(external_id),
          node_name,
          website,
          details,
          Platon::Formatter.new.to_von(amount),
          reward_per,
          program_version,  #client.admin_get_program_version 获取
          Utils.hex_to_bin(program_version_sign), #client.admin_get_program_version 获取
          Utils.hex_to_bin(bls_pub_key), 
          Utils.hex_to_bin(bls_proof)  ## client.admin_get_schnorr_nizk_prove获取
      ]
  	end

   	def update_staking_info(key,benefit_address,node_id,reward_per,external_id,node_name,website,details) #(1001)
  		send key,[1001,
        Utils.bech32_to_bin(benefit_address),
        Utils.hex_to_bin(node_id),
        reward_per,
        Utils.hex_to_bin(external_id),
        node_name,
        website,
        details
      ]
  	end

   	def add_staking(key,node_id,typ,amount) # (1002)
  		send key,[1002,
        Utils.hex_to_bin(node_id),
        typ,
        Platon::Formatter.new.to_von(amount)
      ]
  	end

  	# 撤销质押(一次性发起全部撤销，多次到账)
  	def cancel_staking(key,node_id) #(1003)
  		send key,[1003,
        Utils.hex_to_bin(node_id)
      ]
  	end

  	# 发起委托，委托已质押节点，委托给某个节点增加节点权重来获取收入
  	def delegate(key,typ,node_id,amount) #(1004)
  		send key,[1004,typ,Utils.hex_to_bin(node_id),amount]
  	end

  	# 减持/撤销委托(全部减持就是撤销)
  	def reduce_delegate(key,staking_block_num,node_id,amount) #（1005）
  		send key,[1005,staking_block_num,Utils.hex_to_bin(node_id),amount]
  	end

  	## 查询当前结算周期的验证人队列，返回101个
  	def get_epoch_validators(block_param="latest") #(1100)
  		call [1100],block_param
  	end

  	## 查询当前共识周期的验证人队列，返回25个
  	def get_round_validators(block_param="latest") #(1101)
  		call [1101],block_param
  	end

  	## 查询实时候选人列表,返回全部。包含当前验证人
  	def get_current_candidates(block_param="latest") #(1102)
  		call [1102],block_param
  	end

  	def get_delegate_nodeids_by_addr(address,block_param="latest") #(1103)
  		call [1103, Utils.bech32_to_bin(address)],block_param
  	end

  	# 查询单个委托信息
  	def get_address_delegate_info(staking_block_num, address, node_id, block_param="latest")
  		call [1104, staking_block_num, Utils.bech32_to_bin(address), Utils.hex_to_bin(node_id)],block_param
  	end

  	#
  	def get_node_delegate_info(node_id,block_param="latest")
  		res = call([1105,Utils.hex_to_bin(node_id)],block_param)
  		# format_res_values res,["Shares","Released","ReleasedHes","RestrictingPlan","RestrictingPlanHes","DelegateTotal","DelegateTotalHes","DelegateRewardTotal"]
  	end

    def get_block_reward(block_param="latest")
      call [1200],block_param
    end

    def get_staking_reward(block_param="latest")
      call [1201],block_param
    end

  	# 提交文本提案
  	def submit_proposal(key,verifier,pIDID,other=nil)#2000 
  		send key,[2000,Utils.hex_to_bin(verifier),pIDID],other
  	end
  	# 提交升级提案
  	def update_proposal(key, verifier,pIDID, new_version,end_voting_rounds,other=nil) #2001
  		send key,[2001,Utils.hex_to_bin(verifier), pIDID, new_version,end_voting_rounds],other
  	end

  	# 提交取消提案
  	def cancel_proposal(key,verifier,pIDID,end_voting_rounds,to_be_canceled_proposal_id,other=nil)#2005
  		send key,[2005,Utils.hex_to_bin(verifier), pIDID, end_voting_rounds , to_be_canceled_proposal_id],other
  	end

  	# 给提案投票
  	def vote_proposal(key,verifier,proposal_id,option,program_version,version_sign,other=nil)#2003
  		send key,[2003,Utils.hex_to_bin(verifier),Utils.hex_to_bin(proposal_id),option,program_version,Utils.hex_to_bin(version_sign)],other
  	end

  	# 版本声明
  	def declare_version(key,verifier,program_version,version_sign) #2004
  		send key,[2004,Utils.hex_to_bin(verifier),program_version,Utils.hex_to_bin(version_sign)],other
  	end  	

  	# 查询提案列表
  	def get_proposals(block_param="latest") #2102
  		call [2102],block_param
  	end

  	# 提案查询
  	def get_proposal_info(proposal_id,block_param="latest") #2100
  		call [2100,Utils.hex_to_bin(proposal_id)],block_param
  	end

  	# 查询提案结果
  	def get_proposal_result(proposal_id,block_param="latest") #2101
  		call [2101,Utils.hex_to_bin(proposal_id)],block_param
  	end

  	# 查询节点的链生效版本
  	def get_version_in_effect(block_param="latest")  #2103
  		call [2103],block_param
  	end

  	# 查询提案的投票人数 
  	def get_votes_number(proposal_id,block_hash,block_param="latest")  #2105
  		call [2105, Utils.hex_to_bin(proposal_id),Utils.hex_to_bin(block_hash)]
  	end

    # 查询治理参数列表
    def get_govern_params(module_name,block_param="latest")  # 2106
      call [2106, module_name],block_param
    end

    # 查询当前块高的治理参数值
    def get_govern_param_value(module_name, name,block_param="latest")  #2104
      call [2104,module_name,name],block_param
    end

  	# 举报双签 
  	def report_duplicate_sign(key,duplicate_sign_type,data,other=nil)#3000
  		send key,[3000,duplicate_sign_type,data],other
  	end
  	# 查询节点被举报情况
  	def get_node_oversign(type,node_id,block_number,block_param="latest")  #3001
  		call [3001,type,Utils.hex_to_bin(node_id),block_number],block_param
  	end

    # 创建锁仓计划 4000
    def create_restricting_plan(key,account,restricting_plans)
      send key,[4000,
        Utils.bech32_to_bin(account),
        restricting_plans
      ]
    end

    # 获取锁仓信息 4100
    def get_restricting_info(account,block_param="latest")
      call [4100, Utils.bech32_to_bin(account)],block_param
    end

    #################奖励接口
    ## 提取委托奖励
    # 5000
    def withdraw_delegate_reward(key)
      send key,[5000]
    end

    ## 查询未提取的委托奖励
    def get_delegate_reward(address,node_ids=[],block_param="latest")
      call [5100,Utils.bech32_to_bin(address),node_ids.map{|item| Utils.hex_to_bin(item)}],block_param
    end

  	private
  	# def format_res_values(res,keys)
  	# 	keys.each do |key|
  	# 		res["Ret"][key] = res["Ret"][key].to_i(16)
  	# 	end
  	# 	res
  	# end

  end
end
