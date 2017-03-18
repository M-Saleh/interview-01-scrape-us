# Assumption:If a partner not rated yet, will be give -1.

require 'net/http'
require 'nokogiri'
require 'set'

PARTNERS_URL = 'https://access.kfit.com/partners/'
OUTPUT_FILENAME = 'kfit_partners.csv'
# Used for discard the duplicates
@partner_ids = Set.new

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
				info['name'] = row[1].gsub(/[^0-9A-Za-z ]/, '') # Remove all special chars
			when 4
				info['address'] = row[1].gsub(/[^0-9A-Za-z ]/, '')
			when 5
				info['city'] = row[1].gsub(/[^0-9A-Za-z ]/, '')
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

def write_to_file(info_arr)
	File.open(OUTPUT_FILENAME, 'w') { |file|
		file.write("city, partner name, address, latitude, longitude, average rating\n")
		info_arr.each do |info|
			file.write("#{info['city']}, #{info['name']}, #{info['address']}, #{info['latitude']}, #{info['longitude']}, #{info['rating']}\n") 
		end
	}
end

def get_partner(partner_id)
	@partners_remaining_count -=1
	if @partner_ids.include?(partner_id)
		puts "DUPLICATED, partner #{partner_id} is found before"
		return nil
	end
	@partner_ids.add(partner_id)
	puts "Working on partner : #{partner_id}, remaining #{@partners_remaining_count}"
	partner_page = get_page(PARTNERS_URL+partner_id.to_s)
	partner_info = get_partner_info(partner_page)
	partner_info['rating'] = get_partner_rate(partner_page)
	return partner_info
end

partners_page = get_page(PARTNERS_URL)
partners_elements = partners_page.xpath('//script[contains(text(),"kfitMap.outlets.push")]')
info_arr = []
@partners_remaining_count = partners_elements.length
partners_elements.each do |part_elem|
	partner_info = get_partner(get_partner_id(part_elem))	
	info_arr << partner_info if partner_info
end

puts "Writing to the output file"
write_to_file(info_arr)
