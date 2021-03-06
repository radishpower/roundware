<?php

/** 
 * Proxy requests to http://rwstage.listenfaster.com/roundware/ so it can 
 * be called as though it were a local resource, avoiding XSS issues. 
 * 
 * $Id: proxy.php 1069 2012-01-14 05:23:46Z zburke $
 * 
 */

main();

function main()
{
	// operation is required
	if (! isset($_GET['operation']))
	{
		exit('missing required paramter: operation'); 
	}
	
	$fx = $_GET['operation'];
	$values = $_GET;
	unset($values['operation']); 
	
	echo do_curl($fx, 1, $values); 
	
}



/**
 * Use cURL to call a remote URL and return the result. 
 * 
 * @param string $operation name of the function to call on the remote server
 * @param int $id PK of the project
 * @param array $values hash of key-value pairs, passed as args to the remote server
 * 
 * @return string JSON
 */
function do_curl($operation, $id, $values)
{
		$curl = curl_init();
		
		$request = 'http://rwstage.listenfaster.com/roundware/?operation=' . $operation . '&project_id=1' 
			. '&' . http_build_query($values);
		
		curl_setopt($curl, CURLOPT_URL, $request);
		curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
	
		$ret = curl_exec($curl);
		
		return $ret;
}

