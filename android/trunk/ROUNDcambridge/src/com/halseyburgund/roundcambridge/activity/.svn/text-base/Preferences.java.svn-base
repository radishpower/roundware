/*
 	This file is part of ROUNDcambridge. Originally developed for the
 	Android OS by Rob Knapen, based on earlier work by Dan Latham.
 	
    ROUNDcambridge is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    ROUNDcambridge is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with ROUNDcambridge.  If not, see <http://www.gnu.org/licenses/>.
 */
package com.halseyburgund.roundcambridge.activity;

import com.halseyburgund.roundcambridge.R;

import android.content.SharedPreferences;
import android.os.Bundle;
import android.preference.PreferenceActivity;
import android.preference.PreferenceManager;

/**
 * Activity to display application preferences and allow the user to edit
 * them.
 *  
 * @author Rob Knapen
 */
public class Preferences extends PreferenceActivity {

	public final static String CONNECT_TO_SERVER = "connectToServerPref";
	public final static String SHOW_DETAILED_MESSAGES = "showDetailedMessagesPref";
	public final static String SERVER_NAME = "serverNamePref";
	public final static String SERVER_PAGE = "serverPagePref";
	public final static String MOCK_LATITUDE = "mockLocationLatitudePref";
	public final static String MOCK_LONGITUDE = "mockLocationLongitudePref";
	
	private boolean connectToServer = true;
	private boolean showDetailedMessages = false;
	private String serverName = "";
	private String serverPage = "";
	private String mockLatitude = "N/A";
	private String mockLongitude = "N/A";
	
	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		addPreferencesFromResource(R.xml.preferences);
	}

	
	@Override
	protected void onStart() {
		super.onStart();
		getPrefs();
	}

	
	private void getPrefs() {
		SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(getBaseContext());
		connectToServer = prefs.getBoolean(CONNECT_TO_SERVER, true);
		showDetailedMessages = prefs.getBoolean(SHOW_DETAILED_MESSAGES, false);
		
		String defaultServerUrl = getString(R.string.rw_spec_server_url);
		String defaultName = "";
		String defaultPage = "";
		
		int pos = defaultServerUrl.lastIndexOf('/');
		if (pos > 0) {
			defaultPage = defaultServerUrl.substring(pos + 1);
			defaultName = defaultServerUrl.substring(0, pos - 1);
		}
		
		serverName = prefs.getString(SERVER_NAME, defaultName);
		serverPage = prefs.getString(SERVER_PAGE, defaultPage);
		
		mockLatitude = prefs.getString(MOCK_LATITUDE, "N/A");
		mockLongitude = prefs.getString(MOCK_LONGITUDE, "N/A");
	}


	public boolean isConnectToServer() {
		return connectToServer;
	}


	public boolean isShowDetailedMessages() {
		return showDetailedMessages;
	}
	
	
	public String getServerName() {
		return serverName;
	}


	public String getServerPage() {
		return serverPage;
	}
	
	
	public String getMockLatitude() {
		return mockLatitude;
	}

	
	public String getMockLongitude() {
		return mockLongitude;
	}
	
}
