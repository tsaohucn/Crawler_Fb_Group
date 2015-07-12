#!/usr/bin/env ruby
require './fb_page_crawler'
#require './config/fb_config'
require './config_tmp.rb'
require 'time'

def main
  myfb = FbPageCrawler.new
  myfb.app_id = APP_ID
  myfb.app_secret = APP_SECRET
  #myfb.access_token = APP_TOKEN # set access_token if you have a valid one
  myfb.fb_get_token!

  ARGV.each { |page|
    puts "Adding #{page} into page database"
    myfb.db_add_page(page) # Add a page into database
  }
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
