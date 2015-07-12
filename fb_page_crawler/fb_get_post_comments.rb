class FbPageCrawler
  # Return a array of comments in a post
  # each element is a hash: id, from{id, name}, message, like_count, created_time
  def fb_get_post_comments(post_id)
    limit = 100
    maxlimit = @page_maxlimit
    offset = 0
    result = []
    begin
      raise 'post_id can not be empty' if post_id.nil? || post_id.empty?
      query = "/#{post_id}/comments?"
      query << "fields=id,from,message,like_count" if @apply_fields
      query << "&limit=#{limit}&offset=#{offset}"
	  #puts query
      data = fb_graph_get(query)
      raise 'No available data retrieved' if data.nil? || data.empty?
      data = JSON.parse(data)
      raise 'No available data retrieved' unless data.has_key?('data')

      #json format: {"id"=>id, "from"=>name}, ...]
      #result.merge! Hash[ json_data['data'].map{|item| [item['id'], item['name']]} ]
      tmp_result =  Array(data['data']) # ensure result will be an array
      tmp_result.each { |item| yield item } if block_given? # OPTIMIZE: improve yield performance
      result.concat(tmp_result)
      offset += limit

      #$stderr.puts "fb_get_post_comments: receive #{tmp_result.size} data from post #{post_id}" if tmp_result.size > 0
      # TRICKY: skip next querying to improve performance
      # REVIEW: cancel the below break if some comments could be invisable due to privacy
      break if tmp_result.size < (limit * 0.9)
    end until tmp_result.size == 0 || offset >= maxlimit
    result
  rescue => ex
    @@logger.error ex.message
    @@logger.debug ex.backtrace.join("\n")
	#puts ex.message
    # Return a empty array
    []
  end
end
