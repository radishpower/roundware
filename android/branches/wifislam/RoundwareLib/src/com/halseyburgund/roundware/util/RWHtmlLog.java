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
package com.halseyburgund.roundware.util;

import java.io.File;
import java.io.FileWriter;
import java.text.SimpleDateFormat;
import java.util.Date;

import android.os.Environment;
import android.util.Log;

public class RWHtmlLog {

	// debugging
	private final static String TAG = "RWHtmlLog";
	private final static boolean D = true;
	private final static boolean LOG_TO_FILE = false;

	// this folder will be created on the external storage, if available
	public final static String LOG_FILES_FOLDER = "/roundware/logs/";

	// log types
	private final static int ERROR = 0;
	private final static int WARNING = 1;
	private final static int INFO = 2;
	
	static File mLogFile;
	static FileWriter mOut = null;
	static SimpleDateFormat mTf = new SimpleDateFormat("hh:mm:ss");

	static {
		mOut = null;
		if (LOG_TO_FILE) {
			try {
				// check availability of external storage
				String state = Environment.getExternalStorageState();
	
				if (!Environment.MEDIA_MOUNTED.equals(state)) {
					throw new Exception("No storage media mounted in writable state");
				}			
				
				SimpleDateFormat df = new SimpleDateFormat("yyyy-MMM-d");
				String name = df.format(new Date());
			    String dirName = Environment.getExternalStorageDirectory().getAbsolutePath() + LOG_FILES_FOLDER;
	
			    // create the directory if needed
				File dir = new File(dirName);
				if (!dir.exists()) {
					dir.mkdirs();
				}
				
				mLogFile = new File(dirName + name + ".html");
				mOut = new FileWriter(mLogFile, true);
				Log.i(TAG, "Using log file: " + mLogFile.getAbsolutePath());
			} catch (Exception e) {
				Log.e(TAG, "Could not create logfile, exception: " + e.getMessage());
			}
		} else {
			Log.w(TAG, "Log file disabled, will not store log messages in output file.");
		}
	}

	
	static public void e(String tag, String m, Throwable e) {
		StringBuilder sb = new StringBuilder();
		if (tag != null) {
			sb.append(tag).append(": ");
		}
		if (m != null) {
			sb.append(m);
		}
		if ((e != null) && (e.getMessage() != null) ) {
			sb.append(" - ").append(e.getMessage());
		}
		writeLog(ERROR, sb.toString());
	}

	
	static public void e(String m) {
		writeLog(ERROR, m);
	}

	
	static public void i(String tag, String m, Throwable e) {
		StringBuilder sb = new StringBuilder();
		if (tag != null) {
			sb.append(tag).append(": ");
		}
		if (m != null) {
			sb.append(m);
		}
		if ((e != null) && (e.getMessage() != null) ) {
			sb.append(" - ").append(e.getMessage());
		}
		writeLog(INFO, sb.toString());
	}
	
	
	static public void i(String m) {
		writeLog(INFO, m);
	}

	
	static public void w(String tag, String m, Throwable e) {
		StringBuilder sb = new StringBuilder();
		if (tag != null) {
			sb.append(tag).append(": ");
		}
		if (m != null) {
			sb.append(m);
		}
		if ((e != null) && (e.getMessage() != null) ) {
			sb.append(" - ").append(e.getMessage());
		}
		writeLog(WARNING, sb.toString());
	}
	
	
	static public void w(String m) {
		writeLog(WARNING, m);
	}

	
	private static String logTypeAsString(int logType) {
		String result = "";
		switch (logType) {
		case ERROR:
			result = "Error";
			break;
		case WARNING:
			result = "Warning";
			break;
		case INFO:
			result = "Info";
			break;
		}
		return result;
	}
	
	private static void writeLog(int logType, String s) {
		try {
			String time = mTf.format(new Date());
			String msg = time + " " + logTypeAsString(logType) + " - " + s + "<br/>";
			if (mOut != null) {
				mOut.write(msg);
				mOut.flush();
			}

			if ((D) || (mOut == null)) {
				switch (logType) {
				case ERROR:
					Log.e(TAG, s);
					break;
				case WARNING:
					Log.w(TAG, s);
					break;
				case INFO:
					Log.i(TAG, s);
					break;
				default:
					Log.e(TAG, msg);
				}
			}

		} catch (Exception e) {
			Log.e(TAG, "Could not log message '" + s + "', exception: " + e.getMessage());
			e.printStackTrace();
		}
	}
}