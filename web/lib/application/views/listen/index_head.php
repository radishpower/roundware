<script type="text/javascript">
$(document).ready(
	function (){

		$(":checkbox").click(function(){

			var l = $('input:checked').map(function() {
				  return this.value;
				}).get().join(',');

			$.ajax({
				  url: 'http://rw.local/proxy.php?operation=modify_stream&session_id=<?php echo $rw_session_id; ?>&tags=' + l,
				  dataType: 'json',
				  success: function(data)
				  {
					  console.log('stream modified');
				  },
				  error: function(data)
				  {
					  console.log('stream update failure'); 
				  }
				});
		});


		$('#listen').click(function(){
			var l = $('input:checked').map(function() {
				  return this.value;
				}).get().join(',');
			
			$.ajax({
				url: 'http://rw.local/proxy.php?operation=request_stream&session_id=<?php echo $rw_session_id; ?>&tags=' + l,
				dataType: 'json',
				success: function(data)
				{
					console.log(data.stream_url); 
					$('#audiourl').html(data.stream_url); 
					$('#audiosource').attr('src', data.stream_url); 
					$('#audiocontrols').show(); 
				},
				error: function(data)
				{
					console.log('stream update failure'); 
				}
				});
			
		}); 

		

	});

	</script>