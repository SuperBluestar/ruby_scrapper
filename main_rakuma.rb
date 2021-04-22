require 'dotenv'
require "./rakuma"
require "./google_drive_spreadsheet"
require "./searched_db"
require './notification'

SPREADSHEET_KEY = ENV['GOOGLE_SPREAD_SHEET_ID'];
SEARCHED_RAKUMA_DB = 'searched_rakuma.txt'
IGNORE_TITLE_DB = 'rakuma_ignore_title.txt'

started_at = Time.now
notification = Notification.new

puts DateTime.now
session = GoogleDrive::Session.from_config('config.json')
spreadsheet = session.spreadsheet_by_key(SPREADSHEET_KEY)

config = ConfigSheet.new(spreadsheet)
inputs = InputSheet.new(spreadsheet)
outputs = OutputSheet.new(spreadsheet)
searched = SearchedDB.new(SEARCHED_RAKUMA_DB)
ignore_title_db = SearchedDB.new(IGNORE_TITLE_DB)
ignore_words = config.data[:CommonIgnoreWords]
ignore_words.gsub! /\R/, ' '
ignore_words.gsub! /　/, ' '
ignore_words = ignore_words.split ' '

inputs.data.each { |x|
  if x[:enable] != 'x' && x[:purchase_price].to_i > 0
    puts x
    invalids = x[:invalids]
    list = RakumaList.new(x, config.data[:SearchLimit].to_i, invalids: invalids)
    filtered = [];
    list.products.each { |p|
      if outputs.check2(p) == nil
        if !searched.check(p.id) && !ignore_title_db.check(p.title)
          p.load
          filtered << p unless p.ignore?(ignore_words)
        end
      end
      searched.update p.id, DateTime.now
      ignore_title_db.update p.title, DateTime.now
    }
    filtered.each { |p|
      outputs.add_new_item(p) if (p.price.to_i < p.data[:purchase_price].delete(',').to_i)
    }
    sleep(5)
  end
}
searched.save
ignore_title_db.save
outputs.save

notification.send 'RakumaList', started_at
puts DateTime.now