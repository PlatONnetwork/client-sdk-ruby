require 'net/http'
require 'json'
module Platon
  class HttpClient < Client
    attr_accessor :host, :port, :uri, :ssl, :proxy

    def initialize(host,chain_name, proxy = nil)
      super(chain_name,log)
      uri = URI.parse(host)
      raise ArgumentError unless ['http', 'https'].include? uri.scheme
      @host = uri.host
      @port = uri.port
      @proxy = proxy
      
      @ssl = uri.scheme == 'https'
      @uri = URI("#{uri.scheme}://#{@host}:#{@port}#{uri.path}")
    end

    def update_setting(params)  # :host,:proxy, :chain_id, :hrp
      if params[:host]
        uri = URI.parse(params[:host])
        raise ArgumentError unless ['http', 'https'].include? uri.scheme
        @host = uri.host
        @port = uri.port
      end
      @proxy = proxy if params[:proxy]
      super(params)
    end

    def send_single(payload)
      if @proxy.present?
        _, p_username, p_password, p_host, p_port = @proxy.gsub(/(:|\/|@)/,' ').squeeze(' ').split
        http = ::Net::HTTP.new(@host, @port, p_host, p_port, p_username, p_password)
      else
        http = ::Net::HTTP.new(@host, @port)
      end

      if @ssl
        http.use_ssl = true
      end
      header = {'Content-Type' => 'application/json'}
      request = ::Net::HTTP::Post.new(uri, header)
      request.body = payload
      response = http.request(request)
      response.body
    end

    def send_batch(batch)
      result = send_single(batch.to_json)
      result = JSON.parse(result)
      result.sort_by! { |c| c['id'] }
    end
  end

end
