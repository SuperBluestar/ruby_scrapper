require 'dotenv'
require "./yahoo_auction"
require "./google_drive_spreadsheet"
require './notification'

SPREADSHEET_KEY = ENV['GOOGLE_SPREAD_SHEET_ID'];
SEARCHED_DB = "searched.txt"

started_at = Time.now
notification = Notification.new

puts DateTime.now
session = GoogleDrive::Session.from_config('config.json')
spreadsheet = session.spreadsheet_by_key(SPREADSHEET_KEY)

outputs = OutputSheet.new(spreadsheet);

outputs.data.each{ |x|
	if x[:url].include?('yahoo')
		status = YahooAuctionProduct.CheckAlive(x[:url]);
		outputs.set_status_mark(x[:row], status);
		sleep(2);
	end
}

outputs.save

notification.send 'YahooAuctionProduct_CheckAlive', started_at
puts DateTime.now