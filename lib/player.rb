
module StatTracker
	module Data
		class Player

			attr_accessor :name
			attr :owned_by
			attr_reader :team
			attr_reader :pos
			attr_reader :_id
			attr_reader :stats
			
			def initialize(values = {})

				@_id = values["_id"]
				@name = values[:name] || values["name"]
				@team = values[:team] || values["team"]
				@pos = values[:pos] || values["pos"]
				@owned_by = values[:owned_by] || values["owned_by"]

				@stats = values[:stats] || values["stats"] || []
				
			end

			def ==(another)
				@name == another.name and
				@team == another.team and
				@pos == another.pos and
				@owned_by == another.owned_by
			end

			def update_result(week, res)
				@stats[week]["res"] = res
			end

			def add_stats(week, stats)
				@stats[week] = stats
			end

			def get_stats(week)
				@stats[week]
			end
			
			def update_owner(new_owner)
				@owned_by = new_owner
			end

			def to_s
				"#{@name} (#{@team}) #{@pos} #{@owned_by} #{@stats}"
			end
		end
	end
end

