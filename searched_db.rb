require 'date'
require 'pp'

class SearchedDB
	def initialize(filename)
		@name = filename;
		@list = []# ファイルから読み込んでリストを初期化
		if File.exist?(@name)  
			File.readlines(@name).each{ |line|
				rec = line.split(/,/)
				if rec.size > 1
					id = rec.slice(0..rec.size - 2).join(',')
					deadtime = rec.last
					@list << { :id => id, :deadtime => deadtime.strip }
				end
			}
			clean;	   # 終了日時を過ぎているアイテムは削除
		end
	end

	def add(id, deadtime = "")
		@list << { :id => id, :deadtime => deadtime }
	end

	def update(id, deadtime = '')
		index = index_of(id)
		if index == nil
			add id, deadtime
		else
			@list[index] = { :id => id, :deadtime => deadtime }
		end
	end

	def index_of(id)
		@list.each_with_index{ |x, i| return i if x[:id] == id }
		nil
	end

	def check(id)
		@list.each{ |x| return true if  x[:id] == id }
		false
	end

	def clean
		dst = []
		now = DateTime.now + Rational(9, 24) 
		@list.each { |x|
			if x[:deadtime] != ""		# 終了日時が存在しない場合は残り数分
				dead = DateTime.parse(x[:deadtime]) + 14;	# 終了日時から2週間立ったら消す(追加しない)
				dst << x if dead > now 
			end
		}
		@list = dst;
	end

	def save
		File.open(@name,"w") { |f|
			@list.each{ |x| f.puts("%s,%s" % [x[:id], x[:deadtime]]) }
		}
	end
end

