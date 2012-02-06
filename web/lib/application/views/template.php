<!DOCTYPE html>
<html dir="ltr" lang="en-US">
<head>
<!--  
<?php 
if (isset($rw))
{
	echo print_r($rw, TRUE); 
}
?>
-->

<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<title>Roundware | an open-source, participatory, location-aware audio platform</title>

<link rel='stylesheet' href='/css/smoothness/jquery-ui-1.8.17.custom.css' type='text/css' />
<script type='text/javascript' src='/js/jquery-1.7.1.min.js'></script>
<script type='text/javascript' src='/js/jquery-ui-1.8.17.custom.min.js'></script>	
<?php 
if (isset($css))
{
	foreach ($css as $i)
	{
		echo link_tag('css/' . $i) . "\n";
	}
}


if (isset($js))
{
	foreach ($js as $i)
	{
		if ('http' == substr($i, 0, 4))
		{
			echo '<script type="text/javascript" src="' . $i . '"></script>' . "\n";
		}
		else
		{
			echo '<script type="text/javascript" src="/js/' . $i . '"></script>' . "\n";
		}
	}
	
}


if (isset($head))
{
	echo $head; 
}


?>

</head>
<body>
<div style="margin: 0 10% 0 10%; ">
	<div>
	<a class="mainlogo-link" href="http://www.roundware.org" title="Roundware"><img class="mainlogo-img" src="http://www.roundware.org/wp-content/uploads/2011/11/rw_banner_960.png" alt="Roundware" /></a>
	</div>
	<div id="sidebar-wrap" style="float: right;">
		<?php $this->load->view('navigation')?>
	</div>
	<div id="content">
	<?php if (isset($content)) echo $content; ?>
	</div>
</div>	
</body>
</html>