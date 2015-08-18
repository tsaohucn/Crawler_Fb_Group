class FbPageCrawler
  # Check if the target is a facebook numberic id such as 123456 or 123_456
  def fb_is_numberid?(target_id)
    reg = /^\d+_?\d*$/
    reg.match(target_id)
  end
end
