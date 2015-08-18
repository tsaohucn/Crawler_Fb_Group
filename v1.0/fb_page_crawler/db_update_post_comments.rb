class FbPageCrawler
  # Update comments for the post
  def db_update_post_comments(post_id)
    time_update = Time.now
    comments = fb_get_post_comments(post_id)
	#print post_id.to_s << " comments is empty? "
	#puts comments.empty?
    return if comments.empty?
    coll = @mongo_db[TABLE_COMMENTS]
    target = {'_id' => post_id}
    if comments.size >= 900 # facebook limit is 1000
      old_comments = coll.find(target,{:fields => {'doc' => 1}}).first
      old_comments = old_comments['doc'] unless old_comments.nil?
      comments.concat(old_comments) unless old_comments.nil?
      comments.uniq!{ |s| s['id'] } unless old_comments.nil?
    end
    data = {'_id' => post_id,
            'last_updated' => time_update,
            'count' => comments.size,
            'page_id' => post_id.scan(/\d+/).first,
            'doc' => comments}
    res = coll.update(target, data)
	#puts "post_comment result=" << res.to_s
    coll.insert(data) if res.has_key?('nModified') && res['nModified'] == 0
    #@@logger.debug "db_update_post_comments: post_id=#{post_id} response:#{res.inspect}"
	$stderr.puts "db_update_post_comments: post_id=#{post_id} response:#{res.inspect}"
  rescue => ex
    @@logger.error ex.message
    @@logger.debug ex.backtrace.join("\n")
  end
end
