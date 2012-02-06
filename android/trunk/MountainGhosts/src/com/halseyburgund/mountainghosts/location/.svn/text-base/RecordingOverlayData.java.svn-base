/*
 	This file is part of Mountain Ghosts. Originally developed for the
 	Android OS by Rob Knapen, based on earlier work by Dan Latham.
 	
    Mountain Ghosts is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Mountain Ghosts is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Mountain Ghosts.  If not, see <http://www.gnu.org/licenses/>.
 */
package com.halseyburgund.mountainghosts.location;

import java.io.Serializable;


/**
 * Recording overlay data to present a recording as marker on a map. Also
 * contains the info needed to play the recording from the server.
 * 
 * @author Rob Knapen
 */
public class RecordingOverlayData implements Serializable {

	private static final long serialVersionUID = 1L;
	
	private int id;
	private String author = "";
	private String topic = "";
	private String details = "";
	private double lat = Double.NaN;
	private double lon = Double.NaN;
	private int marker = 0;
	private String streamUrl = "";
	
	
	/**
	 * Creates an empty instance.
	 */
	public RecordingOverlayData() {
		super();
	}
	
	
	/**
	 * Returns true if this data can be displayed on the map.
	 */
	public boolean canBeDisplayedOnMap() {
		return ((lat != Double.NaN) && (lon != Double.NaN));
	}
	

	public int getId() {
		return id;
	}


	public String getAuthor() {
		return author;
	}


	public void setAuthor(String author) {
		this.author = author;
	}


	public String getTopic() {
		return topic;
	}


	public void setTopic(String topic) {
		this.topic = topic;
	}


	public String getDetails() {
		return details;
	}


	public void setDetails(String details) {
		this.details = details;
	}


	public double getLat() {
		return lat;
	}


	public void setLat(double lat) {
		this.lat = lat;
	}


	public double getLon() {
		return lon;
	}


	public void setLon(double lon) {
		this.lon = lon;
	}


	public int getMarker() {
		return marker;
	}


	public void setMarker(int marker) {
		this.marker = marker;
	}


	public String getStreamUrl() {
		return streamUrl;
	}


	public void setStreamUrl(String streamUrl) {
		this.streamUrl = streamUrl;
	}


	public void setId(int id) {
		this.id = id;
	}
	
}
