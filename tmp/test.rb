require './fb_page_crawler'
#require './config/fb_config'
require './config_tmp'
require 'time'
require 'rubygems'
require 'bson'
require './test_functions'


UID = "100000084109008"
APP_TOKEN = "571548196209117|RUlkmpJw5Iz-wOgIZxE-1KzGJFY"
PAGEID = "kfctaiwan"
POSTID = "324273577645211_485199588219275"
POSTID2 = "182099101856685_507301769336415"

PAGES = ['mcdonalds.tw','kfctaiwan','mosburger.tw','PizzaHut.TW','pec21c','Dominos.tw','BurgerKingTW','119109161438728']
POSTS = ["324273577645211_485979561474611", "324273577645211_485199588219275", "324273577645211_484830968256137", "324273577645211_484743631598204", "324273577645211_484352118304022", "324273577645211_484343488304885", "324273577645211_484005045005396", "324273577645211_483694791703088", "324273577645211_483632758375958", "324273577645211_483113345094566"]

#101615286547831 mcdonalds.tw 台灣麥當勞官方粉絲團
#324273577645211 kfctaiwan 肯德基 KFC Taiwan 非吃不可粉絲團
#259676855661 mosburger.tw MOS Burger 摩斯漢堡「癮迷」俱樂部
#263705449348 PizzaHut.TW 必勝客 Pizza Hut Taiwan
#169166689767336 pec21c 21 Century 風味館
#115361891807579 Dominos.tw 達美樂 Domino's Pizza Taiwan
#363470173013 BurgerKingTW BurgerKing 漢堡王火烤美味分享團
#119109161438728  爭鮮
#267009673341918 tw.yoshinoya 吉野家‧發現幸福
#194009723957256 openlife.co 開心集。開心點 OPENLIFE！

def test_functions
  myfb = FbPageCrawler.new
  myfb.app_id = APP_ID
  myfb.app_secret = APP_SECRET
  myfb.page_limit = 100

  t0 = Time.parse("2013-01-1T12:42:42+00:00").to_i
  t1 = Time.parse("2013-04-01T12:00:00+08:00").to_i
  t2 = Time.parse("2013-05-01T12:00:00+08:00").to_i
  
  t_latest = nil
  t_oldest = nil

  user_id = '100000084109008'
  page_ids = ['mcdonalds.tw','kfctaiwan','mosburger.tw','PizzaHut.TW','pec21c','Dominos.tw','BurgerKingTW','119109161438728']
  page_id = page_ids[0]

  pline = lambda { puts '------------------------------'}
  # Test fb_get_token
  puts 'fb_get_token: '
  result = myfb.fb_get_token!
  p result
  pline.call

  # Test fb_get_user
  print 'fb_get_user: '
  result = myfb.fb_get_user(user_id)
  p result
  pline.call

  # Test fb_get_posts
  print 'fb_get_posts: '
  result = myfb.fb_get_posts(page_id, :since => t1, :until => t2, :limit => 3)
  result.each { |post| puts post['id']}
  puts "Retrieve #{result.size} posts"
  pline.call

  # Test fb_get_posts by block call
  print 'fb_get_posts (block): '
  myfb.fb_get_posts(page_id, :since => t1, :until => t2, :limit => 3) { |post| puts post['id'] }
  puts "Retrieve #{result.size} posts"
  pline.call

end

def test_database
include Mongo
  client = MongoClient.new(MONGODB_HOST, MONGODB_PORT)
  client.add_auth(MONGODB_DBNAME, MONGODB_USER_NAME, MONGODB_USER_PWD)
  db = client[MONGODB_DBNAME]
  #auth = db.authenticate(DB_USER_NAME, DB_USER_PWD)
  coll = db['test']

  #coll.remove
  puts 'Insert data ...'
  14.times do |i|
    doc = {'_id' => i, 'cht' => '中文測試', 'value' => rand(100), 'count' => rand(10)}
    ele = {'a' => rand(100), 'b' => rand(100)}
    doc['last_updated'] = Time.now
    #coll.insert({'_id' => i}.merge(doc))
    r = coll.update({'_id' => i}, doc)
    #r = coll.update({'_id' => i}, '$set' => {'value.a' => rand(100)})
    r= coll.insert(doc) unless r['updatedExisting']
    puts "work #{i} : #{r.inspect}"
  end

  puts 'List data ...'
  puts "There are #{coll.count} records:"
  #coll.find.each { |doc| puts doc.inspect }
  bson = coll.find('_id' => 5).first
  puts '...'
  puts bson.inspect

end

def test_multithread
  myfb = FbPageCrawler.new
  myfb.app_id = APP_ID
  myfb.app_secret = APP_SECRET
  myfb.access_token = APP_TOKEN
  myfb.page_limit = 100

  r1, r2 = nil, nil
  t1 = Thread.new {
    r1 = myfb.fb_get_post_comments(POSTS[0])
    puts 'Thread 1 Starts'
  }
  t2 = Thread.new {
    r2 = myfb.fb_get_post_comments(POSTS[1])
    puts 'Thraed 2 Starts'
  }
  t1.join
  t2.join

  puts 'r1:'
    r1.map { |e|  e['from']['name'].to_s + "\t:" + e['message'].to_s }.each { |i|  puts i}
  puts 'r2:'
    r2.map { |e|  e['from']['name'].to_s + "\t:" + e['message'].to_s }.each { |i|  puts i}

end

def test_active_user(myfb, target_id)
  find_target = {'page_id' => target_id}
  #find_target = {}
  fields = {'last_updated' => 1, 'post_time' => 1, 'doc' => 1, 'page_id' => 1}
  #find_opts = {:sort => ['last_updated', :ascending], :fields => fields}
  find_opts = {:fields => fields}
  page_posts = myfb.mongo_db[TABLE_POSTS].find({'page_id' => target_id},:fields => {'_id' => 1, 'post_time' => 1}).to_a

  users_c = {}
  users_l = {}
  active_users = {}

  ccoll = myfb.mongo_db[TABLE_COMMENTS]
  lcoll = myfb.mongo_db[TABLE_LIKES]
  psum = 0
  csum = 0
  hasc_sum = 0
  maxv = 0
  target_id = ''
  page_posts.each { |post|
  find_target = {'_id' => post['_id']}
  ccoll.find(find_target,find_opts).limit(1).each { |e|
    psum += 1 
    #csum += e['doc']['comments']['data'].size if e['doc']['comments']
    #e['doc'].each { |i| p i }
    #hasc_sum += 1 if e['doc']['comments']
    tmp = e['doc'].size
    e['doc'].each { |cc| users_c[cc['from']['id']] = cc['from']['name'] }
    #e['doc'].each { |cc| puts cc['message'].gsub(/\s/,' ')}
    csum += tmp
    hasc_sum += 1 if tmp > 0 # not necessary
    if tmp > maxv
      maxv = tmp
      target_id = e['_id']
    end
  }
  #
  lcoll.find(find_target,find_opts).limit(1).each { |e|
    tmp = e['doc'].size
    e['doc'].each { |cc| users_l[cc['id']] = cc['name'] }
  }
  }
  active_users = users_c.merge users_l
  puts "#{page_posts.size} posts"
  puts "Max comment value is #{maxv}, by #{target_id}"
  puts "#{csum} comments in #{hasc_sum} posts over total #{page_posts.size} posts"
  puts "#{users_c.size} users left comments, #{users_l.size} users likes"
  puts "Total #{active_users.size} active users"
end

def list_coll(mongodb, collname)
  coll = mongodb[collname]
  puts "Table #{collname}:"
  coll.find.each { |e| puts "#{e['_id']}: #{e['doc']['created_time']} (#{e['last_updated']}" }
  #coll.find.each { |e| puts e.inspect }
  puts "Total #{coll.size} records"
end

def db_init(myfb, pages)
  pages.each { |e|
    puts "Page \"#{e}\":"
    myfb.db_add_page(e)
  }
end

def testa(a, opts={}, &block)
  r = "*#{a + opts.inspect}*"
  testb(r, &block)
end

def testb(b)
  yield "<#{b}>"
end

def output_comments(page_id)
  myfb = FbPageCrawler.new
  myfb.app_id = APP_ID
  myfb.app_secret = APP_SECRET
  myfb.access_token = APP_TOKEN
  myfb.page_limit = 100
  
  find_target = {'page_id' => page_id}
  fields = {'_id' => 1, 'last_updated' => 1, 'post_time' => 1, 'doc' => 1, 'page_id' => 1}
  #find_opts = {:sort => ['last_updated', :ascending], :fields => fields}
  find_opts = {:fields => fields}

  pcoll = myfb.mongo_db[TABLE_POSTS]
  ccoll = myfb.mongo_db[TABLE_COMMENTS]
  lcoll = myfb.mongo_db[TABLE_LIKES]

  post_count = 0
  comt_count = 0
  puts "Processing page #{page_id} ..."
  File.open("./tmp/comments/#{page_id}.txt", 'w+') { |file|
    posts = pcoll.find(find_target, find_opts).to_a
    posts.each{ |post|
      next if post['doc'].has_key?('error')
      next if post['doc']['message'].nil?
      post_count += 1
      # write posts info into file
      #p post unless post.has_key?('doc')
      #p post unless post['doc'].has_key?('from')
      output_data = []
      output_data << post['_id'] << post['_id'] << post['doc']['from']['id']
      output_data << Time.parse(post['doc']['created_time'].to_s).to_i
      output_data << Time.parse(post['doc']['created_time'].to_s).iso8601
      output_data << post['doc']['message'].to_s.gsub(/\s/, ' ')
      file.puts output_data.join("\t").to_s
      # find all comments for the post
      ccoll.find({'_id' => post['_id']}, find_opts).each { |pcomt|
        comt_count += pcomt['doc'].size
        pcomt['doc'].each{ |e|
          output_data = []
          output_data << post['_id'] << e['id'] << e['from']['id']
          output_data << Time.parse(e['created_time'].to_s).to_i
          output_data << Time.parse(e['created_time'].to_s).iso8601
          output_data << e['message'].to_s.gsub(/\s/, ' ')
          file.puts output_data.join("\t").to_s
        }
      }

    }
    puts "Page(#{page_id}): #{comt_count} comments in #{post_count} posts over total #{posts.size} posts"
  }

end

def dump_posts(page_id)
  myfb = FbPageCrawler.new
  pcoll = myfb.mongo_db[TABLE_POSTS]
  ccoll = myfb.mongo_db[TABLE_COMMENTS]
  lcoll = myfb.mongo_db[TABLE_LIKES]
  find_target = {'page_id' => page_id}
  fields = {} #{'_id' => 1, 'last_updated' => 1, 'post_time' => 1, 'doc' => 1, 'page_id' => 1}
  #find_opts = {:sort => ['last_updated', :ascending], :fields => fields}
  find_opts = {:fields => fields}

  puts "Processing page #{page_id} ..."
  File.open("./tmp/posts/#{page_id}.txt", 'w+') { |file|
    pcoll.find(find_target,{}).each{ |post|
      comment_count = 0
      comment_count2 = 0
      db_comment = ccoll.find_one({'_id' => post['_id']}, {:fields => {'count' => 1}})
      comment_count = post['doc']['comments']['data'].size if post['doc'].has_key?('comments')
      comment_count2 = db_comment['count'] unless db_comment.nil?
      comment_count = comment_count2 if comment_count2 > comment_count
      post['comment_count'] = comment_count
      file.puts post.to_json
    }
  }
end

def dump_pages(page_id)
  myfb = FbPageCrawler.new
  pcoll = myfb.mongo_db[TABLE_PAGES]
  find_target = {'_id' => page_id}
  fields = {} #{'_id' => 1, 'last_updated' => 1, 'post_time' => 1, 'doc' => 1, 'page_id' => 1}
  #find_opts = {:sort => ['last_updated', :ascending], :fields => fields}
  find_opts = {:fields => fields}

  puts "Processing page #{page_id} ..."
  File.open("./tmp/posts/pagesinfo.txt", 'a+') { |file|
    pcoll.find(find_target,{}).each{ |post|
      file.puts post.to_json
    }
  }
end

def main
  myfb = FbPageCrawler.new
  myfb.app_id = APP_ID
  myfb.app_secret = APP_SECRET
  myfb.access_token = APP_TOKEN
  myfb.page_limit = 100
  #myfb.apply_fields = true

  page_ids = ['mcdonalds.tw','kfctaiwan','mosburger.tw','PizzaHut.TW','pec21c','Dominos.tw','BurgerKingTW','119109161438728']
  page_id = page_ids[1]

  t0 = Time.parse("2013-05-01T02:42:42+00:00").to_i

  #test_database

  #puts page_ids.join("\n")

  #myfb.mongo_db[TABLE_PAGES].remove
  #myfb.mongo_db[TABLE_POSTS].remove
  #myfb.mongo_db[TABLE_COMMENTS].remove
  #myfb.mongo_db[TABLE_LIKES].remove

  #myfb.db_add_page(page_id)
  #db_init(myfb, page_ids)

  $leave = false
  #Signal.trap('INT'){
    $leave = true
  #  puts 'Waitting program to terminate ...'
  #}

  #$leave = true
  time_care = Time.new(2013, 5, 1)
  counter = 0
  until $leave
  
  end

  #find_target = {'page_id' => '194009723957256'}
  find_target = {'page_id' => '169166689767336'}
  find_target = {}
  fields = {'_id' => 1, 'last_updated' => 1, 'post_time' => 1, 'doc' => 1, 'page_id' => 1}
  #find_opts = {:sort => ['last_updated', :ascending], :fields => fields}
  find_opts = {:fields => fields}

  #test_active_user(myfb, '101615286547831')
  #myfb.db_read_pages.each { |e| puts "#{e['_id']} #{e['doc']['username']} #{e['doc']['name']}"}

  pcoll = myfb.mongo_db[TABLE_POSTS]
  ccoll = myfb.mongo_db[TABLE_COMMENTS]
  lcoll = myfb.mongo_db[TABLE_LIKES]

  p_sta = Hash.new(0)
  c_sta = Hash.new(0)
  l_sta = Hash.new(0)

  sum1 = 0
  sum2 = 0 
  sum3 = 0

  File.open('./tmp/hotposts.txt', 'w+') { |f|
    pcoll.find({'doc.likes.count' => { '$gt' => 5000 }}, find_opts).each { |post|
      msg = ''
      msg = post['doc']['message'].to_s.gsub(/\s/, ' ') if post.has_key?('doc')
      time = post['post_time'].strftime('%Y-%m-%d')
      f.print post['_id'], "\t", time, "\t", post['page_id'], "\t", post['doc']['likes']['count'], "\t", post['doc']['type'], "\t", msg
      f.puts
    }
  }

  #output_users(myfb, '324273577645211')
  #dump_users_action(myfb)

  #pages = myfb.db_read_pages
  #pages.each { |e| 
  #  puts "#{e['_id']} \t#{e['doc']['username']}  \t#{e['doc']['likes']} \t##{e['doc']['name']}"
  #}
  #puts "Total #{pages.size} pages"

  #output_comments('119109161438728')
  food_pages = ['101615286547831', '324273577645211', '259676855661', '263705449348', '169166689767336', '115361891807579', '363470173013', '119109161438728', '267009673341918']
  food_pages.each { |page_id|
    #puts "Processing page #{page_id}"
    #output_comments(page_id)
  }
  #output_comments('267009673341918')  

  #{'doc.error':{$exists:true}}

  #pages = []
  #File.open('tmp/41pages.txt', 'r') { |f|
  #  f.each { |line|
      #puts line
  #    id = line.to_i
  #    pages.push id.to_s if id > 0
  #  }
  #}
  
end #main


# Main Process begins
begin
  time_start = Time.now
  puts "Start: #{time_start}"
  puts "========================================"
  main
rescue => ex
  $stderr.puts ex.message
  $stderr.puts ex.backtrace.join("\n")
ensure
  time_end = Time.now
  puts "========================================"
  puts "End: #{time_end}"
  time_cost = time_end - time_start
  puts "Time cost: #{time_cost} seconds"
  puts "Time cost: #{Time.at(time_cost).gmtime.strftime('%R:%S')}"
end
