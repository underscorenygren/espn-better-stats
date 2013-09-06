
	var TABLE_ID = 'data_table',
		TABLE_INS_ID = 'table_body',
		data = {
			"name" : [],
			"team" : [],
			"pos" : [],
			"owner" : []
		},
		players = null,
		table = null;

	function load_table() {

		var $table = $("#" + TABLE_INS_ID), 
			week_max = 0;

		function add_cell($tr, txt) {
			$tr.append($('<td>' + txt + '</td>'));
		}

		$table.empty(); 
		$.get("/players", function(data) {
			players = JSON.parse(data);
			week_max = players[0]["stats"].length -1;

			for (i = 0, il = players.length; i < il; i++) { 
				var player = players[i],
					name = player["name"],
					team = player["team"],
					pos = player["pos"],
					owner = player["owned_by"],
					stats = player["stats"][week_max],
					res = stats["res"] || "N/A",
					proj = stats["proj"], 
					res_tot = stats["pts"],
					proj_plusmin_pts = "N/A",
					proj_plusmin_pct = "N/A",
					$tr = $("<tr></tr>");

				if (res != "N/A") {
					var res_f = parseFloat(res),
						proj_f = parseFloat(proj);
					proj_plusmin_pts = (res_f - proj_f);
					proj_plusmin_pct = (!proj_f) ? 0.0 : (proj_plusmin_pts) / proj_f;
					proj_plusmin_pct = "" + proj_plusmin_pct * 100 + "%";
				}
					
				add_cell($tr, name);
				add_cell($tr, team);
				add_cell($tr, pos);
				add_cell($tr, owner);
				add_cell($tr, res);
				add_cell($tr, proj);
				add_cell($tr, res_tot);
				add_cell($tr, proj_plusmin_pts);
				add_cell($tr, proj_plusmin_pct);
				$table.append($tr); 
				add_to_data(name, team, pos, owner);
			}
			init_table_sorter();
			init_autocomplete();
			$('#app').show();
		});
	}
	function add_to_data(name, team, pos, owner) {
		if (data["name"].indexOf(name) == -1) { data["name"].push(name); }
		if (data["team"].indexOf(team) == -1) { data["team"].push(team); }
		if (data["pos"].indexOf(pos) == -1) { data["pos"].push(pos); }
		if (data["owner"].indexOf(owner) == -1) { data["owner"].push(owner); }
	}


	function get_selected_value(id) {
		var $jq_elem = $("#" + id), 
			val; 

		val = $jq_elem.find("option:selected");
		if (!val.length) { 
			val = $jq_elem.find(":checked");
		}
		return val.val();
	}

	function init_week_selector(cur_week) {
		var $weeks = $('#weeks');

		$weeks.find('@value='+cur_week).checked();
		$weeks.find('input').change(table_update);
	}

	function init_table_sorter() {
		table = $("#" + TABLE_ID).dataTable({
			"bPaginate" : false,
			"bInfo" : false
		});
		$.fn.dataTableExt.afnFiltering.push(ownership_filtering);
		$.fn.dataTableExt.afnFiltering.push(autocomplete_filtering);

	}

	function init_autocomplete() {
			$('.autocomplete')
				.each(function() {
					var $this = $(this);
					$this.autocomplete({
						"source" : data[$this.attr('id')]
					})
				}).click(function(e) {
					e.stopPropagation();
				}).keyup(table_update);
	}

	function table_update() { table.fnDraw(); }
	function autocomplete_filtering(oSettings, aData, iDataIndex) {
		var autos = ["name", "team", "pos", "owner"], 
			i, il, id, $val;

		for (i = 0, il = autos.length; i < il; i++) {
			id = autos[i];
			val = $('#' + id).val();
			if (val.length && aData[i].toLowerCase().indexOf(val.toLowerCase()) === -1) {
				return false;
			}
		}
		return true;
	}

	function ownership_filtering(oSettings, aData, iDataIndex) { 
		var ownership = get_selected_value("ownership"), 
			own = aData[3], 
			is_free = own == 'FA' || own.indexOf('WA') == 0;
		if (ownership == 'All') { return true; }
		if (ownership == 'Free') { is_free; } 
		else { return !is_free; } 
	}

	var interval = setInterval(function() {
		console.log("interval");
		if ($) { 
			clearInterval(interval);
			$(document).ready(function() { 
				load_table();
				$('.table_update').change(table_update);
				$('body').keyup(function(e) {
					if (e.keyCode == 27) {
						$('input').val('');
						table_update();
					}
				});
			});
		}
	}, 100); 
	 