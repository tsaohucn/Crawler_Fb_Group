class FbPageCrawler
  # Acquire application access_token with app_id and app_secret
  # return the string of the access token
  # Run fb_get_token! to update access_token
  def fb_get_close_token
    #raise "app_id is empty" if @app_id.empty?
    #raise "app_secret is empty" if @app_secret.empty?
    #query = "/oauth/access_token?"
    #query << "client_id=#@app_id"
    #query << "&client_secret=#@app_secret"
    #query << "&grant_type=client_credentials"

   # res = fb_graph_get(query)
    #raise "Fail to acquire access_token" if res.nil? || res.empty?
    #token = res[/access_token=(.*)/, 1]
    #raise "Fail to acquire a correct access_token" if token.nil? || token.empty?
    @access_token = "CAAXRUfyZCg2IBABO51mtVirUJVJm3ODeZAaxsZCdO2YEHFjcZBJO8BADEZCWExKk7OYuyCXof4hLZAD4EuUWlf44C7suzsACQML2YUFZCNz2jzKJWzoZCqVaNHwHjI9fU5uqL87XS7e0FBYBpSzsSLkIsD3ZAPIFVCG2E6No8ElV9zqBVmwmRsteWSoZCK5hZBz1EMZD"
  rescue => ex
    @@logger.error ex.message
    @@logger.debug ex.backtrace.join('\n')
    ''
  end

  #def fb_get_token!
    #token = fb_get_token
    #@access_token = token unless token.nil? || token.empty?
  #end
end

