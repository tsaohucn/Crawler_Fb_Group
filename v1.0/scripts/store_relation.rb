#require './fb_page_crawler'
#require './config/fb_config'
require './config/db_ro_config'
require 'time'
require 'rubygems'
require 'json'
require 'bson'
require 'mongo'
#require './test_functions'

$input_path = './scripts/'
$output_path = './tmp/store_relation/'

def is_numberic?(target_id)
  reg = /^\d+_?\d*$/
  reg.match(target_id)
end

def read_pages(pages_file)
  pages = []
  pages = File.open($input_path + pages_file, 'r').map { |page| page.strip }
  pages
end

def get_pageids(mongo_db, pages)
  page_ids = []
  pages.each { |page_name|
    if is_numberic?(page_name)
      page_ids << page_name
      #puts "page_id: #{page_name}"
      next
    end
    coll = mongo_db[TABLE_PAGES]
    find_target = {'doc.username' => page_name}
    find_opts = {:fields => {'doc.username' => 1}}
    tmp_id = coll.find_one(find_target,find_opts)['_id']
    page_ids << tmp_id
    #puts "page_id: #{tmp_id}\tpage_username: #{page_name}"
  }
  page_ids
end

def dump_users(mongo_db, page_id)
  pcoll = mongo_db[TABLE_POSTS]
  ccoll = mongo_db[TABLE_COMMENTS]
  lcoll = mongo_db[TABLE_LIKES]

  find_target = {'page_id' => page_id}
  fields = {'_id' => 1, 'last_updated' => 1, 'post_time' => 1, 'page_id' => 1, 
            'doc' => 1}
  find_opts = {:fields => fields}

  puts "Processing page #{page_id} ..."
  users = {}

  # comments
  ccoll.find(find_target, find_opts).each { |post|
    post['doc'].each { |e|
      tmp_id = e['from']['id']
      tmp_name = e['from']['name']
      users[tmp_id] = tmp_name
    }
  }

  #likes
  lcoll.find(find_target, find_opts).each { |post|
    post['doc'].each { |e|
      tmp_id = e['id']
      tmp_name = e['name']
      users[tmp_id] = tmp_name
    }
  }

  puts "Retrieve #{users.size} users"
  File.open($output_path + "#{page_id}_users.txt", 'w+') { |file|
    users.each { |k,v|
      file.puts "#{k}\t#{v}"
    }
  }
  users
end

def compute_store_relation(mongo_db, page_ids)
  page_coll = mongo_db[TABLE_PAGES]
  pcoll = mongo_db[TABLE_POSTS]
  ccoll = mongo_db[TABLE_COMMENTS]
  lcoll = mongo_db[TABLE_LIKES]

  page_doc = Hash.new

  user_comments_by_page = Hash.new { |h,k| h[k] = Hash.new(0) }
  user_likes_by_page = Hash.new{ |h,k| h[k] = Hash.new(0) }
  user_total_by_page = Hash.new{ |h,k| h[k] = Hash.new(0) }

  comments_stores = Hash.new(0)
  likes_stores = Hash.new(0)
  total_stores = Hash.new(0)

  # process each page detail data
  page_ids.each_with_index { |page_id,i|
    find_target = {'page_id' => page_id}
    #fields = {'_id' => 1, 'last_updated' => 1, 'post_time' => 1, 'page_id' => 1, 
    #          'doc' => 1}
    #find_opts = {:fields => fields}

    printf '[%2d/%2d] ', i+1, page_ids.size;
    puts "Processing page #{page_id} ..."

    # check pages
    find_opts = {:fields => {'doc' => 1}}
    page_coll.find({'_id' => page_id}, find_opts).each { |page|
      #page_name[page_id] = page['doc']['name'] if page['doc'].has_key?('name')
      page_doc[page_id] = page['doc']
    }

    # check posts
    #find_opts = {:fields => {'doc' => 1}}
    #pcoll.find(find_target, find_opts).each { |post|
    #  posts_by_page[page_id] += 1
    #}

    # check comments
    find_opts = {:fields => {'count' => 1, 'doc' => 1}}
    ccoll.find(find_target, find_opts).each { |post|
      # read comment users
      post['doc'].each { |e|
        tmp_id = e['from']['id']
        tmp_name = e['from']['name']
        user_comments_by_page[tmp_id][page_id] += 1
        user_total_by_page[tmp_id][page_id] += 1
      }
    }

    # check likes
    find_opts = {:fields => {'count' => 1, 'doc' => 1}}
    lcoll.find(find_target, find_opts).each { |post|
      # read like users
      post['doc'].each { |e|
        tmp_id = e['id']
        tmp_name = e['name']
        user_likes_by_page[tmp_id][page_id] += 1
        user_total_by_page[tmp_id][page_id] += 1
      }
    }

  }

  total_threshold = 0
  stores_threshold = 2

  File.open($output_path + 'store_relation_total.txt', 'w+') { |file|
    file.puts "\##{ page_ids.size } stores"
    file.puts "\##{ user_total_by_page.size } users"
    output_data = ['#user_id/page_id']
    output_data.concat page_ids
    output_data << 'total' << 'stores'
    file.puts output_data.join("\t")
    user_total_by_page.each{ |user_id, user_data|
      output_data = [user_id]
      sum = 0
      stores = 0
      page_ids.each { |page_id|
        stores += 1 if user_data[page_id] > 0
        sum += user_data[page_id]
        output_data << user_data[page_id]
      }
      output_data << sum << stores
      next if sum < total_threshold || stores < stores_threshold
      file.puts output_data.join("\t")
      user_data['sum'] = sum
      user_data['stores'] = stores
      total_stores[stores] += 1
    }
  }

  File.open($output_path + 'store_relation_comments.txt', 'w+') { |file|
    file.puts "\##{ page_ids.size } stores"
    file.puts "\##{ user_comments_by_page.size } users"
    output_data = ['#user_id/page_id']
    output_data.concat page_ids
    output_data << 'total' << 'stores'
    file.puts output_data.join("\t")
    user_comments_by_page.each{ |user_id, user_data|
      output_data = [user_id]
      sum = 0
      stores = 0
      page_ids.each { |page_id|
        stores += 1 if user_data[page_id] > 0
        sum += user_data[page_id]
        output_data << user_data[page_id]
      }
      output_data << sum << stores
      next if sum < total_threshold || stores < stores_threshold
      file.puts output_data.join("\t")
      user_data['sum'] = sum
      user_data['stores'] = stores
      comments_stores[stores] += 1
    }
  }

  File.open($output_path + 'store_relation_likes.txt', 'w+') { |file|
    file.puts "\##{ page_ids.size } stores"
    file.puts "\##{ user_likes_by_page.size } users"
    output_data = ['#user_id/page_id']
    output_data.concat page_ids
    output_data << 'total' << 'stores'
    file.puts output_data.join("\t")
    user_likes_by_page.each{ |user_id, user_data|
      output_data = [user_id]
      sum = 0
      stores = 0
      page_ids.each { |page_id|
        stores += 1 if user_data[page_id] > 0
        sum += user_data[page_id]
        output_data << user_data[page_id]
      }
      output_data << sum << stores
      next if sum < total_threshold || stores < stores_threshold
      file.puts output_data.join("\t")
      user_data['sum'] = sum
      user_data['stores'] = stores
      likes_stores[stores] += 1
    }
  }

  puts "#{ page_ids.size } stores"
  puts "total distribution: "
  p total_stores
  puts "comments distribution: "
  p comments_stores
  puts "likes distribution: "
  p likes_stores

end

def main
  include Mongo
  client = MongoClient.new(MONGODB_HOST, MONGODB_PORT)
  client.add_auth(MONGODB_DBNAME, MONGODB_USER_NAME, MONGODB_USER_PWD, MONGODB_DBNAME)
  mongo_db = client[MONGODB_DBNAME]

  coll = mongo_db[TABLE_PAGES]
  pcoll = mongo_db[TABLE_POSTS]
  ccoll = mongo_db[TABLE_COMMENTS]
  lcoll = mongo_db[TABLE_LIKES]

  #page_ids = ['101615286547831','324273577645211','259676855661','263705449348','363470173013']

  find_target = {'page_id' => '259676855661'}
  find_target = {}
  fields = {'_id' => 1, 'last_updated' => 1, 'post_time' => 1, 'doc' => 1, 'page_id' => 1}
  #find_opts = {:sort => ['last_updated', :ascending], :fields => fields}
  find_opts = {:fields => fields}

  # retrieve pushme stores from the file
  file_name = 'pages_pushme.txt'
  pages = read_pages(file_name)
  puts "Read #{pages.size} records from #{file_name}"

  # confirm the facebook id for the pushme stores
  page_ids = get_pageids(mongo_db, pages)
  puts "Read #{page_ids.size} records of pushme stores"

  unless Dir.exists?($output_path)
    puts "Creating #{$output_path}"
    Dir.mkdir($output_path)
  end

  page_ids = ['101615286547831','324273577645211', '259676855661', '263705449348', '363470173013']
  #page_ids = ['141718479281233', '141785292567024', '173520646027481', '206564696048496']

  compute_store_relation(mongo_db,page_ids)

  #p page_ids
  #dump_data(mongo_db, page_ids)
  #dump_data(mongo_db, ['448442665197068','453295671370774'])

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
