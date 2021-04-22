require 'dotenv'
require "./yahoo_auction"
require "./google_drive_spreadsheet"
require "./searched_db"
require './ignore_fetch'
require './notification'

Dotenv.load

SPREADSHEET_KEY = ENV['GOOGLE_SPREAD_SHEET_ID'];
SEARCHED_DB = "searched.txt"

started_at = Time.now
notification = Notification.new

puts DateTime.now
session = GoogleDrive::Session.from_config('config.json')
spreadsheet = session.spreadsheet_by_key(SPREADSHEET_KEY)

config = ConfigSheet.new(spreadsheet)
bans = BansSheet.new(spreadsheet)
inputs = InputSheet.new(spreadsheet);
outputs = OutputSheet.new(spreadsheet);
searched = SearchedDB.new(SEARCHED_DB);
ignore_fetch = IgnoreFetch.new(config.data[:CommonIgnoreWords])

inputs.data.each { |x|
  if x[:enable] != 'x'
    puts x
    invalids = x[:invalids] + ' ' + bans.words.join(' ');
    list = YahooAuctionList.new(x, invalids.strip, config.data[:SearchLimit].to_i, config.data[:AuctionCategory].to_i);
    filtered = [];
    list.products.each { |p|
      if outputs.check(p) != nil || searched.check(p.id) == false
        if ignore_fetch.match_here? p.link
          puts "#{p.link} +++++ 除外"
        else
          puts "#{p.link} +++++ 対象"
          if (outputs.update(p) == false)
            if searched.check(p.id) == false and p.finish != ""
              filtered << p
            else
              puts p.id.to_s + " is already checked";
            end
          end
        end
      else
        puts "#{p.link} +++++ 除外チェック前スルー"
      end
      searched.add(p.id, p.finish) if p.finish != ""
    }
    filtered.each { |p|
      if p.seller?(bans.users) and p.ids?(bans.ids) and p.rating.to_f >= config.data[:SellerRateLimit].to_f
        if p.data[:purchase_price].delete(',').to_i > p.current.to_i
          outputs.add_new(p)
        end
      end
    }
    sleep(3);
  end
}
searched.save;
outputs.save

notification.send 'YahooAuctionList', started_at
puts DateTime.now