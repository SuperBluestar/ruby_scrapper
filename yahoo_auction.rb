require 'open-uri'
require 'nokogiri'
require 'uri'
require 'pp'

class YahooAuctionList
        YahooAuctionURL = 'https://auctions.yahoo.co.jp/search/search?'

	attr_reader :products
        def initialize(data, invalids, limit, category=nil)
		@data = data;
		@invalids = invalids; #除外ワード
                @limit = limit; # 最大検索数
		@category = category; # 検索カテゴリ
                @count = 0;     # ヒット数
                @products = []; # 商品リスト
                @charset = nil; # 文字コード
                @request = 50;  # 1回あたりの表示数
                offset = 1;
                while @products.size < @limit
                        list = getList(offset);
                        @products += list;
                        break if list.size < @request;	
                        offset += @request;
			sleep(5);
                end
        end

        def getList(offset)
                list = [];
		url = YahooAuctionURL + URI.encode_www_form(va: @data[:words]) + '&' + URI.encode_www_form(ve: @invalids) + '&b=' + offset.to_s + '&n=' + @request.to_s + '&mode=2&ei=UTF-8&new=1&s1=new'; # 詳細表示、UTF8、新着、新着順表示
		url = url + '&aucmaxprice=' + @data[:purchase_price].delete(',').to_s if @data[:purchase_price] != nil
		url = url + '&auccat=' + @category.to_s if @category != nil
                begin
                        contents = open(url){ |f| @charset = f.charset; f.read }
			date = DateTime.now
                        doc = Nokogiri::HTML.parse(contents, nil, @charset)
			doc.css('.Product').each{ |p| list << YahooAuctionProduct.new(p, @data, @invalids, date) } if checkCount(doc);
                rescue
                        puts "ERROR: #$!"
                end
                return list;
        end

	# 
	def checkCount(doc)
		auction = doc.css('.SearchMode').css('.Tab__item')[1].css('.Tab__subText').inner_html
		flat = doc.css('.SearchMode').css('.Tab__item')[2].css('.Tab__subText').inner_html
		return true if auction != "" or flat != ""
		return false;
	end
end

class YahooAuctionProduct
	attr_reader :title, :link, :seller, :seller_url, :rating, :current, :immediate, :finish, :data, :invalids, :date, :id

        def initialize(product, data, invalids, date)
               @title = product.css('.Product__titleLink')[0][:title]           # 商品タイトル
               @link = product.css('.Product__titleLink')[0][:href]             # 商品リンク
               @seller = product.css('.Product__seller')[0][:title]             # 出品者名
               @seller_url = product.css('.Product__seller')[0][:href]          # 出品者リンク
               @rating = product.css('.Product__rating')[0].inner_html          # 出品者評価
               @current = product.css('.Product__priceValue').first.inner_html.delete(',円'); # 現在価格
               @immediate = product.css('.Product__priceValue')[1] == nil ? "-" : product.css('.Product__priceValue')[1].inner_html.delete(',円');  # 即決価格
	       @finish = product.css('.Product__otherInfo').css('.u-textGray').inner_html;
	       @finish = $1 if /([0-9\s:\/]+)/ =~ @finish		        # 終了日時(ただし残り数分になると表示されない)
	       @data = data;
	       @invalids = invalids;
	       @date = date;
	       @id = auctionID
        end

        def seller?(names)
		names.each{ |x| return false if x == @seller }
		return true;
        end

        def ids?(ids)
		ids.each{ |x| return false if x == @id }
		return true;
        end

	def valid?
		@words.split(' ').each{ |w| 
			if /#{w}/i =~ @title then
			else 
				return false 
			end
		}
		return true;
	end

	def auctionID
		id = "-";
		id = $1 if /auction\/(.+)\z/ =~ @link;
		return id;
	end

	def YahooAuctionProduct.CheckAlive(url)
		charset = nil;
		contents = open(url){ |f| charset = f.charset; f.read }
		doc = Nokogiri::HTML.parse(contents, nil, charset)
		return doc.css('.ClosedHeader__tag').size > 0 ? :Closed : :Open
	end
end


