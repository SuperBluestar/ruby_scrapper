require 'open-uri'
require 'nokogiri'
require 'uri'
require 'pp'

class RakumaList
  URL = 'https://fril.jp/s?'

  attr_reader :products

  def initialize(data, limit, invalids: '')
    @data = data
    @invalids = invalids
    @limit = limit # 最大検索数
    @count = 0 # ヒット数
    @products = [] # 商品リスト
    @request = 36 # 1回あたりの表示数
    page = 1
    while @products.size < @limit
      list = getList(page)
      @products += list
      break if list.size < @request
      page += 1
      sleep(3)
    end
  end

  def gsub_space(url)
    url.gsub(/　/,"%E3%80%80").gsub(/ /,"%20").gsub(/\t/,"%09")
  end

  def getList(page)
    list = []
    keyword = @data[:words]
    url = URL + URI.encode_www_form(query: keyword)
    url = url + '&category_id=682&status=new&transaction=selling'
    url = url + '&max=' + @data[:purchase_price].delete(',').to_s
    url = url + '&' + URI.encode_www_form(page: page)
    puts url
    begin
      charset = nil
      contents = open(url) { |f| charset = f.charset; f.read }
      date = DateTime.now
      doc = Nokogiri::HTML.parse(contents, nil, charset)
      if doc.css('.nohit')[0] == nil
        doc.css('.item').each { |p|
          product = RakumaProduct.new(p, @data, date)
          if product.check
            list << product
          end
        }
      end
    rescue
      puts "ERROR: #$!"
    end
    list
  end
end

class RakumaProduct
  URL = 'https://item.fril.jp/'
  attr_reader :data, :title, :link, :seller, :seller_url, :seller_good, :seller_bad, :date, :id, :price

  def initialize(product, data, date)
    @data = data
    @date = date
    @link = product.css('a')[0][:href] # 商品リンク
    @title = product.at("//span[@itemprop = 'name']").children.text # 商品タイトル
    @price = product.at("//span[@itemprop = 'price']").children.text.delete(',¥').to_i # 商品価格
    @sold = (product.css('.item-box__soldout_ribbon').size > 0 ? :SOLD : :SELL) # 販売状態
    @id = auctionID
  end

  def check
    @data[:words].split(/\s/).each { |w| return true if @title.downcase.include?(w.downcase) == true }
    false
  end

  def load
    return if @sold == :SOLD
    begin
      puts @link
      charset = nil
      contents = open(@link) { |f| charset = f.charset; f.read }
      doc = Nokogiri::HTML.parse(contents, nil, charset)
      @seller = doc.css('.header-shopinfo__shop-name')[0].children.text
      @seller_url = doc.css('.shopinfo-wrap')[0][:href]
      @seller_good = 0
      @seller_bad = 0
      @description = doc.css('.item__description').inner_html
      sleep(2)
    rescue
      puts "ERROR: #$!"
    end
  end

  def ignore?(ignore_words)
    return false if ignore_words.empty? || @description.empty?
    ignore_words.each do |ignore_word|
      return true if @description.include? ignore_word
    end
    false
  end

  def auctionID
    @link.gsub(URL, '')
  end
end

