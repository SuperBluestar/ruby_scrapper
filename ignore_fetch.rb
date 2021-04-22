require 'dotenv'
require 'open-uri'
require 'uri'
require 'json'
Dotenv.load

class IgnoreFetch
  def initialize(ignore_words)
    @ignore_words = ignore_words
    unless @ignore_words.is_a? Array
      @ignore_words.gsub! /\R/, ' '
      @ignore_words.gsub! /　/, ' '
      @ignore_words = @ignore_words.split ' '
    end
  end

  def match?(target_url)
    return false if @ignore_words.empty?
    params = "#{target_url}&"
    params = params + @ignore_words.map { |ignore_word|
      "keyword[]=#{ignore_word}"
    }.join('&')
    result = open("#{ENV['LM_API_URL']}api/html_parses?url=#{URI.encode(params)}", 'LMAPITOKEN' => ENV['LM_API_TOKEN']).read
    result = JSON.parse(result, symbolize_names: true)
    sleep 1
    result[:match]
  rescue => e
    puts e
    sleep 10
    return false
  end

  def match_here?(target_url)
    return false if @ignore_words.empty?
    result = open("#{ENV['LM_API_URL']}api/html_parses/show?url=#{URI.encode(target_url)}", 'LMAPITOKEN' => ENV['LM_API_TOKEN']).read
    result = JSON.parse(result, symbolize_names: true)
    sleep 1
    ignore_check result[:content]
  rescue => e
    puts e
    sleep 10
    return false
  end

  private
    def ignore_check(text)
      return false if @ignore_words.empty?
      @ignore_words.any? do |ignore_word|
        !text.index(ignore_word).nil?
      end
    end
end