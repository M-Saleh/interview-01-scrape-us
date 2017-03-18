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

# Return city, partner_name, address, latitude, longitude.
def get_partner_info(partner_page)
	info_node = partner_page.xpath('//script[contains(text(),"var outlet_details")]')
	if !info_node.empty?
		info = {}
		rows = info_node.first.text.split("\n")
		line_index = 0
		rows.each do |row|
			row = row.split(":").map{|r| r.strip}
			case line_index
			when 3
				info['name'] = row[1]
			when 4
				info['address'] = row[1]
			when 5
				info['city'] = row[1]
			when 6
				location = row[1].scan(/\d+.\d+/)
				info['latitude'] = location[0]
				info['longitude'] = location[1]
			when line_index > 6
				# Got all info, just break.
				break
			end
			line_index += 1
		end	
	end

	return info
end

def get_partner(partner_id)	
	partner_page = get_page(PARTNERS_URL+partner_id.to_s)
	partner_info = get_partner_info(partner_page)
	partner_info['rating'] = get_partner_rate(partner_page)
	puts partner_info
end

partners_page = get_page(PARTNERS_URL)
partners_elements = partners_page.xpath('//script[contains(text(),"kfitMap.outlets.push")]')
partners_elements.each{|p| get_partner(get_partner_id(p))}