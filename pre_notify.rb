require 'dotenv'
require "./yahoo_auction"
require "./google_drive_spreadsheet"
require "./searched_db"
require './ignore_fetch'
require './notification'

Dotenv.load

SPREADSHEET_KEY = ENV['GOOGLE_SPREAD_SHEET_ID'];
SEARCHED_DB = "searched.txt"

started_at = Time.now + 600

notification = Notification.new
subject = "ResearchSheet : #{started_at.strftime('%Y-%m-%d %H:%M:%S')}処理分 : 10分前通知"
body = "#{started_at.strftime('%Y-%m-%d %H:%M:%S')}処理分の10分前通知です。\n終了するまでシートの操作はしないようにしてください。"

notification.send_direct subject, body