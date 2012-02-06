<script type="text/javascript">
$(document).ready(
	function (){
		$('#upload').click(function() {
			create_add_envelope(); 
			return false;
		}); 

		function create_add_envelope()
		{
			$.ajax({
				  url: 'http://rw.local/proxy.php?operation=create_envelope&session_id=<?php echo $rw_session_id; ?>',
				  dataType: 'json',
				  success: function(data)
				  {
					  add_asset(data.envelope_id); 
				  },
				  error: function(data)
				  {
					  console.log('failed'); 
				  }
				});
			
		}

		

		function add_asset(envelope_id)
		{
			var tags = new Array(); 

			$('#recording .tag').each(function(id, item){
				tags.push($(item).val())
				});

			data = { 
					"envelope_id" : envelope_id, 
					"tags" : tags.join(), 
					"latitude" : "43.117458", 
					"longitude" : "-77.62477189999998",
					"file" : ""
					};

			$.ajax({
				  url: 'http://rw.local/proxy.php?operation=add_asset_to_envelope&session_id=<?php echo $rw_session_id; ?>',
				  dataType: 'json',
				  data: data, 
				  success: function(data)
				  {
					  console.log('success: ' + data); 
				  },
				  error: function(data)
				  {
					  console.log('failed'); 
				  }
				});
		}

	}
);
</script>


<form id="recording">
<?php echo $content; ?>


<input type="submit" value="Submit" id="upload" />
</form>