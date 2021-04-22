require 'dotenv'
require "./yahoo_auction"
require "./google_drive_spreadsheet"
require "./searched_db"
require './ignore_fetch'

Dotenv.load

SPREADSHEET_KEY = ENV['GOOGLE_SPREAD_SHEET_ID'];
SEARCHED_DB = "searched.txt"

puts DateTime.now
session = GoogleDrive::Session.from_config('config.json')
spreadsheet = session.spreadsheet_by_key(SPREADSHEET_KEY)

config = ConfigSheet.new(spreadsheet);
ignore_fetch = IgnoreFetch.new(config.data[:CommonIgnoreWords])

urls = [
    # 'https://page.auctions.yahoo.co.jp/jp/auction/p796930387',
    # 'https://page.auctions.yahoo.co.jp/jp/auction/p792874883',
    # 'https://page.auctions.yahoo.co.jp/jp/auction/c853991210',
    # 'https://page.auctions.yahoo.co.jp/jp/auction/b488571371',
    # 'https://page.auctions.yahoo.co.jp/jp/auction/s771721540',
    # 'https://page.auctions.yahoo.co.jp/jp/auction/b504442130',
    # 'https://page.auctions.yahoo.co.jp/jp/auction/n454334395',
    # 'https://page.auctions.yahoo.co.jp/jp/auction/503894715',
    # 'https://page.auctions.yahoo.co.jp/jp/auction/b501980838',
    # 'https://page.auctions.yahoo.co.jp/jp/auction/g454408023',
    # 'https://page.auctions.yahoo.co.jp/jp/auction/g449852684',
    # 'https://page.auctions.yahoo.co.jp/jp/auction/u384546826',
    # 'https://page.auctions.yahoo.co.jp/jp/auction/b500753793',
    # 'https://page.auctions.yahoo.co.jp/jp/auction/g454339401',
    # 'https://page.auctions.yahoo.co.jp/jp/auction/o424776621',
    # 'https://page.auctions.yahoo.co.jp/jp/auction/h504510760',
    'https://page.auctions.yahoo.co.jp/jp/auction/s755215858',
    'https://page.auctions.yahoo.co.jp/jp/auction/c853785554',
    'https://page.auctions.yahoo.co.jp/jp/auction/d438051549',
    'https://page.auctions.yahoo.co.jp/jp/auction/c818393611'
]

urls.each do |url|
  if ignore_fetch.match? url
    puts "#{url} : 除外"
  else
    puts "#{url} : 対象"
  end
end