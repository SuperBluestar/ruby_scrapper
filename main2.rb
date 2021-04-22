require 'dotenv'
require 'google_drive'
require './ebay'
require './exchange'
require "./google_drive_spreadsheet"
require './notification'

SPREADSHEET_KEY = ENV['GOOGLE_SPREAD_SHEET_ID'];

started_at = Time.now
notification = Notification.new

puts DateTime.now
session = GoogleDrive::Session.from_config('config.json')
spreadsheet = session.spreadsheet_by_key(SPREADSHEET_KEY)
config = ConfigSheet.new(spreadsheet);
inputs = InputSheet.new(spreadsheet);
outputs = OutputSheet.new(spreadsheet);
common_invalid_words = config.data[:CommonIgnoreWordsEBay] || ''

inputs.data.each_with_index { |x, i|
  item = Ebay.new(x[:ebay_words], "#{common_invalid_words} #{x[:ebay_invalids]}", x[:ebay_category]);
  inputs.update(i, item.sold, item.sell);
  sleep(1);
}
inputs.save;

inputs.data.each_with_index { |x, i|
  puts x.to_s
  outputs.data.each { |y|
    if x[:words] == y[:words]
      puts y[:row]
      outputs.update_ebay(y[:row], x)
    end
  }
}
outputs.save;

notification.send 'Ebay', started_at
puts DateTime.now