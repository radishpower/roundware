/*
 	This file is part of Mountain Ghosts. Originally developed for the
 	Android OS by Rob Knapen, based on earlier work by Dan Latham.
 	
    Mountain Ghosts is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Mountain Ghosts is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Mountain Ghosts.  If not, see <http://www.gnu.org/licenses/>.
 */
package com.halseyburgund.mountainghosts.activity;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.List;
import java.util.Map;

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
import android.graphics.drawable.Drawable;
import android.location.Location;
import android.media.AudioFormat;
import android.media.AudioRecord;
import android.media.MediaPlayer;
import android.media.MediaRecorder;
import android.os.AsyncTask;
import android.os.Bundle;
import android.os.Handler;
import android.os.IBinder;
import android.provider.Settings;
import android.util.Log;
import android.view.View;
import android.view.animation.AnimationUtils;
import android.widget.AdapterView;
import android.widget.ImageButton;
import android.widget.ImageView;
import android.widget.ListView;
import android.widget.TextView;
import android.widget.ViewFlipper;

import com.google.android.maps.GeoPoint;
import com.google.android.maps.MapActivity;
import com.google.android.maps.MapController;
import com.google.android.maps.MapView;
import com.google.android.maps.Overlay;
import com.halseyburgund.mountainghosts.Main;
import com.halseyburgund.mountainghosts.R;
import com.halseyburgund.mountainghosts.location.RecordingOverlayData;
import com.halseyburgund.mountainghosts.location.RecordingOverlayItem;
import com.halseyburgund.mountainghosts.location.RecordingsOverlay;
import com.halseyburgund.mountainghosts.view.LevelMeterView;
import com.halseyburgund.mountainghosts.view.SlidingPanel;
import com.halseyburgund.roundware.adapter.RWListAdapter;
import com.halseyburgund.roundware.server.RWAction;
import com.halseyburgund.roundware.util.RWList;
import com.halseyburgund.roundware.util.RWListItem;
import com.halseyburgund.roundware.services.RWService;
import com.halseyburgund.roundware.util.RWHtmlLog;

/**
 * Ocean Voices Speak activity.
 * 
 * @author Rob Knapen, Dan Latham
 */
public class Speak extends MapActivity implements MediaPlayer.OnCompletionListener {

	// debugging
	private final static String TAG = "Speak";
	private final static boolean D = false;
	private final static boolean SUBMIT_DISABLED = false; 

	// preferences keys for state storage
	public final static String PREFS_KEY_LEGAL_NOTICE_ACCEPTED = "SavedLegalNoticeAccepted";
	
	// settings for storing recording as file
    public static final String noteFilename = "note";
    public static final String noteFilenameExtension = ".wav";
    public static final String noteScratchPath = Main.STORAGE_PATH + "scratch/";
    public static final String scratchFilePath = noteScratchPath + noteFilename + noteFilenameExtension;

	private static final int PHONE_SAMPLE_RATE = 22050; // 44100, 22050, 11025
	private static final int EMULATOR_SAMPLE_RATE = 8000; // leave at 8K, currently something else crashes the app in the emulator	
	private int sampleRate = EMULATOR_SAMPLE_RATE;	// changed at runtime

    private Handler previewHandler = null;
	private int previewTimerCount = 0;
	private RecordThread recordThread;
	
	private boolean bRecording = false;
    private boolean isPlaying = false;
    //private static final int MAX_RECORD_TIME = 120;		// seconds
    //private static final int NUM_SAMPLES = 10;		// number of samples used to calculate DB level
	//private static final int MAX_RETRY = 3;			// Max number of network retries
    
	private MediaPlayer mpPreview = null;

	// view references
	private ViewFlipper flipper;
    private LevelMeterView levelMeter;
	private SlidingPanel questionPanel;
	private SlidingPanel speakerPanel;
	private SlidingPanel occupationPanel;
	private SlidingPanel currentPanel;
	private SlidingPanel recordPanel;
	private ImageButton homeButton;
	private ImageButton exitButton;
	private ImageButton recordButton;
	private ImageButton rerecordButton;
	private ImageButton submitButton;
	private ImageView helpImage;
	private TextView recordTimeLabel;

	// map specific
	private RecordingsOverlay recordingsOverlay;
	private MapView gMap;
	private List<Overlay> mapOverlays;
	private Drawable mapMarker;
	
	// click listeners
	private View.OnClickListener previewListener;
	private View.OnClickListener recordListener;
	private View.OnClickListener rerecordListener;
	private View.OnClickListener submitListener;
	private View.OnClickListener homeListener;
	private View.OnClickListener listenListener;
	
	// fields
	private RWService rwServiceBinder;
	private RWList allQuestions = new RWList();
	private RWListAdapter questionAdapter;
	private RWListAdapter speakerAdapter;
	private RWListAdapter occupationAdapter;
	private int selectedQuestion;
	private boolean mLegalNoticeHasBeenAccepted = false;

	
	/**
	 * Handles the connection between the Roundware service and this activity.
	 */
	private ServiceConnection rwServiceConnection = new ServiceConnection() {
		@Override
		public void onServiceConnected(ComponentName className, IBinder service) {
			// called when the connection is made
	    	if (D) { Log.i(TAG, "+++ On Service Connected +++"); }
			rwServiceBinder = ((RWService.RWServiceBinder)service).getService();
			rwServiceBinder.fadeOutPlayer();
			updateQuestions();
		}

		@Override
		public void onServiceDisconnected(ComponentName name) {
			// received when the service unexpectedly disconnects
	    	if (D) { Log.i(TAG, "+++ On Service Disconnected +++"); }
			rwServiceBinder = null;
		}
	};
	

	@Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.speak);
        
 		// Level meter
 		levelMeter = (LevelMeterView)findViewById(R.id.record_level_meter);

    	// Sample rate - emulator crashes when set > 8K. If we're not running in emulator, set it
 		// The number 9774D56D682E549C is the fixed ID for Android 2.2 in the emulator.
 		String androidId = Settings.Secure.getString(this.getContentResolver(), android.provider.Settings.Secure.ANDROID_ID);
 		if (D) { Log.i(TAG, "AndroidID: " + androidId); }
		if (androidId == null || androidId.equalsIgnoreCase("9774D56D682E549C")) {
			sampleRate = EMULATOR_SAMPLE_RATE;
		} else {
			sampleRate = PHONE_SAMPLE_RATE;
		}
		
		// init misc view references
		helpImage = (ImageView)findViewById(R.id.record_help);
    	recordTimeLabel = (TextView) findViewById(R.id.label_record_time);

    	// initialize all the rest
    	initListeners();
    	initFunctionButtons();
    	initSelectionLists();
    	initSlidingPanels();
    	initMapView();
    	
    	// Flipper setup
    	flipper = (ViewFlipper)findViewById(R.id.flipper);
    	flipper.setInAnimation(AnimationUtils.loadAnimation(this, R.anim.slide_left));
    	flipper.setOutAnimation(AnimationUtils.loadAnimation(this, R.anim.slide_left));
    	
		// connect to service started by main activity
		connectToService();
	}

	
	private BroadcastReceiver connectedStateReceiver = new BroadcastReceiver() {
		@Override
		public void onReceive(Context context, Intent intent) {
			if (RWService.ACTION_STREAM_CONNECTED.equals(intent.getAction())) {
				// void - skip: Toast.makeText(getBaseContext(), "Connected", Toast.LENGTH_SHORT).show();
			} else if (RWService.ACTION_STREAM_DISCONNECTED.equals(intent.getAction())) {
				// TODO: maybe need to handle disconnect on Speak in a different way?
				// void = skip: Toast.makeText(getBaseContext(), "Disconnected", Toast.LENGTH_SHORT).show();
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
	
	
	private void showLegalNoticeDialog() {
		Builder alertBox;
		alertBox = new AlertDialog.Builder(this);
		alertBox.setTitle(R.string.legal_notice_title);
		alertBox.setMessage(R.string.legal_notice);
		alertBox.setPositiveButton(android.R.string.ok, new DialogInterface.OnClickListener() {
			@Override
			public void onClick(DialogInterface arg0, int arg1) {
				mLegalNoticeHasBeenAccepted = true;
			}
		});
		alertBox.setNegativeButton(android.R.string.no, new DialogInterface.OnClickListener() {
			@Override
			public void onClick(DialogInterface arg0, int arg1) {
				mLegalNoticeHasBeenAccepted = false;
				finish();
			}
		});
		alertBox.setCancelable(false);
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

	
    @Override
    protected void onPause() {
    	super.onPause();
    	saveSettings();
    	unregisterReceiver(connectedStateReceiver);
    }
    
    
    private void saveSettings() {
		SharedPreferences prefs = getSharedPreferences(Main.PREFS, MODE_PRIVATE);
		SharedPreferences.Editor prefsEditor = prefs.edit();
		prefsEditor.putBoolean(PREFS_KEY_LEGAL_NOTICE_ACCEPTED, mLegalNoticeHasBeenAccepted);
		prefsEditor.commit();
    }
    
    
    private void restoreSettings() {
		SharedPreferences prefs = getSharedPreferences(Main.PREFS, MODE_PRIVATE);
		mLegalNoticeHasBeenAccepted = prefs.getBoolean(PREFS_KEY_LEGAL_NOTICE_ACCEPTED, false);
    }
    
    
    @Override
    protected void onResume() {
    	super.onResume();
    	
    	restoreSettings();
    	
    	IntentFilter filter = new IntentFilter();
    	filter.addAction(RWService.ACTION_STREAM_CONNECTED);
    	filter.addAction(RWService.ACTION_STREAM_DISCONNECTED);
    	filter.addAction(RWService.ACTION_ERROR);
    	filter.addAction(RWService.ACTION_MESSAGE);
    	filter.addAction(RWService.ACTION_SHARING);
    	registerReceiver(connectedStateReceiver, filter);
    	
		// make sure playback is still silenced
		if (rwServiceBinder != null) {
			rwServiceBinder.fadeOutPlayer();
		}
		
    	// more frequent updating of questions when needed
    	if ((rwServiceBinder != null) && rwServiceBinder.isLocationBasedQuestionsEnabled()) {
    		updateQuestions();
    	}
    	
		// show legal notice about making recordings
		if (!mLegalNoticeHasBeenAccepted) {
			showLegalNoticeDialog();
		}
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
		retrieveQuestionsFromResource(allQuestions, RWListItem.Category.DEMOGRAPHIC, R.array.rw_speaker_kind_record, true);
		retrieveQuestionsFromResource(allQuestions, RWListItem.Category.USERTYPE, R.array.rw_user_type, true);
		new RetrieveQuestionsTask().execute(); // will restore selections when done
	}


	@Override
	protected boolean isRouteDisplayed() {
		return false;
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
        	RWHtmlLog.e("Connecting to Roundware Service failed");
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
	 * Initializes all references to buttons and sets them up with listeners
	 * when appropriate. Some listeners are varied based on user interaction.
	 */
    private void initFunctionButtons() {
        // main home and exit
	    homeButton = (ImageButton) findViewById(R.id.button_home);
	    homeButton.setOnClickListener(homeListener);
	    exitButton = (ImageButton) findViewById(R.id.button_exit);
	    exitButton.setOnClickListener(homeListener);
	    	
	    // Thanks listen and home
	    ImageButton button = (ImageButton) findViewById(R.id.button_thanks_home);
	    button.setOnClickListener(listenListener);
	    
	    // recording
	    recordButton = (ImageButton) findViewById(R.id.button_record);
	    recordButton.setOnClickListener(null);
	    rerecordButton = (ImageButton) findViewById(R.id.button_rerecord);
	    rerecordButton.setOnClickListener(rerecordListener);

	    // submitting
	    submitButton = (ImageButton) findViewById(R.id.button_submit);
	    submitButton.setOnClickListener(null);
    }

    
    /**
     * Creates all listeners available as instance fields.
     */
    private void initListeners() {
    	homeListener = new View.OnClickListener() {
			@Override
			public void onClick(View v) {
				homeActivity();
			}
		};

		listenListener = new View.OnClickListener() {
			@Override
			public void onClick(View v) {
	    		listenActivity();
			}
		};

		rerecordListener = new View.OnClickListener() {
			@Override
			public void onClick(View v) {
				resetRecord();
			}
		};

	    submitListener = new View.OnClickListener() {
	    	public void onClick(View v) {
	    		submitRecording();
	    	}
	    };
		
	    previewListener = new View.OnClickListener() {
	    	public void onClick(View v) {
    			previewTimerCount = 0;
        		recordTimeLabel.setText(R.string.record_counter_zero);

                if (isPlaying) {
                	donePlaying();
	    		    mpPreview.stop();
	    		} else {
	    		    recordButton.setImageResource(R.drawable.speak_stop_selector);  	
					previewHandler = new Handler();
		    		previewHandler.postDelayed(updatePreviewStatus, 1000);
		    		
        			if (initPlayback()) {
        				mpPreview.start(); 
        				isPlaying = true;
        			}
        			
        			updateNavButtonsState(false, false);
	    		    showHelpView(false);
	    		}
	    	}
	    };
	    
	    recordListener = new View.OnClickListener() {
	    	private Handler mHandler = new Handler();
    		int timerCount = 30;
            
	    	public void onClick(View v) {
	    		if (bRecording) {
	    		    mHandler.removeCallbacks(updateRecordStatus);
	    			doneRecording();
	    		} else {
	    			if (rwServiceBinder != null) {
	    				timerCount = rwServiceBinder.getMaxAllowedRecordingTimeInSec();
	    			} else {
	    				RWHtmlLog.w("RWServiceBinder is null, using default max recording time");
	    			}
	    		   	int min = timerCount / 60;
	    		   	int sec = timerCount - (min * 60);
	        		recordTimeLabel.setText(String.format("%1d:%02d", min, sec));
	                mHandler.removeCallbacks(updateRecordStatus);
	                mHandler.postDelayed(updateRecordStatus, 1000);
	    			startRecording();
			    }
	    	}
	    	
	    	private Runnable updateRecordStatus = new Runnable() {
			   public void run() {
				   --timerCount;
	    		   int min = timerCount / 60;
	    		   int sec = timerCount - (min * 60);
	    		   recordTimeLabel.setText(String.format("%1d:%02d", min, sec));
				   if (timerCount > 0) {
					   mHandler.postDelayed(updateRecordStatus, 1000);
				   } else {
					   mHandler.removeCallbacks(updateRecordStatus);
					   doneRecording();
				   }
			   }
			};	
	    };
    }
    
    
    /**
     * Initializes all sliding panels for this view.
     */
    private void initSlidingPanels() {
		questionPanel = (SlidingPanel)findViewById(R.id.question_panel);
		speakerPanel = (SlidingPanel)findViewById(R.id.speaker_panel);
		occupationPanel = (SlidingPanel)findViewById(R.id.occupation_panel);
		recordPanel = (SlidingPanel)findViewById(R.id.record_panel);	
		currentPanel = speakerPanel;
    }
    
    
    /**
     * Initializes the map display.
     */
    private void initMapView() {
    	gMap = (MapView)findViewById(R.id.mapview);
    	gMap.setSatellite(true);
		gMap.setBuiltInZoomControls(true);
    	
    	mapOverlays = gMap.getOverlays();
    	mapMarker = this.getResources().getDrawable(R.drawable.map_pin_speak);
    	recordingsOverlay = new RecordingsOverlay(this, mapMarker);
    }
    
    
    /**
     * Initializes the selection lists used in this view.
     */
    private void initSelectionLists() {
    	// turn all questions off by default, except categories with only a single item
    	allQuestions.clearSelection();
    	allQuestions.autoSelectSingleItemInCategories();

    	// create subsets (copies) of the list for the adapters with all items not selected
    	
		// selection list of what? questions
		// questionAdapter = new SimpleListAdapter(this, R.layout.question_list_item, allQuestions.sublist(RWListItem.Category.QUESTION).clearSelections(), R.layout.question_list_item);
		questionAdapter = new RWListAdapter(this, allQuestions, RWListItem.Category.QUESTION, R.layout.question_list_item);
		if (allQuestions.filter(RWListItem.Category.QUESTION).size() > 1) {		
			questionAdapter.clearSelection();
		}
		ListView questions = (ListView) findViewById(R.id.question_list);
		questions.setAdapter(questionAdapter);
        questions.setOnItemClickListener(new QuestionItemClickListener());

		// selection list of type of speakers
		// speakerAdapter = new SimpleListAdapter(this, R.layout.speaker_list_item, allQuestions.sublist(RWListItem.Category.DEMOGRAPHIC).clearSelections(), R.layout.speaker_list_item);
		speakerAdapter = new RWListAdapter(this, allQuestions, RWListItem.Category.DEMOGRAPHIC, R.layout.speaker_list_item);
		if (allQuestions.filter(RWListItem.Category.DEMOGRAPHIC).size() > 1) {		
			speakerAdapter.clearSelection();
		}
		ListView speakers = (ListView) findViewById(R.id.speaker_list);
		speakers.setAdapter(speakerAdapter);
        speakers.setOnItemClickListener(new SpeakerItemClickListener());
		
		// selection list of occupation / user types
		// occupationAdapter = new SimpleListAdapter(this, R.layout.speaker_list_item, allQuestions.sublist(RWListItem.Category.USERTYPE).clearSelections(), R.layout.speaker_list_item);
		occupationAdapter = new RWListAdapter(this, allQuestions, RWListItem.Category.USERTYPE, R.layout.speaker_list_item);
		if (allQuestions.filter(RWListItem.Category.USERTYPE).size() > 1) {		
			occupationAdapter.clearSelection();
		}
		ListView occupations = (ListView) findViewById(R.id.occupation_list);
		occupations.setAdapter(occupationAdapter);
		occupations.setOnItemClickListener(new OccupationItemClickListener());
    }
    
    
    /**
     * Initializes a selection list from a resource.
     * 
     * @param choices list to initialize
     * @param arrayResourceId containing items
     * @param defaultState (on or off) to give to each item
     */
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
    
    
	/**
	 * Modifies the sliding input panels.
	 * 
	 * @param panel to make visible (can be null)
	 */
    protected void setPanel(SlidingPanel panel) {
    	if (currentPanel != null) {
    		currentPanel.hide();
    	}   
	    
		if (currentPanel == panel) {
			panel.hide();
			currentPanel = null;
		} else if (panel != null) {
			panel.show();
			currentPanel = panel;		
		}
		
	    if (panel == recordPanel) {
		    TextView recordTitle = (TextView) findViewById(R.id.record_question_title);
		    recordTitle.setText(allQuestions.filter(RWListItem.Category.QUESTION).get(selectedQuestion).getText());
	    }
    }
    
    
    /**
     * Starts an activity to show the Home screen.
     */
    private void homeActivity() {
		Intent intent = new Intent(this, Main.class);
		startActivity(intent);
    }
    
    
    /**
     * Starts an activity to show the Listen screen.
     */
    private void listenActivity() {
		Intent player = new Intent(this, Listen.class);
		startActivity(player);
    }
    
    
    /**
     * Updates the state of the navigation buttons on the screen.
     * 
     * @param enabled state for the buttons
     * @param preview show recording or preview state
     */
    protected void updateNavButtonsState(boolean enabled, boolean preview) {
    	if (!enabled) {
			rerecordButton.setOnClickListener(null);
			submitButton.setOnClickListener(null);
			homeButton.setOnClickListener(null);
			exitButton.setOnClickListener(null);
    	} else {
    		submitButton.setOnClickListener(submitListener);
			if (preview) {
			    rerecordButton.setOnClickListener(new ConfirmDelete(new ContinueRerecord()));
				homeButton.setOnClickListener(new ConfirmDelete(new ContinueHome()));
				exitButton.setOnClickListener(new ConfirmDelete(new ContinueHome()));
			} else {
				rerecordButton.setOnClickListener(rerecordListener);
				homeButton.setOnClickListener(homeListener);
			}
    	}
    }

    
    /**
     * Makes either the help view visible or the recording view.
     * 
     * @param visible True to show help view
     */
    protected void showHelpView(boolean visible) {
    	if (visible) {
        	helpImage.setVisibility(View.VISIBLE);
        	recordTimeLabel.setVisibility(View.GONE);
        	levelMeter.setVisibility(View.GONE);
    	} else {
	    	helpImage.setVisibility(View.GONE);
	    	recordTimeLabel.setVisibility(View.VISIBLE);
	    	levelMeter.setVisibility(View.VISIBLE);
    	}
    }

    
	/**
	 * Resets the level meter.
	 */
	public void resetMeter() {
		levelMeter.reset();
	}
	
    
	/**
	 * Updates the level meter.
	 * 
	 * @param samples
	 */
    public synchronized void updateLevelMeter(short [] samples) {
 		levelMeter.setLevel(samples);
		levelMeter.postInvalidate();
    }
    
    
    /**
     * Switches state to the start recording state.
     */
    protected void resetRecord() {
		recordButton.setImageResource(R.drawable.speak_record_disabled);
		recordButton.setOnClickListener(null);
		submitButton.setOnClickListener(null);
		homeButton.setOnClickListener(homeListener);
		//listenButton.setOnClickListener(listenListener);
		rerecordButton.setOnClickListener(rerecordListener);
		
    	File file = new File(scratchFilePath);
	    file.delete();
	    initSelectionLists();
	    setPanel(speakerPanel);
    }

    
    /**
     * Switches state to the recording in progress state.
     */
    public void startRecording() {
    	showHelpView(false);
    	updateNavButtonsState(false, false);
	    recordButton.setImageResource(R.drawable.speak_stop_selector);
    	bRecording = true;

    	// send non critical notification to server when possible
    	if (rwServiceBinder != null) {
    		rwServiceBinder.performServerNotification(R.string.rw_event_type_start_record, null, true);
    	} else {
    		if (D) { Log.d(TAG, "RWServiceBinder is null, can not send log event: start record"); }
    	}
    	
		recordThread = new RecordThread();
		recordThread.start();
    }
    
    
    /**
     * Switches state to the done recording state.
     */
	protected void doneRecording() {
    	bRecording = false;
		recordButton.setImageResource(R.drawable.listen_play_selector);
	    recordButton.setOnClickListener(previewListener);

	    // send non critical notification to server when possible
    	if (rwServiceBinder != null) {
    		rwServiceBinder.performServerNotification(R.string.rw_event_type_stop_record, null, true);
    	} else {
    		if (D) { Log.d(TAG, "RWServiceBinder is null, can not send log event: stop record"); }
    	}

		updateNavButtonsState(true, true);
	    showHelpView(true);
	}
	
	
	/**
	 * Submits a recording to the server.
	 */
	protected void submitRecording() {
		Location location = rwServiceBinder.getLastKnownLocation();
		if (location == null) {
			showErrorDialog("Oh oh, there was a problem figuring out your location. Your recording will be submitted anyway, but might not show up in the app.");
		}
		
		try {
			uploadRecording();
		} catch (Exception e) {
			showErrorDialog("Oh oh, there was a problem submitting your recording: " + e.getMessage() + ". Please try again later.");
		}
	}

	
	private void uploadRecording() throws Exception {
		if (D && SUBMIT_DISABLED) {
			Log.d(TAG, "Skipping submitted the recording, DEBUG and SUBMIT_DISABLED flags are set.");
			return;
		}

		if (rwServiceBinder == null) {
			throw new Exception("Roundware background service is not running, can not upload recording at this time!");
		}
		
		// try to upload the recording
		RWAction action = null;
		Location loc = rwServiceBinder.getLastKnownLocation();
		action = rwServiceBinder.createUploadRecordingAction(allQuestions, scratchFilePath);
		if (action != null) {
			rwServiceBinder.perform(action, false);
		}

		// always show thank you screen
		flipper.showNext();
		
		// add position marker to the map when possible
		if (loc != null) {
			// create a map marker for the recording
			RecordingOverlayData data = new RecordingOverlayData();
			data.setAuthor(getString(R.string.app_name) + "- Android Roundware Client");
			data.setTopic(allQuestions.filter(RWListItem.Category.QUESTION).get(selectedQuestion).getText());
			data.setLon(loc.getLongitude());
			data.setLat(loc.getLatitude());
			RecordingOverlayItem item = new RecordingOverlayItem(this, data);
			recordingsOverlay.addOverlay(item);
			
			// attach marker overlay to the map
			mapOverlays.clear();
			mapOverlays.add(recordingsOverlay);
			
			// animate map to marker position 
			MapController mc = gMap.getController();
			GeoPoint gPoint = new GeoPoint((int)(loc.getLatitude()*1E6),(int)(loc.getLongitude()*1E6));
			mc.animateTo(gPoint);
			mc.setZoom(18);
		}
	}
	
	
	/**
	 * Initializes playback of the last recording.
	 * 
	 * @return true when playback is possible
	 */
    protected boolean initPlayback() {
    	boolean bReturn = true;
    	
    	// Setup for playback
    	File file = new File(scratchFilePath);
    	
    	if (file.exists()) { 
    		mpPreview = new MediaPlayer();
    		mpPreview.setOnCompletionListener(this);
		  
    		try {
    			mpPreview.setDataSource(scratchFilePath);
    			mpPreview.prepare();
    		} catch(Exception ex) {
    			mpPreview = null;
    			bReturn = false;
    			RWHtmlLog.e("Preparing media player " + ex.getMessage());
    		}
    	}
    	return bReturn;
    }

    
    /**
     * Switches state to the done playing state.
     */
    protected void donePlaying() {
		isPlaying = false;
	    if (previewHandler != null) {
	    	previewHandler.removeCallbacks(updatePreviewStatus);
		    previewHandler = null;
		}

	    recordButton.setImageResource(R.drawable.listen_play_selector);
	    updateNavButtonsState(true, true);
    	showHelpView(true);
    }

    
    /**
     * MediaPlayer notification when reaching end of playback.
     */
    public void onCompletion(MediaPlayer mp) {
    	donePlaying();
    }

    
    /**
     * Thread to update playback time indication.
     */
	private Runnable updatePreviewStatus = new Runnable() {
	   public void run() {
		   	previewTimerCount++;
		   	int min = previewTimerCount / 60;
		   	int sec = previewTimerCount - (min * 60);
    		recordTimeLabel.setText(String.format("%1d:%02d", min, sec));
    		if (previewHandler != null) {
    			previewHandler.postDelayed(updatePreviewStatus, 1000);
    		}
	   }
	};

	
	/**
	 * Thread for making a recording.
	 */
	private class RecordThread extends Thread {	    
	    public void run() {
    		// ensure scratch folder exists
        	File scratch = new File(noteScratchPath);
        	if (!scratch.exists()) {
        		scratch.mkdirs();
        	}
	    	recordAudio();
	    }
	
	    public void recordAudio() {
	    	int channelConfiguration = AudioFormat.CHANNEL_CONFIGURATION_MONO;
	    	int audioEncoding = AudioFormat.ENCODING_PCM_16BIT;

	    	// We're important...
	    	android.os.Process.setThreadPriority(android.os.Process.THREAD_PRIORITY_URGENT_AUDIO);

	    	// Allocate Recorder and Start Recording...
	    	int minBufferSize = AudioRecord.getMinBufferSize(sampleRate, channelConfiguration, audioEncoding);
	    	if (minBufferSize == AudioRecord.ERROR_BAD_VALUE) {
	    		Log.e(TAG, "Bad value, could not create audio buffer!");
	    		return;
	    	} else if (minBufferSize == AudioRecord.ERROR) {
	    		Log.e(TAG, "System Error, could not create audio buffer!");
	    		return;
	    	}
	    	
	    	int bufferSize = 2 * minBufferSize;
	    	AudioRecord recordInstance = new AudioRecord(MediaRecorder.AudioSource.MIC, sampleRate, channelConfiguration, audioEncoding, bufferSize);

	    	byte[] data = new byte[bufferSize];
	    	ByteArrayOutputStream bytesOut = new ByteArrayOutputStream();
	    	short[] samples = new short[10];
	    	int offset;
	    	
	    	recordInstance.startRecording();
	    	try  {
	    		while (bRecording) { 
	    			recordInstance.read(data, 0, bufferSize);
	    			bytesOut.write(data);
	    			
	    			offset = 0;
	    			for(int i = 0; i < 10; i++) {
	    				samples[i] = (short) (((data[offset+1] << 8)) | ((data[offset] & 0xff)));
	    				offset += 2;
	    			}
	    			updateLevelMeter(samples);
	    		}
	    	} catch (IOException e) {
	    		RWHtmlLog.e(e.getMessage());
	    	} catch (OutOfMemoryError om) {
	    		RWHtmlLog.e("Record - Out of memory");
	    	}
	    	
	    	recordInstance.stop();
	    	save(scratchFilePath, bytesOut.toByteArray());
	    	recordInstance.release();

	        resetMeter();
	    }

	    
	    /**
	     * Saves the supplied byte stream as a WAV file
	     * @param name The desired filename
	     * @param bytes The sound data in 16-bit little-endian PCM format
	     */
		public void save(String name, byte[] bytes) {
			File fileName = new File(name);
			if (fileName.exists())
				fileName.delete();

			try {
				fileName.createNewFile();
				FileOutputStream out = new FileOutputStream(fileName);

				byte[] header = createHeader(bytes);		
                out.write(header); 
                out.write(bytes);
				out.flush(); 
                out.close();
				System.gc();
				
			} catch (Exception e) {
				RWHtmlLog.e("Error saving WAV file: " + e.getMessage());
			}
		}

		
		/**
		 * Creates a valid WAV header for the given bytes,
		 * using the class-wide sample rate
		 * @param bytes The sound data to be appraised
		 * @return The header, ready to be written to a file
		 */
		public byte[] createHeader(byte[] bytes) {				
			int totalLength = bytes.length + 4 + 24 + 8;
			byte[] lengthData = intToBytes(totalLength);
			byte[] samplesLength = intToBytes(bytes.length);
			byte[] bitRate = intToBytes(sampleRate);
			byte[] bytesPerSecond = intToBytes(sampleRate*2);

			ByteArrayOutputStream out = new ByteArrayOutputStream();

			try {
				out.write(new byte[] {'R','I','F','F'});
				out.write(lengthData);
				out.write(new byte[] {'W','A','V','E'});

				out.write(new byte[] {'f','m','t',' '});
				out.write(new byte[] {0x10,0x00,0x00,0x00}); // 16 bit chunks
				out.write(new byte[] {0x01,0x00,0x01,0x00}); // mono
				out.write(bitRate); // sampling rate
				out.write(bytesPerSecond); // bytes per second
				out.write(new byte[] {0x02,0x00,0x10,0x00}); // 2 bytes per sample

				out.write(new byte[] {'d','a','t','a'});
				out.write(samplesLength);	
			} catch (IOException e) {
				RWHtmlLog.e("Error saving WAV file: " + e.getMessage());
			}

			return out.toByteArray();
		}

		
		/**
		 * Turns an integer into its little-endian 
		 * four-byte representation
		 * @param in The integer to be converted
		 * @return The bytes representing this integer
		 */
		public byte[] intToBytes(int in) {
			byte[] bytes = new byte[4];
			for (int i=0; i<4; i++) {
				bytes[i] = (byte) ((in >>> i*8) & 0xFF);
			}
			return bytes;
		}
	}
	

	private class ConfirmDelete implements View.OnClickListener {
		DialogInterface.OnClickListener continueListener;
		
		public ConfirmDelete(DialogInterface.OnClickListener listener) {
			continueListener = listener;
		}
		
	 	public void onClick(View v) {		 
	 		Builder alertBox;

			alertBox = new AlertDialog.Builder(Speak.this);
			alertBox.setTitle(R.string.confirm_title);
			alertBox.setMessage(R.string.confirm_message);
			alertBox.setPositiveButton(android.R.string.yes, new SubmitRecord());
			alertBox.setNegativeButton(android.R.string.no, continueListener);
			
			alertBox.show();
	 	}	
	}

	 
	private class ContinueHome implements DialogInterface.OnClickListener
	{
		public void onClick(DialogInterface dialog, int whichButton) {
			 dialog.cancel();
			 homeActivity();
		}
	}
	 

	private class ContinueRerecord implements DialogInterface.OnClickListener
	{
		 public void onClick(DialogInterface dialog, int whichButton) {
			 dialog.cancel();
			 resetRecord();
		 }
	}
	
	
	private class SubmitRecord implements DialogInterface.OnClickListener {
		 public void onClick(DialogInterface dialog, int whichButton) {
			 dialog.cancel();
			 submitRecording();
		 }
	}
	
	
	private class ListItemClickListener implements ListView.OnItemClickListener {
		RWListItem lastItem;
		ImageView lastImage;
		TextView lastText;

		public void onItemClick(AdapterView<?> parent, View v, int position, long id) {
			ImageView image = (ImageView)v.findViewById(android.R.id.icon);
			TextView text = (TextView)v.findViewById(android.R.id.text1);

			// this doesn't work: parent.getFirstVisiblePosition() + position
			// to get offset. id seems to be the right value.
			RWListItem q = (RWListItem)parent.getItemAtPosition((int)id);

			if (lastItem != null) {
				lastItem.setOff();
				lastImage.setSelected(false);
				lastText.setSelected(false);
			}

			if (!q.isOn()) {
				image.setSelected(true);
				text.setSelected(true);
				q.setOn();
				lastItem = q;
				lastImage = image;
				lastText = text;
			}
		}
	}

	
	private class SpeakerItemClickListener extends ListItemClickListener {
		public void onItemClick(AdapterView<?> parent, View v, int position, long id) {
			super.onItemClick(parent, v, position, id);
			//selectedSpeaker = (int)id;
			// only show user type selection when needed
			if (allQuestions.filter(RWListItem.Category.USERTYPE).size() > 1) {
				setPanel(occupationPanel);
			} else {
				setPanel(questionPanel);
			}
		}	 
	}

	
	private class OccupationItemClickListener extends ListItemClickListener {
		public void onItemClick(AdapterView<?> parent, View v, int position, long id) {
			super.onItemClick(parent, v, position, id);
			//selectedOccupation = (int)id;
			setPanel(questionPanel);
		}	 
	}
	
	
  private class QuestionItemClickListener extends ListItemClickListener {
	  public void onItemClick(AdapterView<?> parent, View v, int position, long id) {
		  super.onItemClick(parent, v, position, id);
		  selectedQuestion = (int)id;
		  recordTimeLabel.setText(R.string.record_counter_zero);
		  setPanel(recordPanel);
		  resetMeter();
		  recordButton.setImageResource(R.drawable.speak_record_selector);
		  recordButton.setOnClickListener(recordListener);
	  }	 
  }
  
  
  /**
   * Async Task to retrieve the information for the Speak questions from
   * the server. These are used to fill the selection lists that are used
   * in the user interface. Note that the questions are placed in the list
   * in the order they are received from the server.
   * 
   * Note that onPostExecute runs in the UI thread.
   * 
   * @author Rob Knapen
   */
	private class RetrieveQuestionsTask extends AsyncTask<Void, Void, String> {
		@Override
		protected String doInBackground(Void... params) {
			if (rwServiceBinder != null) {
				return rwServiceBinder.performRetrieveQuestions(true);
			}
			if (D) { Log.e(TAG, "RetrieveQuestionsTask started but RWService is not available!"); }
			return null;
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
					if (kvMap.containsKey("id") && kvMap.containsKey("text") && kvMap.containsKey("speakyn")) {
						if ("Y".equalsIgnoreCase(kvMap.get("speakyn"))) {
							allQuestions.add(RWListItem.create(RWListItem.Category.QUESTION, kvMap.get("id"), kvMap.get("text"), false));
						}
					}
				}
			}
			initSelectionLists();
		}
	}
}
