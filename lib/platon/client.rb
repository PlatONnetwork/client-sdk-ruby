module Platon
  class Client

    DEFAULT_GAS_LIMIT = 400_000 

    DEFAULT_GAS_PRICE = 1_000_000_000  #1 GVON

    RPC_COMMANDS = %w(web3_clientVersion web3_sha3 net_version net_peerCount net_listening platon_protocolVersion platon_syncing platon_gasPrice platon_accounts platon_blockNumber platon_getBalance platon_getStorageAt platon_getTransactionCount platon_getBlockTransactionCountByHash platon_getBlockTransactionCountByNumber platon_getCode platon_sign platon_sendTransaction platon_sendRawTransaction platon_call platon_estimateGas platon_getBlockByHash platon_getBlockByNumber platon_getTransactionByHash platon_getTransactionByBlockHashAndIndex platon_getTransactionByBlockNumberAndIndex platon_getTransactionReceipt platon_getUncleByBlockHashAndIndex platon_newFilter platon_newBlockFilter platon_newPendingTransactionFilter platon_uninstallFilter platon_getFilterChanges platon_getFilterLogs platon_getLogs platon_getWork platon_submitWork platon_submitHashrate db_putString db_getString db_putHex db_getHex shh_post shh_version shh_newIdentity shh_hasIdentity shh_newGroup shh_addToGroup shh_newFilter shh_uninstallFilter shh_getFilterChanges shh_getMessages)
    #PLATON_UNSUPPORT_COMMANDS =  %w(platon_coinbase ,plton_mining,platon_hashrate,platon_getUncleCountByBlockHash,platon_getUncleCountByBlockNumber,platon_getUncleByBlockNumberAndIndex platon_getCompilers platon_compileLLL platon_compileSolidity platon_compileSerpent)
    PLATON_RPC_COMMANDS = %w(platon_evidences admin_getProgramVersion admin_getSchnorrNIZKProve)
    RPC_MANAGEMENT_COMMANDS = %w(admin_addPeer admin_datadir admin_nodeInfo admin_peers admin_setSolc admin_startRPC admin_startWS admin_stopRPC admin_stopWS debug_backtraceAt debug_blockProfile debug_cpuProfile debug_dumpBlock debug_gcStats debug_getBlockRlp debug_goTrace debug_memStats debug_seedHash debug_setHead debug_setBlockProfileRate debug_stacks debug_startCPUProfile debug_startGoTrace debug_stopCPUProfile debug_stopGoTrace debug_traceBlock debug_traceBlockByNumber debug_traceBlockByHash debug_traceBlockFromFile debug_traceTransaction debug_verbosity debug_vmodule debug_writeBlockProfile debug_writeMemProfile miner_hashrate miner_makeDAG miner_setExtra miner_setGasPrice miner_start miner_startAutoDAG miner_stop miner_stopAutoDAG personal_importRawKey personal_listAccounts personal_lockAccount personal_newAccount personal_unlockAccount personal_sendTransaction txpool_content txpool_inspect txpool_status)

    attr_accessor :command, :id, :logger, :default_account, :gas_price, :gas_limit, :ppos, :hrp,:chain_id

    def initialize(chain_name=nil)
      @id = 0
      @batch = nil
      # @formatter = Platon::Formatter.new
      @gas_price = DEFAULT_GAS_PRICE 
      @gas_limit = DEFAULT_GAS_LIMIT


      @ppos = Platon::Ppos.new self

      set_network(chain_name.downcase.to_sym)

    end

    def self.create(host_or_ipcpath)
      return IpcClient.new(host_or_ipcpath) if host_or_ipcpath.end_with? '.ipc'
      return HttpClient.new(host_or_ipcpath) if host_or_ipcpath.start_with? 'http'
      raise ArgumentError.new('Unable to detect client type')
    end

    def set_network(network) 
      config = {
        platon: {hrp:"lat", chain_id:100},
        platondev: {hrp: "lat", chain_id: 210309},
        alaya:{hrp:"atp",chain_id:201018} ,
        alayadev:{hrp:"atp",chain_id: 201030}
      }
      if config[network]
        @hrp = config[network][:hrp]  
        @chain_id = config[network][:chain_id]

        puts "Using Network: #{network}: hrp->#{hrp} , chain_id->#{chain_id}"
      else
        puts "Warning: Network:#{network} not found. You can use 'update_setting' to set hrp & chain_id"
      end

    end

    def update_setting(params)
      @hrp = params[:hrp]
      @chain_id = params[:chain_id]
    end

    def batch
      @batch = []

      yield
      result = send_batch(@batch)

      @batch = nil
      reset_id

      return result
    end

    def get_id
      @id += 1
      return @id
    end

    def reset_id
      @id = 0
    end

    def default_account
      @default_account ||= platon_accounts[0]
    end

    def int_to_hex(p)
      p.is_a?(Integer) ? "0x#{p.to_s(16)}" : p 
    end

    def encode_params(params)
      params.map(&method(:int_to_hex))
    end

    def get_nonce(address)
      platon_get_transaction_count(address, "pending")
    end
    
    def transfer_to(address, amount)
      platon_send_transaction({to: address, value: int_to_hex(amount)})
    end

    def transfer_to_and_wait(address, amount)
      wait_for(transfer_to(address, amount))
    end


    def transfer(key, bech32_address, amount,other=nil)
      raise ArgumentError.new("#{bech32_address} not match current network hrp :#{hrp}") unless Bech32.decode(bech32_address)[0] == hrp
      args = { 
        from: key.address,
        to: Utils.decode_bech32_address(bech32_address),
        value: amount.to_i,
        data: "",
        nonce: get_nonce(key.bech32_address(hrp:hrp)),
        gas_limit: (other && other[:gas_limit])|| gas_limit,
        gas_price: (other && other[:gas_price]) || gas_price,
        chain_id: chain_id
      }

      tx = Platon::Tx.new(args)
      tx.sign key
      platon_send_raw_transaction(tx.hex)
    end
    
    def transfer_and_wait(key, address, amount,other=nil)
      return wait_for(transfer(key, address, amount,other))
    end
    
    def wait_for(tx)
      transaction = Platon::Transaction.new(tx, self, "", [])
      transaction.wait_for_miner
      return transaction
    end

    def send_command(command,args)

      # if ["platon_call"].include?(command)
      #   args << "latest"
      # end
      
      payload = {jsonrpc: "2.0", method: command, params: encode_params(args), id: get_id}
      puts payload
      # @logger.info("Sending #{payload.to_json}") if @log
      if @batch
        @batch << payload
        return true
      else
        p output = JSON.parse(send_single(payload.to_json))
        # @logger.info("Received #{output.to_json}") if @log
        reset_id
        raise IOError, output["error"]["message"] if output["error"]
        
        if %W(net_peerCount platon_protocolVersion platon_gasPrice platon_blockNumber platon_getBalance platon_getTransactionCount platon_getBlockTransactionCountByHash platon_getBlockTransactionCountByNumber platon_estimateGas).include?(command)
          return output["result"].to_i(16)
        end

        return output["result"]
      end
    end

    (RPC_COMMANDS + RPC_MANAGEMENT_COMMANDS + PLATON_RPC_COMMANDS).each do |rpc_command|
      method_name = rpc_command.underscore

      define_method method_name do |*args|
        # puts "res： #{method_name}"
        send_command(rpc_command, args)
      end
    end


  end

end

