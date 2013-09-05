$: << './lib'

require 'sinatra'
require 'db'
require 'json'

get '/' do 
	erb :index
end

get '/players' do
	@db = StatTracker::DB.new()
	all = @db.get_all_players()
	players = all.to_a
	players.each do |player|
		player.delete "_id"
	end
	players.to_json
end
