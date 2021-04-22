require 'mail'
require 'dotenv'

Dotenv.load

Mail.defaults do
  delivery_method :smtp, {
      address: ENV['SMTP_ADDRESS'],
      port: ENV['SMTP_PORT'],
      domain: ENV['SMTP_DOMAIN'],
      user_name: ENV['SMTP_USERNAME'],
      password: ENV['SMTP_PASSWORD'],
      authentication: 'plain',
      enable_starttls_auto: true
  }
end
class Notification
  def initialize
    @start_at = {}
  end

  def send_direct(subject, body)
    Mail.deliver do
      to ENV['NOTIFICATION_TO']
      from ENV['NOTIFICATION_FROM']
      subject subject
      text_part do
        body body
        content_type 'text/plain; charset=UTF-8'
      end
    end
  end

  def send(key, started_at)
    subject = "ResearchSheet : #{key} : #{started_at.strftime('%Y-%m-%d %H:%M:%S')}処理分 : 終了"
    send_direct(subject, "ResearchSheet\n#{key}\n\n収集処理が終了しました。\nシートの操作をしていただいて問題ありません。")
  end
end