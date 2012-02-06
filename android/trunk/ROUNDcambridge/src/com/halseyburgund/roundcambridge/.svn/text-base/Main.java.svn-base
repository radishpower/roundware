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
package com.halseyburgund.roundcambridge;

import java.util.UUID;

import com.halseyburgund.roundcambridge.activity.Listen;
import com.halseyburgund.roundcambridge.activity.Preferences;
import com.halseyburgund.roundcambridge.activity.Speak;
import com.halseyburgund.roundcambridge.view.VersionDialog;
import com.halseyburgund.roundware.services.RWService;
import com.halseyburgund.roundware.util.RWHtmlLog;

import android.app.Activity;
import android.app.AlertDialog;
import android.app.ProgressDialog;
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
import android.os.Environment;
import android.os.IBinder;
import android.preference.PreferenceManager;
import android.util.Log;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.widget.ImageButton;
import android.widget.TextView;
import android.widget.Toast;

public class Main extends Activity {
	
	// debugging
	private final static String TAG = "ROUNDcambridge";
	private final static boolean D = false;

    public final static String STORAGE_PATH = Environment.getExternalStorageDirectory().getAbsolutePath() + "/roundcambridge/";
    
    public final static String PREFS = "ROUNDcambridge";
    public final static String INTENT_EXTRA_UDID = "udid";
	
	private final static int MENU_ITEM_INFO = Menu.FIRST;
	private final static int MENU_ITEM_PREFERENCES = Menu.FIRST + 1;
	private final static int MENU_ITEM_EXIT = Menu.FIRST + 2;
	
    // view references
	private ImageButton listenButton;
	private ImageButton speakButton;
	
	// fields
	private ProgressDialog progressDialog;
	private Intent rwService;
	private RWService rwServiceBinder;
	private String userId;
	private boolean connected;

	
	/**
	 * Handles the connection between the Roundware service and this activity.
	 */
	private ServiceConnection rwServiceConnection = new ServiceConnection() {
		@Override
		public void onServiceConnected(ComponentName className, IBinder service) {
			// called when the connection is made
	    	if (D) { Log.i(TAG, "+++ On Service Connected +++"); }
			rwServiceBinder = ((RWService.RWServiceBinder)service).getService();
			updateServerForPreferences();
			new RetrieveNumberOfRecordingsTask().execute();
		}

		@Override
		public void onServiceDisconnected(ComponentName name) {
			// received when the service unexpectedly disconnects
	    	if (D) { Log.i(TAG, "+++ On Service Disconnected +++"); }
			rwServiceBinder = null;
			setConnected(false);
		}
	};
	
	
	public void onCreate(Bundle savedInstanceState) {
    	if (D) { Log.i(TAG, "+++ On Create +++"); }
        super.onCreate(savedInstanceState);
        
        setContentView(R.layout.main);
		setVolumeControlStream(AudioManager.STREAM_MUSIC);		
        
    	initFunctionButtons();
    	
    	// create session start unless one is passed in
        initServerSesssion(getIntent());
        
        showVersionDialog(false);
    }

	
	private BroadcastReceiver connectedStateReceiver = new BroadcastReceiver() {
		@Override
		public void onReceive(Context context, Intent intent) {
			if (RWService.ACTION_STREAM_CONNECTED.equals(intent.getAction())) {
				// connection to server is established
				setConnected(true);
				updateServerForPreferences();
				checkLocationProviderAvailability();
			} else if (RWService.ACTION_STREAM_DISCONNECTED.equals(intent.getAction())) {
				// connection to server is lost
				setConnected(false);
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
	
	
	private void setConnected(boolean state) {
		connected = state;

		// remove progress dialog when applicable
		if ((progressDialog != null) && (state != false)) {
			if (D) { Log.d(TAG, "dismissing progress dialog"); }
			progressDialog.dismiss();
		}

		// update button states
		if (listenButton != null) {
			listenButton.setEnabled(connected);
		}
		if (speakButton != null) {
			speakButton.setEnabled(connected);
		}
		
		// update footer message
		TextView tv = (TextView)findViewById(R.id.number_of_recordings);
		if ((tv != null) && (!connected)) {
			tv.setText("Not connected");
		}
	}
	
	
    @Override
    protected void onPause() {
    	if (D) { Log.i(TAG, "+++ On Pause +++"); }
    	unregisterReceiver(connectedStateReceiver);
    	super.onPause();
    }

    
    @Override
    protected void onResume() {
    	if (D) { Log.i(TAG, "+++ On Resume +++"); }
    	IntentFilter filter = new IntentFilter();
    	filter.addAction(RWService.ACTION_STREAM_CONNECTED);
    	filter.addAction(RWService.ACTION_STREAM_DISCONNECTED);
    	filter.addAction(RWService.ACTION_ERROR);
    	filter.addAction(RWService.ACTION_MESSAGE);
    	filter.addAction(RWService.ACTION_SHARING); // not really expected here
    	registerReceiver(connectedStateReceiver, filter);
		updateServerForPreferences();
		if (connected) {
			updateNumberOfRecordings();
		}
		checkLocationProviderAvailability();
    	super.onResume();
    }
    
    
	private void checkLocationProviderAvailability() {
		if (rwServiceBinder != null) {
			boolean gpsEnabled = rwServiceBinder.isGpsEnabled();
			boolean networkLocationEnabled = rwServiceBinder.isNetworkLocationEnabled();
			
			if ((!gpsEnabled) && (!networkLocationEnabled)) {
				showMessageDialog(getString(R.string.enable_location_provider_message));
			} else if (!gpsEnabled) {
				showMessageDialog(getString(R.string.enable_gps_message));
			}
		}
	}
    
    
    @Override
    protected void onDestroy() {
    	if (D) { Log.i(TAG, "+++ On Destroy +++"); }
    	super.onDestroy();
    	SharedPreferences prefs = getSharedPreferences(PREFS, MODE_PRIVATE); 		
    	SharedPreferences.Editor prefsEditor = prefs.edit().clear();
    	prefsEditor.commit();
    	stopService();
    }
    
    
    @Override
	protected void onStop() {
    	if (D) { Log.i(TAG, "+++ On Stop +++"); }
		super.onStop();
	}
    
    
	@Override
	public boolean onCreateOptionsMenu(Menu menu) {
		super.onCreateOptionsMenu(menu);

		menu.add(0, MENU_ITEM_INFO, Menu.NONE, R.string.info_menuitem)
			.setShortcut('1', 'i')
			.setIcon(android.R.drawable.ic_menu_info_details);
		
		menu.add(0, MENU_ITEM_PREFERENCES, Menu.NONE, R.string.preferences_menuitem)
			.setShortcut('4', 'p')
			.setIcon(android.R.drawable.ic_menu_preferences);
		
		menu.add(0, MENU_ITEM_EXIT, Menu.NONE, R.string.exit_menuitem)
		.setShortcut('3', 'e')
		.setIcon(android.R.drawable.ic_menu_close_clear_cancel);
		
		return true;
	}

	
	@Override
	public boolean onPrepareOptionsMenu(Menu menu) {
		return super.onPrepareOptionsMenu(menu);
	}

	
	@Override
	public boolean onOptionsItemSelected(MenuItem item) {
		switch (item.getItemId()) {
			case MENU_ITEM_INFO: {
				showVersionDialog(true);
				return true;
			}
			case MENU_ITEM_PREFERENCES: {
				Intent settingsActivity = new Intent(getBaseContext(), Preferences.class);
				startActivity(settingsActivity);
				return true;
			}
			case MENU_ITEM_EXIT: {
				deleteQueueAndExit();
				return true;
			}
		}
		return super.onOptionsItemSelected(item);
	}
	
	
	private void deleteQueueAndExit() {
		if ((rwServiceBinder == null) || (!rwServiceBinder.deleteQueue())) {
			String msg = "Can't delete queue at the moment!";
			Toast.makeText(getApplicationContext(), msg, Toast.LENGTH_SHORT).show();
			RWHtmlLog.e(msg);
		}
		finish();
	}

	
	private void showVersionDialog(boolean forced) {
		try {
			VersionDialog.show(this, "com.halseyburgund.roundcambridge", R.layout.version_dialog, R.string.version_text, forced);
		} catch (Exception e) {
			Log.e(TAG, "Unable to show version dialog!", e);
		}
	}
	
	
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

	
	/**
     * Initializes a server session.
     * 
     * @param intent
     * @return true when successful, false when failed
     */
    private boolean initServerSesssion(Intent intent) {
    	Bundle extras = intent.getExtras();
    	
        if (extras != null) {
        	userId = extras.getString(INTENT_EXTRA_UDID);
        }
        
        if (userId == null) {
        	userId = UUID.randomUUID().toString();
        }

        if (!startService()) {
        	return false;
        }
        
        return true;
    }
    
    
    private boolean startService() {
		if (D) { Log.d(TAG, "opening progress dialog"); }
		progressDialog = ProgressDialog.show(this, getString(R.string.connecting_to_server_title), getString(R.string.connecting_to_server_message), true, true);
    	
        try {
        	// create connection to the OV service
        	Intent bindIntent = new Intent(Main.this, RWService.class);
        	bindService(bindIntent, rwServiceConnection, Context.BIND_AUTO_CREATE);

        	// start the service
        	rwService = new Intent(this, RWService.class);
    		rwService.putExtra(RWService.INTENT_EXTRA_USER_ID, userId);

    		String serverUrlOverride = readServerUrlOverrideFromPreferences();
        	if (serverUrlOverride != null) {
            	rwService.putExtra(RWService.INTENT_EXTRA_SERVER_URL_OVERRIDE, serverUrlOverride);
        	}

        	rwService.putExtra(RWService.INTENT_EXTRA_NOTIFICATION_TITLE, getString(R.string.notification_title));
        	rwService.putExtra(RWService.INTENT_EXTRA_NOTIFICATION_DEFAULT_TEXT, getString(R.string.notification_default_text));
            rwService.putExtra(RWService.INTENT_EXTRA_NOTIFICATION_ICON_ID, R.drawable.status_icon);
        	rwService.putExtra(RWService.INTENT_EXTRA_NOTIFICATION_ACTIVITY_CLASS_NAME, this.getClass().getName());
        	startService(rwService);
        } catch(Exception ex) {
        	if (D) {
        		Log.e(TAG, ex.getMessage());
        		ex.printStackTrace();
        	}
        	RWHtmlLog.e("start of Roundware Service failed");
        	return false;
        }
        return true;
    }

    
    private String readServerUrlOverrideFromPreferences() {
		SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(getBaseContext());
		String serverName = prefs.getString(Preferences.SERVER_NAME, null);
		String serverPage = prefs.getString(Preferences.SERVER_PAGE, null);
		if ((serverName != null) && (serverPage != null)) {
			return serverName + "/" + serverPage;
		} else {
			return null;
		}
    }

    
    private void updateServerForPreferences() {
    	if (rwServiceBinder != null) {
			SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(getBaseContext());
			boolean showDetailedMessages = prefs.getBoolean(Preferences.SHOW_DETAILED_MESSAGES, false);
			rwServiceBinder.setShowDetailedMessages(showDetailedMessages);

			String mockLat = prefs.getString(Preferences.MOCK_LATITUDE, "");
			String mockLon = prefs.getString(Preferences.MOCK_LONGITUDE, "");
			rwServiceBinder.setMockLocation(mockLat, mockLon);

			// TODO: add more dynamic preferences handling here
    	}
    }
    
    
    private boolean stopService() {
    	if (rwServiceBinder != null) {
    		// rwServiceBinder.setNotificationText("Thank you for using Roundware");
    		rwServiceBinder.stopService();
			unbindService(rwServiceConnection);
    	} else {
	    	if (rwService != null) {
	    		return stopService(rwService);
	    	}
    	}
    	return true;
    }
    
    
    private void updateNumberOfRecordings() {
    	TextView tv = (TextView)findViewById(R.id.number_of_recordings);
    	tv.setText("");
    	new RetrieveNumberOfRecordingsTask().execute();
    }
    
    
    /**
     * Initializes the buttons in the view.
     */
    private void initFunctionButtons() {
    	// listen button
	    listenButton = (ImageButton) findViewById(R.id.button_main_listen);
	    listenButton.setOnClickListener(new View.OnClickListener() {
	    	public void onClick(View v) {
	    		Intent intent = new Intent(Main.this, Listen.class);
	    		// get current ids from service
	    		if (rwServiceBinder != null) {
		    		intent.putExtra(INTENT_EXTRA_UDID, rwServiceBinder.getUserId());
	    		} else {
	    			// use start up values
		    		intent.putExtra(INTENT_EXTRA_UDID, userId);
	    		}
	    		startActivity(intent);
	    	}
	    });

	    // speak button
	    speakButton = (ImageButton) findViewById(R.id.button_main_speak);
	    speakButton.setOnClickListener(new View.OnClickListener() {
	    	public void onClick(View v) {
	    		Intent intent = new Intent(Main.this, Speak.class);
	    		// get current ids from service
	    		if (rwServiceBinder != null) {
		    		intent.putExtra(INTENT_EXTRA_UDID, rwServiceBinder.getUserId());
	    		} else {
	    			// use start up values
		    		intent.putExtra(INTENT_EXTRA_UDID, userId);
	    		}
	    		startActivity(intent);
	    	}
	    });
	    
	    
		// exit button
		ImageButton button = (ImageButton) findViewById(R.id.button_exit);
		button.setOnClickListener(new View.OnClickListener() {
			public void onClick(View v) {
				deleteQueueAndExit();
			}
		});
    }

    
    /**
     * Async Task to retrieve the current number of recordings from the Roundware
     * service and display it on the screen. Note that onPostExecute runs in the UI
     * thread.
     * 
     * @author Rob Knapen
     */
	private class RetrieveNumberOfRecordingsTask extends AsyncTask<Void, Void, String> {
		
		public RetrieveNumberOfRecordingsTask() {
			TextView tv = (TextView)findViewById(R.id.number_of_recordings);
			tv.setText("Updating...");
		}
		
		@Override
		protected String doInBackground(Void... params) {
			if (rwServiceBinder != null) {
				return rwServiceBinder.performRetrieveNumberOfRecordings(null, true);
			} else {
				return null;
			}
		}

		@Override
		protected void onPostExecute(String result) {
			super.onPostExecute(result);
			TextView tv = (TextView)findViewById(R.id.number_of_recordings);
			if (result == null) {
				tv.setText("Not Connected");
			} else {
				tv.setText(String.format(getString(R.string.current_recordings_STRING), result));
			}
		}
	}    
}