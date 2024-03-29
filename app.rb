require 'sinatra'
require 'sinatra/activerecord'
require 'haml'
require 'xmlsimple'
require 'rest-client'

set :database, 'sqlite3:///db/shortened_urls.db'
set :address, 'localhost:9393'
#set :address, 'exthost.etsii.ull.es:4567'

class Visit < ActiveRecord::Base
	belongs_to :shortenedUrl
	def self.create_with_ip url,ip
		xml = RestClient.get "http://api.hostip.info/get_xml.php?ip=#{ip}"
		country = XmlSimple.xml_in(xml.to_s, { 'ForceArray' => false })['featureMember']['Hostip']['countryAbbrev']
		Visit.create :country => country, :url_id => url
	end
end

class ShortenedUrl < ActiveRecord::Base
  # Validates whether the value of the specified attributes are unique across the system.
  validates_uniqueness_of :url
  # Validates that the specified attributes are not blank
  validates_presence_of :url
  #validates_format_of :url, :with => /.*/
  validates_format_of :url, 
       :with => %r{^(https?|ftp)://.+}i, 
       :allow_blank => true, 
       :message => "The URL must start with http://, https://, or ftp:// ."
end


get '/' do
	haml :index
end

post '/' do
  @short_url = ShortenedUrl.find_or_create_by_url(params[:url])
  if @short_url.valid?
    haml :success, :locals => { :address => settings.address }
  else
    haml :index
  end
end

get '/:shortened' do
  	short_url = ShortenedUrl.find(params[:shortened].to_i(36))
  	redirect short_url.url
	Visit.create_with_ip short_url.id, request.ip
	redirect short_url.url
end
