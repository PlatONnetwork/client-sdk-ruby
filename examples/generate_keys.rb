require "platon"

puts "Example : generate key , print address and private_key"

while true
	puts ""
	puts "Press any key to Generate keys.."
	STDIN.readline


	key = Platon::Key.new
	puts "Address on PlatON: #{key.bech32_address(hrp: "lat")}"
	puts "Address on Alaya: #{key.bech32_address(hrp: "atp")}"
	puts "EIP55 address: #{key.address}"
	puts "PrivateKey: #{key.private_hex}"
	puts "===================================="
end