# frozen_string_literal: true

require_relative "platon/version"
require 'active_support'
require 'active_support/core_ext'
require 'digest/sha3'

require 'ffi'
require 'money-tree'
require 'rlp'

module Platon

  BYTE_ZERO = "\x00".freeze
  UINT_MAX = 2**256 - 1

  class << self

    def replayable_chain_id
      27
    end

    def v_base
      replayable_chain_id
    end

    def replayable_v?(v)
      [replayable_chain_id, replayable_chain_id + 1].include? v
    end

    def chain_id_from_signature(signature)
      return nil if Platon.replayable_v?(signature[:v])

      cid = (signature[:v] - 35) / 2
      (cid < 1) ? nil : cid
    end
  end

  require_relative 'platon/bech32'
  require_relative 'platon/abi'
  require_relative 'platon/client'
  require_relative 'platon/ipc_client'
  require_relative 'platon/http_client'
  require_relative 'platon/singleton'
  require_relative 'platon/solidity'
  require_relative 'platon/initializer'
  require_relative 'platon/contract'
  require_relative 'platon/explorer_url_helper'
  require_relative 'platon/function'
  require_relative 'platon/function_input'
  require_relative 'platon/function_output'
  require_relative 'platon/contract_event'
  require_relative 'platon/encoder'
  require_relative 'platon/decoder'
  require_relative 'platon/formatter'
  require_relative 'platon/transaction'
  require_relative 'platon/deployment'
  require_relative 'platon/contract_initializer'
  require_relative 'platon/railtie' if defined?(Rails)

  require_relative 'platon/ppos'

  autoload :Address, 'platon/address'
  autoload :Gas, 'platon/gas'
  autoload :Key, 'platon/key'
  autoload :OpenSsl, 'platon/open_ssl'
  autoload :Secp256k1, 'platon/secp256k1'
  autoload :Sedes, 'platon/sedes'
  autoload :Tx, 'platon/tx'
  autoload :Utils, 'platon/utils'

  autoload :SegwitAddr, 'platon/segwit_addr'

  class ValidationError < StandardError; end
  class InvalidTransaction < ValidationError; end
end
