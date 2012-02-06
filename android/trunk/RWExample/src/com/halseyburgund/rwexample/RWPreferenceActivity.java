/*
    ROUNDWARE
	a participatory, location-aware media platform
	Android client library
   	Copyright (C) 2008-2011 Halsey Solutions
	with contributions by Rob Knapen (shuffledbits.com) and Dan Latham
	http://roundware.org | contact@roundware.org

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

 	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 	GNU General Public License for more details.

 	You should have received a copy of the GNU General Public License
 	along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/ 		
package com.halseyburgund.rwexample;

import android.os.Bundle;
import android.preference.PreferenceActivity;

/**
 * Activity to display application preferences and allow the user to edit
 * them.
 *
 * @author Rob Knapen
 */
public class RWPreferenceActivity extends PreferenceActivity {

    public final static String CONNECT_TO_SERVER = "connectToServerPref";
    public final static String SHOW_DETAILED_MESSAGES = "showDetailedMessagesPref";
    public final static String SERVER_NAME = "serverNamePref";
    public final static String SERVER_PAGE = "serverPagePref";
    public final static String MOCK_LATITUDE = "mockLocationLatitudePref";
    public final static String MOCK_LONGITUDE = "mockLocationLongitudePref";
    public final static String USE_ONLY_WIFI = "useOnlyWiFiPref";

    
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        addPreferencesFromResource(R.xml.preferences);
    }

}
