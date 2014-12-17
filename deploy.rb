require 'yaml'
require 'net/http'
require 'nokogiri'

# Construct base url
class NameCheap
	def initialize()  
		# Our commands
		@check  = "namecheap.domains.dns.getHosts"
		@update = "namecheap.domains.dns.setHosts"

    	# Instance variables  
		@baseurl  = "http://api.namecheap.com/xml.response"
		@baseurl += "?apiuser="  + ENV['username'] 
		@baseurl += "&apikey="   + ENV['key']
		@baseurl += "&username=" + ENV['username']
		@baseurl += "&ClientIp=107.22.240.13" # Just some random IP
	end

	def query
		return call "#{@baseurl}&Command=#{@check}&SLD=madisetti&TLD=me"
	end

	# Possibly change this to post
	def process changes
		return call "#{@baseurl}&Command=#{@update}&SLD=madisetti&TLD=me#{changes}"
	end

	def call url
		puts "Getting #{url}"
		return parse Net::HTTP.get(URI.parse(url))
	end

	def parse response
		result = Hash.new
		doc = Nokogiri::XML(response)
		doc.remove_namespaces!

		# Let's see what's going on
		puts doc
		puts '--------'

		doc.xpath("//host").each do |host|
			if result[host.attribute("Name").value] == nil
				result[host.attribute("Name").value] = []
			end
			result[host.attribute("Name").value].push(host.attributes().map{|x| x.value})
		end
		return result
	end
end

# Let's encapsulate everythang
def run()

	# Start off our url
	nc = NameCheap.new

	data = YAML.load_file('_data/records.yml')

	# Find what records exist
	# records = nc.query()

	# init blank string of needed changes
	changes = ""
	count   = 1

	# Lookup to see if match
	data.each do |member|
		changes += "&HostName#{count}=#{member['subdomain']}"
		changes += "&RecordType#{count}=#{member['type']}"
		changes += "&Address#{count}=" + URI.escape(member['address'], "= &")
		changes += "&TTL#{count}=1800"
		count += 1
	end

	nc.process(changes)
end

run()