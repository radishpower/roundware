<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Welcome extends CI_Controller {

	public function __construct()
	{
		parent::__construct();

		$this->load->library('Roundware'); 
	}
	
	
	public function index()
	{
		$this->load->view('template', array('content' => 'content', 'rw' => $this->roundware->rw_config()));	
	}
	
	
	
	/**
	 * Call get_listen for a project and translate the results into an HTML form
	 */
	public function listen()
	{
		$head = $this->load->view('listen/index_head', array(
			'rw_session_id' => $this->roundware->rw_session_id, 
		), TRUE);
		$content = $this->load->view('listen/index', array('content' => $this->roundware->get_listen()), TRUE);
		
		$this->load->view('template', array(
			'head' => $head, 
			'content' => $content, 
			'rw' => $this->roundware->rw_config()
		)); 
	}
	
	
	
	/**
	 * Call get_speak for a project and translate the results into an HTML form
	 */
	public function speak()
	{
		$data = array(
			'rw_session_id' => $this->roundware->rw_session_id, 
			'content' => $this->roundware->get_speak(),
		);
		
		$content = $this->load->view('speak/submit', $data, TRUE);
		
		$this->load->view('template', array('content' => $content, 'rw' => $this->roundware->rw_config()));
	}
	
	
	/**
	 * Call get_tags for a project and display the raw object
	 */
	public function tags()
	{
		$this->load->view('template', array('content' => '<pre>' . print_r($this->roundware->get_tags(), TRUE), '</pre>', 'rw' => $this->roundware->rw_config()));	
	}
	
	
	
	/**
	 * geocoding example
	 */	
	public function geocode()
	{
		$content = $this->load->view('geocode/content', array(), TRUE);
		$head = $this->load->view('geocode/head', array(), TRUE);
		
		$this->load->view('template', array(
			'head' => $head, 
			'content' => $content, 
			'rw' => $this->roundware->rw_config(),
			'css' => array('autogeocomplete.css'),
			'js' => array('http://maps.google.com/maps/api/js?sensor=false', 'jquery.autogeocomplete.js')
		));
		
	}
	
}

/* End of file welcome.php */
/* Location: ./application/controllers/welcome.php */