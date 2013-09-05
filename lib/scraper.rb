$: << '.'
require 'httparty'
require 'nokogiri'
require 'pp'

require 'db'

class String
	def remove!(substring)
		self.slice!(substring)
		self
	end
end

module StatTracker

	class Scraper

		def initialize(opt = {})
			@db = StatTracker::DB.new()
		end

		def scrape_players()

			i = 1

			ESPN.find_all_players().each do |player|
				@db.save_player(player)
				puts "#{i.to_s.ljust(3)}) Saved player #{player}"
				i += 1
			end
		end

		def scrape_stats()
			ESPN.update_stats(@db)
		end
	end

	class ESPN

		include HTTParty
		include Nokogiri

		@@url = "http://games.espn.go.com/ffl/freeagency?leagueId=481629&seasonId=2013&context=freeagency&view=overview&avail=-1"
		@@full_name_to_short = {
			"Patriots" => "NE",
			"Giants" => "NYG",
			"Jets" => "NYJ",
			"49ers" => "SF", 
			"Falcons" => "Atl", 
			"Dolphins" => "Mia",
			"Panthers" => "Car", 
			"Redskins" => "Wsh", 
			"Vikings" => "Min", 
			"Broncos" => "Den",
			"Bears" => "Chi",
			"Seahawks" => "Sea",
			"Bengals" => "Cin", 
			"Chargers" => "SD", 
			"Texans" => "Hou",
			"Packers" => "GB",
			"Rams" => "StL",
			"Cardinals" => "Ari", 
			"Steelers" => "Pit", 
			"Ravens" => "Bal", 
			"Titans" => "Ten",
			"Browns" => "Cle",
			"Buccaneers" => "TB",
			"Bills" => "Buf",
			"Colts" => "Ind",
			"Cowboys" => "Dal",
			"Lions" => "Det",
			"Saints" => "NO",
			"Eagles" => "Phi",
			"Jaguars" => "Jac",
			"Chiefs" => "KC",
			"Raiders" => "Oak"
		}

		def self.mixed_row_to_vals(html_row_node)
			mixed_field = html_row_node.css('.playertablePlayerName')
			
			name = mixed_field.css('a').first.content
			cleaned = mixed_field.text
			cleaned.remove!(name)
			cleaned.remove!(', ')

			team, pos = cleaned.split(/[[:space:]]/)
			if pos == 'D/ST'
				team_name = name.gsub(pos, '').rstrip
				team = @@full_name_to_short[team_name]
			end
			[name, team, pos]
		end

		def self.html_to_owner(html_row_node)
			html_row_node.xpath('td[3]').text
		end

		def self.html_to_player(html_row_node)
			name, team, pos, owned_by = html_to_info(html_row_node)
			player = StatTracker::Data::Player.new(:name => name, :team => team, :pos => pos, :owned_by => owned_by)
			player
		end 

		def self.html_to_info(html_row_node)
			name, team, pos = mixed_row_to_vals(html_row_node)
			owned_by = html_to_owner(html_row_node)
			[name, team, pos, owned_by]
		end

		def self.html_to_player_name(html_row_node)
			mixed_row_to_vals(html_row_node)[0]
		end

		def self.html_to_stats(row_node)
			stats = row_node.css('.playertableStat')
			data = row_node.css('.playertableData')
			pts = stats[0].text
			avg = stats[1].text
			last = stats[2].text
			proj = stats[3].text
			prk = data[0].text
			oprk = data[1].text
			starting = data[2].text
			own = data[3].text
			plus_minus = data[4].text
			last = '0' if last == '--'
			proj = '0' if proj == '--'
			res = nil
			res = last if proj == last

			stat = {
				"res" => res,
				:proj => proj, 
				:pts => pts, 
				:avg => avg, 
				:last => last, 
				:oprk => oprk, 
				:starting => starting, 
				:own => own, 
				:plus_minus => plus_minus
			}
			stat
		end

		def self.parse_agency_page(startIndex = 0)

			ofs_url = @@url + "&startIndex=#{startIndex}"
			resp = HTTParty.get(ofs_url)

			doc = Nokogiri::HTML(resp.body)

			week_elem = doc.xpath("//*[@id=\"playertable_0\"]/tr[1]/th[5]").text
			week = week_elem[5,].to_i
			rows = doc.css("tr.pncPlayerRow")
			
			[week, rows]
		end


		def self.update_stats db

			added = 0
			updated = 0
			owner = 0

			(0..600).step(50) do |startIndex|
				week, rows = parse_agency_page(startIndex)
				rows.each do |row|
					changed = false
					name, team = html_to_info(row)
					player = db.from_db(name, team)
					existing_stats = player.get_stats(week)
					current_owner = html_to_owner(row)
					stat = html_to_stats row
					res = stat["res"]
					if current_owner != player.owned_by
						changed = true
						puts "#{player} changed owner"
						player.update_owner(current_owner)
						owner += 1
					end
					if existing_stats.nil?
						changed = true
						player.add_stats(week, stat)
						puts "Added stats for #{player}"
						added += 1

					elsif res and existing_stats["res"].nil?
						changed = true
						player.update_result(week, res)

						puts "Updated week #{week} stats for #{player}"
						updated += 1
					end
					if changed 
						db.update_player(player)
					end
				end
			end

			puts "Finished reading stats, added #{added}, updated #{updated}, #{owner} changed owner"
		end

		def self.find_all_players()
			players = []

			(0..600).step(50) do |startIndex|
				week, rows = parse_agency_page(startIndex)
				rows.each do |row|			
					player = html_to_player(row)
					players << player

				end
			end

			players
		end
	end
end

if __FILE__ == $0
	require 'trollop'
	puts "Running scraper"
	opts = Trollop::options do
		opt :players, "Scrape ESPN for all players and store in DB"
		opt :stats, "Scrape the current stats"
	end
	scraper = StatTracker::Scraper.new()
	if opts[:players]
		puts "Scraping players"
		scraper.scrape_players
	end
	if opts[:stats]
		puts "Scraping stats"
		scraper.scrape_stats
	end
	puts "Program done"
end