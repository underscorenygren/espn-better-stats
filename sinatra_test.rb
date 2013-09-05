require './app'
require 'rspec'
require 'rack/test'
require 'json'

describe "App Test" do

	include Rack::Test::Methods

	def app
		Sinatra::Application
	end

	it "loads index" do
		get '/'
		last_response.should be_ok
	end

	it "loads players" do
		get '/players'
		last_response.should be_ok
		resp = last_response.body
		arr = JSON.parse(resp)
		arr.length.should eq(650)
	end
end