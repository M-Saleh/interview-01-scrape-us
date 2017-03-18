# Assumption:If a partner not rated yet, will be give -1.

require 'net/http'
require 'nokogiri' 

PARTNERS_URL = 'https://access.kfit.com/partners/'

# Return a Nokogiri object for a page.
def get_page(page_url)
	response = Net::HTTP.get_response(URI(page_url))
	if response.is_a?(Net::HTTPSuccess)
		return Nokogiri::HTML(response.body)
	else
		puts "Error, Can't fetch this page#{page_url}"
	end
end

# Return a partner id from its element.
def get_partner_id(partner_element)
	# partner_element contains all info, we need just the id in third row
	rows = partner_element.text.split("\n")
	return rows[2].scan(/\d+/)[0].to_i
end

def get_partner_rate(partner_page)
	rate_node = partner_page.css('.rating').first
	# If a partner not rated yet, return -1
	return rate_node ? rate_node.text.to_f : -1
end

def get_partner(partner_id)	
	page = get_page(PARTNERS_URL+partner_id.to_s)	
	rate = get_partner_rate(page)
	puts rate
end

partners_page = get_page(PARTNERS_URL)
partners_elements = partners_page.xpath('//script[contains(text(),"kfitMap.outlets.push")]')
partners_elements.each{|p| get_partner(get_partner_id(p))}