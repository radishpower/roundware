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
import java.util.Properties;

import com.halseyburgund.roundware.provider.RWDbAdapter;

import android.content.Context;
import android.os.Environment;


/**
 * Queue of Action items, provided as access to a local database.
 * 
 * TODO: Currently the queue and database (?) will be shared between apps
 * using RWLib. Check if this causes problems and apps need to have a
 * unique instance. The database might be ok but the shared folder might
 * cause the most interference, in particular for the deleteQueue method. 
 * 
 * @author Rob Knapen, Dan Latham
 */
public class RWActionQueue {
	
    public final static String STORAGE_PATH = Environment.getExternalStorageDirectory().getAbsolutePath() + "/roundware/";
    public final static String NOTE_QUEUE_PATH = STORAGE_PATH + "queue/";
	
    private static RWActionQueue mInstance;
    private Context mContext;
    
    
    private RWActionQueue() {
    	// void
    }

    
    public static RWActionQueue instance() {
    	if (mInstance == null) {
        	mInstance = new RWActionQueue();
    	}
    	return mInstance;
    }

    
    public void init(Context context) {
    	createDir(NOTE_QUEUE_PATH);
    	this.mContext = context;
    }
    
    
    public int count() {
    	RWDbAdapter db = null;
    	int count = 0;
    	try {
			db = new RWDbAdapter(mContext);
			if (db != null) {
				count = db.count();
			}
    	} finally {
    		if (db != null) {
    			db.close();
    		}
    	}
		return count;
    }
   
    
    public void add(Properties props) {
    	RWDbAdapter db = null;
    	try {
			db = new RWDbAdapter(mContext);
			if (db != null) {
				db.insert(props);
			}
    	} finally {
    		if (db != null) {
    			db.close();
    		}
    	}
    }
	
    
    public RWAction get() {
    	RWDbAdapter db = null;
    	RWAction action = null;
    	try {
			db = new RWDbAdapter(mContext);
			if (db != null) {
				action = db.getAction();
			}
    	} finally {
    		if (db != null) {
    			db.close();
    		}
    	}
		return action;
    }
    
    
	public void delete(RWAction action) {   
	    String filename = action.getFilename();
	    if (filename != null) {
	    	File noteFile = new File(filename);
	    	noteFile.delete();
	    }
	    	
    	RWDbAdapter db = null;
    	try {
			db = new RWDbAdapter(mContext);
			if (db != null) {
		    	db.delete(action.getDatabaseId());
			}
    	} finally {
    		if (db != null) {
    			db.close();
    		}
    	}
	
	}

	
	public boolean deleteQueue() {
		boolean bReturn = RWDbAdapter.drop(mContext);
        bReturn = bReturn && deleteDir(new File(STORAGE_PATH));
        return bReturn;
	}
	
	
    // Deletes all files and subdirectories under dir.
    // Returns true if all deletions were successful.
    // If a deletion fails, the method stops attempting to delete and returns false.
    private boolean deleteDir(File dir) {
        if (dir.isDirectory()) {
            String[] children = dir.list();
            for (int i=0; i<children.length; i++) {
                boolean success = deleteDir(new File(dir, children[i]));
                if (!success) {
                    return false;
                }
            }
        }
        // The directory is now empty so delete it
        return dir.delete();
    } 
    
    
    private void createDir(String path) {
    	File queue = new File(path);
    	if (!queue.exists()) {
    		queue.mkdirs();
    	}
    }
}