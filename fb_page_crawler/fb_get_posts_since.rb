class FbPageCrawler
  # Retrieve posts from now to last_time
  # return a array of post hashes
  # last_time must be Time
  # last_time should be the latest posts that has been obtained in past
  def fb_get_posts_since(page_id, last_time, opts={})
    find_opts = {
      :since => last_time,
      :until => nil,
      :limit => @page_limit,
      :access_token => @access_token
    }.merge opts # TODO: rewrite opts with ruby 2.0 features
    result = []
    t_latest, t_oldest = nil, Time.now
    begin
      find_opts[:until] = t_oldest - 1
      data = fb_get_posts(page_id, find_opts)
      #$stderr.puts "fb_get_posts_since: receive #{data.size} records from page #{page_id}" if data.size > 0
      result.concat(data) unless data.empty?
      # The received posts from facebook have been sorted from new to old
      unless result.empty?
        # Sort result if it is not sorted
        t_latest = Time.parse(result.first['created_time']) # unused now
        t_oldest = Time.parse(result.last['created_time'])
      end
    end until data.empty?
    result.each { |item| yield item } if block_given? # OPTIMIZE: improve yield performance
    result
  rescue => ex
    @@logger.error ex.message
    @@logger.debug ex.backtrace.join('\n')
    # Return a empty array
    []
  end
end

