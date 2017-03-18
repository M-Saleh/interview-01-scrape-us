require 'net/http'
require 'nokogiri' 

PARTNERS_URL = 'https://access.kfit.com/partners/'

# Return a Nokogiri object for a page.
def get_page(page_url)
	response = Net::HTTP.get_response(URI(page_url))
	if response.is_a?(Net::HTTPSuccess)
		Nokogiri::HTML(response.body)
	else
		puts "Error, Can't fetch this page#{page_url}"
	end
end


partners_page = get_page(PARTNERS_URL)
partners_elements = partners_page.xpath('//script[contains(text(),"kfitMap.outlets.push")]')
puts partners_elements.length