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

import java.util.Properties;

import com.halseyburgund.roundware.util.RWHtmlLog;

import android.content.Context;

public class RWActionData {

	// debugging
	private final static String TAG = "RWAactionData";
	private final static boolean D = false;
	
	// key-value pairs of data
	private Context mContext;
	private Properties mProperties;

	
	public RWActionData(Context context) {
		this(context, null);
	}
	
	
	public RWActionData(Context context, Properties p) {
		mContext = context;
		mProperties = new Properties();
		if (p != null) {
			for (Object key : p.keySet()) {
				mProperties.put(key, p.get(key));
			}
		}
	}

	
	public RWActionData add(int keyResId, int valueResId) {
		String key = mContext.getString(keyResId);
		String value = mContext.getString(valueResId);
		return add(key, value);
	}
	
	
	public RWActionData add(int keyResId, String value) {
		String key = mContext.getString(keyResId);
		return add(key, value);	
	}
	
	
	public RWActionData add(String key, String value) {
		if ((key != null) && (value != null)) {
			mProperties.put(key, value);
		} else {
			if (D) { 
				RWHtmlLog.w(TAG, String.format(
						"property not added, key='%s' value='%s'",
						(key == null) ? "null" : key,
						(value == null) ? "null" : value
						), null);
			}
		}
		return this;
	}
	
	
	public RWActionData remove(String key) {
		mProperties.remove(key);
		return this;
	}
	
	
	public Object get(int keyResId) {
		String key = mContext.getString(keyResId);
		return get(key);
	}
	
	
	public Object get(String key) {
		return mProperties.get(key);
	}
	
	
	public String getStringForResId(int resId) {
		return mContext.getString(resId);
	}
	
	
	public String getStr(int keyResId, int defaultValueResId) {
		String key = mContext.getString(keyResId);
		String defaultValue = mContext.getString(defaultValueResId);
		return getStr(key, defaultValue);
	}
	
	
	public String getStr(int keyResId, String defaultValue) {
		String key = mContext.getString(keyResId);
		return getStr(key, defaultValue);
	}
	
	
	public String getStr(String key, String defaultValue) {
		Object value = mProperties.get(key);
		if (value != null) {
			return value.toString();
		} else {
			return defaultValue;
		}
	}
	
	
	public Properties getProperties() {
		return mProperties;
	}
	
	
	public Properties getServerProperties() {
		Properties result = new Properties();
		for (Object key : mProperties.keySet()) {
			if (!(key instanceof String) || (!(((String)key).startsWith("_")))) {
				result.put(key, mProperties.get(key));
			}
		}
		return result;
	}
	
}
