class FbPageCrawler
  # Config the database client for mongodb
  def mongo_set_config(opts={})
    o = {:host => MONGODB_HOST,
         :port => MONGODB_PORT,
         :dbname => MONGODB_DBNAME,
         :user => MONGODB_USER_NAME,
         :pwd => MONGODB_USER_PWD}.merge opts
    client = MongoClient.new(o[:host], o[:port])
    client.add_auth(o[:dbname], o[:user], o[:pwd], o[:dbname])
    @mongo_db = client[o[:dbname]]
  end
end