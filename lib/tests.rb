$: << '.'
require 'rspec'
require 'player'
require 'scraper'

@@ref = {
		:name => "Drew",
		:team => "NO",
		:pos => "QB",
		:owned_by => "FA",
}


describe StatTracker::Data::Player do
	
	it "should create a player" do
		player = StatTracker::Data::Player.new(@@ref)
		expect(!player.nil?)
	end

	it "should accept string instead of symbols" do 
		player = StatTracker::Data::Player.new({
				"name" => @@ref[:name],
				"team" => @@ref[:team],
				"pos" => @@ref[:pos], 
				"owned_by" => @@ref[:owned_by],
		})
		p2 = StatTracker::Data::Player.new(@@ref)
		expect(player).to eq(p2)
	end

	it "should handle stats" do
		stats = {:test => "a stat"}
		player = StatTracker::Data::Player.new(@@ref)
		player.add_stats(2, stats)
		added = player.get_stats(2)
		expect(!added.nil?)
		expect(player.get_stats(1).nil?)

	end

	it "should update owner" do 
		player = StatTracker::Data::Player.new(@@ref)
		player.update_owner("me")
		expect(player.owned_by).to eq("me")
	end
end

describe StatTracker::ESPN do

	before(:all) do 
		@players = StatTracker::ESPN.find_all_players()
	end

	it "should parse 650 players" do
		expect(@players.length).to eq(650)
	end

	it "shouldn't have garbage data" do
		@players.each do |player|
			expect(!player.name.nil?)
			expect(!player.team.nil?)
			expect(!player.pos.nil?)
			expect(!player.owned_by.nil?)
			expect(!player.stats.nil?)
		end
	end
end