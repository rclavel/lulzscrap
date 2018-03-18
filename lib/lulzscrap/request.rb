class Lulzscrap::Request
  def initialize(scrap)
    @scrap = scrap
  end

  def put(string_uri, headers:, body:)
    original_headers = headers.dup
    loop_on_request(times: 3) do
      headers = original_headers.dup
      uri = URI.parse(string_uri)
      request = Net::HTTP::Put.new(uri)

      headers['User-Agent'] ||= TorManager::Tor.get_random_user_agent
      request.content_type = headers.delete('Content-Type')
      headers.each do |header_name, header_value|
        request[header_name] = header_value
      end
      request.body = body
      req_options = { use_ssl: uri.scheme == 'https' }

      response = TorManager::Tor.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end

      if response.code != '200'
        raise "Invalid HTTP code #{response.code} for URL #{string_uri} and parameters #{request.body}. Exiting!"
      end

      if response.body.empty?
        @scrap.log("Empty response received. User agent is: #{request['User-Agent']}")
        sleep 3
        nil
      else
        response
      end
    end
  end

  def loop_on_request(times:)
    attempts = 0
    while attempts < times
      response = yield

      # Prevent empty body when content is blocked by host
      return response if response&.body.is_a?(String)
      attempts += 1
    end

    raise Lulzscrap::Request::ConnectionBlockedByHost
  end

  class ConnectionBlockedByHost < Lulzscrap::Scrap::Exception; end
end
