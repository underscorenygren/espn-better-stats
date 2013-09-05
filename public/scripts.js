
	var TABLE_ID = 'data_table',
		TABLE_INS_ID = 'table_body',
		table = null;

	function load_table() {

		var $table = $("#" + TABLE_INS_ID);
		$table.empty(); 
		$.get("/players", function(data) {
			var players = JSON.parse(data);
			for (i = 0, il = players.length; i < il; i++) { 
				var player = players[i], 
					$tr = $("<tr></tr>");
				$tr.append($("<td>" + player["name"] + "</td>"));
				$tr.append($("<td>" + player["team"] + "</td>"));
				$tr.append($("<td>" + player["pos"] + "</td>"));
				$tr.append($("<td>" + player["owned_by"] + "</td>"));
				$table.append($tr); 
			}
			init_table_sorter();
		});
	}

	function init_table_sorter() {
		table = $("#" + TABLE_ID).dataTable({
			"bPaginate" : false,
		});
		$.fn.dataTableExt.afnFiltering.push(ownership_filtering);
	}

	function ownership_filtering(oSettings, aData, iDataIndex) { 
		var ownership = $('#ownership option:selected').val(), 
			own = aData[3]; 
		if (ownership == 'All') { return true; }
		if (ownership == 'Free') { return own == 'FA'} 
		else { return own != 'FA' } 
	}

	function bind_selector() {
		$sel = $('#ownership'); 
		$sel.change(function() {  table.fnDraw(); });
	}

	var interval = setInterval(function() {
		console.log("interval");
		if ($) { 
			clearInterval(interval);
			$(document).ready(function() { 
				load_table();
				bind_selector(); 
			});
		}
	}, 100); 
	 