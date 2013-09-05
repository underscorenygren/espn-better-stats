require 'mongo'
require 'player'
include Mongo

class String
	def proper_name
		exceptions = {
			"Maui'A" => "Maui'a",
			"Ta'Ufo'Ou" => "Ta'ufo'ou",
			"Iii" => "III", 
			"D/St" => "D/ST",
		}
		#http://stackoverflow.com/questions/1791639/converting-upper-case-string-into-title-case-using-ruby

		prop = split(/(\W)/).map(&:capitalize).join
		
		exceptions.each do |wrong, right|
			prop.gsub!(wrong, right)
		end
		prop
	end
end

def obj_to_hash(obj)
	hash = {}
	obj.instance_variables.each do |var|
		hash[var.to_s.delete("@")] = obj.instance_variable_get(var)
	end
	hash
end

module StatTracker
	class DB

		@@db_name = "ffstats"
		@@player_coll = "players"

		def initialize
			@mongo = MongoClient.new().db(@@db_name)
		end

		def find_player(name, team = nil)
			proper = name.proper_name
			search = {:name => proper}
			if team
				search[:team] = team
			end
			player = @mongo[@@player_coll].find_one(search)
			if player.nil?
				puts "No player for #{name}"
			end
			player
		end

		def from_db(player_name, team)
			db_player = find_player(player_name, team)
			throw :no_player if db_player.nil?
			StatTracker::Data::Player.new(db_player)
		end

		def save_player(player)
			player.name = player.name.proper_name
			save(@@player_coll, player)
		end

		def update_player(player)
			player.name = player.name.proper_name
			update(@@player_coll, player)
		end

		def save(collection, obj)
			save_update(collection, obj, true)
		end

		def update(collection, obj)
			save_update(collection, obj, false)
		end

		def save_update(coll, obj, do_insert = false)
			coll = @mongo[coll]
			hash = obj_to_hash(obj)
			if do_insert
				hash.delete "_id"
				coll.insert(hash)
			else
				coll.update({"_id" => hash["_id"]}, hash)
			end	
		end
		
		def num_players
			return @mongo[@@player_coll].count()
		end

		def get_all_players
			@mongo[@@player_coll].find({})
		end
	end
end
