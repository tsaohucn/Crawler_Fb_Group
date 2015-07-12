class FbPageCrawler
  # Insert data into databse
  def db_insert_data(coll, data)
    coll.insert(data)
  rescue => ex
    @@logger.error ex.message
    @@logger.debug ex.backtrace.join("\n")
  end
end
