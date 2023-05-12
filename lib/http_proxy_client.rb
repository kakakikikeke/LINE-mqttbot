# frozen_string_literal: true

# IP を固定させるためのプロキシ情報を管理するクラス
class HTTPProxyClient
  def http(uri)
    proxy_class = Net::HTTP::Proxy(ENV['FIXIE_URL_HOST'],
                                   ENV['FIXIE_URL_POST'],
                                   ENV['FIXIE_URL_USER'],
                                   ENV['FIXIE_URL_PASSWORD'])
    http = proxy_class.new(uri.host, uri.port)
    http.use_ssl = true if uri.scheme == 'https'
    http
  end

  def get(url, header = {})
    uri = URI(url)
    http(uri).get(uri.request_uri, header)
  end

  def post(url, payload, header = {})
    uri = URI(url)
    http(uri).post(uri.request_uri, payload, header)
  end
end
