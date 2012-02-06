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

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import com.halseyburgund.roundcambridge.Main;
import com.halseyburgund.roundcambridge.R;
import com.halseyburgund.roundcambridge.view.SlidingPanel;
import com.halseyburgund.roundware.util.RWList;
import com.halseyburgund.roundware.util.RWListItem;
import com.halseyburgund.roundware.adapter.RWListAdapter;
import com.halseyburgund.roundware.services.RWService;
import com.halseyburgund.roundware.util.RWHtmlLog;

import android.app.Activity;
import android.app.AlertDialog;
import android.app.AlertDialog.Builder;
import android.content.BroadcastReceiver;
import android.content.ComponentName;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.ServiceConnection;
import android.content.SharedPreferences;
import android.media.AudioManager;
import android.os.AsyncTask;
import android.os.Bundle;
import android.os.IBinder;
import android.util.Log;
import android.view.View;
import android.widget.AdapterView;
import android.widget.ImageButton;
import android.widget.ImageView;
import android.widget.ListView;
import android.widget.SeekBar;
import android.widget.TextView;
import android.widget.Toast;


/**
 * ROUNDcambridge Listen activity.
 * 
 * @author Rob Knapen, Dan Latham
 */
public class Listen extends Activity implements SeekBar.OnSeekBarChangeListener {

	// debugging
	private final static String TAG = "Listen";
	private final static boolean D = false;

	private final static int RECORDINGS_CHECK_THRESHOLD_MILLIS = 60000; // check recordings at most once every 60 sec.
	
	// shared preferences entries
	public final static String PREFS_KEY_QUESTION_BASE = "SavedSelectedQuestionId";
	public final static String PREFS_KEY_VOLUME_LEVEL = "SavedVolumeLevel";

	// references to UI elements
	private SlidingPanel statusPanel;
	private SlidingPanel questionPanel;
	private SlidingPanel speakerPanel;
	private SlidingPanel occupationPanel;
	private SlidingPanel volumePanel;
	private SlidingPanel currentPanel;
	private ImageButton speakerButton;
	private ImageButton questionButton;
	private SeekBar volumeBar;

	// fields
	private RWList allQuestions = new RWList();
	private RWListAdapter questionAdapter;
	private RWListAdapter speakerAdapter;
	private RWListAdapter occupationAdapter;
	private RWService rwServiceBinder;

	private boolean streamConnected = false;
	
	private int volumeLevel = 40;
	private boolean showNrRecordings = false;
	private int lastKnownNumberOfRecordings = -1;
	private long lastRecordingsRetrievalMillis = -1;

	
	/**
	 * Handles the connection between the Roundware service and this activity.
	 */
	private ServiceConnection rwServiceConnection = new ServiceConnection() {
		@Override
		public void onServiceConnected(ComponentName className, IBinder service) {
			// called when the connection is made
	    	if (D) { Log.i(TAG, "+++ On Service Connected +++"); }
			rwServiceBinder = ((RWService.RWServiceBinder)service).getService();
			rwServiceBinder.fadeInPlayer(volumeLevel);
			rwServiceBinder.setVolumeLevel(volumeLevel, false);
			updatePlayButtonState(true);
			updateQuestions();
		}

		@Override
		public void onServiceDisconnected(ComponentName name) {
			// received when the service unexpectedly disconnects
	    	if (D) { Log.i(TAG, "+++ On Service Disconnected +++"); }
			rwServiceBinder = null;
		}
	};
	
	
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.listen);
		
		setVolumeControlStream(AudioManager.STREAM_MUSIC);		
		
		initVolumeSeeker();
		initSlidingPanels();
		initSelectionLists();
		initFunctionButtons();

		// connect to service started by main activity
		connectToService();
	}

	
	private BroadcastReceiver connectedStateReceiver = new BroadcastReceiver() {
		@Override
		public void onReceive(Context context, Intent intent) {
			if (RWService.ACTION_STREAM_CONNECTED.equals(intent.getAction())) {
				updatePlayButtonState(true);
				streamConnected = true;
				updateNumberOfRecordings();
			} else if (RWService.ACTION_STREAM_DISCONNECTED.equals(intent.getAction())) {
				updatePlayButtonState(false);
				streamConnected = false;
				updateCenterMessage("Audio stream disconnected, press the play button to retry.", true);
			} else if (RWService.ACTION_LOCATION_UPDATED.equals(intent.getAction())) {
				// user location updated
				updateNumberOfRecordings();
			} else if (RWService.ACTION_MESSAGE.equals(intent.getAction())) {
				// message to user from the server - display in dialog with only OK button
				String msg = intent.getStringExtra(RWService.INTENT_EXTRA_SERVER_MESSAGE);
				showMessageDialog(msg);
			} else if (RWService.ACTION_ERROR.equals(intent.getAction())) {
				// error message from server - log and update state
				String msg = intent.getStringExtra(RWService.INTENT_EXTRA_SERVER_MESSAGE);
				Log.e(TAG, msg);
				showErrorDialog(msg);
			} else if (RWService.ACTION_SHARING.equals(intent.getAction())) {
				// message from server intended for social sharing - delegated through Intent
				String msg = intent.getStringExtra(RWService.INTENT_EXTRA_SERVER_MESSAGE);
				confirmSendingSharingMessage(msg);
			}
		}
	};
	
	
	private void showMessageDialog(String message) {
		Builder alertBox;
		alertBox = new AlertDialog.Builder(this);
		alertBox.setTitle(R.string.message_title);
		alertBox.setMessage(message);
		alertBox.setPositiveButton(android.R.string.ok, new DialogInterface.OnClickListener() {
			@Override
			public void onClick(DialogInterface arg0, int arg1) {
				// void
			}
		});
		alertBox.show();
	}

	
	private void showErrorDialog(String message) {
		Builder alertBox;
		alertBox = new AlertDialog.Builder(this);
		alertBox.setTitle(R.string.error_title);
		alertBox.setMessage(message);
		alertBox.setPositiveButton(android.R.string.ok, new DialogInterface.OnClickListener() {
			@Override
			public void onClick(DialogInterface arg0, int arg1) {
				// void - could handle specific state changes here
			}
		});
		alertBox.show();
	}
	
	
	private void confirmSendingSharingMessage(final String message) {
		AlertDialog.Builder builder = new AlertDialog.Builder(this);
		builder.setTitle(R.string.confirm_sharing_title)
			.setMessage(R.string.confirm_sharing_message)
			.setCancelable(true)
			.setPositiveButton(android.R.string.ok, new DialogInterface.OnClickListener() {
				@Override
				public void onClick(DialogInterface dialog, int which) {
					startSharingIntent(message);
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
    
	
	private void startSharingIntent(String message) {
		Intent intent = new Intent(Intent.ACTION_SEND);
		intent.putExtra(Intent.EXTRA_SUBJECT, R.string.sharing_subject);
		intent.putExtra(Intent.EXTRA_TEXT, message);
		intent.setType("text/plain");
		startActivity(Intent.createChooser(intent, getString(R.string.sharing_chooser_title)));
	}
	
	
    private void restartStream() {
		if (D) { Log.d(TAG, "Restart of audio stream requested"); }
		if (streamConnected) {
			if (D) { Log.d(TAG, "... already connected to stream, not going to try again."); }
		} else {
			if (rwServiceBinder != null) {
				rwServiceBinder.startPlayingStream();
			}
		}
    }

	
	@Override
	protected void onPause() {
		super.onPause();
		saveSelections();
		unregisterReceiver(connectedStateReceiver);
	}

	
	@Override
	protected void onResume() {
		super.onResume();

		// restore volume level setting
		restoreSelections(false, true);
		
    	IntentFilter filter = new IntentFilter();
    	filter.addAction(RWService.ACTION_STREAM_CONNECTED);
    	filter.addAction(RWService.ACTION_STREAM_DISCONNECTED);
    	filter.addAction(RWService.ACTION_LOCATION_UPDATED);
    	filter.addAction(RWService.ACTION_ERROR);
    	filter.addAction(RWService.ACTION_MESSAGE);
    	filter.addAction(RWService.ACTION_SHARING); // not really expected here
    	registerReceiver(connectedStateReceiver, filter);

    	// more frequent updating of questions when needed
    	if ((rwServiceBinder != null) && rwServiceBinder.isLocationBasedQuestionsEnabled()) {
    		// update questions and selections
    		updateQuestions();
    	} else {
    		// restore questions selections
    		restoreSelections(true, false);
    	}
    	
		setStatus();
	}
	
	
	@Override
	protected void onDestroy() {
		disconnectFromService();
		super.onDestroy();
	}

	
	private void updateQuestions() {
		if (rwServiceBinder == null) {
			if (D) { Log.d(TAG, "updateQuestions called but RWService not yet available! Skipping."); }
			return;
		}
		retrieveQuestionsFromResource(allQuestions, RWListItem.Category.DEMOGRAPHIC, R.array.rw_speaker_kind_listen, true);
		retrieveQuestionsFromResource(allQuestions, RWListItem.Category.USERTYPE, R.array.rw_user_type, true);
		new RetrieveQuestionsTask().execute(); // will restore selections when done
	}

	
	private void saveSelections() {
		SharedPreferences prefs = getSharedPreferences(Main.PREFS, MODE_PRIVATE);
		SharedPreferences.Editor prefsEditor = prefs.edit();

		String key;
		for (RWListItem item : allQuestions) {
			key = PREFS_KEY_QUESTION_BASE + "_" + item.getCategory() + "_" + item.getId();
			// if (D) { Log.d(TAG, "Saving question id: " + key); }
			prefsEditor.putBoolean(key, item.isOn());
		}
		
		prefsEditor.putInt(PREFS_KEY_VOLUME_LEVEL, volumeLevel);
		prefsEditor.commit();
	}
	
	
	private void restoreSelections(boolean questionsSelection, boolean volumeSelection) {
		SharedPreferences prefs = getSharedPreferences(Main.PREFS, MODE_PRIVATE);
		
		String key;

		if (questionsSelection) {
			for (RWListItem item : allQuestions) {
				key = PREFS_KEY_QUESTION_BASE + "_" + item.getCategory() + "_" + item.getId();
				// if (D) { Log.d(TAG, "Restoring question id: " + key); }
				item.set(prefs.getBoolean(key, true));
			}
		}
		setStatus();
		
		if (volumeSelection) {
			setVolumeLevel(prefs.getInt(PREFS_KEY_VOLUME_LEVEL, volumeLevel));
			volumeBar.setProgress(volumeLevel);
		}
	}

	
	private void initVolumeSeeker() {
		volumeBar = (SeekBar) findViewById(R.id.volume);
		volumeBar.setOnSeekBarChangeListener(this);
		setVolumeLevel(volumeLevel);
	}
	
	
	private void initSlidingPanels() {
		statusPanel = (SlidingPanel) findViewById(R.id.status_panel);
		questionPanel = (SlidingPanel) findViewById(R.id.question_panel);
		speakerPanel = (SlidingPanel) findViewById(R.id.speaker_panel);
		occupationPanel = (SlidingPanel) findViewById(R.id.occupation_panel);
		volumePanel = (SlidingPanel) findViewById(R.id.volume_panel);
		currentPanel = statusPanel;
		showNrRecordings = true;
	}

	
	private void initSelectionLists() {
		// selection list of what? questions
		// questionAdapter = new SimpleListAdapter(this, R.layout.question_list_item, allQuestions.sublist(RWListItem.Category.QUESTION), R.layout.question_list_item);
		questionAdapter = new RWListAdapter(this, allQuestions, RWListItem.Category.QUESTION, R.layout.question_list_item);
		ListView questions = (ListView) findViewById(R.id.question_list);
		questions.setAdapter(questionAdapter);
		ListView.OnItemClickListener questionClicked = new ListItemClickListener();
		questions.setOnItemClickListener(questionClicked);

		// selection list of type of speakers
		// speakerAdapter = new SimpleListAdapter(this, R.layout.speaker_list_item, allQuestions.sublist(RWListItem.Category.DEMOGRAPHIC), R.layout.speaker_list_item);
		speakerAdapter = new RWListAdapter(this, allQuestions, RWListItem.Category.DEMOGRAPHIC, R.layout.speaker_list_item);
		ListView speakers = (ListView) findViewById(R.id.speaker_list);
		speakers.setAdapter(speakerAdapter);
		speakers.setOnItemClickListener(new ListItemClickListener());
		
		// selection list of occupation / user types
		// occupationAdapter = new SimpleListAdapter(this, R.layout.speaker_list_item, allQuestions.sublist(RWListItem.Category.USERTYPE), R.layout.speaker_list_item);
		occupationAdapter = new RWListAdapter(this, allQuestions, RWListItem.Category.USERTYPE, R.layout.speaker_list_item);
		ListView occupations = (ListView) findViewById(R.id.occupation_list);
		occupations.setAdapter(occupationAdapter);
		occupations.setOnItemClickListener(new ListItemClickListener());
	}

	
	private void retrieveQuestionsFromResource(RWList choices, RWListItem.Category category, int arrayResourceId, boolean defaultState) {
		if (choices != null) {
			choices.removeAll(category);
			String[] items = getResources().getStringArray(arrayResourceId);
			int pos;
			for (String item : items) {
				pos = item.indexOf(':');
				choices.add(RWListItem.create(category, item.substring(0, pos), item.substring(pos+1, item.length()), defaultState));
			}
		}
	}

	
	private void initFunctionButtons() {
		
		// home button
		ImageButton button = (ImageButton) findViewById(R.id.button_home);
		button.setOnClickListener(new View.OnClickListener() {
			public void onClick(View v) {
				Intent homeIntent = new Intent(Listen.this, Main.class);
				Listen.this.startActivity(homeIntent);
			}
		});
		
		// exit button
		button = (ImageButton) findViewById(R.id.button_exit);
		button.setOnClickListener(new View.OnClickListener() {
			public void onClick(View v) {
				ImageView imageView = (ImageView) findViewById(R.id.button_play);
				if (rwServiceBinder == null) {
					imageView.setImageResource(R.drawable.listen_play_selector);
				} else {
					if (rwServiceBinder.isPlaying()) {
						imageView.setImageResource(R.drawable.listen_play_selector);
						rwServiceBinder.fadeOutPlayer();
					}
				}
				finish();
			}
		});

		questionButton = (ImageButton) findViewById(R.id.button_what);
		questionButton.setOnClickListener(new View.OnClickListener() {
			public void onClick(View v) {
				setPanel(questionPanel); // toggle panel
			}
		});

		speakerButton = (ImageButton) findViewById(R.id.button_who);
		speakerButton.setOnClickListener(new View.OnClickListener() {
			public void onClick(View v) {
				if (currentPanel == speakerPanel) {
					// only show user type selection when needed
					if (allQuestions.filter(RWListItem.Category.USERTYPE).size() > 1) {
						setPanel(occupationPanel); // follow up panel
					} else {
						allQuestions.selectAll(RWListItem.Category.USERTYPE);
						setPanel(speakerPanel); // toggle panel
					}
				} else if (currentPanel == occupationPanel) {
					setPanel(occupationPanel); // toggle panel
				} else {
					setPanel(speakerPanel); // toggle panel
				}
			}
		});

		button = (ImageButton) findViewById(R.id.button_volume);
		button.setOnClickListener(new View.OnClickListener() {
			public void onClick(View v) {
				setPanel(volumePanel); // toggle panel
			}
		});

		button = (ImageButton) findViewById(R.id.button_record);
		button.setOnClickListener(new View.OnClickListener() {
			public void onClick(View v) {
				if (rwServiceBinder != null) {
					Intent recorder = new Intent(Listen.this, Speak.class);
					recorder.putExtra("sessionStart", rwServiceBinder.getSessionId());
					Listen.this.startActivity(recorder);
				} else {
					Toast.makeText(Listen.this, "No valid session, can not start recording!", Toast.LENGTH_SHORT);
				}
			}
		});

		final ImageButton playButton = (ImageButton) findViewById(R.id.button_play);
		playButton.setOnClickListener(new View.OnClickListener() {
			public void onClick(View v) {
				if (rwServiceBinder == null) {
					updatePlayButtonState(false);
				} else {
					if (rwServiceBinder.isPlaying()) {
						volumeLevel = rwServiceBinder.getVolumeLevel();
						rwServiceBinder.fadeOutPlayer();
						updatePlayButtonState(false);
					} else {
						restartStream(); // will only reconnect if necessary
						rwServiceBinder.fadeInPlayer(volumeLevel);
						updatePlayButtonState(true);
					}
				}
			}
		});
	}
	
	
	private void updatePlayButtonState(boolean isPlaying) {
		ImageButton playButton = (ImageButton) findViewById(R.id.button_play);
		if (rwServiceBinder == null) {
			// no connection, function of button is to start playback
			playButton.setImageResource(R.drawable.listen_play_selector);
			return;
		}
		if (isPlaying) {
			// playback active, function of button is to pause it
			playButton.setImageResource(R.drawable.listen_pause_selector);
		} else {
			// playback pause, function of button is to start it
			playButton.setImageResource(R.drawable.listen_play_selector);
		}
	}
	
	
	protected void setPanel(SlidingPanel panel) {
		currentPanel.hide();

		if (currentPanel == panel) {
			// if closing panel, save settings
			if (rwServiceBinder != null) {
				rwServiceBinder.performModifyStream(allQuestions, false);
				setStatus();
			} else {
				Toast.makeText(Listen.this, "No valid session, can not adjust playback stream!", Toast.LENGTH_SHORT);
			}
			statusPanel.show();
			currentPanel = statusPanel;
			showNrRecordings = true;
		} else {
			panel.show();
			currentPanel = panel;
			showNrRecordings = false;
		}

		// deal with button state
		speakerButton.setSelected((currentPanel == speakerPanel) || (currentPanel == occupationPanel));
		questionButton.setSelected(currentPanel == questionPanel);

		updateCenterMessage(null, showNrRecordings);
	}

	
	protected void setStatus() {
		TextView status = (TextView) findViewById(R.id.status_msg);
		if ((rwServiceBinder != null) && (rwServiceBinder.isPlayingStaticSoundtrack())) {
			status.setText(R.string.playing_static_soundtrack_msg);
			updateCenterMessage("", false);
			return;
		}

		// Status strings
		final String and = getString(R.string.and);
		final String comma = getString(R.string.comma);
		final String period = getString(R.string.period);
		final String space = " ";

		ArrayList<String> people = new ArrayList<String>();
		for (RWListItem item : allQuestions.filter(RWListItem.Category.DEMOGRAPHIC)) {
			if (item.isOn()) {
				people.add(item.getText());
			}
		}
		
		String msg = getString(R.string.listening_to_sounds);

		if (people.size() > 0) {
			msg = getString(R.string.listening_to_voices) + space;

			for (int i = 0, j = people.size(); i < j; i++) {
				if (i == 0) {
					msg += people.get(i);
				} else if (i == j - 1) {
					msg += space + and + space + people.get(i);
				} else {
					msg += comma + space + people.get(i);
				}
			}

			msg += period;
		}

		status.setText(msg);
		updateNumberOfRecordings();
	}
	
	
	private void setVolumeLevel(int level) {
		volumeLevel = level;
		if (rwServiceBinder != null) {
			rwServiceBinder.setVolumeLevel(volumeLevel, false);
		}
	}
	
	
	/**
	 * Start a background task to retrieve the number of recordings available
	 * for the current selection of speakers and questions.
	 */
	protected void updateNumberOfRecordings() {
		if ((rwServiceBinder != null) && (rwServiceBinder.isPlayingStaticSoundtrack())) {
			updateCenterMessage("", false);
		} else {
			new UpdateNumberOfRecordingsTask().execute();
		}
	}
	
	
    private boolean connectToService() {
        try {
        	// create connection to the Roundware service
        	Intent bindIntent = new Intent(this, RWService.class);
        	bindService(bindIntent, rwServiceConnection, Context.BIND_AUTO_CREATE);
        } catch(Exception ex) {
        	if (D) {
        		Log.e(TAG, ex.getMessage());
        		ex.printStackTrace();
        	}
        	RWHtmlLog.e("Connecting to Roundware service failed");
        	return false;
        }
        return true;
    }
	

    private void disconnectFromService() {
    	if (rwServiceConnection != null) {
    		unbindService(rwServiceConnection);
    	}
    }
    
	
	/**
	 * Handler for volume seeker updates.
	 */
	public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
		setVolumeLevel(seekBar.getProgress());
	}
	
	
	public void onStartTrackingTouch(SeekBar seekBar) {
		// void
	}

	
	public void onStopTrackingTouch(SeekBar seekBar) {
		setVolumeLevel(seekBar.getProgress());
	}
	
	
	private class ListItemClickListener implements ListView.OnItemClickListener {
		public void onItemClick(AdapterView<?> parent, View v, int position, long id) {
			ImageView image = (ImageView) v.findViewById(android.R.id.icon);
			TextView text = (TextView) v.findViewById(android.R.id.text1);

			// this doesn't work: parent.getFirstVisiblePosition() + position
			// to get offset
			RWListItem q = (RWListItem) parent.getItemAtPosition((int) id);

			if (q.isOn()) {
				image.setSelected(false);
				text.setSelected(false);
				q.setOff();
			} else {
				image.setSelected(true);
				text.setSelected(true);
				q.setOn();
			}
		}
	}

	
    /**
     * Async Task to retrieve the information for the listen questions from
     * the server. These are used to fill the selection lists that are used
     * in the user interface. Note that the questions are placed in the list
     * in the order they are received from the server.
     * 
     * Note that onPostExecute runs in the UI thread.
     * 
     * @author Rob Knapen
     */
	private class RetrieveQuestionsTask extends AsyncTask<Void, Void, String> {
		
		// TODO: move class to RoundwareLib?
		
		@Override
		protected String doInBackground(Void... params) {
			if (rwServiceBinder != null) {
				return rwServiceBinder.performRetrieveQuestions(true);
			} else {
				if (D) { Log.e(TAG, "RetrieveQuestionsTask started but RWService is not available!"); }
				return null;
			}
		}

		@Override
		protected void onPostExecute(String result) {
			super.onPostExecute(result);
			allQuestions.removeAll(RWListItem.Category.QUESTION);
			// check for errors
			if (result == null) {
				if (D) { Log.e(TAG, "Operation failed, no response available extract questions from."); }
			} else {
				List<Map<String, String>> kvMaps = rwServiceBinder.retrieveKvMapFromServerResponse(result);
				for (Map<String, String> kvMap : kvMaps) {
					if (kvMap.containsKey("id") && kvMap.containsKey("text") && kvMap.containsKey("listenyn")) {
						if ("Y".equalsIgnoreCase(kvMap.get("listenyn"))) {
							allQuestions.add(RWListItem.create(RWListItem.Category.QUESTION, kvMap.get("id"), kvMap.get("text"), true));
						}
					}
				}
			}
			restoreSelections(true, false);
			initSelectionLists();
		}
	}
	
	
	/**
	 * Updates the center message that can be used to show information to the
	 * user that is blending in the background a bit. When passing null as the
	 * message the text on the screen will not be changed. Use an empty string
	 * to clear the message, or simply set the visibility to false.
	 * 
	 * @param message to show, null for no change
	 * @param visible true to show the message, false to make it invisible
	 */
	private void updateCenterMessage(String message, boolean visible) {
		TextView tv = (TextView)findViewById(R.id.number_of_recordings);
		tv.setVisibility(visible ? View.VISIBLE : View.INVISIBLE);
		if (message != null) {
			tv.setText(message);
		}
	}

	
    /**
     * Async Task to retrieve the information for the listen questions from
     * the server. These are used to fill the selection lists that are used
     * in the user interface.
     * 
     * Note that onPostExecute runs in the UI thread.
     * 
     * @author Rob Knapen
     */
	private class UpdateNumberOfRecordingsTask extends AsyncTask<Void, Void, String> {
		@Override
		protected String doInBackground(Void... params) {
			// limit number of recordings checking
			long currentMillis = System.currentTimeMillis();
			if ((lastKnownNumberOfRecordings < 0) || ((currentMillis - lastRecordingsRetrievalMillis) > RECORDINGS_CHECK_THRESHOLD_MILLIS)) {
				if (rwServiceBinder != null) {
					return rwServiceBinder.performRetrieveNumberOfRecordings(allQuestions, true);
				} else {
					return null;
				}
			}
			lastRecordingsRetrievalMillis = currentMillis;
			return String.valueOf(lastKnownNumberOfRecordings);
		}

		@Override
		protected void onPostExecute(String result) {
			super.onPostExecute(result);
			if (result == null) {
				updateCenterMessage("", showNrRecordings);
			} else {
				lastKnownNumberOfRecordings = Integer.valueOf(result);
				updateCenterMessage(String.format(getString(R.string.available_recordings_STRING), result), showNrRecordings);
			}
		}
	}
}
