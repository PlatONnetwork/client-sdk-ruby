

本Gem是PlatON与Alaya的Ruby SDK ,通过对PlatON RPC接口的调用，实现了钱包管理、链信息查询及质押、委托奖励、治理、锁仓等模块，也可通过该SDK实现合约的部署、查询、调用等操作。

## 安装

在应用的 Gemfile 中添加如下一行:

```ruby
gem 'platon'
```

然后执行:

    $ bundle install

或手动安装platon gem:

    $ gem install platon


## 快速入门示例

```ruby
## generate new key 
key = Platon::Key.new  

## print bech32 address 
puts key.bech32_address(hrp: "atp") 

client = Platon::HttpClient.new("http://127.0.0.1:6789",:alayadev)

## see current block number
client.platon_block_number  

## transfer 0.01 ATP to others
client.transfer key,"atpxxxxxxxxxxxxxxx",10**16

```


## 使用

#### Keys

创建一组Key,获得其公钥、私钥、地址等

```ruby
key = Platon::Key.new
key.private_hex ## private key
=> "08bb093d6184cb06a3f80507953ba6768c03d8114a429b0ec7875bb6b6e1a8a6"

key.public_hex ## public key
=> "04641129e66399310ce4a41098d3b3fc4d722edf423dfdc0a76eba5d6e2155bbe611ee2a5c06011ab76040ca53b9ead4c5061d8cc8a89afa3f45af5830661d4b34"

key.bech32_address  ## bech32 address ,default "atp"
=> "atp1ls87d3mqfhxadjsmn0ns844tj8ljlsq89k95cn" 

key.bech32_address(hrp: "lat") 
=> "lat1ls87d3mqfhxadjsmn0ns844tj8ljlsq8uqnv8u"

key.address ## EIP55 checksummed address
=> "0xFc0Fe6c7604dcDd6ca1B9be703D6AB91fF2fC007"
```

将key加密保存至json文件

```ruby
## default address hrp:"lat"
encrypted_key_info = Platon::Key.encrypt key,"your_password"

## set address hrp

encrypted_key_info = Platon::Key.encrypt key,"your_password",{hrp:"atp"}

## or save to location

Platon::Key.encrypt_and_save key,"your_password",{hrp:"atp",keypath:'./some/path.json'}

## or default keypath: "~/.platon/keystore" ,and use default hrp:"lat"

Platon::Key.encrypt_and_save key,"your_password" 

```

从json文件解密

```ruby
decrypted_key = Platon::Key.decrypt encrypted_key_info,"your_password"

or

decrypted_key = Platon::Key.decrypt File.read('./some/path.json'), 'your_password'
```

#### Client

建立http client 用于Contract 与 PPOS 方法调用。需要传入 PlatON Node地址及指定网络

```ruby
client = Platon::HttpClient.new("http://127.0.0.1:6789",:alayadev)
```

传入网络，会使用一下参数:
```ruby
    platondev: {hrp: "lat", chain_id: 210309}
    alaya:{hrp:"atp",chain_id:201018} 
    alayadev:{hrp:"atp",chain_id: 201030}
```

你可以通过 `client.update_setting` 来自定义hrp及chain_id:

```ruby
client.update_setting(hrp:"atx",chain_id: 1234)
```

#### Transactions

构建一笔交易 :

```ruby
args = { 
    from: key.address,
    to: key2.address,
    value: 1_000_000_000_000,
    data: hex_data,  
    nonce: 1,
    gas_limit: 21_000,
    gas_price: 10_000_000_000,
    chain_id: chain_id
}
tx = Platon::Tx.new args
```

或者从raw transaction中进行解密

```ruby
tx = Platon::Tx.decode hex
```

使用指定key进行签名及广播

```ruby
tx.sign key
client.platon_send_raw_transaction(tx.hex)
```

通过 `tx.hex`查看交易的raw transaction, 通过 `platon_send_raw_transaction` 广播至区块链网络. 通过 `tx.hash` 可查看txid


#### Contracts

可通过链上已部署合约来获得Contract实例，需要传入合约名、合约地址及abi文件

```ruby
contract = Platon::Contract.create(client: client ,name: "MyContract", address: "atpxxxx_your_bench32_address", abi: abi)
```

或者可直接通过传入合约源代码获取Contract实例：

```ruby
contract = Platon::Contract.create(client: client , file: "MyContract.sol", address: "atpxxxx_your_bench32_address")
```

#### 合约调用



对于合约的只读方法，使用 `call` 进行调用 , 该方法不会向链上发送任何transaction. 对于可能改变合约状态的方法，需要通过`transact` 或 `transact_and_wait` 进行调用 .

```ruby
contract.call.[function_name](params)

contract.transact.[function_name](params)

contract.transact_and_wait.[function_name](params)  
```

#### PPOS

我们实现了所有的系统合约PPOS的调用，详见下述文档。

#### Utils

```ruby
Platon::Utils.is_bech32_address?("atp1tfm3e44jwdjmelcc9yacus700wcts0zhgw6425")
=> true

Platon::Utils.decode_bech32_address "atp1tfm3e44jwdjmelcc9yacus700wcts0zhgw6425"
=> "0x5a771cd6b27365bcff18293b8e43cf7bb0b83c57"

Platon::Utils.to_bech32_address("atp","0x5a771cd6b27365bcff18293b8e43cf7bb0b83c57")
=>"atp1tfm3e44jwdjmelcc9yacus700wcts0zhgw6425"

Platon::Formatter.new.to_von(0.5)
=> 500000000000000000

Platon::Formatter.new.to_gvon(10)
=> 10000000000

Platon::Formatter.new.from_von(500000000000000000)
=> "0.5"
```


## 基础RPC接口
基础API包括网络、交易、查询、节点信息、经济模型参数配置等相关的接口，具体说明如下。

### web3_client_version
返回当前客户端版本

* 参数:
    
    无
* 返回值
    `String`: 当前版本号
* 示例

```ruby
client = Platon::HttpClient.new("http://127.0.0.1:6789",:alayadev)
client.web3_client_version
=> "PlatONnetwork/alaya-node/v0.15.0-unstable-9867ee68/linux-amd64/go1.13.4"
```

### web3_sha3
返回给定数据的keccak-256（并非标准sha3-256）

* 参数
    
    `String`:待转换的哈希值
* 返回值
    `String`:sha3计算结果
    
* 示例

```ruby
client = Platon::HttpClient.new("http://127.0.0.1:6789",:alayadev)
client.web3_sha3("0x68656c6c6f20776f726c64")
=> "0x47173285a8d7341e5e972fc677286384f802f8ef42a5ec5f03bbfa254cb01fad"
```

### net_listening
如果客户端正活跃监听网络链接，则返回true

* 参数
    无
* 返回值
    `Boolean`: 正在监听返回true,否则返回false
* 示例


```ruby
client = Platon::HttpClient.new("http://127.0.0.1:6789",:alayadev)
client.net_listening
=> true
```

### net_peer_count
查看当前客户端所连接的节点数

* 参数
    无
* 返回值
    `Integer`: 返回当前客户端链接的节点数
* 示例

```ruby
client = Platon::HttpClient.new("http://127.0.0.1:6789",:alayadev)
client.net_peer_count
 => 24
```

### platon_protocol_version
查询

* 参数
    无
* 返回值
    `Integer`: 返回当前Platon协议版本
* 示例

```ruby
client = Platon::HttpClient.new("http://127.0.0.1:6789",:alayadev)
client.platon_protocol_version
 => 63
```

### platon_syncing
查询当前节点的同步状态

* 参数
    无
* 返回值
    `Object | Boolean`: 返回当前同步的状态，或返回 `false`，当没在同步时:
    `startingBlock`:`QUANTITY` - 起始区块
    `currentBlock` :`QUANTITI` - 当前区块，与 platon_block_number 相同
    `highestBlock` :`QUANTITY` - 估计最高的区块
* 示例

```ruby
client = Platon::HttpClient.new("http://127.0.0.1:6789",:alayadev)
client.platon_syncing
### syncing
=>{
    startingBlock: '0x384',
    currentBlock: '0x386',
    highestBlock: '0x454'
  }
### or when not syncing 
=> false
```

### platon_gas_price
返回当前gas价格
* 参数
    无
* 返回值
    ```Integer```: 当前gas价格，单位为von
* 示例

```ruby
client = Platon::HttpClient.new("http://127.0.0.1:6789",:alayadev)
client.platon_gas_price
=> 1000000000
```

### platon_accounts
返回客户端拥有的platon账户

* 参数
    无
* 返回值
    `Array`: 客户端拥有的platon账户
* 示例

```ruby
client = Platon::HttpClient.new("http://127.0.0.1:6789",:alayadev)
client.platon_accounts
=>[]
```

### platon_block_number
返回区块链上最新区块

* 参数
    无
* 返回值
    `Integer`: 客户端中监听到的链上最新区块
* 示例

```ruby
client = Platon::HttpClient.new("http://127.0.0.1:6789",:alayadev)
client.platon_block_number
=> => 10513205
```

### platon_get_balance

查询账户余额

* 参数
    * `String` 待查询地址,bech32
    * `Integer | String` :可传递区块号 或 "lastest", "earliest","pending"。详见默认区块参数 [默认区块参数说明](#默认区块参数说明)。
* 返回值
    * `Integer`: 账户余额（von）
* 示例

```ruby
client = Platon::HttpClient.new("http://127.0.0.1:6789",:alayadev)
client.platon_get_balance("atp12kwg77yu4aqf0xmjgdysrkjzqnapt3wasvnpne","latest")
=> 28907596000000000

client.platon_get_balance("atp12kwg77yu4aqf0xmjgdysrkjzqnapt3wasvnpne", 10713205)
=> 28907596000000000
```

### platon_get_storage_at
* 参数
    * `String` 待查询地址，bech32
    * `String` hex string ,存储的位置
    * `String` "lastest", "earliest","pending"。详见默认区块参数 [默认区块参数说明](#默认区块参数说明)
* 返回值
    * `String` 该存储位置的值
* 示例

```ruby
client = Platon::HttpClient.new("http://127.0.0.1:6789",:alayadev)
client.platon_get_storage_at("atp12kwg77yu4aqf0xmjgdysrkjzqnapt3wasvnpne","0x2","latest")
=> "0x"
```

### platon_get_transaction_count
返回地址发起的交易数量

* 参数
 
    * `String` 待查询地址,bech32 address
    * `Integer | String` :可传递区块号 或 "lastest", "earliest","pending"。详见默认区块参数 [默认区块参数说明](#默认区块参数说明)。
* 返回值
    * `Integer`: 返回该地址发起的交易数量
* 示例

```ruby
client = Platon::HttpClient.new("http://127.0.0.1:6789",:alayadev)
client.platon_get_transaction_count("atp12kwg77yu4aqf0xmjgdysrkjzqnapt3wasvnpne","latest")
=> 50
```

### platon_get_block_transaction_count_by_hash
根据区块哈希值查询交易数量

* 参数

    * `String` 待查询的区块哈希值
* 返回值

    * `Integer` 返回该区块中交易数
* 示例

```ruby
client = Platon::HttpClient.new("http://127.0.0.1:6789",:alayadev)
client.platon_get_block_transaction_count_by_hash("0xd2dede658ef3ec62336b5cd3b6d62997d5a025edb48860c1ec84bd186f8225b8")
=> 1
```


### platon_get_block_transaction_count_by_number
根据区块高度查询交易数量

* 参数

    * `Integer`: 待查询的区块高度
* 返回值
    
    * `Integer`: 返回该区块中的交易数
* 示例

```ruby
client = Platon::HttpClient.new("http://127.0.0.1:6789",:alayadev)
client.platon_get_block_transaction_count_by_number(10805358)
=> 1
```

### platon_get_code
返回指定地址的code

* 参数

    * `String`: 待查询的地址 bech32 address
    * `Integer | String` :可传递区块号 或 "lastest", "earliest","pending"。详见默认区块参数 [默认区块参数说明](#默认区块参数说明)。
* 返回值

    `String`: 该地址的code
* 示例

```ruby
client = Platon::HttpClient.new("http://127.0.0.1:6789",:alayadev)
client.platon_get_code("atp1cay80hvyqpmt65wsn6nwng048q88jcg2jlf3sv","latest")
=> "0x608060405260...
```

### platon_sign

使用某给定账号对data进行签名,注意：该地址需要提前解锁

* 参数

    * `String`: 指定签名的bench32地址
    * `String`: 待签名的信息，需要为0x开头的hex字符串
* 返回值

    * `String`: 已签名数据
* 示例

```ruby
client = Platon::HttpClient.new("http://127.0.0.1:6789",:alayadev)
client.platon_sign("atp1zdpu5f55gxurfzgkn8tgc7pwwl34jquf5twpyn","0x1234")
=> "0x1d39459e2050493f89ec0aa09112bce7a08a9774d054fc71159e2435961ef1732862145cd0cedd1859bfd8698044c2a0963262b75aeb187650f4ca4f8b5b754c1b"
```

### platon_send_transaction
发送服务待签名交易

* 参数

    * `Object`: Transaction 交易结构
        * `String`: from ，交易发送地址
        * `String`: to , 交易接收地址
        * `Integer`: gas, 本次交易gas用量上限
        * `Integer`: gasPrice, gas价格
        * `Integer`: value,转账金额
        * `String`: data, 上链数据，合约的已编译代码或调用的方法的签名与编码参数的哈希
        * `Integer`: nonce, 交易nonce值
* 返回值

    `String`: 32Bytes 的已签名字符串 或 如果交易不可用返回zero hash
* 示例

```ruby
client = Platon::HttpClient.new("http://127.0.0.1:6789",:alayadev)
client.platon_send_transaction({
    "from": "atp1zdpu5f55gxurfzgkn8tgc7pwwl34jquf5twpyn",
    "to": "atp1h5dx7v9qgf40mctz5cm76kl4ap5lmau759ap70",
    "gas": "0x76c0", # 30400,
    "gasPrice": "0x9184e72a000", # 10000000000000
    "value": "0x9184e72a", # 2441406250
    "data": "0xd46e8dd67c5d32be8d46e8dd67c5d32be8058bb8eb970870f072445675058bb8eb970870f072445675"
    })
=> "0xe670ec64341771606e55d6b4ca35a1a6b75ee3d5145a99d05921026d1527331"
```

### platon_send_raw_transaction
创建一个新的消息调用交易，或对于已签名交易做合约创建

* 参数

    * `Object`: Transaction 交易结构
    * `String`: data 已签名交易
* 返回值

    * `String`: 32Bytes 的已签名字符串 或 如果交易不可用返回zero hash
```
params: ["0xd46e8dd67c5d32be8d46e8dd67c5d32be8058bb8eb970870f072445675058bb8eb970870f072445675"]
```
* 示例

```ruby
client = Platon::HttpClient.new("http://127.0.0.1:6789",:alayadev)
client.platon_send_raw_transaction(["0xd46e8dd67c5d32be8d46e8dd67c5d32be8058bb8eb970870f072445675058bb8eb970870f072445675"])
```

### platon_call
执行一个消息调用交易，消息调用交易直接在节点旳执行而不需要通过区块链的挖矿来执行

* 参数

    * `Object`: Transaction 交易结构
        * `String`: from ，交易发送地址
        * `String`: to , 交易接收地址
        * `Integer`: gas, 本次交易gas用量上限
        * `Integer`: gasPrice, gas价格
        * `Integer`: value,转账金额
        * `String`: data, 上链数据，合约的已编译代码或调用的方法的签名与编码参数的哈希
        * `Integer | String` :可传递区块号 或 "lastest", "earliest","pending"。详见默认区块参数 [默认区块参数说明](#默认区块参数说明)。
* 返回值

    * 执行合约的返回值
* 示例

```ruby
client = Platon::HttpClient.new("http://127.0.0.1:6789",:alayadev)
client.platon_call({
    "from": "atp1zdpu5f55gxurfzgkn8tgc7pwwl34jquf5twpyn",
    "to": "atp1h5dx7v9qgf40mctz5cm76kl4ap5lmau759ap70",
    "gas": "0x76c0", # 30400,
    "gasPrice": "0x9184e72a000", # 10000000000000
    "value": "0x9184e72a", # 2441406250
    "data": "0xd46e8dd67c5d32be8d46e8dd67c5d32be8058bb8eb970870f072445675058bb8eb970870f072445675"
    },"latest")
=> "0xe670ec64341771606e55d6b4ca35a1a6b75ee3d5145a99d05921026d1527331"
```

### platon_estimate_gas
生成并返回完成交易所需的gas估算值。 交易将不会添加到区块链中。 注:由于各种原因（包括EVM机制和节点性能），估算值可能大大超过交易实际使用的gas

* 参数

    * `Object`: Transaction 交易结构
    * `String`: from ，交易发送地址
    * `String`: to , 交易接收地址
    * `Integer`: gas, 本次交易gas用量上限
    * `Integer`: gasPrice, gas价格
    * `Integer`: value,转账金额
    * `String`: data, 上链数据，合约的已编译代码或调用的方法的签名与编码参数的哈希
    * `Integer | String` :可传递区块号 或 "lastest", "earliest","pending"。详见默认区块参数 [默认区块参数说明](#默认区块参数说明)。
* 返回值

    * `Integer`: 评估的gas使用值
* 示例

```ruby
client = Platon::HttpClient.new("http://127.0.0.1:6789",:alayadev)
client.platon_estimate_gas({
    "from": "atp1zdpu5f55gxurfzgkn8tgc7pwwl34jquf5twpyn",
    "to": "atp1h5dx7v9qgf40mctz5cm76kl4ap5lmau759ap70",
    "gasPrice": "0x9184e72a000", # 10000000000000
    "value": "0x9184e72a", # 2441406250
    "data": "0xd46e8dd67c5d32be8d46e8dd67c5d32be8058bb8eb970870f072445675058bb8eb970870f072445675"
    })
=> 21000
```

### platon_get_block_by_hash
通过交易hash查询block

* 参数

    * `String`: 32Bytes 区块哈希值
    * `Boolean`: true 返回区块全量信息，false 只返回交易的hash值
* 返回值
    * `Object`: 区块的结构，或如果未找到返回 `nil`
* 示例

```ruby
client = Platon::HttpClient.new("http://127.0.0.1:6789",:alayadev)
client.platon_get_block_by_hash("0xf71f0868b162b5b6d8240d44790a9cf4159add927c880218c9a17cb590bd6ea7",false)
=> {"extraData"=>"0xd9820f0086706c61746f6e88676f312e31332e34856c696e7578000000000000d0ce481ee2aeca0cc474c03882afa2bb25968d025f63ee9b114df8965bb8efd11557c936950c4b40cc1ce540bc98e117df88f4f0f08081cbfbabd2e614fcd7e800", "gasLimit"=>"0x8fcf88", "gasUsed"=>"0x8a34", "hash"=>"0xf71f0868b162b5b6d8240d44790a9cf4159add927c880218c9a17cb590bd6ea7", "logsBloom"=>"0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000020000000000000000000400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000", "miner"=>"atp1vthcqh8cvl5lcz98zeh53r5mtjp89ulma9ghnd", "nonce"=>"0x037185230d3468bb10d034e1679330d7bc6fdc8cc4d61b5f0892148e81b14dfd8ba9ec00f52ebc67bfd58195ef8da0fb85ba82707fc90f379e5802c56f8b5e1dd0fb4f1cbb796b4e78de9d2813217c5476", "number"=>"0xa80ea9", "parentHash"=>"0x032bbd2d3f940b130bf79fe228ba2ec323cf3695f163a1aa0a57dec33fb67afb", "receiptsRoot"=>"0x9bc39b40af8267744a06a5060335eeaf8e2854244c710cdcc81d8768acc0654c", "size"=>"0x355", "stateRoot"=>"0x10475ff8bcfa50364e33883a2a6b0e92b12acf9727c703fe9d84078ad497cab0", "timestamp"=>"0x177ff4bfd89", "transactions"=>["0x11b3640628b0a8b28fa9e7aa20f70962b9dd6eecc9d8c8521af3f4898cc3b88c"], "transactionsRoot"=>"0x2c3e9057fe0bf02fc2dc09580eb11a678cd39893e0341722bb07ed53a9f89d88"}
```

### platon_get_block_by_number
通过区块高度返回区块信息

* 参数

    * `Integer | String` :可传递区块号 或 "lastest", "earliest","pending"。详见默认区块参数 [默认区块参数说明](#默认区块参数说明)。
    * `Boolean`: true 返回区块全量信息，false 只返回交易的hash值
* 返回值

    * `Object`: 区块的结构，或如果未找到返回 `nil`
* 示例

```ruby
client = Platon::HttpClient.new("http://127.0.0.1:6789",:alayadev)
client.platon_get_block_by_number(11013801,false)
=> {"extraData"=>"0xd9820f0086706c61746f6e88676f312e31332e34856c696e7578000000000000d0ce481ee2aeca0cc474c03882afa2bb25968d025f63ee9b114df8965bb8efd11557c936950c4b40cc1ce540bc98e117df88f4f0f08081cbfbabd2e614fcd7e800", "gasLimit"=>"0x8fcf88", "gasUsed"=>"0x8a34", "hash"=>"0xf71f0868b162b5b6d8240d44790a9cf4159add927c880218c9a17cb590bd6ea7", "logsBloom"=>"0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000020000000000000000000400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000", "miner"=>"atp1vthcqh8cvl5lcz98zeh53r5mtjp89ulma9ghnd", "nonce"=>"0x037185230d3468bb10d034e1679330d7bc6fdc8cc4d61b5f0892148e81b14dfd8ba9ec00f52ebc67bfd58195ef8da0fb85ba82707fc90f379e5802c56f8b5e1dd0fb4f1cbb796b4e78de9d2813217c5476", "number"=>"0xa80ea9", "parentHash"=>"0x032bbd2d3f940b130bf79fe228ba2ec323cf3695f163a1aa0a57dec33fb67afb", "receiptsRoot"=>"0x9bc39b40af8267744a06a5060335eeaf8e2854244c710cdcc81d8768acc0654c", "size"=>"0x355", "stateRoot"=>"0x10475ff8bcfa50364e33883a2a6b0e92b12acf9727c703fe9d84078ad497cab0", "timestamp"=>"0x177ff4bfd89", "transactions"=>["0x11b3640628b0a8b28fa9e7aa20f70962b9dd6eecc9d8c8521af3f4898cc3b88c"], "transactionsRoot"=>"0x2c3e9057fe0bf02fc2dc09580eb11a678cd39893e0341722bb07ed53a9f89d88"}
```

### platon_get_transaction_by_hash
通过指定交易hash查询交易内容

* 参数

    `String`: 32Bytes 交易hash值
* 返回值

    `Object`: 交易object， 或未找到时返回 `nil`
* 示例

```ruby
client = Platon::HttpClient.new("http://127.0.0.1:6789",:alayadev)
client = Platon::HttpClient.new("http://127.0.0.1:6789",:alayadev)
client.platon_get_transaction_by_hash("0x11b3640628b0a8b28fa9e7aa20f70962b9dd6eecc9d8c8521af3f4898cc3b88c")
=> {"blockHash"=>"0xf71f0868b162b5b6d8240d44790a9cf4159add927c880218c9a17cb590bd6ea7", "blockNumber"=>"0xa80ea9", "from"=>"atp196439hyj6mwnr23876cu59wfjaga2wntr36wz0", "gas"=>"0x186a0", "gasPrice"=>"0x1dcd65000", "hash"=>"0x11b3640628b0a8b28fa9e7aa20f70962b9dd6eecc9d8c8521af3f4898cc3b88c", "input"=>"0xc483821388", "nonce"=>"0xc48", "to"=>"atp1zqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqxxwje8t", "transactionIndex"=>"0x0", "value"=>"0x0", "v"=>"0x62298", "r"=>"0xe79901088b2d0825b2b333b587562d980fd1d7fe1053de5992ee3449ddf7276d", "s"=>"0x467bee5c4372f718de469f6e64a0927e95641ff585f01243b47f65407db4097e"}
```

### platon_get_transaction_by_block_hash_and_index
通过指定区块hash与交易index position 查询交易

* 参数

    * `String`: 32Bytes, 区块hash
    * `Integer`: 交易的索引位置
* 返回值

    `Object`: 交易object， 或未找到时返回 `nil`
* 示例

```ruby
client = Platon::HttpClient.new("http://127.0.0.1:6789",:alayadev)
client.platon_get_transaction_by_block_hash_and_index("0xf71f0868b162b5b6d8240d44790a9cf4159add927c880218c9a17cb590bd6ea7",0)
 => {"blockHash"=>"0xf71f0868b162b5b6d8240d44790a9cf4159add927c880218c9a17cb590bd6ea7", "blockNumber"=>"0xa80ea9", "from"=>"atp196439hyj6mwnr23876cu59wfjaga2wntr36wz0", "gas"=>"0x186a0", "gasPrice"=>"0x1dcd65000", "hash"=>"0x11b3640628b0a8b28fa9e7aa20f70962b9dd6eecc9d8c8521af3f4898cc3b88c", "input"=>"0xc483821388", "nonce"=>"0xc48", "to"=>"atp1zqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqxxwje8t", "transactionIndex"=>"0x0", "value"=>"0x0", "v"=>"0x62298", "r"=>"0xe79901088b2d0825b2b333b587562d980fd1d7fe1053de5992ee3449ddf7276d", "s"=>"0x467bee5c4372f718de469f6e64a0927e95641ff585f01243b47f65407db4097e"}
```


### platon_get_transaction_by_block_number_and_index
通过区块高度及交易在区块中位置查询交易信息

* 参数

    * `Integer | String` :可传递区块号 或 "lastest", "earliest","pending"。详见默认区块参数 [默认区块参数说明](#默认区块参数说明)。
    * `Integer`: 交易的索引位置
* 返回值

    `Object`: Transaction object
* 示例

```ruby
client = Platon::HttpClient.new("http://127.0.0.1:6789",:alayadev)
client.platon_get_transaction_by_block_number_and_index(11013801,0)
 => {"blockHash"=>"0xf71f0868b162b5b6d8240d44790a9cf4159add927c880218c9a17cb590bd6ea7", "blockNumber"=>"0xa80ea9", "from"=>"atp196439hyj6mwnr23876cu59wfjaga2wntr36wz0", "gas"=>"0x186a0", "gasPrice"=>"0x1dcd65000", "hash"=>"0x11b3640628b0a8b28fa9e7aa20f70962b9dd6eecc9d8c8521af3f4898cc3b88c", "input"=>"0xc483821388", "nonce"=>"0xc48", "to"=>"atp1zqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqxxwje8t", "transactionIndex"=>"0x0", "value"=>"0x0", "v"=>"0x62298", "r"=>"0xe79901088b2d0825b2b333b587562d980fd1d7fe1053de5992ee3449ddf7276d", "s"=>"0x467bee5c4372f718de469f6e64a0927e95641ff585f01243b47f65407db4097e"}
```


###platon_get_transaction_receipt
根据交易hash返回交易回执

* 参数

    * `String`: 32Bytes ,交易哈希值
* 返回值

    * `Object`: Transaction Receipt Object, 未找到回执时返回nil
* 示例

```ruby
client = Platon::HttpClient.new("http://127.0.0.1:6789",:alayadev)
 client.platon_get_transaction_receipt("0x11b3640628b0a8b28fa9e7aa20f70962b9dd6eecc9d8c8521af3f4898cc3b88c")
 => {"blockHash"=>"0xf71f0868b162b5b6d8240d44790a9cf4159add927c880218c9a17cb590bd6ea7", "blockNumber"=>"0xa80ea9", "contractAddress"=>nil, "cumulativeGasUsed"=>"0x8a34", "from"=>"atp196439hyj6mwnr23876cu59wfjaga2wntr36wz0", "gasUsed"=>"0x8a34", "logs"=>[{"address"=>"atp1zqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqxxwje8t", "topics"=>[], "data"=>"0xf8f830b8f5f8f3f84fb84088e70a87f6acc8edf3b381c02f3c3317392e458af688920bbfe04e3694979847e25d59fb7fe2c1d3487f1ae5a7876fbcefabe06f722dfa28a83f3ca4853c42548307a2f5880518bc6e5f2b8cb4f84fb8409460fce5beea98e4d56c62a920bb041f45e48a5a7b96d12d02a16cbb20863be9c76491127533d9cefa5b4cec48ae6595b7ba347ef7dc8277cfb343eebde4646b8307a2f488060ff2b59a3ef16bf84fb840ab74f5500dd35497ce09b2dc92a3da26ea371dd9f6d438559b6e19c8f1622ee630951b510cb370aca8267f9bb9a9108bc532ec48dd077474cb79a48122f2ab038307bd438806d8e64037faad55", "blockNumber"=>"0xa80ea9", "transactionHash"=>"0x11b3640628b0a8b28fa9e7aa20f70962b9dd6eecc9d8c8521af3f4898cc3b88c", "transactionIndex"=>"0x0", "blockHash"=>"0xf71f0868b162b5b6d8240d44790a9cf4159add927c880218c9a17cb590bd6ea7", "logIndex"=>"0x0", "removed"=>false}], "logsBloom"=>"0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000020000000000000000000400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000", "status"=>"0x1", "to"=>"atp1zqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqxxwje8t", "transactionHash"=>"0x11b3640628b0a8b28fa9e7aa20f70962b9dd6eecc9d8c8521af3f4898cc3b88c", "transactionIndex"=>"0x0"}

```


### platon_evidences
返回双签证据

* 参数

    无
* 返回值

    * `String`: 证据字符串包含三种类型的证据：duplicatePrepare，duplicateVote，duplicateViewchange。 每种类型都包含多个证据，因此它是一个数组结构。 解析时请注意。
        * duplicatePrepare

        ```ruby
            {
              "prepareA": {
                "epoch": 0,            //共识轮epoch值
                "viewNumber": 0,       //共识轮view值
                "blockHash": "0x06abdbaf7a0a5cb1deddf69de5b23d6bc3506fdadbdcfc32333a1220da1361ba",    //区块hash
                "blockNumber": 16013,       //区块number
                "blockIndex": 0,        //区块在一轮view中的索引值
                "blockData": "0xe1a507a57c1e9d8cade361fefa725d7a271869aea7fd923165c872e7c0c2b3f2",     //区块rlp编码值
                "validateNode": {            
                  "index": 0,     //验证人在一轮epoch中的索引值
                  "address": "0xc30671be006dcbfd6d36bdf0dfdf95c62c23fad4",    //验证人地址
                  "nodeId": "19f1c9aa5140bd1304a3260de640a521c33015da86b88cd2ecc83339b558a4d4afa4bd0555d3fa16ae43043aeb4fbd32c92b34de1af437811de51d966dc64365",    //验证人nodeID
                  "blsPubKey": "f93a2381b4cbb719a83d80a4feb93663c7aa026c99f64704d6cc464ae1239d3486d0cf6e0b257ac02d5dd3f5b4389907e9d1d5b434d784bfd7b89e0822148c7f5b8e1d90057a5bbf4a0abf88bbb12902b32c94ca390a2e16eea8132bf8c2ed8f"    //验证人bls公钥
                },
                "signature": "0x1afdf43596e07d0f5b59ae8f45d30d21a9c5ac793071bfb6382ae151081a901fd3215e0b9645040c9071d0be08eb200900000000000000000000000000000000"     //消息签名
              },
              "prepareB": {
                "epoch": 0,
                "viewNumber": 0,
                "blockHash": "0x74e3744545e95f4defc82d731504a39994b8013575491f83f7520cf796347b8f",
                "blockNumber": 16013,
                "blockIndex": 0,
                "blockData": "0xb11be0a3634e29281403d690c1a0bc38e96ea34b3aea0b0da2883800f610c3b7",
                "validateNode": {
                  "index": 0,
                  "address": "0xc30671be006dcbfd6d36bdf0dfdf95c62c23fad4",
                  "nodeId": "19f1c9aa5140bd1304a3260de640a521c33015da86b88cd2ecc83339b558a4d4afa4bd0555d3fa16ae43043aeb4fbd32c92b34de1af437811de51d966dc64365",
                  "blsPubKey": "f93a2381b4cbb719a83d80a4feb93663c7aa026c99f64704d6cc464ae1239d3486d0cf6e0b257ac02d5dd3f5b4389907e9d1d5b434d784bfd7b89e0822148c7f5b8e1d90057a5bbf4a0abf88bbb12902b32c94ca390a2e16eea8132bf8c2ed8f"
                },
                "signature": "0x16795379ca8e28953e74b23d1c384dda760579ad70c5e490225403664a8d4490cabb1dc64a2e0967b5f0c1e9dbd6578c00000000000000000000000000000000"
              }
            }
        ```
        
        * duplicateVote
        
        ```ruby
            {
              "voteA": {
                "epoch": 0,   //共识轮epoch值
                "viewNumber": 0,    //共识轮view值
                "blockHash": "0x58b5976a471f86c4bd198984827bd594dce6ac861ef15bbbb1555e7b2edc2fc9",   //区块hash
                "blockNumber": 16013,   //区块number
                "blockIndex": 0,    //区块在一轮view中的索引值
                "validateNode": { 
                  "index": 0,    //验证人在一轮epoch中的索引值
                  "address": "0xc30671be006dcbfd6d36bdf0dfdf95c62c23fad4",  //验证人地址
                  "nodeId": "19f1c9aa5140bd1304a3260de640a521c33015da86b88cd2ecc83339b558a4d4afa4bd0555d3fa16ae43043aeb4fbd32c92b34de1af437811de51d966dc64365",   //验证人nodeID
                  "blsPubKey": "f93a2381b4cbb719a83d80a4feb93663c7aa026c99f64704d6cc464ae1239d3486d0cf6e0b257ac02d5dd3f5b4389907e9d1d5b434d784bfd7b89e0822148c7f5b8e1d90057a5bbf4a0abf88bbb12902b32c94ca390a2e16eea8132bf8c2ed8f"    //验证人bls公钥
                },
                "signature": "0x071350aed09f226e218715357ffb7523ba41271dd1d82d4dded451ee6509cd71f6888263b0b14bdfb33f88c04f76790d00000000000000000000000000000000"    //消息签名
              },
              "voteB": {
                "epoch": 0,
                "viewNumber": 0,
                "blockHash": "0x422515ca50b9aa01c46dffee53f3bef0ef29884bfd014c3b6170c05d5cf67696",
                "blockNumber": 16013,
                "blockIndex": 0,
                "validateNode": {
                  "index": 0,
                  "address": "0xc30671be006dcbfd6d36bdf0dfdf95c62c23fad4",
                  "nodeId": "19f1c9aa5140bd1304a3260de640a521c33015da86b88cd2ecc83339b558a4d4afa4bd0555d3fa16ae43043aeb4fbd32c92b34de1af437811de51d966dc64365",
                  "blsPubKey": "f93a2381b4cbb719a83d80a4feb93663c7aa026c99f64704d6cc464ae1239d3486d0cf6e0b257ac02d5dd3f5b4389907e9d1d5b434d784bfd7b89e0822148c7f5b8e1d90057a5bbf4a0abf88bbb12902b32c94ca390a2e16eea8132bf8c2ed8f"
                },
                "signature": "0x9bf6c01643058c0c828c35dc3277666edd087cb439c5f6a78ba065d619f812fb42c5ee881400a7a42dd8366bc0c5c88100000000000000000000000000000000"
              }
            }
        ```
        
        * duplicateViewchange
        
        ```ruby
            {
              "viewA": {
                "epoch": 0,  
                "viewNumber": 0, 
                "blockHash": "0xb84a40bb954e579716e7a6b9021618f6b25cdb0e0dd3d8c2c0419fe835640f36",  //区块hash
                "blockNumber": 16013, 
                "validateNode": {
                  "index": 0,  
                  "address": "0xc30671be006dcbfd6d36bdf0dfdf95c62c23fad4", 
                  "nodeId": "19f1c9aa5140bd1304a3260de640a521c33015da86b88cd2ecc83339b558a4d4afa4bd0555d3fa16ae43043aeb4fbd32c92b34de1af437811de51d966dc64365",
                  "blsPubKey": "f93a2381b4cbb719a83d80a4feb93663c7aa026c99f64704d6cc464ae1239d3486d0cf6e0b257ac02d5dd3f5b4389907e9d1d5b434d784bfd7b89e0822148c7f5b8e1d90057a5bbf4a0abf88bbb12902b32c94ca390a2e16eea8132bf8c2ed8f"
                },
                "signature": "0x9c8ba2654c6b8334b1b94d3b421c5901242973afcb9d87c4ab6d82c2aee8e212a08f2ae000c9203f05f414ca578cda9000000000000000000000000000000000",
                "blockEpoch": 0,
                "blockView": 0
              },
              "viewB": {
                "epoch": 0,
                "viewNumber": 0,
                "blockHash": "0x2a60ed6f04ccb9e468fbbfdda98b535653c42a16f1d7ccdfbd5d73ae1a2f4bf1",
                "blockNumber": 16013,
                "validateNode": {
                  "index": 0,
                  "address": "0xc30671be006dcbfd6d36bdf0dfdf95c62c23fad4",
                  "nodeId": "19f1c9aa5140bd1304a3260de640a521c33015da86b88cd2ecc83339b558a4d4afa4bd0555d3fa16ae43043aeb4fbd32c92b34de1af437811de51d966dc64365",
                  "blsPubKey": "f93a2381b4cbb719a83d80a4feb93663c7aa026c99f64704d6cc464ae1239d3486d0cf6e0b257ac02d5dd3f5b4389907e9d1d5b434d784bfd7b89e0822148c7f5b8e1d90057a5bbf4a0abf88bbb12902b32c94ca390a2e16eea8132bf8c2ed8f"
                },
                "signature": "0xed69663fb943ce0e0dd90df1b65e96514051e82df48b3867516cc7e505234b9ca707fe43651870d9141354a7a993e09000000000000000000000000000000000",
                "blockEpoch": 0,
                "blockView": 0
              }
            }
        
        ```

* 示例

```ruby
client = Platon::HttpClient.new("http://127.0.0.1:6789",:alayadev)
client.platon_evidences
=> "{}"  ## 暂无的状态
```



### admin_node_info
查看当前节点详情

* 参数

    无
* 返回值

    `Object`: 当前节点详情
* 示例

```ruby
client = Platon::HttpClient.new("http://127.0.0.1:6789",:alayadev)
client.admin_node_info
=> {node information } #略
```

### admin_peers

查看当前节点所连接的节点信息
* 参数

    无
* 返回值

    `Array`: 已连接的节点信息
* 示例

```ruby
client = Platon::HttpClient.new("http://127.0.0.1:6789",:alayadev)
client.admin_peers
=> [{Node 1 information} ,  {Node 2 information}, ..., {node information N}] # 略
```

### admin_get_program_version

查询code版本及签名

* 参数

    无
* 返回值

    `Object`: 包含两部分内容，版本与签名
* 示例

```ruby
client = Platon::HttpClient.new("http://127.0.0.1:6789",:alayadev)
client. admin_get_program_version
=>{"Version"=>3840, "Sign"=>"0x169237f89092ad73f1db8dbb58703e59fe07e2ee5ce60aed16ff20c6313d800006b586ac074e03d7616664ee2c934bf5d2496dd4bd1592dae6c31a90641fbaaa00"}
```

### admin_get_schnorr_NIZK_Prove
返回BLS证明

* 参数

    无
* 返回值

    `String`: BLS证明
* 示例

```ruby
client = Platon::HttpClient.new("http://127.0.0.1:6789",:alayadev)
client.admin_get_schnorr_nizk_prove
=> "98d139a10b5e0d4d0968da2ed7d49cb654fcd3b19fd1cd88f6413480e88eb557ad66487ed9e97fe28a868e7da77e91d061df9996b4a1f1d675c415a962764770"
```

### admin_datadir
返回数据存储路径

* 参数

    无
* 返回值

    `String`: 数据路径
* 示例

```ruby
client = Platon::HttpClient.new("http://127.0.0.1:6789",:alayadev)
client.admin_datadir
=> "/home/ubuntu/platon-node/data"
```




## 钱包&转账接口

### keys创建 & 地址转换
创建一组新的public/private key并得到 bech32 地址

```ruby
key = Platon::Key.new
key.private_hex ## 私钥
=> "08bb093d6184cb06a3f80507953ba6768c03d8114a429b0ec7875bb6b6e1a8a6"

key.public_hex ## 公钥
=> "04641129e66399310ce4a41098d3b3fc4d722edf423dfdc0a76eba5d6e2155bbe611ee2a5c06011ab76040ca53b9ead4c5061d8cc8a89afa3f45af5830661d4b34"

key.address
=> "0xFc0Fe6c7604dcDd6ca1B9be703D6AB91fF2fC007"

key.bech32_address  ## bech32 格式公钥 ,默认是 "lat"
=> "lat1ls87d3mqfhxadjsmn0ns844tj8ljlsq8uqnv8u" 

key.bech32_address(hrp: "atp") 
=> "atp1ls87d3mqfhxadjsmn0ns844tj8ljlsq89k95cn"
```

### 使用已有私钥导入创建key

```ruby
key = Platon::Key.new priv: private_key
```


### 备份钱包 encrypt

备份钱包，输入密码加密得到json字符串。第三个参数为options,hash类型，可传参数有:  hrp

```ruby
# 默认使用的hrp为"lat"
encrypted_key_info = Platon::Key.encrypt key,"your_password"

#or

encrypted_key_info = Platon::Key.encrypt key,"your_password",{hrp:"atp"}

```
### 备份钱包且存储

备份钱包，输入密码加密得到json字符串,并存储于指定路径或默认路径。第三个参数为options,hash类型，可传参数有:  hrp ,keypath

```ruby
#使用默认地址:  ~/.platon/keystore ,默认hrp: "lat"
Platon::Key.encrypt_and_save key,"your_password" 

# or 

Platon::Key.encrypt_and_save key,"your_password",{hrp:"atp",keypath:'./some/path.json'}

```


### 恢复钱包 decrypt
恢复钱包，输入密码得到key对象, 恢复钱包可适配任意hrp，无需指定hrp

```ruby
decrypted_key = Platon::Key.decrypt encrypted_key_info,"your_password"

# or 先读取指定路径的钱包文件

decrypted_key = Platon::Key.decrypt File.read('./some/path.json'), 'your_password'
```

###查询本地钱包 list_wallets

可传参数options,默认路径为 "~/.platon/keystore"

```ruby
Platon::Key.list_wallets

# or

Platon::Key.list_wallets(keypath:"/your/wallet/path/")
```


### 转账操作 transfer:

转账操作，可以指定gas_price与gas_limit

```ruby
client = Platon::HttpClient.new("http://127.0.0.1:6789",:alayadev)
client.transfer key,"atpxxxxxxxxxxxxxxx",10**16

# or 

client.transfer key,"atpxxxxxxxxxxxxxxx",10**16,{gas_limit: 500_000 , gas_price: 2_000_000_000}  ## 指定gas_price 与 gas_limit
```

通过如下方式验证是否为bech32地址:

```ruby
Platon::Utils.is_bech32_address?("atp1c5jsm49tp69cv0sktgg5ntj8pp5ppzqr4735gv")
=> true
```

### 签名交易 tx.sign

使用给定的key进行交易签名 

```ruby
    key = Platon::Key.new
    args = { 
        key: "some contents"
    }
    tx = Platon::Tx.new(args)
    tx.sign key
```

## Rake任务辅助工具
提供了一些 rake 任务可以作为辅助工具，如：

```ruby
rake 'platon:contract:compile[path]'            # Compile a contract
rake 'platon:contract:deploy[path]'             # Compile and deploy contract
rake 'platon:transaction:byhash[id]'            # Get info about transaction
rake 'platon:transaction:send[address,amount]'  # Send [amount of] ATP to an account
```

举例如下：
```ruby
rake 'platon:contract:compile[./spec/fixtures/greeter.sol]'
```


## 验证人&质押模块


### 发起质押

发起质押(1000)

* 参数
    * `Object`: 发起方的 Key 实例，通过 Platon::Key.new 创建或导入
    * `Integer`: typ, 表示使用账户自由金额还是账户的锁仓金额做质押，0: 自由金额； 1: 锁仓金额 2:优先使用锁仓余额，锁仓余额不足，则剩下使用自由金额
    * `String`: benefitAddress,用于接受出块奖励和质押奖励的收益账户
    * `String`: nodeId,被质押的节点Id(也叫候选人的节点Id)
    * `String`: externalId,外部Id(有长度限制，给第三方拉取节点描述的Id)
    * `String`: nodeName,被质押节点的名称(有长度限制，表示该节点的名称)
    * `String`: website,节点的第三方主页(有长度限制，表示该节点的主页)
    * `String`: details 节点的描述(有长度限制，表示该节点的描述)
    * `Integer`: amount , 质押的金额，填写单位 ATP或者 LAT 
    * `Integer`: rewardPer, 委托所得到的奖励分成比例，采用BasePoint 1BP=0.01%
    * `Integer`: programVersion, 程序的真实版本，治理rpc获取
    * `String`: programVersionSign,程序的真实版本签名，治理rpc获取
    * `String`: blsPubKey,bls的公钥
    * `String`: blsProof, bls的证明,通过拉取证明接口获取

* 返回值
    * `String`: 交易hash
    
* 示例

```ruby
client.ppos.create_staking key,0,key.bech32_address,"9d3f5a4d80a4b5b89df5ad7dadd1ef0e54854decfd5c4b808d064d4e73374e9848ac6b02bc651e9ea15f184b2a4317ea50424402670799bb0910cafeb7323f4d","", "hello-dposclub","https://www.baidu.com","integration-node1-details", 100000, 8888,65536,"0x7f4d68fb9f100aff45b9c4730c102973ca7bd63d262c2707bb3e8b18ead2865272c1b4ed23de9bfd13ebb41b3562969cfdafc303e070c4b71723c997a8c53fbd01","69365262afd3c8a6971db4f8a97a0dec049b83a85905f41429c45635de483e03f058f7ae4befb592f391fa49f68a970581a3ab4688baf9eaa6c5d0bf3e80669536ac44c91db0bacc88379ccbb33561e08f03b722ef0f296a94c06873f7b71a06","ce36b2fd6d6d76cf3a7a35e77455b3cae261568454027bbb4c28268d3c5cc16f9f6e56ca9f44c723d3181011bd31d50e39437776c474708b02ffabf088d79a1f"
==> "0x46b763893c43e2296404dfbc1a669b76ca3be7e59f37783e2fa610cb48112df4"
```


### 修改质押

节点修改质押信息(1001)

* 参数
    * `Object`: 发起方的 Key 实例，通过 Platon::Key.new 创建或导入
    * `String`: benefitAddress,用于接受出块奖励和质押奖励的收益账户
    * `String`: nodeId,被质押的节点Id(也叫候选人的节点Id)
    * `String`: externalId,外部Id(有长度限制，给第三方拉取节点描述的Id)
    * `String`: nodeName,被质押节点的名称(有长度限制，表示该节点的名称)
    * `String`: website,节点的第三方主页(有长度限制，表示该节点的主页)
    * `String`: details 节点的描述(有长度限制，表示该节点的描述)
    * `Integer`: amount , 质押的金额，填写单位 ATP或者 LAT 
    * `Integer`: rewardPer, 委托所得到的奖励分成比例，采用BasePoint 1BP=0.01%
    * `Integer`: programVersion, 程序的真实版本，治理rpc获取。可通过client.admin_get_program_version获取
    * `String`: programVersionSign,程序的真实版本签名，治理rpc获取，可通过client.admin_get_program_version 获取
    * `String`: blsPubKey,bls的公钥
    * `String`: blsProof, bls的证明,通过拉取证明接口获取。可通过client.admin_get_program_version 获取

* 返回值
    * `String`: 交易hash
    
* 示例

```ruby
client.ppos.update_staking_info(key,key.bech32_address,"9d3f5a4d80a4b5b89df5ad7dadd1ef0e54854decfd5c4b808d064d4e73374e9848ac6b02bc651e9ea15f184b2a4317ea50424402670799bb0910cafeb7323f4d",8866,"","hi-new-name-dpos","https://baidu.com","integration-node2-details")
=> "0xc5c1fd9a1259cb3a1c138bfc5a48a823e2018248f9e53c16b43f3fd2d91a8d98"
```

### 增加质押

节点增持质押（1002）

* 参数
    * `Object`: 发起方的 Key 实例，通过 Platon::Key.new 创建或导入
    * `String`: nodeId,被质押的节点Id(也叫候选人的节点Id)
    * `Integer`: typ, 表示使用账户自由金额还是账户的锁仓金额做质押，0: 自由金额； 1: 锁仓金额
    * `Integer`: amount , 质押的金额，填写单位 ATP或者 LAT 
    
* 返回值
    * `String`: 交易hash
    
* 示例

```ruby
client.ppos.add_staking(key,"9d3f5a4d80a4b5b89df5ad7dadd1ef0e54854decfd5c4b808d064d4e73374e9848ac6b02bc651e9ea15f184b2a4317ea50424402670799bb0910cafeb7323f4d",0,20)
=> "0x2a2a523b1d1ba1c3430a1a4e40d485596ad455c56fe3cfc77ae42179890fd82e"
```

### 撤销质押
撤销质押(一次性发起全部撤销，多次到账),注意有退出时间。 （1003）

* 参数
    * `Object`: 发起方的 Key 实例，通过 Platon::Key.new 创建或导入
    * `String`: nodeId,被质押的节点Id(也叫候选人的节点Id)

* 返回值
    * `String`: 交易hash
    
* 示例

```ruby
client.ppos.cancel_staking(key,"9d3f5a4d80a4b5b89df5ad7dadd1ef0e54854decfd5c4b808d064d4e73374e9848ac6b02bc651e9ea15f184b2a4317ea50424402670799bb0910cafeb7323f4d")
=> 0x6409062ce61ea5a74bf8be7f0f0cb04c1874de4aa3e4897c1ea71482ce9b78ec
```



### 发起委托  delegate

发起委托

* 参数
    * `Object`: 发起方的 Key 实例，通过 Platon::Key.new 创建或导入
    * `Integer`: 0或者1，表示使用账户自由金额还是账户的锁仓金额做委托，0: 自由金额； 1: 锁仓金额
    * `String`: 被质押节点的node_id
    * `Integer`: amount, 委托金额 (按照最小单位算，1LAT = 10**18 von)

* 返回值
    * `String`: 交易hash
    
* 示例

```ruby
# 质押10ATP/LAT

client.ppos.delegate(key,0,"0x62f537293042326df6637a38319c3cb7abd032554137a800c25c29f0e07287407f96df7601b7b00d1c0c9b26a3eedffd3397af470ba564298e047c450202cfd2",10*10**18)
```

### 减少/撤销委托 reduce_delegate

减持/撤销委托(全部减持就是撤销)

* 参数
    * `Object`: 发起方的 Key 实例，通过 Platon::Key.new 创建或导入
    * `Integer`: 质押时的区块高度，代表着某个node的某次质押的唯一标示
    * `String`: 被质押节点的node_id
    * `Integer`: amount, 委托金额 (按照最小单位算，1LAT = 10**18 von)

* 返回值
    * `String`: 交易hash
    
* 示例

```ruby
## 取出10ATP/LAT质押

 client.ppos.reduce_delegate(key,453063,"62f537293042326df6637a38319c3cb7abd032554137a800c25c29f0e07287407f96df7601b7b00d1c0c9b26a3eedffd3397af470ba564298e047c450202cfd2",10*10**18)
```

### 查询未领取的委托奖励 get_delegate_reward

查询账户在各节点未领取的奖励,funcType:5100

* 参数
    * `String`: 待查询地址，bech32 地址
    * `Array`: （可选）node_ids 默认为[]，即查询账户委托的所有节点。也可传入数组，每项元素为质押节点的node_id
    * `Integer | String` : (可选，默认"latest")可传递区块号 或 "lastest", "earliest","pending"。详见默认区块参数 [默认区块参数说明](#默认区块参数说明)。

* 返回值
    * `String`: nodeID, 质押节点的ID
    * `String(0x十六进制字符串)`: reward, 未领取的奖励数量
    * `Integer`: stakingNum ,质押时的区块高度，代表着某个node的某次质押的唯一标示

* 示例

```ruby
client.ppos.get_delegate_reward(key.bech32_address)

or

client.ppos.get_delegate_reward(key.bech32_address,["62f537293042326df6637a38319c3cb7abd032554137a800c25c29f0e07287407f96df7601b7b00d1c0c9b26a3eedffd3397af470ba564298e047c450202cfd2"])
```


### 提取所有委托奖励 withdraw_delegate_reward
提取账户当前所有的可提取的委托奖励,funcType:5000
* 参数
    * `Object`: 发起方的 Key 实例，通过 Platon::Key.new 创建或导入

* 返回值
    * `String`: 交易hash
    
* 示例

```ruby
client.ppos.withdraw_delegate_reward key
```



### 查看结算周期验证人 get_epoch_validators

查看当前结算周期的验证人,funcType 1100

* 参数
    * 无
    * `Integer | String` : (可选，默认"latest")可传递区块号 或 "lastest", "earliest","pending"。详见默认区块参数 [默认区块参数说明](#默认区块参数说明)。
* 返回值

* 返回值

    Array,其中每个元素中参数如下：

    * `String`: NodeId ,被质押的节点Id(也叫候选人的节点Id)
    * `String`: BlsPubKey, BLS公钥
    * `String`: StakingAddress,发起质押时使用的账户(后续操作质押信息只能用这个账户，撤销质押时，von会被退回该账户或者该账户的锁仓信息中)
    * `String`: BenefitAddress, 用于接受出块奖励和质押奖励的收益账户
    * `Integer`: RewardPer, 节点收益返还比例, 10000为 100%
    * `Integer`: NextRewardPer
    * `Integer`: RewardPerChangeEpoch
    * `String`: StakingTxIndex,发起质押时的交易索引
    * `String`: ProgramVersion, 被质押节点的PlatON进程的真实版本号(获取版本号的接口由治理提供)
    * `Integer`: StakingBlockNum,发起质押时的区块高度
    * `String(0x十六进制字符串)`: Shares,当前候选人总共质押加被委托的von数目
    * `String`: ExternalId, 外部Id(有长度限制，给第三方拉取节点描述的Id)
    * `String`: NodeName,被质押节点的名称(有长度限制，表示该节点的名称)
    * `String`: Website,节点的第三方主页(有长度限制，表示该节点的主页)
    * `String`: Details,节点的描述(有长度限制，表示该节点的描述)

* 示例

```ruby
client.ppos.get_epoch_validators
or
client.ppos.get_epoch_validators("latest")
```

### 查看共识周期验证人

查看当前共识周期的验证人，即共识中+出块中 ，funcType 1101。

* 参数
    * 无
    * `Integer | String` : (可选，默认"latest")可传递区块号 或 "lastest", "earliest","pending"。详见默认区块参数 [默认区块参数说明](#默认区块参数说明)。
* 返回值

* 返回值

    Array,其中每个元素中参数如下：

    * `String`: NodeId ,被质押的节点Id(也叫候选人的节点Id)
    * `String`: BlsPubKey, BLS公钥
    * `String`: StakingAddress,发起质押时使用的账户(后续操作质押信息只能用这个账户，撤销质押时，von会被退回该账户或者该账户的锁仓信息中)
    * `String`: BenefitAddress, 用于接受出块奖励和质押奖励的收益账户
    * `Integer`: RewardPer, 节点收益返还比例, 10000为 100%
    * `Integer`: NextRewardPer
    * `Integer`: RewardPerChangeEpoch
    * `String`: StakingTxIndex,发起质押时的交易索引
    * `String`: ProgramVersion, 被质押节点的PlatON进程的真实版本号(获取版本号的接口由治理提供)
    * `Integer`: StakingBlockNum,发起质押时的区块高度
    * `String(0x十六进制字符串)`: Shares,当前候选人总共质押加被委托的von数目
    * `String`: ExternalId, 外部Id(有长度限制，给第三方拉取节点描述的Id)
    * `String`: NodeName,被质押节点的名称(有长度限制，表示该节点的名称)
    * `String`: Website,节点的第三方主页(有长度限制，表示该节点的主页)
    * `String`: Details,节点的描述(有长度限制，表示该节点的描述)

* 示例

```ruby
client.ppos.get_round_validators
or
client.ppos.get_round_validators("latest")
```

### 查看实时验证人列表 get_current_candidates

查看当前共识周期的验证人，即当前所有节点，含候选中 ，funcType 1102。

* 参数
    * 无
    * `Integer | String` : (可选，默认"latest")可传递区块号 或 "lastest", "earliest","pending"。详见默认区块参数 [默认区块参数说明](#默认区块参数说明)。
* 返回值

* 返回值
    
    Array,其中每个元素中参数如下：

    * `String`: NodeId ,被质押的节点Id(也叫候选人的节点Id)
    * `String`: BlsPubKey, BLS公钥
    * `String`: StakingAddress,发起质押时使用的账户(后续操作质押信息只能用这个账户，撤销质押时，von会被退回该账户或者该账户的锁仓信息中)
    * `String`: BenefitAddress, 用于接受出块奖励和质押奖励的收益账户
    * `Integer`: RewardPer, 节点收益返还比例, 10000为 100%
    * `Integer`: NextRewardPer
    * `Integer`: RewardPerChangeEpoch
    * `String`: StakingTxIndex,发起质押时的交易索引
    * `String`: ProgramVersion, 被质押节点的PlatON进程的真实版本号(获取版本号的接口由治理提供)
    * `String`: Status, 候选人的状态(状态是根据uint32的32bit来放置的，可同时存在多个状态，值为多个同时存在的状态值相加【0: 节点可用 (32个bit全为0)； 1: 节点不可用 (只有最后一bit为1)； 2： 节点出块率低但没有达到移除条件的(只有倒数第二bit为1)； 4： 节点的von不足最低质押门槛(只有倒数第三bit为1)； 8：节点被举报双签(只有倒数第四bit为1)); 16: 节点出块率低且达到移除条件(倒数第五位bit为1); 32: 节点主动发起撤销(只有倒数第六位bit为1)】
    * `Integer`: StakingEpoch, 当前变更质押金额时的结算周期
    * `Integer`: StakingBlockNum,发起质押时的区块高度
    * `String(0x十六进制字符串)`: Shares,当前候选人总共质押加被委托的von数目
    * `String(0x十六进制字符串)`: Released,发起质押账户的自由金额的锁定期质押的von
    * `String(0x十六进制字符串)`: ReleasedHes,发起质押账户的自由金额的犹豫期质押的von
    * `String(0x十六进制字符串)`: RestrictingPlan,发起质押账户的锁仓金额的锁定期质押的von
    * `String(0x十六进制字符串)`: RestrictingPlanHes,发起质押账户的锁仓金额的犹豫期质押的von
    * `Integer`: DelegateEpoch,最近一次对该候选人发起的委托时的结算周期
    * `String(0x十六进制字符串)`: DelegateTotal, 接受委托总数
    * `String(0x十六进制字符串)`: DelegateTotalHes
    * `String(0x十六进制字符串)`: DelegateRewardTotal 累计委托奖励
    * `String`: ExternalId, 外部Id(有长度限制，给第三方拉取节点描述的Id)
    * `String`: NodeName,被质押节点的名称(有长度限制，表示该节点的名称)
    * `String`: Website,节点的第三方主页(有长度限制，表示该节点的主页)
    * `String`: Details,节点的描述(有长度限制，表示该节点的描述)

* 示例

```ruby
client.ppos.get_current_candidates
or
client.ppos.get_current_candidates("latest")
```

### 查询账户所代理的节点ID get_delegate_nodeids_by_addr

查询某账户锁代理的节点ID信息 , funcType 1103

* 参数
    * `String`: bech32 address ,委托人的账户地址
    * `Integer | String` : (可选，默认"latest")可传递区块号 或 "lastest", "earliest","pending"。详见默认区块参数 [默认区块参数说明](#默认区块参数说明)。

* 返回值

    Array,其中每个元素中参数如下：
    * `String`: Addr , 委托人的账户地址
    * `Integer`: StakingBlockNum, 发起质押时的区块高度

* 示例

```ruby
client.ppos.get_delegate_nodeids_by_addr("your_atp_or_lat_address")
```

### 查询单个委托信息 get_address_delegate_info
查询单个委托的相关信息， funType 1104 

* 参数
    * `Integer`:发起质押时的区块高度
    * `String`: 委托人账户地址
    * `String`: 验证人的节点Id
    * `Integer | String` : (可选，默认"latest")可传递区块号 或 "lastest", "earliest","pending"。详见默认区块参数 [默认区块参数说明](#默认区块参数说明)。
* 返回值

    Array,其中每个元素中参数如下：
    * `String`: Addr , 委托人的账户地址
    * `Integer`: StakingBlockNum, 发起质押时的区块高度
    * `String`: NodeId ,被质押的节点Id(也叫候选人的节点Id)
    * `Integer`: DelegateEpoch: 最近一次对该候选人发起的委托时的结算周期
    * `String(0x十六进制字符串)`: Released,发起质押账户的自由金额的锁定期质押的von
    * `String(0x十六进制字符串)`: ReleasedHes,发起质押账户的自由金额的犹豫期质押的von
    * `String(0x十六进制字符串)`: RestrictingPlan,发起质押账户的锁仓金额的锁定期质押的von
    * `String(0x十六进制字符串)`: RestrictingPlanHes,发起质押账户的锁仓金额的犹豫期质押的von
    * `String(0x十六进制字符串)`: CumulativeIncome
    
* 示例

```ruby
client.ppos.get_address_delegate_info(509677,"atp1842mp45vw30vgvzmylwdxmxxc00ggjp6q2gv8v","fad2c7f917eb3057d85031eae8bbda52541b527dd1d24a25e7e9b40d7329570a85dc45ec61b189a9cc30047ae906a08dc375558828e1c76dc853ce99b42b91e4")
```



### 查询质押信息 get_node_delegate_info

查询节点的质押信息 , funcType 1105

* 参数

    * `String`: 验证人的节点id
    * `Integer | String` : (可选，默认"latest")可传递区块号 或 "lastest", "earliest","pending"。详见默认区块参数 [默认区块参数说明](#默认区块参数说明)。

* 返回值

    Array,其中每个元素中参数如下：
    * `String`: NodeId ,被质押的节点Id(也叫候选人的节点Id)
    * `String`: StakingAddress,发起质押时使用的账户(后续操作质押信息只能用这个账户，撤销质押时，von会被退回该账户或者该账户的锁仓信息中)
    * `String`: BenefitAddress, 用于接受出块奖励和质押奖励的收益账户
    * `String`: StakingTxIndex,发起质押时的交易索引
    * `String`: ProgramVersion, 被质押节点的PlatON进程的真实版本号(获取版本号的接口由治理提供)
    * `String`: Status, 候选人的状态(状态是根据uint32的32bit来放置的，可同时存在多个状态，值为多个同时存在的状态值相加【0: 节点可用 (32个bit全为0)； 1: 节点不可用 (只有最后一bit为1)； 2： 节点出块率低但没有达到移除条件的(只有倒数第二bit为1)； 4： 节点的von不足最低质押门槛(只有倒数第三bit为1)； 8：节点被举报双签(只有倒数第四bit为1)); 16: 节点出块率低且达到移除条件(倒数第五位bit为1); 32: 节点主动发起撤销(只有倒数第六位bit为1)】
    * `Integer`: StakingEpoch, 当前变更质押金额时的结算周期
    * `Integer`: StakingBlockNum,发起质押时的区块高度
    * `String(0x十六进制字符串)`: Shares,当前候选人总共质押加被委托的von数目
    * `String(0x十六进制字符串)`: Released,发起质押账户的自由金额的锁定期质押的von
    * `String(0x十六进制字符串)`: ReleasedHes,发起质押账户的自由金额的犹豫期质押的von
    * `String(0x十六进制字符串)`: RestrictingPlan,发起质押账户的锁仓金额的锁定期质押的von
    * `String(0x十六进制字符串)`: RestrictingPlanHes,发起质押账户的锁仓金额的犹豫期质押的von
    * `String`: ExternalId, 外部Id(有长度限制，给第三方拉取节点描述的Id)
    * `String`: NodeName,被质押节点的名称(有长度限制，表示该节点的名称)
    * `String`: Website,节点的第三方主页(有长度限制，表示该节点的主页)
    * `String`: Details,节点的描述(有长度限制，表示该节点的描述)   

* 示例

```ruby
client.ppos.get_node_delegate_info("0x48f9ebd7559b7849f80e00d89d87fb92604c74a541a7d76fcef9f2bcc67043042dfab0cfbaeb5386f921208ed9192c403f438934a0a39f4cad53c55d8272e5fb")
=> {:jsonrpc=>"2.0", :method=>"platon_call", :params=>[{"data"=>"0xf84883820451b842b84048f9ebd7559b7849f80e00d89d87fb92604c74a541a7d76fcef9f2bcc67043042dfab0cfbaeb5386f921208ed9192c403f438934a0a39f4cad53c55d8272e5fb", "to"=>"atp1zqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqzfyslg3"}, "latest"], :id=>1}
 => {"Code"=>0, "Ret"=>{"NodeId"=>"48f9ebd7559b7849f80e00d89d87fb92604c74a541a7d76fcef9f2bcc67043042dfab0cfbaeb5386f921208ed9192c403f438934a0a39f4cad53c55d8272e5fb", "BlsPubKey"=>"821043f4df086533691f0445deb51cf524f45ab7a855a3f1a79fa0f65ceb1cabd2674bbe4575c645dfbd878734ad0910568db5aebcd46bfd72d50c9007c1328559fb1e7de876990ab7c7d3bc7cb9e291da6fe28ba185de5fe7f99566de3b8381", "StakingAddress"=>"atp129fa9ypppsfv5kljjdg6g49kc4tuzhz6f9cleu", "BenefitAddress"=>"atp1zqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqr5jy24r", "RewardPer"=>0, "NextRewardPer"=>0, "RewardPerChangeEpoch"=>0, "StakingTxIndex"=>0, "ProgramVersion"=>3841, "Status"=>0, "StakingEpoch"=>0, "StakingBlockNum"=>0, "Shares"=>"0x23934c5a09da1900000", "Released"=>"0x23934c5a09da1900000", "ReleasedHes"=>"0x0", "RestrictingPlan"=>"0x0", "RestrictingPlanHes"=>"0x0", "DelegateEpoch"=>0, "DelegateTotal"=>"0x0", "DelegateTotalHes"=>"0x0", "DelegateRewardTotal"=>"0x0", "ExternalId"=>"", "NodeName"=>"alaya.node.1", "Website"=>"alaya.network", "Details"=>"The Alaya Node"}}
```

### 查询当前结算周期的区块奖励 get_block_reward
查询当前结算周期的区块奖励

* 参数
    * 无
    * `Integer | String` : (可选，默认"latest")可传递区块号 或 "lastest", "earliest","pending"。详见默认区块参数 [默认区块参数说明](#默认区块参数说明)。

* 返回值
    * `String(0x十六进制字符串)` 

* 示例

```ruby
client.ppos.get_block_reward
```

### 查询当前结算周期的质押奖励 get_staking_reward
查询当前结算周期的质押奖励
* 参数
    * 无
    * `Integer | String` : (可选，默认"latest")可传递区块号 或 "lastest", "earliest","pending"。详见默认区块参数 [默认区块参数说明](#默认区块参数说明)。

* 返回值
    * `String(0x十六进制字符串)`

* 示例

```ruby
client.ppos.get_staking_reward
```

## 治理模块

### 提交文本提案 submit_proposal
提交文本提案（2000）

* 参数
    * `Object`: 发起方的 Key 实例，通过 Platon::Key.new 创建或导入
    * `String`: verifier, 传入node_id,提交提案的验证人
    * `String(uint64)`: piDID, PIPID

* 返回值
    * `String`: 交易hash
* 示例

```ruby
client.ppos.submit_proposal(key,"9d3f5a4d80a4b5b89df5ad7dadd1ef0e54854decfd5c4b808d064d4e73374e9848ac6b02bc651e9ea15f184b2a4317ea50424402670799bb0910cafeb7323f4d","1",{gas_price:(1.5 * 10**15).to_i,gas_limit:350000})
```

### 提交升级提案 update_proposal
提交升级提案2001

* 参数
    * `Object`: 发起方的 Key 实例，通过 Platon::Key.new 创建或导入
    * `String`: verifier, 传入node_id,提交提案的验证人
    * `String(uint64)`: piDID, PIPID
    * `Integer`: newVersion, 升级版本
    * `Integer`: endVotingRounds, 投票共识轮数量。说明：假设提交提案的交易，被打包进块时的共识轮序号时round1，则提案投票截止块高，就是round1 + endVotingRounds这个共识轮的第230个块高（假设一个共识轮出块250，ppos揭榜提前20个块高，250，20都是可配置的 ），其中0 < endVotingRounds <= 4840（约为2周，实际论述根据配置可计算），且为整数）
* 返回值
    * `String`: 交易hash
* 示例

```ruby
client.ppos.update_proposal(key,"9d3f5a4d80a4b5b89df5ad7dadd1ef0e54854decfd5c4b808d064d4e73374e9848ac6b02bc651e9ea15f184b2a4317ea50424402670799bb0910cafeb7323f4d","15",2,10,{gas_price:(2.2 * 10**15).to_i,gas_limit:480000})
```

### 提交取消提案 cancel_proposal
提交取消提案 (2005)

* 参数
    * `Object`: 发起方的 Key 实例，通过 Platon::Key.new 创建或导入
    * `String`: verifier, 传入node_id,提交提案的验证人
    * `String(uint64)`: piDID, PIPID
    * `Integer`: endVotingRounds,投票共识轮数量。参考提交升级提案的说明，同时，此接口中此参数的值不能大于对应升级提案中的值
    * `String`: tobeCanceledProposalID,待取消的升级提案ID

* 返回值
    * `String`: 交易hash
* 示例

```ruby
client.ppos.cancel_proposal(key,"9d3f5a4d80a4b5b89df5ad7dadd1ef0e54854decfd5c4b808d064d4e73374e9848ac6b02bc651e9ea15f184b2a4317ea50424402670799bb0910cafeb7323f4d","15",9,"0x01bb9da5d4a5649aa6adf5cfc87f2986c5bd8c7be3c1bf1addf30f4c99caf432")
```

### 给提案投票 vote_proposal
给提案投票(2003)

* 参数
    * `Object`: 发起方的 Key 实例，通过 Platon::Key.new 创建或导入
    * `String`: verifier, 传入node_id,提交提案的验证人
    * `String(uint64)`: piDID, PIPID
    * `Integer`: option,投票选项 , 1：支持；2：反对；3：弃权
    * `String`: programVersion,节点代码版本，有rpc的get_program_version接口获取
    * `String`: versionSign,代码版本签名，有rpc的get_program_version接口获取
* 返回值
    * `String`: 交易hash
* 示例

```ruby
client.ppos.vote_proposal(key,"9d3f5a4d80a4b5b89df5ad7dadd1ef0e54854decfd5c4b808d064d4e73374e9848ac6b02bc651e9ea15f184b2a4317ea50424402670799bb0910cafeb7323f4d","15", 1, 65536,"0x7f4d68fb9f100aff45b9c4730c102973ca7bd63d262c2707bb3e8b18ead2865272c1b4ed23de9bfd13ebb41b3562969cfdafc303e070c4b71723c997a8c53fbd01")
```

### 版本声明 declare_version
版本声明(2004)

* 参数
    * `Object`: 发起方的 Key 实例，通过 Platon::Key.new 创建或导入
    * `String`: verifier, 传入node_id,提交提案的验证人
    * `String`: programVersion,节点代码版本，有rpc的get_program_version接口获取
    * `String`: versionSign,代码版本签名，有rpc的get_program_version接口获取
* 返回值
    * `String`: 交易hash
* 示例

```ruby
client.ppos.declare_version(key,"9d3f5a4d80a4b5b89df5ad7dadd1ef0e54854decfd5c4b808d064d4e73374e9848ac6b02bc651e9ea15f184b2a4317ea50424402670799bb0910cafeb7323f4d",65536,"0x7f4d68fb9f100aff45b9c4730c102973ca7bd63d262c2707bb3e8b18ead2865272c1b4ed23de9bfd13ebb41b3562969cfdafc303e070c4b71723c997a8c53fbd01")
```

### 查询提案列表 get_proposals
查询提案列表，funcType 2102

* 参数
    * 无
    * `Integer | String` : (可选，默认"latest")可传递区块号 或 "lastest", "earliest","pending"。详见默认区块参数 [默认区块参数说明](#默认区块参数说明)。

* 返回值

    Array,其中每个元素为Proposal数据结构

* 示例

```ruby
client.ppos.get_proposals
```

### 提案查询 get_proposal_info
针对某提案进行查询，funcType:2100

* 参数
    * `String`: proposal id ,待查询的提案ID
    * `Integer | String` : (可选，默认"latest")可传递区块号 或 "lastest", "earliest","pending"。详见默认区块参数 [默认区块参数说明](#默认区块参数说明)。
* 返回值

    Proposal接口实现对象的json字符串

* 示例

```ruby
client.ppos.get_proposal_info("0x261cf6c0f518aeddffb2aa5536685af6f13f8ba763c77b42f12ce025ef7170ed")
```

### 查询提案结果 get_proposal_result
针对某提案，查询提案结果， funcType: 2101

* 参数
    * `String`: proposal id ,待查询的提案ID
    * `Integer | String` : (可选，默认"latest")可传递区块号 或 "lastest", "earliest","pending"。详见默认区块参数 [默认区块参数说明](#默认区块参数说明)。

* 返回值
    TallyResult对象的json字符串，TallyResult：保存单个提案结果的对象

    * `String`: proposalID 提案ID
    * `Integer`: yeas 赞成票票数
    * `Integer`: nays 反对票票数
    * `Integer`: abstentions 弃权票票数
    * `Integer`: accuVerifiers 在整个投票期内有投票资格的验证人总数
    * `Integer`: status 提案状态 。 1 投票中，2：投票通过，3：投票失败，4：（升级提案）预生效，5：（升级提案）生效，6：被取消

* 示例

```ruby
client.ppos.get_proposal_result("0x261cf6c0f518aeddffb2aa5536685af6f13f8ba763c77b42f12ce025ef7170ed")
=> {"Code"=>0, "Ret"=>{"proposalID"=>"0x261cf6c0f518aeddffb2aa5536685af6f13f8ba763c77b42f12ce025ef7170ed", "yeas"=>102, "nays"=>0, "abstentions"=>0, "accuVerifiers"=>116, "status"=>5, "canceledBy"=>"0x0000000000000000000000000000000000000000000000000000000000000000"}}
```

### 查询节点的链生效版本 get_version_in_effect

查询节点的链生效版本, funcType:2103

* 参数

    * 无
    * `Integer | String` : (可选，默认"latest")可传递区块号 或 "lastest", "earliest","pending"。详见默认区块参数 [默认区块参数说明](#默认区块参数说明)。
    
* 返回值
    * 版本号的json字符串，如{65536}，表示版本是：1.0.0。 解析时，需要把ver转成4个字节。主版本：第二个字节；小版本：第三个字节，patch版本，第四个字节。解析示例见下:
* 示例

```ruby
 client.ppos.get_version_in_effect
  {"Code"=>0, "Ret"=>3840}
  
 ## 版本号解析
 65535.to_s(16) => "10000" 即 1.0.0
 3840.to_s(16) => "f00" 即 0.15.0
 
```

### 查询提案投票人数 get_votes_number
指定proposal id 与区块hash,查询提案投票人数,funcType:2105

* 参数

    * 无
    * `Integer | String` : (可选，默认"latest")可传递区块号 或 "lastest", "earliest","pending"。详见默认区块参数 [默认区块参数说明](#默认区块参数说明)。
    
* 返回值
    * `Array`: 包含4个元素，含义分别为：累积可投票人数、赞成票数、反对票数、弃权票数

* 示例

```ruby
client.ppos.get_votes_number("0x261cf6c0f518aeddffb2aa5536685af6f13f8ba763c77b42f12ce025ef7170ed","0x520a94980d6a243d469040936fcb64928e2a3bde1d79508ffd80e4a0d4fc3e57")

 => {"Code"=>0, "Ret"=>[116, 102, 0, 0]}

```

### 查询治理参数列表 get_govern_params
查询治理参数列表，funcType: 2106

* 参数
    * `String`, module name 
    * `Integer | String` : (可选，默认"latest")可传递区块号 或 "lastest", "earliest","pending"。详见默认区块参数 [默认区块参数说明](#默认区块参数说明)。
    
* 返回值
    Array,其中每个元素结构为:
    * `Object`: ParamItem :
        * `String`: Module
        * `String`: Name
        * `String`: Desc ,描述
    * `Object`: ParamValue :
        * `String`: StaleValue
        * `String`: Value ，值
        * `Integer`: ActiveBlock
* 示例

```ruby
client.ppos.get_govern_params("staking")

=> {"Code"=>0, "Ret"=>[{"ParamItem"=>{"Module"=>"staking", "Name"=>"stakeThreshold", "Desc"=>"minimum amount of stake, range: [10000000000000000000000, 1000000000000000000000000]"}, "ParamValue"=>{"StaleValue"=>"", "Value"=>"10000000000000000000000", "ActiveBlock"=>0}}, {"ParamItem"=>{"Module"=>"staking", "Name"=>"operatingThreshold", "Desc"=>"minimum amount of stake increasing funds, delegation funds, or delegation withdrawing funds, range: [1000000000000000000, 10000000000000000000000]"}, "ParamValue"=>{"StaleValue"=>"", "Value"=>"1000000000000000000", "ActiveBlock"=>0}}, {"ParamItem"=>{"Module"=>"staking", "Name"=>"maxValidators", "Desc"=>"maximum amount of validator, range: [25, 201]"}, "ParamValue"=>{"StaleValue"=>"", "Value"=>"101", "ActiveBlock"=>0}}, {"ParamItem"=>{"Module"=>"staking", "Name"=>"unStakeFreezeDuration", "Desc"=>"quantity of epoch for skake withdrawal, range: (MaxEvidenceAge, 336]"}, "ParamValue"=>{"StaleValue"=>"", "Value"=>"168", "ActiveBlock"=>0}}, {"ParamItem"=>{"Module"=>"staking", "Name"=>"rewardPerMaxChangeRange", "Desc"=>"Delegated Reward Ratio The maximum adjustable range of each modification, range: [1, 2000]"}, "ParamValue"=>{"StaleValue"=>"", "Value"=>"500", "ActiveBlock"=>0}}, {"ParamItem"=>{"Module"=>"staking", "Name"=>"rewardPerChangeInterval", "Desc"=>"The interval for each modification of the commission reward ratio, range: [2, 28]"}, "ParamValue"=>{"StaleValue"=>"", "Value"=>"10", "ActiveBlock"=>0}}]}
```

### 查询当前块高的治理参数值 get_govern_param_value
查询当前块高的治理参数值 funcType:2106
* 参数

    * `String`, module name  模块名称
    * `String`, name ,方法名
    * `Integer | String` : (可选，默认"latest")可传递区块号 或 "lastest", "earliest","pending"。详见默认区块参数 [默认区块参数说明](#默认区块参数说明)。
* 返回值

    * `String`: 该param的值

* 示例

```ruby
client.ppos.get_govern_param_value("staking","stakeThreshold")
=> {"Code"=>0, "Ret"=>"10000000000000000000000"}
```


### 举报双签 report_duplicate_sign
举报节点双签（3000）

* 参数
    * `Object`: 发起方的 Key 实例，通过 Platon::Key.new 创建或导入
    * `Integer`: typ, 代表双签类型，1：prepareBlock，2：prepareVote，3：viewChange
    * `String`: data, 单个证据的json值，格式参照[RPC接口Evidences]
* 返回值
    * `String`: 交易hash
* 示例

```ruby
client.ppos.report_duplicate_sign(key,1,"{}")
```

### 查询节点被举报双签 get_node_oversign
funcType:3001

* 参数
    * `Integer`: type 代表双签类型，1：prepareBlock，2：prepareVote，3：viewChange
    * `String`: 节点ID ，64bytes
    * `Integer`: 多签的块高
* 返回值
    * `String`: 举报的交易hash
* 示例

```ruby
client.ppos.get_node_oversign(1,"0xed552a64f708696ac53962b88e927181688c8bc260787c82e1c9c21a62da4ce59c31fc594e48249e89392ce2e6e2a0320d6688b38ad7884ff6fe664faf4b12d9",12300000)
```


### 创建锁仓计划 create_restricting_plan

创建锁仓计划（4000）

* 参数
    * `String`: address ,锁仓释放到账的账户
    * `Array`: 锁仓计划列表，数组，数组结构为
        - `Integer`: epoch,锁仓的周期，表示结算周期的倍数。与每个结算周期出块数的乘积表示在目标区块高度上释放锁定的资金。Epoch * 每周期的区块数至少要大于最高不可逆区块高度。
        - `Integer`: amount, 标识目标区块上待释放的金额 。注意需要大于治理参数中minimumRelease

* 返回值
    * `String`: 举报的交易hash
    
* 示例

```ruby
client.ppos.create_restricting_plan(key,"lat10z2enrjz2lk2hz3n9z3l2gmyxujnhuaqklw6dd",[[50,200 * 10**18]])
```

### 获取锁仓计划 get_restricting_info

获取锁仓计划（4100）

* 参数
    * `String`: address 锁仓释放到账的账户

* 返回值
    * `String`: balance, 总锁仓余额-已释放金额
    * `String`: pledge , 质押/抵押金额
    * `String`: debt , 欠释放金额
    * `Array`: plans ,  锁仓分录信息，json数组：[{"blockNumber":"","amount":""},...,{"blockNumber":"","amount":""}]。其中：
blockNumber：`Integer` ,释放区块高度
amount：`string(0x十六进制字符串)`，释放金额

* 示例

```ruby
client.ppos.get_restricting_info("lat10z2enrjz2lk2hz3n9z3l2gmyxujnhuaqklw6dd")

=>{"Code"=>0, "Ret"=>{"balance"=>"0xad78ebc5ac6200000", "debt"=>"0x0", "plans"=>[{"blockNumber"=>2074750, "amount"=>"0xad78ebc5ac6200000"}], "Pledge"=>"0x0"}}
```


