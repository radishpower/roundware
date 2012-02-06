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

import java.io.File;
import com.halseyburgund.roundware.R;
import com.halseyburgund.roundware.util.RWHtmlLog;


/**
 * Class that represents an Action, which is kind of a unit of communication
 * with the server. After an action is created, preferably by one of the
 * static create...Action methods, it's perform or method can be called to
 * execute it directly. Alternatively (preferred) it can be passed to the
 * OVService perform method to be executed in the background. The RWService
 * also puts failed actions into a queue and retries them later and will
 * overwrite the url specified for the action if the user has altered them
 * in the application settings.
 * 
 * @author Rob Knapen, Dan Latham
 */
public class RWAction {

	// TODO: Consider merging RWAction and RWActionData classes
	
	// debugging
	private final static String TAG = "RWAction";
	private final static boolean D = false;

	// fields
	private Long mDbId;
	private RWActionData mData;
	

	public RWAction(Long databaseId, RWActionData data) {
		this.mDbId = databaseId;
		this.mData = data;
	}
	
	
	public String validate() {
		StringBuilder sb = new StringBuilder();
		
		// validation rules
		
		// 1. Action should at least have config and operation
		if ((getConfig() == null) || (getConfig().length() == 0)) {
			sb.append("Parameter 'config' is not defined");
		}
		if ((getOperation() == null) || (getOperation().length() == 0)) {
			sb.append("Parameter 'operation' is not defined");
		}
		
		// 2. Only request stream operation and request number of recordings are allowed without session id
		if ((getSessionId() == null) || (getSessionId().length() == 0)) {
			String reqStreamOpName = mData.getStringForResId(R.string.rw_op_get_stream);
			String reqRecordsOpName = mData.getStringForResId(R.string.rw_op_number_of_recordings);
			String opName = getOperation();
			if (reqStreamOpName.equalsIgnoreCase(opName) && reqRecordsOpName.equalsIgnoreCase(opName)) {
				sb.append("Parameter 'sessionid' is required for operation '" + opName + "' but not defined");
			}
		}

		// TODO: Add more validation rules here
		
		// return result
		if (sb.length() == 0) {
			return null;
		} else {
			if (D) {
				RWHtmlLog.w(sb.toString());
			}
			return sb.toString();
		}
	}
	
	
	public String perform() throws Exception {
		String filename = getFilename();
		if (filename != null) {
			if (D) { RWHtmlLog.i(TAG, "Uploading file: " + filename, null); }
			String response = RWHttpManager.uploadFile(getUrl(), mData.getServerProperties(), mData.getStringForResId(R.string.rw_key_file), filename);
			if (D) { RWHtmlLog.i(TAG, "Server response: " + response, null); }
			File noteFile = new File(filename);
			noteFile.delete();
			return "";
		} else {
			if (D) { RWHtmlLog.i(TAG, "Sending GET to : " + getUrl(), null); }
			String response = RWHttpManager.doGet(getUrl(), mData.getServerProperties());
			return response;
		}
	}

	
	public RWActionData getData() {
		return mData;
	}
	

	public Long getDatabaseId() {
		return mDbId;
	}

	
	public String getUrl() {
		Object value = mData.get(R.string.rw_key_server_url);
		if (value != null) {
			return value.toString();
		}
		return null;
	}

	
	public String getUserId() {
		Object value = mData.get(R.string.rw_key_ud_id);
		if (value != null) {
			return value.toString();
		}
		return null;
	}


	public String getSessionId() {
		Object value = mData.get(R.string.rw_key_session_id);
		if (value != null) {
			return value.toString();
		}
		return null;
	}

	
	public String getConfig() {
		Object value = mData.get(R.string.rw_key_config);
		if (value != null) {
			return value.toString();
		}
		return null;
	}
	
	
	public String getOperation() {
		Object value = mData.get(R.string.rw_key_operation);
		if (value != null) {
			return value.toString();
		}
		return null;
	}

	
	public String getFilename() {
		Object value = mData.get(R.string.rw_key_filename);
		if (value != null) {
			return value.toString();
		}
		return null;
	}

	
	public String getCaption() {
		Object value = mData.get(R.string.rw_key_label);
		if (value != null) {
			return value.toString();
		}
		return null;
	}
	
	
	public Double getLatitude() {
		Object value = mData.get(R.string.rw_key_latitude);
		if (value != null) {
			return Double.valueOf(value.toString());
		}
		return Double.NaN;
	}
	
	
	public Double getLongitude() {
		Object value = mData.get(R.string.rw_key_longitude);
		if (value != null) {
			return Double.valueOf(value.toString());
		}
		return Double.NaN;
	}
}
