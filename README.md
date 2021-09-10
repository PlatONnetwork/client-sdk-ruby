# Ruby SDK for Platon & Alaya 


<p align="center">
    <img src="./platon-ruby-logo.png" width="80" title="platon ruby SDK" alt="platon ruby SDK">
</p>


Gem "platon" helps to make interacting with platon&alaya blockchain from ruby .


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'platon'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install platon


## Quick Start

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


## Usage

#### Keys

Create a new public/private key and get its address

```ruby
key = Platon::Key.new
key.private_hex ## private key
=> "08bb093d6184cb06a3f80507953ba6768c03d8114a429b0ec7875bb6b6e1a8a6"

key.public_hex ## public key
=> "04641129e66399310ce4a41098d3b3fc4d722edf423dfdc0a76eba5d6e2155bbe611ee2a5c06011ab76040ca53b9ead4c5061d8cc8a89afa3f45af5830661d4b34"

key.bech32_address  ## bech32 address ,default "lat"
=> "lat1ls87d3mqfhxadjsmn0ns844tj8ljlsq8uqnv8u" 

key.bech32_address(hrp: "atp") 
=> "atp1ls87d3mqfhxadjsmn0ns844tj8ljlsq89k95cn"

key.address ## EIP55 checksummed address
=> "0xFc0Fe6c7604dcDd6ca1B9be703D6AB91fF2fC007"
```

Encrypt keys to json file

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

Decrypt keys from json file

```ruby
decrypted_key = Platon::Key.decrypt encrypted_key_info,"your_password"

or

decrypted_key = Platon::Key.decrypt File.read('./some/path.json'), 'your_password'
```

#### Transactions

Build a transcation :

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

Or decode from an encoded raw transaction

```ruby
tx = Platon::Tx.decode hex
```

You can sign the transaction:

```ruby
tx.sign key
platon_send_raw_transaction(tx.hex)
```

Get the raw transaction with `tx.hex`, and broadcast it through any PlatON node with `platon_send_raw_transaction` . Or just get the TXID with `tx.hash`

#### Client

By default methods interactiong with contracts&PPOS will use default JSON RPC Client that will handle connection to platon node. 

```ruby
client = Platon::HttpClient.new("http://127.0.0.1:6789",:alayadev)
```

Default setting:
```
    platondev: {hrp: "lat", chain_id: 210309}
    alaya:{hrp:"atp",chain_id:201018} 
    alayadev:{hrp:"atp",chain_id: 201030}
```

You can use `client.update_setting` to change chain configs:

```ruby
client.update_setting(hrp:"atx",chain_id: 1234)
```

#### Contracts

You can get contract from blockchain. To do so you need a contract name ,contract address and ABI definition:

```ruby
contract = Platon::Contract.create(client: client ,name: "MyContract", address: "atpxxxx_your_bench32_address", abi: abi)
```

Alternatively you can obtain abi definition and name from contract source file:
```ruby
contract = Platon::Contract.create(client: client , file: "MyContract.sol", address: "atpxxxx_your_bench32_address")
```

Interacting with contracts:

You can `call` contract read-only method , no transaction will be sent to the network. If method changes contract state ,`transact` method can be used .

```ruby
contract.call.[function_name](params)

contract.transact.[function_name](params)

contract.transact_and_wait.[function_name](params)  
```

#### PPOS

All PPOS methods have been implemented. See [Docs](./doc/zh-cn.md) 

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

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. 

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/vianull/client-sdk-ruby.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
