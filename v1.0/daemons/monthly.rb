#!/usr/bin/env ruby
#require './fb_page_crawler'
#require './config/fb_config'
require '../config/db_w_config'
require 'time'
require 'rubygems'
require 'json'
require 'bson'
require 'mongo'

$output_path = '../tmp/monthly/'
#$output_path = '/home/youlin/projects/fb_page_crawler/tmp/monthly/'

def monthly_update(mongo_db, page_id, year, month)
  pcoll = mongo_db[TABLE_POSTS]
  ccoll = mongo_db[TABLE_COMMENTS]
  lcoll = mongo_db[TABLE_LIKES]
  ucoll = mongo_db[TABLE_USERS]
  scoll = mongo_db[TABLE_STATISTICS]

  db_id = page_id + '+' + ('%04d-%02d' % [year,month])
  file_name = $output_path + db_id + '.txt'
  puts "Processing statistics for #{db_id} ..."
  if File.exist?(file_name)
    #return # don't update existing files
    mtime = File.new(file_name).mtime.utc
    ntime = Time.new.utc
    ttime = Time.utc(year,month)
    return if mtime - ttime > 60 * 60 * 24 * 30 * 2 # 2 months, don't update old files that have been updated
    return if ntime - mtime < 60 * 60 * 23 # 1 day, don't update files that have been updated recently
  end

  date_start = Time.utc(year,month)
  year2 = year
  month2 = month + 1
  if month2 > 12
    year2 += 1
    month2 = 1
  end
  date_end = Time.utc(year2,month2)

  find_target = {'page_id' => page_id, 'post_time' => { '$gt' => date_start - 1, '$lt' => date_end}}
  fields = {'_id' => 1, 'last_updated' => 1, 'post_time' => 1, 'page_id' => 1, 
            'doc.type' => 1, 'doc.shares.count' => 1, 'doc.likes.count' => 1}
  find_opts = {:fields => fields}

  db_data = { '_id' => db_id,
              'page_id' => page_id,
              'year' => year,
              'month' => month,
              'last_updated' => Time.now,
              #'users' => nil,
              'share_count' => 0,
              'user_count' => 0,
              'post_count' => 0,
              'comment_count' => 0,
            }
  users_hash = Hash.new { |h,k| h[k] = Hash.new(0) }
  #scoll.insert(db_data)
  #raise "Page \"#{page_id}\" has been in the database" unless coll.find('_id' => page_data['id']).first.nil?
  pcoll.find(find_target,find_opts).each{ |post|
    db_data['post_count'] += 1
    # shares
    share_count = 0
    share_count = post['doc']['shares']['count'].to_i if post.has_key?('doc') && post['doc'].has_key?('shares')
    db_data['share_count'] += share_count

    # comments
    comment_count = 0
    #likes_on_comments = 0
    db_comment = ccoll.find_one({'_id' => post['_id']}, {:fields => {'count' => 1, 'doc' => 1}}) # find the post comments
    comment_count = post['doc']['comments']['data'].size if post['doc'].has_key?('comments')
    unless db_comment.nil?
      comment_count = db_comment['count'] if db_comment['count'] > comment_count
      db_comment['doc'].each { |e|
        #likes_on_comments += e['like_count'].to_i
        next unless e.has_key?('from')
        tmp_id = '0'
        tmp_id = e['from']['id'] if !e['from'].nil? && e['from'].has_key?('id')
        users_hash[tmp_id][:comments] += 1
        users_hash[tmp_id][:likes_on_comments] += e['like_count'].to_i
      }
    end
    db_data['comment_count'] += comment_count

    # likes
    db_like = lcoll.find_one({'_id' => post['_id']}, {:fields => {'count' => 1, 'doc' => 1}}) # find the post likes
    unless db_like.nil?
      db_like['doc'].each { |e|
        users_hash[e['id']][:likes] += 1
      }
    end
  }

  # update users
  db_data['user_count'] = users_hash.size
  #db_data['users'] = users_hash # remove this due to document size limit

  # write to database
  puts "#{db_data['post_count']} posts are processed for #{page_id} at #{"%04d-%02d" % [year,month]}"
  return if db_data['post_count'] == 0
  res = scoll.update({'_id' => db_data['_id']}, db_data)
  scoll.insert(db_data) if res.has_key?('updatedExisting') && res['updatedExisting'] == false

  File.open(file_name, 'w+'){ |file|
    users_hash.each{ |k,v|
      file.puts ({id: k}.merge v).to_json
    }
  }
rescue => ex
  $stderr.puts ex.message
  $stderr.puts ex.backtrace.join("\n")
end

def all_update(mongo_db)
  page_coll = mongo_db[TABLE_PAGES]
  find_target = {}
  fields = {'_id' => 1, 'last_updated' => 1, 
            'doc.name' => 1, 'doc.username' => 1,
            'latest_post_time' => 1, 'oldest_post_time' => 1}
  #find_opts = {:sort => ['last_updated', :ascending], :fields => fields}
  find_opts = {:fields => fields}
  page_count = 0
  page_coll.find(find_target, find_opts).each { |page|
    page_count += 1
    puts "#{page['_id']} (#{page['doc']['name']}): #{page['oldest_post_time']} ~ #{page['latest_post_time']}"
    page_full_update(mongo_db, page['_id'], page['oldest_post_time'], page['latest_post_time'])
  }
  puts "#{page_count} pages are processed"

end

def page_full_update(mongo_db, page_id, date_start = nil, date_end = nil)
  year1 = month1 = year2 = month2 = 0
  if date_start.nil? || date_end.nil?
    page_coll = mongo_db[TABLE_PAGES]
    find_target = {'_id' => page_id}
    fields = {'_id' => 1, 'last_updated' => 1, 
              'doc.name' => 1, 'doc.username' => 1,
              'latest_post_time' => 1, 'oldest_post_time' => 1}
    #find_opts = {:sort => ['last_updated', :ascending], :fields => fields}
    find_opts = {:fields => fields}
    page_info = page_coll.find_one(find_target, find_opts)
    raise "Cannot find page #{page_id}" if page_info.nil?

    year1 = page_info['oldest_post_time'].utc.year
    month1 = page_info['oldest_post_time'].utc.month
    year2 = page_info['latest_post_time'].utc.year
    month2 = page_info['latest_post_time'].utc.month
  elsif
    year1 = date_start.utc.year
    month1 = date_start.utc.month
    year2 = date_end.utc.year
    month2 = date_end.utc.month
  end

  while year1 * 12 + month1 <= year2 * 12 + month2
    #puts "%s <%04d-%02d>" % [page_id, year1, month1]
    monthly_update(mongo_db, page_id, year1, month1)
    month1 += 1
    if month1 > 12
      month1 = 1
      year1 += 1
    end
  end

end

def main
  include Mongo
  client = MongoClient.new(MONGODB_HOST, MONGODB_PORT)
  client.add_auth(MONGODB_DBNAME, MONGODB_USER_NAME, MONGODB_USER_PWD, MONGODB_DBNAME)
  mongo_db = client[MONGODB_DBNAME]

  # test
  unless Dir.exists?($output_path)
    puts "Creating #{$output_path}"
    Dir.mkdir($output_path)
  end

  #page_id = '267009673341918'
  #year = 2011
  #month = 11
  #monthly_update(mongo_db, page_id, year, month)
  #page_full_update(mongo_db, page_id)
  all_update(mongo_db)

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
