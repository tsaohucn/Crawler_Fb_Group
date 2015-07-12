class FbPageCrawler
	# Send the query string to facebook graph host
  # return response body if '200' OK is received
	def fb_graph_get(query)
    retried = 0
    begin
      @@logger.debug 'querying: ' + query
      http = Net::HTTP.new @@fb_graph_host, '443'
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE     
	  #puts "URI.escape(query)= " <<URI.escape(query)
      req = Net::HTTP::Get.new(URI.escape(query)) # FIXME: URI.escape cause a obsolete warning
      res = http.request req
      # Handle the response from facebook graph
      # Handle response error such as invalid access_token and parameters
      @@logger.error "Fail to retrieve data (#{res.code}): #{res.body}" if res.code != '200'
      # TODO: handle facebook api error code and message
      data = JSON.parse(res.body) if res.body[0] == '{'
      if !data.nil? && data.has_key?('error')
        @@logger.error "Retrieve a error message: #{data} on querying \"#{query}\""
        if data['error'].has_key?('code')
          error_code = data['error']['code']
          $stderr.puts "FB error code (#{error_code}) : Please reduce the amount of data you're asking for, then retry your request" if error_code == -3
          $stderr.puts "FB error code (#{error_code}) : \"#{query}\" may be unavialable" if error_code == 100
          $stderr.puts "FB error code (#{error_code}) : sleep 30s" if error_code == 613
          sleep 30 if error_code == 613
        end
        return ''
      end
      res.body
    rescue => ex
      @@logger.error ex.message
	  #puts "fb_graph_get:" << ex.message.to_s
      if retried < 2 # OPTIMIZE: should apply a more efficient scheme
        $stderr.puts "fb_graph_get: retrying to query \"#{query}\""
        retried += 1
        sleep 5 * retried * retried
        retry
      end
      @@logger.debug ex.backtrace.join("\n")
    end
  end
end
