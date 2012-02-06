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

import android.app.ProgressDialog;
import android.app.ListActivity;
import android.content.BroadcastReceiver;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.ServiceConnection;
import android.media.AudioManager;
import android.os.AsyncTask;
import android.os.Bundle;
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
import com.halseyburgund.rwframework.core.RWService;
import com.halseyburgund.rwframework.core.RWTags;
import com.halseyburgund.rwframework.core.RWTags.RWTag;
import com.halseyburgund.rwframework.util.RWListAdapter;
import com.halseyburgund.rwframework.util.RWList;
import com.halseyburgund.rwframework.util.RWListItem;


public class RWListenActivity extends ListActivity {

	// Roundware tag type used in this activity
	private final static String ROUNDWARE_TAGS_TYPE = "listen";
	
	// fields
	private ProgressDialog progressDialog;
	private TextView headerLine2TextView;
	private Spinner tagsSpinner;
	private Button playButton;
	private Button pauseButton;
	private Button closeButton;
	private int volumeLevel = 80;
	private RWService rwBinder;
	private RWTags projectTags;
	private RWList tagsList;

	
	/**
	 * Handles connection state to an RWService Android Service. In this
	 * activity it is assumed that the service has already been started
	 * by another activity and we only need to connect to it.
	 */
	private ServiceConnection rwConnection = new ServiceConnection() {
		@Override
		public void onServiceConnected(ComponentName className, IBinder service) {
			rwBinder = ((RWService.RWServiceBinder) service).getService();
			rwBinder.playbackFadeIn(volumeLevel);
			rwBinder.setVolumeLevel(volumeLevel, false);
			
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
			if (RW.READY_TO_PLAY.equals(intent.getAction())) {
				// remove progress dialog when needed
				if (progressDialog != null) {
					progressDialog.dismiss();
				}
			} else if (RW.USER_MESSAGE.equals(intent.getAction())) {
				showMessage(intent.getStringExtra(RW.EXTRA_SERVER_MESSAGE), false, false);
			} else if (RW.ERROR_MESSAGE.equals(intent.getAction())) {
				showMessage(intent.getStringExtra(RW.EXTRA_SERVER_MESSAGE), true, false);
			} else if (RW.SESSION_OFF_LINE.equals(intent.getAction())) {
				showMessage(getString(R.string.connection_to_server_lost_play), true, false);
			}
		}
	};

	
	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.listen);
		setVolumeControlStream(AudioManager.STREAM_MUSIC);
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
		filter.addAction(RW.READY_TO_PLAY);
		filter.addAction(RW.SESSION_OFF_LINE);
		filter.addAction(RW.UNABLE_TO_PLAY);
		filter.addAction(RW.ERROR_MESSAGE);
		filter.addAction(RW.USER_MESSAGE);
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

		// request update of audio stream directly when needed
		if ((rwBinder != null) && (tagsList.hasValidSelectionsForTags())) {
			if (rwBinder.isPlaying()) {
				new ModifyStreamTask(tagsList, getString(R.string.modify_stream_problem)).execute();
			}
		}
	}
	

	/**
	 * Sets up the primary UI widgets (spinner and buttons), and how to
	 * handle interactions.
	 */
	private void initUIWidgets() {
		headerLine2TextView = (TextView) findViewById(R.id.header_line2_textview);
		
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
		
		playButton = (Button) findViewById(R.id.play_button);
		playButton.setOnClickListener(new View.OnClickListener() {
			public void onClick(View v) {
				if (!rwBinder.isPlaying()) {
					if (!rwBinder.isPlayingMuted()) {
						showProgress(getString(R.string.starting_playback_title), getString(R.string.starting_playback_message), true, true);
						rwBinder.playbackStart();
					}
					rwBinder.playbackFadeIn(volumeLevel);
				}
				updateUIState();
			}
		});

		pauseButton = (Button) findViewById(R.id.pause_button);
		pauseButton.setOnClickListener(new View.OnClickListener() {
			public void onClick(View v) {
				if (rwBinder.isPlaying()) {
					volumeLevel = rwBinder.getVolumeLevel();
					rwBinder.playbackFadeOut();
				}
				updateUIState();
			}
		});

		closeButton = (Button) findViewById(R.id.close_button);
		closeButton.setOnClickListener(new View.OnClickListener() {
			public void onClick(View v) {
				rwBinder.playbackStop();
				Intent homeIntent = new Intent(RWListenActivity.this, RWExampleActivity.class);
				RWListenActivity.this.startActivity(homeIntent);
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
			playButton.setEnabled(false);
			pauseButton.setEnabled(false);
			tagsSpinner.setEnabled(false);
			headerLine2TextView.setText(R.string.off_line);
		} else {
			// connected to RWService
			boolean isPlaying = rwBinder.isPlaying();
			playButton.setEnabled(!isPlaying);
			pauseButton.setEnabled(isPlaying);
			tagsSpinner.setEnabled(true);
			
			if (isPlaying) {
				if (rwBinder.isPlayingStaticSoundtrack()) {
					headerLine2TextView.setText(R.string.playing_static_soundtrack_msg);		
				} else {
					headerLine2TextView.setText(R.string.playing);
				}
			} else {
				headerLine2TextView.setText(R.string.paused);
			}
		}
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
	 * Shows a standardized progress dialog for the specified conditions.
	 * 
	 * @param title to be displayed
	 * @param message to be displayed
	 * @param isIndeterminate setting for the progress dialog
	 * @param isCancelable setting for the progress dialog
	 */
	private void showProgress(String title, String message, boolean isIndeterminate, boolean isCancelable) {
		if (progressDialog == null) {
			progressDialog = Utils.showProgressDialog(this, title, message, isIndeterminate, isCancelable);
		}
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
	 * @param type of tag to display options of (e.g. "listen")
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
	 * Async task that calls rwModifyStream for direct processing, but in
	 * the background for Android to keep the UI responsive.
	 * 
	 * @author Rob Knapen
	 */
	private class ModifyStreamTask extends AsyncTask<Void, Void, String> {

		private RWList selections;
		private String errorMessage;
		
		public ModifyStreamTask(RWList selections, String errorMessage) {
			this.selections = selections;
			this.errorMessage = errorMessage;
		}

		@Override
		protected String doInBackground(Void... params) {
			try {
				rwBinder.rwModifyStream(selections, true);
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
