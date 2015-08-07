#!/usr/bin/env ruby
require './fb_page_crawler'
require './config_tmp.rb'
require 'time'

def db_init(myfb, pages)
  pages.each { |e|
    #puts "Adding page \"#{e}\" into database"
    myfb.db_add_page(e)
  }
end

def main
  myfb = FbPageCrawler.new
  myfb.app_id = APP_ID
  myfb.app_secret = APP_SECRET
  #myfb.fb_get_token!
  myfb.fb_get_close_token
  #myfb.access_token = APP_TOKEN # set access_token if you have a valid one

  #page_ids = ['mcdonalds.tw','kfctaiwan','mosburger.tw','PizzaHut.TW',
  #            'pec21c','Dominos.tw','BurgerKingTW','119109161438728']

  # for initialization
  #db_remove(myfb)
  #myfb.db_add_page(page_id) # Add a page into database
  #db_init(myfb, page_ids) # Add pages into database

  $leave = false
#  Signal.trap('INT'){
#    $leave = true
#    puts ' ********** Waitting program to terminate ********** '
#  }

  time_zero = Time.at(0)
  time_new_append = Time.at(1001)
  #time_care = Time.now - 60 * 60 * 24 * 30 # only fetch posts within 30 days
  time_care = Time.new(2010, 1, 1) # only fetch posts after a specificed day
  until $leave
    total_update_time = 0
    total_add_new_feeds_time = 0
    total_add_old_feeds_time = 0
    need_updated_groups = myfb.db_obtain_groups(:limit => 100 ,:update_interval => 60)
    if need_updated_groups.size == 0
      puts "目前沒有需要更新之資料..."
      until need_updated_groups.size > 0
          need_updated_groups = myfb.db_obtain_groups(:limit => 100 ,:update_interval => 60)
      end
    end
    need_updated_groups.each { |group| # pick up pages should be updated
      #add_new_feeds
      group_add_new_feeds_time = myfb.db_add_new_feeds(group['_id'],group['doc']['name'], group['latest_feed_time'])
      total_add_new_feeds_time += group_add_new_feeds_time if group_add_new_feeds_time.class == Float
      next if $leave
      #add_old_feeds
      group_add_old_feeds_time = myfb.db_add_old_feeds(group['_id'],group['doc']['name'],group['oldest_feed_time']) if group['oldest_feed_time'] > time_care && group['check_old_feeds']
      total_add_old_feeds_time += group_add_old_feeds_time if group_add_old_feeds_time.class == Float
      next if $leave
    } 
  #  need_updated_groups.each{|group|
      #update_groups
   #   group_update_time = myfb.db_update_feeds_faster(group['_id'],group['doc']['name'])
   #   total_update_time += group_update_time if group_update_time.class == Float
   #   next if $leave
  #  }
    #File.open("./timelog.txt", "a") { |output|  
      puts "完成全部社團新文章增加[耗時#{total_add_new_feeds_time}秒]"
      puts "完成全部社團舊文章增加[耗時#{total_add_old_feeds_time}秒]"
      #puts "完成全部社團文章更新[耗時#{total_update_time}秒]"
   # }
  end

end

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
  puts "Time cost: #{time_end - time_start}"
end
