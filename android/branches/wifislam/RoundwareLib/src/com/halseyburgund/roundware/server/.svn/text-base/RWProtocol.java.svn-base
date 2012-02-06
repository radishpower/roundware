/*
 	This file is part of RoundwareLib. Originally developed for the
 	Android OS by Rob Knapen, based on earlier work by Dan Latham.
 	
    RoundwareLib is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    RoundwareLib is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with RoundwareLib.  If not, see <http://www.gnu.org/licenses/>.
 */
package com.halseyburgund.roundware.server;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;

import com.halseyburgund.roundware.R;
import com.halseyburgund.roundware.services.RWService;
import com.halseyburgund.roundware.util.RWHtmlLog;


public class RWProtocol {
	
	public enum ServerMessageType { ERROR, USER, SHARING, TRACEBACK }
	
	// debugging
	private final static String TAG = "RWProtocol";
	private final static boolean D = false;
	
	// fields
	private RWService mService;
	private String mKeyErrorMessage;
	private String mKeyErrorTraceback;
	private String mKeyUserMessage;
	private String mKeySharingMessage;
	
	
	public RWProtocol(RWService service) {
		super();
		mService = service;

		// cache some frequently used values from the resources
		mKeyErrorMessage = mService.getString(R.string.rw_key_server_error_message);
		mKeyErrorTraceback = mService.getString(R.string.rw_key_server_error_traceback);
		mKeyUserMessage = mService.getString(R.string.rw_key_server_user_message);
		mKeySharingMessage = mService.getString(R.string.rw_key_server_sharing_message);
	}

	
	public String retrieveServerMessage(ServerMessageType type, String response) {
		if (response == null) {
			return null;
		}
		List<Map<String, String>> result = simpleJsonParse(response);
		if (result.size() >= 1) {
			String key = keyForServerMessageType(type);
			if (result.get(0).containsKey(key)) {
				return result.get(0).get(key);
			}
		}
		return null;
	}

	
	private String keyForServerMessageType(ServerMessageType type) {
		switch (type) {
		case ERROR:
			return mKeyErrorMessage;
		case TRACEBACK:
			return mKeyErrorTraceback;
		case USER:
			return mKeyUserMessage;
		case SHARING:
			return mKeySharingMessage;
		}
		return "";
	}
	
	
	/**
	 * Simple parser a specific JSON response into a list of maps. The
	 * response is expected to be formatted like:
	 * 
	 *  [ { "categoryid": 7, "id": 16, "listenyn": "", "ordering": 16, 
	 *  "speakyn": "0", "subcategoryid": 8, "text": "If you ..." }, 
	 *  { "categoryid": 7, "id": 17, "listenyn": "", "ordering": 6, 
	 *  "speakyn": "0", "subcategoryid": 8, "text": "How ..." } ]
	 * 
	 * Which will be parsed into a list of 2 items. Each item is a map
	 * with a String key (categoryid, id, etc.) and a String value (7,
	 * 16, etc.). 
	 * 
	 * @param jsonResponse
	 * @return parse result of the JSON response 
	 * 
	 * TODO: Consider using json library available in Android 2.2
	 */
	public List<Map<String, String>> simpleJsonParse(String jsonResponse) {
		List<Map<String, String>> result = new ArrayList<Map<String, String>>();

		if (D) { RWHtmlLog.i(TAG, "Parsing JSON string: " + jsonResponse, null); }
		
		boolean isList = jsonResponse.startsWith("[") && jsonResponse.endsWith("]");
		int start = jsonResponse.indexOf("{");
		int end = jsonResponse.lastIndexOf("}");
		
		if ((start >= 0) && (end > 0) && (end > start)) {
			String[] items;
			if (isList) {
				items = jsonResponse.substring(start, end).split("\\}");
			} else {
				items = new String[]{jsonResponse};
			}
			for (String item : items) {
				if (D) { RWHtmlLog.i(TAG, "Parsing JSON item: " + item, null); }
				start = item.indexOf("{");
				String[] values = item.substring(start+1).split(",[ ]*\"");
				Map<String, String> kvMap = new TreeMap<String, String>();
				for (String value : values) {
					String[] kv = value.split(": ", 2);
					if ((kv != null) && (kv.length == 2)) {
						String key = stripQuotes(kv[0].trim());
						String val = stripQuotes(kv[1].trim());
						kvMap.put(key.toLowerCase(), val);
						if (D) { RWHtmlLog.i(TAG, "Found '" + key + "' = '" + val + "'", null); }
					}
				}
				result.add(kvMap);
			}
		}
		return result;
	}
	
	
	/**
	 * Strips a leading and/or trailing quote from the specified text.
	 * 
	 * @param text to remove quotes from
	 * @return text with first leading and last trailing quote removed
	 */
	private String stripQuotes(String text) {
		int start = text.indexOf("\"");
		int end = text.lastIndexOf("\"");
		
		if ((start >= 0) && (end >= 0)) {
			if (end > start) {
				return text.substring(start+1, end);
			} else {
				return text.substring(0, end);
			}
		}
		
		return text;
	}

}
