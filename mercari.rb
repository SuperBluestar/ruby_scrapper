require 'open-uri'
require 'nokogiri'
require 'uri'
require 'pp'

class MercariList
  URL = 'https://www.mercari.com/jp/search/?'

  attr_reader :products

  def initialize(data, limit, category, invalids: '')
    @data = data;
    @invalids = invalids
    @limit = limit; # 最大検索数
    @count = 0; # ヒット数
    @products = []; # 商品リスト
    @request = 50; # 1回あたりの表示数
    @category = category;
    page = 1;
    while @products.size < @limit
      list = getList(page);
      @products += list;
      break if list.size < @request;
      page += 1;
      sleep(3);
    end
  end

  def getList(page)
    list = [];
    keyword = @data[:words]
    unless @invalids.empty?
      keyword += " -#{@invalids.gsub!(/ /, ' -')}"
    end
    url = URL + URI.encode_www_form(keyword: keyword)
    url = url + '&category_root=7&category_child=' + @category;
    url = url + '&item_condition_id%5B1%5D=1&item_condition_id%5B2%5D=1&item_condition_id%5B3%5D=1&status_on_sale=1'
    url = url + '&price_max=' + @data[:purchase_price].delete(',').to_s;
    url = url + '&' + URI.encode_www_form(page: page);
    puts url
    begin
      charset = nil
      contents = open(url) { |f| charset = f.charset; f.read }
      date = DateTime.now
      doc = Nokogiri::HTML.parse(contents, nil, charset)
      if doc.css('.search-result-number')[0] != nil
        doc.css('.items-box').each { |p|
          product = Product.new(p, @data, date);
          if product.check == true;
            list << product
          end
        }
      end
    rescue
      puts "ERROR: #$!"
    end
    return list;
  end
end

class Product
  URL = 'https://www.mercari.com'
  attr_reader :data, :title, :link, :seller, :seller_url, :seller_good, :seller_bad, :date, :id, :price

  def initialize(product, data, date)
    @data = data
    @date = date
    @link = URL + product.css('a')[0][:href]; # 商品リンク
    @title = product.css('.items-box-name')[0].inner_html # 商品タイトル
    @price = product.css('.items-box-price')[0].inner_html.delete(',¥').to_i; # 商品価格
    @sold = (product.css('.item-sold-out-badge').size > 0 ? :SOLD : :SELL); # 販売状態
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
      p = doc.css('.item-detail-table')[0].css('td')
      @seller = p.css('a')[0].inner_html
      @seller_url = p.css('a')[0][:href]
      @seller_good = p.css('.item-user-ratings')[0].css('span').inner_html
      @seller_bad = p.css('.item-user-ratings')[1].css('span').inner_html
      @description = doc.css('.item-description-inner').inner_html
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
    id = "-";
    id = $1 if /items\/(.+)\// =~ @link;
    return id;
  end
end

