require 'open-uri'
require 'uri'
require "json"

class Exchange 
	def initialize
		url = "https://api.exchangeratesapi.io/latest"
		contents = open(url){ |f| f.read }
		@rates = JSON[contents, symbolize_names: true][:rates];
		@rates[:EUR] = 1;
	end

	def to_JPY(usd)
		return usd * (@rates[:JPY] / @rates[:USD])
	end
end

