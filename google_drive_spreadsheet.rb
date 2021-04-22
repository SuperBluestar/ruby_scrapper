require 'google_drive'


class ConfigSheet
	attr_reader :data
	def initialize(spreadsheet)
		@sheet = spreadsheet.worksheet_by_title("config")
		@data = {};
		i = 1;
		loop{
			key = @sheet[i,1];
			val = @sheet[i,2];
			break if key == nil or key == "";
			@data[key.to_sym] = val;
			i += 1;
		}
	end
end

class BansSheet
	attr_reader :users, :ids, :words
	def initialize(spreadsheet)
		sheet = spreadsheet.worksheet_by_title("black")
		@users = [];
		@ids = [];
		@words = [];
		load(sheet, @users, "出品者リスト");
		load(sheet, @ids, "オークションiD");
		load(sheet, @words, "除外キーワード");
	end
	def load(sheet, ary, key)
		col = 1;
		loop{
			val = sheet[1,col]
			break if val == nil or val == "";
			if val == key
				row = 2;
				loop{
					val = sheet[row,col]
					break if val == nil or val == "";
					ary << val;
					row += 1;
				}
				break;
			end
			col += 1;
		}
	end
end

class InputSheet
	attr_reader :data
	def initialize(spreadsheet)
		@sheet = spreadsheet.worksheet_by_title("input")
		@data = [];
		@rows = [
			:words,
			:invalids,
			:ebay_words,
			:ebay_invalids,
			:ebay_category,
			:enable,
			:purchase_price,
			:ebay_sold,
			:ebay_sold_url,
			:ebay_sell,
			:ebay_sell_url,
			:ebay_sold_price,
			:ebay_sell_price,
			:postage,
			:priority,
			:note
		];
		i = 2;
		loop{
			break if @sheet[i,1] == nil or @sheet[i,1] == "";
			rec = Hash.new;
			@rows.each_with_index{ |x,r| rec[x] = @sheet[i, r+1] }
                        rec[:purchase_price].delete(',');
			@data << rec;
			i += 1;
		}
	end

	def update(num, sold, sell)
		row = num + 1 + 1;	# 項目名 + sheet index offset
		@sheet[row, @rows.index(:ebay_sold) + 1] = sold[:count] if sold[:count]
		@sheet[row, @rows.index(:ebay_sold_url) + 1] = sold[:url];
                @sheet[row, @rows.index(:ebay_sold_price) + 1] = sold[:market_price] if sold[:market_price]
		@sheet[row, @rows.index(:ebay_sell) + 1] = sell[:count] if sell[:count]
		@sheet[row, @rows.index(:ebay_sell_url) + 1] = sell[:url];
		@sheet[row, @rows.index(:ebay_sell_price) + 1] = sell[:market_price] if sell[:market_price]
		@sheet[row, @rows.index(:purchase_price) + 1] = "=L" + row.to_s + "*0.88-1100";		# (落札相場 * 0x88) - 1100が入札上限
	end

	def save
		@sheet.save
	end

	def search_target?(data, priority_limit)
		priority = data[:priority].to_f
		return true if priority >= priority_limit
    return true if data[:priority] == '#DIV/0!' && data[:ebay_sold].to_i > 0
		false
	end
end

class OutputSheet
	attr_reader :data;
	def initialize(spreadsheet)
		@sheet = spreadsheet.worksheet_by_title("output")
		@data = [];
		@products = [];
		i = 2;
		loop{
			url = @sheet[i,3];
			words = @sheet[i,9];
			url_ebay = @sheet[i,15];	# eBay需要URL
			break if url == nil or url == "";
			@data << {:row => i, :url => url, :url_ebay => url_ebay, :words => words}
			i += 1;
		}
	end

	def update(product)
		row = check(product);
		if(row != nil)
			@sheet[row, 1] = product.date.new_offset('+9:00').strftime("%Y/%m/%d %H:%M");
			@sheet[row, 4] = product.current;
			@sheet[row, 5] = product.immediate;
			@sheet[row, 8] = product.finish
			@sheet[row, 14] = product.data[:ebay_sold];		# 需要
			@sheet[row, 15] = product.data[:ebay_sold_url];		# 需要URL
			@sheet[row, 16] = product.data[:ebay_sell];		# 供給
			@sheet[row, 17] = product.data[:ebay_sell_url];		# 供給URL
			@sheet[row, 18] = product.data[:ebay_sold_price];	# 落札相場
			@sheet[row, 19] = product.data[:ebay_sell_price];	# 出品相場
			@sheet[row, 21] = product.data[:priority];
			return true;
		end
		return false;
	end

	def set_status_mark(row, status)
		str = @sheet[row, 8];
		if str != nil and str != ""
			/[A-Za-z\s]*(\d{1,2}\/\d{1,2}\s+\d{1,2}:\d{1,2})\s*\z/ =~ str
			@sheet[row, 8] = status.to_s + " " + $1;
		end
	end

	def add_new(product)
		row = lastRow;
		@sheet[row, 1] = product.date.new_offset('+9:00').strftime("%Y/%m/%d %H:%M");	# 収集日時
		@sheet[row, 2] = product.title;				# 商品タイトル
		@sheet[row, 3] = product.link;				# 商品URL
		@sheet[row, 4] = product.current;			# 現在価格
		@sheet[row, 5] = product.immediate;			# 即決価格
		@sheet[row, 6] = product.seller;			# 出品者
		@sheet[row, 7] = product.seller_url;			# 出品者URL
		@sheet[row, 8] = product.finish;			# 終了日時
		@sheet[row, 9] = product.data[:words];			# 検索ワード
		@sheet[row, 10] = product.invalids;			# 除外ワード
		@sheet[row, 11] = "";					# 入札予定
		@sheet[row, 12] = "";					# 予測収益
		@sheet[row, 13] = "=R" + row.to_s + "*0.88-1100";	# (落札相場 * 0x88) - 1100が入札上限
		@sheet[row, 14] = product.data[:ebay_sold];		# 需要
		@sheet[row, 15] = product.data[:ebay_sold_url];		# 需要URL
		@sheet[row, 16] = product.data[:ebay_sell];		# 供給
		@sheet[row, 17] = product.data[:ebay_sell_url];		# 供給URL
		@sheet[row, 18] = product.data[:ebay_sold_price];	# 落札相場
		@sheet[row, 19] = product.data[:ebay_sell_price];	# 出品相場
		@sheet[row, 20] = product.data[:postage];		# 送料
		@sheet[row, 21] = product.data[:priority];		# 優先順位
		@sheet[row, 22] = product.data[:note];	        	# 備考
	end

	def add_new_item(product)
		row = lastRow;
		@sheet[row, 1] = product.date.new_offset('+9:00').strftime("%Y/%m/%d %H:%M");	# 収集日時
		@sheet[row, 2] = product.title;				# 商品タイトル
		@sheet[row, 3] = product.link;				# 商品URL
		@sheet[row, 4] = product.price;				# 価格
		@sheet[row, 6] = product.seller;			# 出品者
		@sheet[row, 7] = product.seller_url;			# 出品者URL
		@sheet[row, 9] = product.data[:words];			# 検索ワード
		@sheet[row, 11] = "";					# 入札予定
		@sheet[row, 12] = "";					# 予測収益
		@sheet[row, 13] = "=R" + row.to_s + "*0.88-1100";	# (落札相場 * 0x88) - 1100が入札上限
		@sheet[row, 14] = product.data[:ebay_sold];		# 需要
		@sheet[row, 15] = product.data[:ebay_sold_url];		# 需要URL
		@sheet[row, 16] = product.data[:ebay_sell];		# 供給
		@sheet[row, 17] = product.data[:ebay_sell_url];		# 供給URL
		@sheet[row, 18] = product.data[:ebay_sold_price];	# 落札相場
		@sheet[row, 19] = product.data[:ebay_sell_price];	# 出品相場
		@sheet[row, 20] = product.data[:postage];		# 送料
		@sheet[row, 21] = product.data[:priority];		# 優先順位
		@sheet[row, 22] = product.data[:note];	        	# 備考
	end

	def check(product)
		@data.each{ |x|	return x[:row] if x[:url] == product.link }
		return nil;
	end

	def check2(product)
		@data.each{ |x|
			id = "-";
			id = $1 if /items\/(.+)\// =~ x[:url];
			return x[:row] if id == product.id
		}
		return nil;
	end

	def lastRow
		i=2;
		loop{
			return i if @sheet[i,1] == "" or @sheet[i,1] == nil;
			i += 1;
		}
	end

	def update_ebay(row, data)
		@sheet[row, 14] = data[:ebay_sold];
		@sheet[row, 15] = data[:ebay_sold_url];
		@sheet[row, 16] = data[:ebay_sell];
		@sheet[row, 17] = data[:ebay_sell_url];
		@sheet[row, 18] = data[:ebay_sold_price];
		@sheet[row, 19] = data[:ebay_sell_price];
		@sheet[row, 21] = data[:priority];
		@sheet[row, 22] = data[:note];
	end

	def save
		@sheet.save
	end
end

