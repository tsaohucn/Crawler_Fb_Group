class FbPageCrawler
  # Return a array of the users hash that like the post, {id,name}
  # Facebook only provides first 1000 records
  def fb_get_post_likes(post_id)
    limit = 200
    maxlimit = @page_maxlimit
    offset = 0
    result = []
    begin
      raise 'post_id can not be empty' if post_id.nil? || post_id.empty?
      query = "/#{post_id}/likes?"
      query << "fields=id,name" if @apply_fields
      query << "&limit=#{limit}&offset=#{offset}"

      data = fb_graph_get(query)
      raise 'No available data retrieved' if data.nil? || data.empty?
      data = JSON.parse(data)
      raise 'No available data retrieved' unless data.has_key?('data')

      # json format: [{"id"=>id, "name"=>name}, ...]
      # Convert array data into hash {id => name}
      #tmp_result = Hash[ data['data'].map{|item| [item['id'], item['name']]} ]
      tmp_result =  Array(data['data']) # ensure result will be an array 
      tmp_result.each { |item| yield item } if block_given? # OPTIMIZE: improve yield performance
      #result.merge!(tmp_result)
      result.concat(tmp_result)
      offset += limit

      #$stderr.puts "fb_get_post_likes: receive #{tmp_result.size} data from post #{post_id}" if tmp_result.size > 0
      # TRICKY: skip next querying to improve performance
      # It should work for likes because likes list should be public
      break if tmp_result.size < limit
    end until tmp_result.size == 0 || offset >= maxlimit
    result
  rescue => ex
    @@logger.error ex.message
    @@logger.debug ex.backtrace.join("\n")
    # Return a empty array
    []
  end
end
