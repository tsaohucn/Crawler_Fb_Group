class FbPageCrawler
  # Update likes for the post
  def db_update_post_likes(post_id)
    time_update = Time.now
    likes = fb_get_post_likes(post_id)
	#print post_id.to_s << " likes is empty? "
	#puts likes.empty?
    return if likes.empty?
    coll = @mongo_db[TABLE_LIKES]
    target = {'_id' => post_id}
    if likes.size >= 900 # facebook limit is 1000
      old_likes = coll.find(target,{:fields => {'doc' => 1}}).first
      old_likes = old_likes['doc'] unless old_likes.nil?
      likes.concat(old_likes) unless old_likes.nil?
      likes.uniq!{ |s| s['id'] } unless old_likes.nil?
    end
    data = {'_id' => post_id,
            'last_updated' => time_update,
            'count' => likes.size,
            'page_id' => post_id.scan(/\d+/).first,
            'doc' => likes}
    res = coll.update(target, data)
	#puts "post_like result=" + res.to_s
    #coll.insert(data) #if res.has_key?('updatedExisting') && res['updatedExisting'] == false
	coll.insert(data) if res.has_key?('nModified') && res['nModified'] == 0
    @@logger.debug "db_update_post_likes: post_id=#{post_id} response:#{res.inspect}"
  rescue => ex
    @@logger.error ex.message
    @@logger.debug ex.backtrace.join("\n")
  end
end
