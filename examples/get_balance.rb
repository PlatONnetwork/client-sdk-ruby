### Get Core Token(lat or atp) balance  
### Get Arc20/Prc20 balance

require "platon"

### Example on Alaya:

RPC = "http://127.0.0.1:6789" # change to your rpc address

TARGET_ADDRESS_1 = "atp1lsds5k5wys93vhm8gvkvepyx5e9hxtfz8w4r5x"
TARGET_ADDRESS_2 = "atp1djc6dvd2y2kj04hhy30rmctkc9nnqmmzlk42uv"


client = Platon::HttpClient.new(RPC,"alaya")

###Get Core Token(lat or atp) balance
res =  client.platon_get_balance(TARGET_ADDRESS_1,"latest")
balance = res / 10**18.to_f
puts "#{TARGET_ADDRESS_1} #{client.hrp.upcase} balance: #{balance} "

###Get Arc20/Prc20 balance
client.default_account = Platon::Key.new.bech32_address  # 随机生成地址并指定即可。 因platon节点要求call也必须传入from参数
minABI=[{"constant":true,"inputs":[{"name":"_owner","type":"address"}],"name":"balanceOf","outputs":[{"name":"balance","type":"uint256"}],"type":"function"},{"constant":true,"inputs":[],"name":"decimals","outputs":[{"name":"","type":"uint8"}],"type":"function"}];
contract = Platon::Contract.create(
	client:client, 
	name: "MyContract", 
	address: "atp16lellpkrv894hmg8am7ns3p2qny2vqj85ud8s6",  #ARC20 contract address
	abi:minABI # Arc20 contract abi
	)

res2 =  contract.call.balance_of(TARGET_ADDRESS_2)
aETH_balance = res2 / 10**18.to_f
puts "#{TARGET_ADDRESS_2} aETH balance: #{aETH_balance}"