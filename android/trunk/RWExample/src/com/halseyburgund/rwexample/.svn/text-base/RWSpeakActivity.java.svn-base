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

import android.app.AlertDialog;
import android.app.ListActivity;
import android.content.BroadcastReceiver;
import android.content.ComponentName;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.ServiceConnection;
import android.os.AsyncTask;
import android.os.Bundle;
import android.os.Environment;
import android.os.IBinder;
import android.view.View;
import android.widget.AdapterView;
import android.widget.AdapterView.OnItemSelectedListener;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.ListView;
import android.widget.Spinner;
import android.widget.TextView;

import com.halseyburgund.rwframework.core.RW;
import com.halseyburgund.rwframework.core.RWRecordingTask;
import com.halseyburgund.rwframework.core.RWService;
import com.halseyburgund.rwframework.core.RWTags;
import com.halseyburgund.rwframework.core.RWTags.RWTag;
import com.halseyburgund.rwframework.util.RWList;
import com.halseyburgund.rwframework.util.RWListAdapter;
import com.halseyburgund.rwframework.util.RWListItem;

public class RWSpeakActivity extends ListActivity {

	// Roundware tag type used in this activity
	private final static String ROUNDWARE_TAGS_TYPE = "speak";
	
	// settings for storing recording as file
	private final static String STORAGE_PATH = Environment.getExternalStorageDirectory().getAbsolutePath() + "/rwdemo/";

    // fields
	private TextView headerLine2TextView;
	private Spinner tagsSpinner;
	private Button recordButton;
	private Button submitButton;
	private Button closeButton;
	private RWService rwBinder;
	private RWTags projectTags;
	private RWList tagsList;
	private RWRecordingTask recordingTask;
	private boolean hasRecording = false;
	
	
	/**
	 * Handles connection state to an RWService Android Service. In this
	 * activity it is assumed that the service has already been started
	 * by another activity and we only need to connect to it.
	 */
	private ServiceConnection rwConnection = new ServiceConnection() {
		@Override
		public void onServiceConnected(ComponentName className, IBinder service) {
			rwBinder = ((RWService.RWServiceBinder) service).getService();
			
			// create a tags list for display and selection
			projectTags = rwBinder.getTags().filterByType(ROUNDWARE_TAGS_TYPE);
			tagsList = new RWList(projectTags);
			tagsList.restoreSelectionState(getSharedPreferences(RWExampleActivity.APP_SHARED_PREFS, MODE_PRIVATE));

			updateUIState();
			updateTagsSpinner(ROUNDWARE_TAGS_TYPE);
		}

		@Override
		public void onServiceDisconnected(ComponentName name) {
			rwBinder = null;
		}
	};
	

	/**
	 * Handles events received from the RWService Android Service that we
	 * connect to. Sinds most operations of the service involve making calls
	 * to the Roundware server, the response is handle asynchronously with
	 * results passed back as broadcast intents. An IntentFilter is set up
	 * in the onResume method of this activity and controls which intents
	 * from the RWService will be received and processed here.
	 */
	private BroadcastReceiver rwReceiver = new BroadcastReceiver() {
		@Override
		public void onReceive(Context context, Intent intent) {
			updateUIState();
			if (RW.SESSION_OFF_LINE.equals(intent.getAction())) {
				showMessage(getString(R.string.connection_to_server_lost_record), false, false);
			} else if (RW.USER_MESSAGE.equals(intent.getAction())) {
				showMessage(intent.getStringExtra(RW.EXTRA_SERVER_MESSAGE), false, false);
			} else if (RW.ERROR_MESSAGE.equals(intent.getAction())) {
				showMessage(intent.getStringExtra(RW.EXTRA_SERVER_MESSAGE), true, false);
			} else if (RW.SHARING_MESSAGE.equals(intent.getAction())) {
				confirmSharingMessage(intent.getStringExtra(RW.EXTRA_SERVER_MESSAGE));
			}
		}
	};
	
	
    @Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.speak);
		initUIWidgets();

		// connect to service started by other activity
		try {
			Intent bindIntent = new Intent(this, RWService.class);
			bindService(bindIntent, rwConnection, Context.BIND_AUTO_CREATE);
		} catch (Exception ex) {
			showMessage(getString(R.string.connection_to_server_failed) + " " + ex.getMessage(), true, true);
		}
	}

    
	@Override
	protected void onPause() {
		super.onPause();
		unregisterReceiver(rwReceiver);
		if (tagsList != null) {
			tagsList.saveSelectionState(getSharedPreferences(RWExampleActivity.APP_SHARED_PREFS, MODE_PRIVATE));
		}
	}


	@Override
	protected void onResume() {
		super.onResume();

		IntentFilter filter = new IntentFilter();
		filter.addAction(RW.SESSION_ON_LINE);
		filter.addAction(RW.SESSION_OFF_LINE);
		filter.addAction(RW.TAGS_LOADED);
		filter.addAction(RW.ERROR_MESSAGE);
		filter.addAction(RW.USER_MESSAGE);
		filter.addAction(RW.SHARING_MESSAGE);
		registerReceiver(rwReceiver, filter);

		updateUIState();
	}


	@Override
	protected void onDestroy() {
		if (rwConnection != null) {
			unbindService(rwConnection);
		}
		super.onDestroy();
	}

	
	@Override
	protected void onListItemClick(ListView l, View v, int position, long id) {
		// let the list decide if the item can be (de)selected
		RWListItem q = (RWListItem) l.getItemAtPosition((int) id);
		RWList displayedItems = ((RWListAdapter) l.getAdapter()).getDisplayedItems();
		if (q.isOn()) {
			displayedItems.deselect(q);
		} else {
			displayedItems.select(q);
		}
		l.invalidateViews();
		updateUIState();
	}

	
	/**
	 * Sets up the primary UI widgets (spinner and buttons), and how to
	 * handle interactions.
	 */
	private void initUIWidgets() {
		headerLine2TextView = (TextView)findViewById(R.id.header_line2_textview);

		tagsSpinner = (Spinner) findViewById(R.id.tags_spinner);
		tagsSpinner.setOnItemSelectedListener(new OnItemSelectedListener() {
			@Override
			public void onItemSelected(AdapterView<?> arg0, View arg1, int arg2, long arg3) {
				Object selection = tagsSpinner.getSelectedItem();
				if (selection instanceof RWTag) {
					RWTag tag = (RWTag) selection;
					updateTagsDisplay(tag.code, tag.type);
				}
			}

			@Override
			public void onNothingSelected(AdapterView<?> arg0) {
				// void
			}
		});
		
		recordButton = (Button) findViewById(R.id.speak_record_button);
		recordButton.setOnClickListener(new View.OnClickListener() {
	    	public void onClick(View v) {
	    		if ((recordingTask != null) && (recordingTask.isRecording())) {
	    		    recordingTask.stopRecording();
	    		    recordButton.setText(R.string.record);
	    		    submitButton.setEnabled(true);
	    		} else {
	    			startRecording();
	    			recordButton.setText(R.string.stop);
	    			submitButton.setEnabled(false);
	    		}
	    	}
		});

		submitButton = (Button) findViewById(R.id.speak_submit_button);
		submitButton.setOnClickListener(new View.OnClickListener() {
			public void onClick(View v) {
	    		if (recordingTask != null) {
	    			stopRecording();
	    			hasRecording = false;
	    			submitButton.setEnabled(false);
	    			new SubmitTask(tagsList, recordingTask.getRecordingFileName(), 
	    					getString(R.string.recording_submit_problem)).execute();
	    		}
			}
		});
		
		closeButton = (Button) findViewById(R.id.speak_close_button);
		closeButton.setOnClickListener(new View.OnClickListener() {
			public void onClick(View v) {
				Intent homeIntent = new Intent(RWSpeakActivity.this, RWExampleActivity.class);
				RWSpeakActivity.this.startActivity(homeIntent);
			}
		});
	}
	

	/**
	 * Updates the state of the primary UI widgets based on current
	 * connection state and other state variables.
	 */
	private void updateUIState() {
		if (rwBinder == null) {
			// not connected to RWService
			recordButton.setEnabled(false);
			submitButton.setEnabled(false);
			tagsSpinner.setEnabled(false);
			getListView().setEnabled(false);
		} else {
			// connected to RWService
			if (!tagsList.hasValidSelectionsForTags()) {
				recordButton.setEnabled(false);
				submitButton.setEnabled(false);
			} else {
				recordButton.setEnabled(true);
				submitButton.setEnabled(hasRecording);
			}
			tagsSpinner.setEnabled(true);
			getListView().setEnabled(true);
		}
		
	}
	
	
	/**
	 * Starts making a recording using the RWRecordingTask of the Roundware
	 * framework. A listener implementation is used to receive callbacks
	 * during recording and update the UI using runnables posted to the
	 * UI thread (the callbacks will be made from a background thread).
	 */
	private void startRecording() {
		recordingTask = new RWRecordingTask(rwBinder, STORAGE_PATH, new RWRecordingTask.StateListener() {
        	private int maxTimeSec = rwBinder.getConfiguration().getMaxRecordingTimeSec();
        	private long startTimeStampMillis;
        	
        	public void recording(long timeStampMillis, short [] samples) {
        		int elapsedTimeSec = (int)Math.round((timeStampMillis - startTimeStampMillis) / 1000.0);
        		final int min = elapsedTimeSec / 60;
        		final int sec = elapsedTimeSec - (min * 60);
        		headerLine2TextView.post(new Runnable() {
        			public void run() {
                		headerLine2TextView.setText(String.format("%1d:%02d", min, sec));
        			}
        		});
        		if (elapsedTimeSec > maxTimeSec) {
        			recordingTask.stopRecording();
        		}
        	}
        	
        	public void recordingStarted(long timeStampMillis) {
        		if (rwBinder != null) {
        			maxTimeSec = rwBinder.getConfiguration().getMaxRecordingTimeSec();
        		}
        		startTimeStampMillis = timeStampMillis;
        		headerLine2TextView.post(new Runnable() {
        			public void run() {
                		headerLine2TextView.setText(R.string.recording_started);
        			}
        		});
        	}
        	
        	public void recordingStopped(long timeStampMillis) {
        		headerLine2TextView.post(new Runnable() {
        			public void run() {
                		headerLine2TextView.setText(R.string.recording_stopped);
        			}
        		});
        	}
        });
		
		recordingTask.execute();
    }
		
	
	/**
	 * Stops the recording task if it is running.
	 */
	private void stopRecording() {
		if ((recordingTask != null) && (recordingTask.isRecording())) {
			recordingTask.stopRecording();
			hasRecording = true;
			updateUIState();
		}
	}
	
	
	/**
	 * Displays a dialog for a (social media) sharing message that was
	 * sent back to the app by the framework after succesfully submitting
	 * a recording. When confirmed an ACTION_SEND intent is created and
	 * used to allow the user to select a matching activity (app) to
	 * handle it. This can be Facebook, Twitter, email, etc., whatever
	 * matching app that is installed on the device.
	 * 
	 * @param message to be shared
	 */
	private void confirmSharingMessage(final String message) {
		AlertDialog.Builder builder = new AlertDialog.Builder(this);
		builder.setTitle(R.string.confirm_sharing_title)
			.setMessage(message)
			.setCancelable(true)
			.setPositiveButton(android.R.string.ok, new DialogInterface.OnClickListener() {
				@Override
				public void onClick(DialogInterface dialog, int which) {
					Intent intent = new Intent(Intent.ACTION_SEND);
					intent.putExtra(Intent.EXTRA_SUBJECT, R.string.sharing_subject);
					intent.putExtra(Intent.EXTRA_TEXT, message);
					intent.setType("text/plain");
					startActivity(Intent.createChooser(intent, getString(R.string.sharing_chooser_title)));
				}
			})
			.setNegativeButton(android.R.string.cancel, new DialogInterface.OnClickListener() {
				@Override
				public void onClick(DialogInterface dialog, int which) {
					dialog.cancel();
				}
			});
		builder.create().show();		
	}
	
	
	/**
	 * Shows a standardized message dialog for the specified conditions.
	 * 
	 * @param message to be displayed
	 * @param isError type of notification
	 * @param isFatal dialog exits activity
	 */
	private void showMessage(String message, boolean isError, boolean isFatal) {
		Utils.showMessageDialog(this, message, isError, isFatal);
	}


	/**
	 * Fills the spinner with the tags of the specified type (e.g. "listen"
	 * or "speak").
	 * 
	 * @param type of tags to be displayed
	 */
	private void updateTagsSpinner(String type) {
		if ((tagsSpinner != null) && (projectTags != null)) {
			RWTags tags = projectTags.filterByType(type);
			tags.sortByOrder();
			ArrayAdapter<RWTag> tagsAdapter = new ArrayAdapter<RWTag>(this, android.R.layout.simple_spinner_item, tags.getTags());
			tagsAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
			tagsSpinner.setAdapter(tagsAdapter);
		}
	}


	/**
	 * Displays the options for the tag with the specified type and code in
	 * the list of this ListActivity.
	 * 
	 * @param code of tag to display options of (e.g. "demo")
	 * @param type of tag to display options of (e.g. "speak")
	 */
	private void updateTagsDisplay(String code, String type) {
		if ((projectTags != null) && (tagsList != null)) {
			setListAdapter(
				new RWListAdapter(getBaseContext(), tagsList, 
					projectTags.findTagByCodeAndType(code, type), 
					R.layout.list_item)
			);
		}
	}

	
	/**
	 * Async task that calls rwSubmit for direct processing, but in the
	 * background for Android to keep the UI responsive.
	 * 
	 * @author Rob Knapen
	 */
	private class SubmitTask extends AsyncTask<Void, Void, String> {

		private RWList selections;
		private String filename;
		private String errorMessage;
		
		public SubmitTask(RWList selections, String filename, String errorMessage) {
			this.selections = selections;
			this.filename = filename;
			this.errorMessage = errorMessage;
		}

		@Override
		protected String doInBackground(Void... params) {
			try {
				rwBinder.rwSubmit(selections, filename, true);
				return null;
			} catch (Exception e) {
				return errorMessage;
			}
		}

		@Override
		protected void onPostExecute(String result) {
			super.onPostExecute(result);
			if (result != null) {
				showMessage(result, true, false);
			}
		}
	}
	
}
