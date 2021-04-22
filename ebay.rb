require 'open-uri'
require 'nokogiri'
require 'uri'
require 'pp'

class Ebay
  BaseURL = "https://www.ebay.com/sch/i.html?"

  class Sitem
    attr_reader :title, :link, :price

    def initialize(item)
      link = item.css('.s-item__link')
      return if link.size == 0
      @title = item.css('.s-item__title').inner_html
      if item.css('.s-item__price').css('.POSITIVE').length == 1
        @price = item.css('.s-item__price').css('.POSITIVE').inner_html.delete('JPY,').to_f
      else
        @price = item.css('.s-item__price').inner_html.delete('JPY,').to_f
      end
      @link = item.css('.s-item__link')[0][:href]
    end
  end

  attr_reader :sold, :sell;

  def initialize(words, invalids, category)
    @words = words; # 検索ワード
    @invalids = invalids; # 除外ワード
    @category = category; # カテゴリ

    @sold = getProducts(makeURL(:sold));
    sleep(1);
    @sell = getProducts(makeURL(:sell));
  end

  def makeURL(type)
    url = BaseURL + URI.encode_www_form(_nkw: @words + " " + @invalids) + \
		     '&' + URI.encode_www_form(_sacat: @category) + \
		     "&LH_TitleDesc=0&_fsrp=1&LH_BIN=1&LH_ItemCondition=4&rt=nc"
    url = url + "&LH_Sold=1&LH1_Complete=1" if type == :sold
    puts url
    url
  end

  def getProducts(url)
    count = 0;
    price = 0;
    sitems = []
    ret = {:url => url, :count => 0, :market_price => 0};
    try = 0;
    begin
      try += 1;
      charset = nil;
      contents = open(url) { |f| charset = f.charset; f.read }
      doc = Nokogiri::HTML.parse(contents, nil, charset)
      if doc.css('.srp-controls__count-heading').css('.BOLD')[0] != nil;
        count = doc.css('.srp-controls__count-heading').css('.BOLD')[0].inner_html.to_i;
        items = doc.css('.s-item__wrapper');
        items.each do |i|
          s = Sitem.new(i)
          sitems << s unless s.title.nil?
        end if (items != nil)
        sitems.each { |p| price += p.price }
        price /= sitems.length if sitems.length > 0;
        ret[:count] = count
        ret[:sitems] = sitems
        ret[:market_price] = price
      end
    rescue
      if try < 4
        sleep(10)
        retry
      end
      puts "ERROR: #$!"
    end
    ret
  end
end

