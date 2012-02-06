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
package com.halseyburgund.roundware.services;

import java.io.IOException;
import java.util.List;
import java.util.Map;
import java.util.Observable;
import java.util.Observer;
import java.util.Timer;
import java.util.TimerTask;

import com.halseyburgund.roundware.R;
import com.halseyburgund.roundware.location.RWLocationTracker;
import com.halseyburgund.roundware.server.RWAction;
import com.halseyburgund.roundware.server.RWActionQueue;
import com.halseyburgund.roundware.server.RWActionFactory;
import com.halseyburgund.roundware.server.RWProtocol;
import com.halseyburgund.roundware.util.RWHtmlLog;
import com.halseyburgund.roundware.util.RWList;

import android.app.Notification;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.location.Location;
import android.media.MediaPlayer;
import android.os.AsyncTask;
import android.os.Binder;
import android.os.IBinder;
import android.os.PowerManager;


/**
 * Service for background playback of Roundware sound stream.
 * 
 * @author Rob Knapen
 */
public class RWService extends Service implements Observer {

	// intent extras for initializing the Roundware background service
    public final static String INTENT_EXTRA_USER_ID = "com.halseyburgund.roundware.user_id";
    public final static String INTENT_EXTRA_SERVER_URL_OVERRIDE = "com.halseyburgund.roundware.server_url";
    public final static String INTENT_EXTRA_NOTIFICATION_TITLE = "com.halseyburgund.roundware.notification_title";
    public final static String INTENT_EXTRA_NOTIFICATION_DEFAULT_TEXT = "com.halseyburgund.roundware.notification_default_text";
    public final static String INTENT_EXTRA_NOTIFICATION_ICON_ID = "com.halseyburgund.roundware.notification_icon_id";
    public final static String INTENT_EXTRA_NOTIFICATION_ACTIVITY_CLASS_NAME = "com.halseyburgund.roundware.notification_activity_class_name";
    public final static String INTENT_EXTRA_SERVER_MESSAGE = "com.halseyburgund.roundware.broadcast_server_message";
    public final static String INTENT_EXTRA_LOCATION_LAT = "com.halseyburgund.roundware.broadcast_server_location_latitude";
    public final static String INTENT_EXTRA_LOCATION_LON = "com.halseyburgund.roundware.broadcast_server_location_longitude";
    public final static String INTENT_EXTRA_LOCATION_PROVIDER = "com.halseyburgund.roundware.broadcast_server_location_provider";
    public final static String INTENT_EXTRA_LOCATION_ACCURACY_M = "com.halseyburgund.roundware.broadcast_server_location_accuracy";

    // service broadcast messages
    // connection to audio stream established
    public final static String ACTION_STREAM_CONNECTED = "com.halseyburgund.roundware.action_stream_connected";
    // connection to audio stream lost
	public final static String ACTION_STREAM_DISCONNECTED = "com.halseyburgund.roundware.action_stream_disconnected";
	// location updated
	public final static String ACTION_LOCATION_UPDATED = "com.halseyburgund.roundware.action_location_updated";
	// error reported by server as result to an operation
	public final static String ACTION_ERROR = "com.halseyburgund.roundware.action_server_error";
	// warning (user message) reported by server as result to an operation
	public final static String ACTION_MESSAGE = "com.halseyburgund.roundware.action_server_message";
	// sharing message send back by server as result
	public final static String ACTION_SHARING = "com.halseyburgund.roundware.action_server_sharing";
	
	// debugging
	private final static String TAG = "RWService";
	private final static boolean D = false;
	
	// private final static int QUEUE_CHECK_INTERVAL = 10000; // 10 sec
	// private final static int PING_THRESHOLD_MILLIS = 30000; // send ping if idle for 30 sec

	// playback notification
	private final static int NOTIFICATION_ID = 10001;
	
	// service binder
	private final IBinder mBinder = new RWServiceBinder();
	
	// fields
	private RWProtocol mProtocol;
	private RWActionFactory mActionFactory;
	private MediaPlayer mPlayer;
	private Timer mQueueTimer;
	private long mLastRequestMillis;

	private PendingIntent mNotificationPendingIntent;
	private Notification mRwNotification;
	private String mNotificationTitle;
	private String mNotificationDefaultText;
	private int mNotificationIconId;
	private Class<?> mNotificationActivity;
	
	private String mServerUrl;
	private String mStreamUrl;
	private String mUserId;
	private String mSessionId;
	private boolean mShowDetailedMessages = false;
	private boolean mStartPlayingWhenReady = false;
	private boolean mStreamConnected = false;
	private long mQueueCheckIntervalMsec = 10000; // 10 sec
	private long mPingThresholdMsec = 60000; // 60 sec
	
	private int mVolumeLevel = 0;
	private int mMinVolumeLevel = 0;
	private int mMaxVolumeLevel = 50;
	private float mVolumeStepMultiplier = 0.95f; // 1 dB = 0.89

	
	/**
	 * Service binder used to communicate with the Roundware service.
	 * 
	 * @author Rob Knapen
	 */
	public class RWServiceBinder extends Binder {
		public RWService getService() {
			return RWService.this;
		}
	}
	
	
    /**
     * Async Task to start play back of a sound stream from the server. When
     * the request is successful it will also start the ping timer that sends
     * heart beats back to the server.
     */
	private class StartPlayingStreamTask extends AsyncTask<Void, Void, String> {
		@Override
		protected String doInBackground(Void... params) {
			// start initial stream without selection
			if (D) { RWHtmlLog.i(TAG, "Starting Playback from Service", null); }
			return perform(mActionFactory.createRequestStreamAction(null), true);
		}

		@Override
		protected void onPostExecute(String result) {
			super.onPostExecute(result);
			if (D) { RWHtmlLog.i(TAG, "Starting Playback from Service result: " + result, null); }
			// check for errors
			mStreamUrl = null;
			mSessionId = null;
			if (result == null) {
				RWHtmlLog.e(TAG, "Operation failed, no response available to start audio stream from.", null);
				broadcastStreamConnectedStatus(false);
			} else {
				String streamUrlKey = getString(R.string.rw_key_stream_url);
				String sessionIdKey = getString(R.string.rw_key_session_id);
				
				List<Map<String, String>> kvMaps = retrieveKvMapFromServerResponse(result);
				for (Map<String, String> kvMap : kvMaps) {
					// TODO: remove old - if (kvMap.containsKey(streamUrlKey) && kvMap.containsKey(sessionIdKey)) {
					if (kvMap.containsKey(streamUrlKey)) {
						mStreamUrl = kvMap.get(streamUrlKey);
						mSessionId = kvMap.get(sessionIdKey);
						break;
					}
				}
				
				if ((mStreamUrl == null) || (mStreamUrl.length() == 0)) {
					broadcastStreamConnectedStatus(false);
				} else {
					if (D) { RWHtmlLog.i(TAG, "Starting MediaPlayer for stream: " + mStreamUrl, null); }
					try {
						mPlayer.setDataSource(mStreamUrl);
						mPlayer.prepareAsync();
						
						// TODO: remove this extra check to see if the static soundtrack has been returned
						String staticSoundtrackName = getString(R.string.rw_spec_static_soundtrack_name);
						if ((mSessionId == null) && (mStreamUrl.endsWith(staticSoundtrackName))) {
							mSessionId = getString(R.string.rw_spec_static_soundtrack_session_id);
						}
						
						// send log message about stream started
						performServerNotification(R.string.rw_event_type_start_listen, null, true);
						// TODO: updateConnectedStatus(true); -> done in onPrepared event from media player! 
					} catch (Exception ex) {
						RWHtmlLog.e(TAG + ": " + ex.toString());
						broadcastStreamConnectedStatus(false);

						// broadcast error message
						Intent intent = new Intent();
						String message = getString(R.string.roundware_error_mediaplayer_problem);
						message = message + "\n\nException: " + ex.getMessage();
						intent.setAction(ACTION_ERROR);
						intent.putExtra(INTENT_EXTRA_SERVER_MESSAGE, message);
						if (D) { RWHtmlLog.i(TAG, "Going to send broadcast event, error message = " + message, null); }
						sendBroadcast(intent);
					}
				}
			}
		}
	}
	
	
	@Override
	public void onCreate() {
		if (D) { RWHtmlLog.i(TAG, "+++ onCreate +++", null); }
		super.onCreate();
		
		// get default server url from resources and reset other critical vars
		mServerUrl = getString(R.string.rw_spec_server_url);
		mStreamUrl = null;
		mSessionId = null;

		String str = getString(R.string.rw_spec_queue_check_interval_in_sec);
		mQueueCheckIntervalMsec = Long.valueOf(str) * 1000;
		
		str = getString(R.string.rw_spec_heartbeat_interval_in_sec);
		mPingThresholdMsec = Long.valueOf(str) * 1000;
		
		// create a factory for actions and a protocol instance
		mActionFactory = new RWActionFactory(this);
		mProtocol = new RWProtocol(this);

		// create a queue for actions
		// TODO: change from singleton to private instance?
		RWActionQueue.instance().init(this);
		
        // Setup for GPS callback
        RWLocationTracker.instance().init(this);
        RWLocationTracker.instance().addObserver(this);
        
        // TODO: only start updates when config requires it!
        startLocationUpdates();
	}
	
	
	public boolean isGpsEnabled() {
		return RWLocationTracker.instance().isGpsEnabled();
	}
	
	
	public boolean isNetworkLocationEnabled() {
		return RWLocationTracker.instance().isNetworkLocationEnabled();
	}
	
	
	private void startLocationUpdates() {
		String str = getString(R.string.rw_spec_min_location_update_time_msec);
		long minTime = Long.valueOf(str);

		str = getString(R.string.rw_spec_min_location_update_distance_meters);
		float minDist = Float.valueOf(str);

		// RWLocationTracker.instance().gotoLastKnownLocation();
		RWLocationTracker.instance().startLocationUpdates(minTime, minDist);
	}
	
	
	public Location getLastKnownLocation() {
		return RWLocationTracker.instance().getLastLocation();
	}

	
	@Override
	public IBinder onBind(Intent intent) {
		return mBinder;
	}
	

	@Override
	public int onStartCommand(Intent intent, int flags, int startId) {
		if (D) { RWHtmlLog.i(TAG, "+++ onStartCommand +++", null); }

		// intent will be null on restart!
		if (intent != null) {
			getSettingsFromIntent(intent);
			// createPlayer();
		}
		startPlayingStream();
		startQueueTimer();
		
		// create a pending intent to start the Listen activity from the notification
		Intent ovIntent = new Intent(this, mNotificationActivity);
		mNotificationPendingIntent = PendingIntent.getActivity(this, 0, ovIntent, Intent.FLAG_ACTIVITY_NEW_TASK);
		
		// create a notification and move service to foreground
		mRwNotification = new Notification(mNotificationIconId, "Roundware Service Started", System.currentTimeMillis());
		mRwNotification.flags = mRwNotification.flags | Notification.FLAG_FOREGROUND_SERVICE | Notification.FLAG_ONGOING_EVENT;
		setNotificationText("");
		
		startForeground(NOTIFICATION_ID, mRwNotification);
		
		return Service.START_STICKY;
	}
	
	
	public void startPlayingStream() {
		// TODO: make thread-safe
		if (!mStreamConnected) {
			createPlayer();
			new StartPlayingStreamTask().execute();
		}
	}
	
	
	private void getSettingsFromIntent(Intent intent) {
		if ((intent != null) && (intent.getExtras() != null)) {
			mUserId = intent.getExtras().getString(INTENT_EXTRA_USER_ID);

			// server url override (can be null)
			String serverUrlOverride = intent.getExtras().getString(INTENT_EXTRA_SERVER_URL_OVERRIDE);
			if ((serverUrlOverride != null) && (serverUrlOverride.length() > 0)) {
				mServerUrl = serverUrlOverride;
			}
			
			// notification icon and handling class
			mNotificationTitle = intent.getExtras().getString(INTENT_EXTRA_NOTIFICATION_TITLE);
			if (mNotificationTitle == null) {
				mNotificationTitle = "Roundware";
			}
			mNotificationDefaultText = intent.getExtras().getString(INTENT_EXTRA_NOTIFICATION_DEFAULT_TEXT);
			if (mNotificationDefaultText == null) {
				mNotificationDefaultText = "Return to app";
			}
			mNotificationIconId = intent.getExtras().getInt(INTENT_EXTRA_NOTIFICATION_ICON_ID, R.drawable.status_icon);
			String className = intent.getExtras().getString(INTENT_EXTRA_NOTIFICATION_ACTIVITY_CLASS_NAME);
			try {
				if (className != null) {
					mNotificationActivity = Class.forName(className);
				}
			} catch (Exception e) {
				RWHtmlLog.e("Unknown class specificied for handling notification: " + className);
				e.printStackTrace();
				mNotificationActivity = null;
			}
		}
	}
	
	
	@Override
	public void onDestroy() {
		if (D) { RWHtmlLog.i(TAG, "+++ onDestroy +++", null); }
		stopService();
		super.onDestroy();
	}
	
	
	public void stopService() {
		if (D) { RWHtmlLog.i(TAG, "Stopping", null); }
		RWLocationTracker.instance().stopLocationUpdates();
		stopQueueTimer();
		releasePlayer();
		stopSelf();
	}
	
	
	@Override
	public void update(Observable observable, Object data) {
		Location location = RWLocationTracker.instance().getLastLocation();
		if (location == null) {
			if (D) { RWHtmlLog.i(TAG, getString(R.string.roundware_no_location_info), null); }
		} else {
			double lat = location.getLatitude();
			double lon = location.getLongitude();
			if (D) { 
				RWHtmlLog.i(TAG, String.format(
						"session id '%s': New position info lat=%.6f lon=%.6f provider=%s accuracy=%.6fm", 
						mSessionId, lat, lon, location.getProvider(), location.getAccuracy()
						), null);
			}
			performMoveListener(true);
			broadcastLocationUpdate(lat, lon, location.getProvider(), location.getAccuracy());
		}
	}

	
	public void setNotificationText(String message) {
		if ((mRwNotification != null) && (mNotificationPendingIntent != null)) {
			NotificationManager nm = (NotificationManager)getSystemService(Context.NOTIFICATION_SERVICE);
			if (nm != null) {
				if (message != null) {
					boolean debugMsg = message.startsWith(".");
					String msg = debugMsg ? message.subSequence(1, message.length()).toString() : message;
					
					boolean defaultMsg = message.equalsIgnoreCase(mNotificationDefaultText);
					
					if ((!debugMsg) || (mShowDetailedMessages)) {
						mRwNotification.setLatestEventInfo(this, mNotificationTitle, msg, mNotificationPendingIntent);
						if (!defaultMsg) {
							mRwNotification.tickerText = msg;
						} else {
							mRwNotification.tickerText = "";
						}
					}
				}

				mRwNotification.when = System.currentTimeMillis();
				mRwNotification.number = RWActionQueue.instance().count();
				
				nm.notify(NOTIFICATION_ID, mRwNotification);
			}
		}
	}
	
	
	public RWActionFactory getActionFactory() {
		return mActionFactory;
	}
	
	
	public String getSessionId() {
		return mSessionId;
	}
	
	
	public String getUserId() {
		return mUserId;
	}
	
	
	public String getServerUrl() {
		return mServerUrl;
	}
	
	
	public String getStreamUrl() {
		return mStreamUrl;
	}
	
	
	public int getMaxAllowedRecordingTimeInSec() {
		String maxTime = getString(R.string.rw_spec_max_recording_time_in_sec);
		try {
			return Integer.valueOf(maxTime);
		} catch (Exception e) {
			RWHtmlLog.e("Error converting max recording time from string: '" + maxTime + "': " + e.getMessage());
			return 30;
		}
	}
	
	
	public boolean isLocationBasedQuestionsEnabled() {
		String val = getString(R.string.rw_spec_location_based_questions_yn);
		if ((val != null) && ("Y".equals(val.toUpperCase()))) {
			return true;
		} else {
			return false;
		}
	}


	/**
	 * Checks if the current session id indicates that the media player is
	 * playing the static soundtrack from the server. This stream is e.g.
	 * returned when the user starts the app outside the geographical range
	 * of the project.
	 * 
	 * @return true when the media player is playing the static soundtrack
	 */
	public boolean isPlayingStaticSoundtrack() {
		String val = getString(R.string.rw_spec_static_soundtrack_session_id);
		if ((val != null) && (mSessionId != null) && (mSessionId.equals(val))) {
			return true;
		} else {
			return false;
		}
	}
	
	
	public boolean isPlaying() {
		if (mPlayer == null) {
			return false;
		} else {
			return mPlayer.isPlaying() && (mVolumeLevel > 0);
		}
	}

	
	public boolean getShowDetailedMessages() {
		return mShowDetailedMessages;
	}
	
	
	public void setShowDetailedMessages(boolean state) {
		mShowDetailedMessages = state;
	}
	
	
	public void setMockLocation(String latitude, String longitude) {
		if (RWLocationTracker.instance().isUsingFixedLocation()) {
			RWLocationTracker.instance().releaseFixedLocation();
		}
		
		try {
			Double lat = Double.valueOf(latitude);
			Double lon = Double.valueOf(longitude);
			RWLocationTracker.instance().fixLocationAt(lat, lon);
		} catch (Exception e) {
			String msg = "Error setting mock location to lat=" + latitude + ", lon=" + longitude + " : " + e.getMessage();
			RWHtmlLog.w(TAG, msg, null);
		}
	}
	
	
	public boolean deleteQueue() {
		return RWActionQueue.instance().deleteQueue();
	}
	
	
	private void startQueueTimer() {
		if (mQueueTimer != null) {
			stopQueueTimer();
		}
		
		mQueueTimer = new Timer();
		TimerTask task = new TimerTask() {
			public void run() {
				queueCheck();
			}
		};
		mQueueTimer.scheduleAtFixedRate(task, 0, mQueueCheckIntervalMsec);
	}

	
	private void stopQueueTimer() {
		if (mQueueTimer != null) {
			if (D) { RWHtmlLog.i(TAG, "Stopping queue processing", null); }
			mQueueTimer.cancel();
			mQueueTimer.purge();
			mQueueTimer = null;
		}
	}
	
	
	public String performMoveListener(boolean now) {
		if (mSessionId != null) {
			return perform(mActionFactory.createMoveListenerAction(), now);
		}
		return null;
	}
	
	
	public String performHeartbeat(boolean now) {
		if (mSessionId != null) {
			return perform(mActionFactory.createHeartbeatAction(), now);
		}
		return null;
	}
	
	
	public String performServerNotification(int eventTypeResId, String optionalMessage, boolean now) {
		return perform(mActionFactory.createServerNotificationAction(eventTypeResId, optionalMessage), now);
	}
	
	
	public String performRetrieveNumberOfRecordings(RWList selections, boolean now) {
		return perform(mActionFactory.createNumberOfRecordingsAction(selections), now);
	}
	
	
	public String performRetrieveQuestions(boolean now) {
		return perform(mActionFactory.createWhatQuestionsAction(), now);
	}
	
	
	public String performRequestStream(RWList selections, boolean now) {
		return perform(mActionFactory.createRequestStreamAction(selections), now);
	}
	
	
	public String performModifyStream(RWList selections, boolean now) {
		return perform(mActionFactory.createModifyStreamAction(selections), now);
	}
	
	
	@Deprecated
	public RWAction createCommentAction(RWList selections, String filename) throws IOException {
		return mActionFactory.createCommentAction(selections, filename);
	}
	
	
	public RWAction createUploadRecordingAction(RWList selections, String filename) throws Exception {
		return mActionFactory.createUploadRecordingAction(selections, filename);
	}
	
	
	public String perform(RWAction action, boolean now) {
		if (now) {
			return perform(action);
		} else {
			RWActionQueue.instance().add(action.getData().getProperties());
			setNotificationText(null);
			return "";
		}
	}
	
	
	public String retrieveMessageFromServerResponse(RWProtocol.ServerMessageType messageType, String response) {
		return mProtocol.retrieveServerMessage(messageType, response);
	}

	
	public List<Map<String, String>> retrieveKvMapFromServerResponse(String response) {
		return mProtocol.simpleJsonParse(response);
	}
	
	
	private String perform(RWAction action) {
		try {
			// update last request time
			mLastRequestMillis = System.currentTimeMillis();
			
			try {
				setNotificationText(action.getCaption());
			} catch (Exception e) {
				RWHtmlLog.w(TAG, "Could not update notification text!", e);
			}
			
			String validationResult = action.validate();
			if (validationResult != null) {
				RWHtmlLog.e(TAG, "Invalid RWAction, will not be sent to server. Reason(s): " + validationResult, null);
				return null;
			}
			
			String result = action.perform();
			
			// when action is an upload a log event needs to be send now
			if (action.getFilename() != null) {
				performServerNotification(R.string.rw_event_type_stop_upload, "Y", true);
			}
			
			setNotificationText(mNotificationDefaultText);
			return broadcastServerMessages(result);
		} catch (Exception ex) {
			RWHtmlLog.e(TAG, "Error: " + ex.getMessage(), ex);
			
			// when action is an upload a log event needs to be send now
			if (action.getFilename() != null) {
				performServerNotification(R.string.rw_event_type_stop_upload, "Error: " + ex.getMessage(), true);
			}
			
			return null;
		}
	}

	
	private String broadcastServerMessages(String response) {
		String message;
		Intent intent = new Intent();

		// process not critical messages first
		
		message = retrieveMessageFromServerResponse(RWProtocol.ServerMessageType.USER, response);
		if (message != null) {
			intent.setAction(ACTION_MESSAGE);
			intent.putExtra(INTENT_EXTRA_SERVER_MESSAGE, message);
			if (D) { RWHtmlLog.i(TAG, "Going to send broadcast event, user message = " + message, null); }
			sendBroadcast(intent);
		}

		message = retrieveMessageFromServerResponse(RWProtocol.ServerMessageType.SHARING, response);
		if (message != null) {
			intent.setAction(ACTION_SHARING);
			intent.putExtra(INTENT_EXTRA_SERVER_MESSAGE, message);
			if (D) { RWHtmlLog.i(TAG, "Going to send broadcast event, sharing message = " + message, null); }
			sendBroadcast(intent);
		}
		
		// process critical messages that stop further handling of the response
		
		message = retrieveMessageFromServerResponse(RWProtocol.ServerMessageType.ERROR, response);
		if (message != null) {
			// see if there is additional traceback info
			String traceback = retrieveMessageFromServerResponse(RWProtocol.ServerMessageType.TRACEBACK, response);
			if (traceback != null) {
				message = message + "\n\nTraceback: " + traceback;
			}
			intent.setAction(ACTION_ERROR);
			intent.putExtra(INTENT_EXTRA_SERVER_MESSAGE, message);
			if (D) { RWHtmlLog.i(TAG, "Going to send broadcast event, error message = " + message, null); }
			sendBroadcast(intent);
			// return null to avoid further processing of server response
			return null;
		}
		
		return response;
	}
	
	
	public void broadcastStreamConnectedStatus(boolean connected) {
		if (D) { RWHtmlLog.i(TAG, "Going to send broadcast event, stream connected state = " + connected, null); }
		Intent intent = new Intent();
		intent.setAction(connected ? ACTION_STREAM_CONNECTED : ACTION_STREAM_DISCONNECTED);
		sendBroadcast(intent);
		this.mStreamConnected = connected;
	}
	
	
	private void broadcastLocationUpdate(double latitude, double longitude, String provider, float accuracy) {
		if (D) { RWHtmlLog.i(TAG, String.format(
				"Going to send broadcast event, location updated lat=%.6f lon=%.6f provider=%s accuracy=%.6fm", 
				latitude, longitude, provider, accuracy), null); }
		Intent intent = new Intent();
		intent.setAction(ACTION_LOCATION_UPDATED);
		intent.putExtra(INTENT_EXTRA_LOCATION_LAT, latitude);
		intent.putExtra(INTENT_EXTRA_LOCATION_LON, longitude);
		intent.putExtra(INTENT_EXTRA_LOCATION_PROVIDER, provider);
		intent.putExtra(INTENT_EXTRA_LOCATION_ACCURACY_M, accuracy);
		sendBroadcast(intent);
	}

	
	private void queueCheck() {
		int count = RWActionQueue.instance().count();
		if (count == 0) {
			// nothing to do, send ping if idle time threshold exceeded
			long currentMillis = System.currentTimeMillis();
			if ((currentMillis - mLastRequestMillis) > mPingThresholdMsec) {
				if (mStreamConnected) {
					performHeartbeat(true);
				}
			}
			
			setNotificationText(null);
			return;
		}
		
		RWAction action = RWActionQueue.instance().get();
		if (action != null) {
			if (perform(action) != null) {
				RWActionQueue.instance().delete(action);
				setNotificationText(null);
			} else {
				setNotificationText(getString(R.string.roundware_notification_request_failed));
				// remove failing action from queue, unless it is a file upload
				if (action.getFilename() == null) {
					RWActionQueue.instance().delete(action);
				}
			}
		}
	}
	

	/**
	 * Creates a media player for sound playback, with initial volume of 0.
	 */
	private void createPlayer() {
		if (mPlayer == null) {
			mPlayer = new MediaPlayer();
			mPlayer.setWakeMode(this, PowerManager.PARTIAL_WAKE_LOCK);
			
			float volume = (float) 0.0;
			mPlayer.setVolume(volume, volume);
			mVolumeLevel = 0;
			mPlayer.pause();

			mPlayer.setOnPreparedListener(new MediaPlayer.OnPreparedListener() {
				@Override
				public void onPrepared(MediaPlayer mp) {
					if (D) { RWHtmlLog.i(TAG, "MediaPlayer prepared event", null); }
					broadcastStreamConnectedStatus(true);
					if (mStartPlayingWhenReady) {
						fadeInPlayer(mVolumeLevel);
					}
				}
			});
			
			mPlayer.setOnInfoListener(new MediaPlayer.OnInfoListener() {
				@Override
				public boolean onInfo(MediaPlayer mp, int what, int extra) {
					RWHtmlLog.w(TAG, "MediaPlayer info event", null);
					return true;
				}
			});
			
			mPlayer.setOnErrorListener(new MediaPlayer.OnErrorListener() {
				@Override
				public boolean onError(MediaPlayer mp, int what, int extra) {
					RWHtmlLog.e(TAG, "MediaPlayer error event", null);
					broadcastStreamConnectedStatus(false);
					return true;
				}
			});
			
			mPlayer.setOnCompletionListener(new MediaPlayer.OnCompletionListener() {
				@Override
				public void onCompletion(MediaPlayer mp) {
					RWHtmlLog.w(TAG, "MediaPlayer completion event", null);
					broadcastStreamConnectedStatus(false);
					mp.stop();
				}
			});
		}
	}
	
	
	/**
	 * Releases the media player after fading out the sounds.
	 */
	private void releasePlayer() {
		if (mPlayer != null) {
			fadeOutPlayer();
			mPlayer.release();
			mPlayer = null;
		}
	}

	
	public void fadeOutPlayer() {
		// let server know user is no longer listening
		performServerNotification(R.string.rw_event_type_stop_listen, null, true);
		
		setVolumeLevel(0, true);
		mStartPlayingWhenReady = false;
//		if (mp != null) {
//			mp.pause();
//		}
		setNotificationText(".Audio muted");
	}
	
	
	public void fadeInPlayer(int endVolumeLevel) {
		mStartPlayingWhenReady = true;
		if (mPlayer != null) {
			try {
				mPlayer.start();
			} catch (Exception ex) {
				RWHtmlLog.w(TAG, "Fade in to volume level " + endVolumeLevel + " caused MediaPlayer exception, delaying!", ex);
				setVolumeLevel(endVolumeLevel, true);
			}
			
			// let server know user started listening
			performServerNotification(R.string.rw_event_type_start_listen, null, true);

			setVolumeLevel(endVolumeLevel, true);
			setNotificationText(".Audio unmuted");
		} else {
			RWHtmlLog.w(TAG, "Fade in to volume level " + endVolumeLevel + " ignored, MediaPlayer not initialized!", null);
			setVolumeLevel(endVolumeLevel, true);
		}
	}
	
	
	private float calcVolumeScalar(int volumeLevel) {
		float volume = 1.0f;
		if (volumeLevel < mMinVolumeLevel) {
			volume = 0.0f;
		} else {
			if (volumeLevel < mMaxVolumeLevel) {
				for (int i = mMaxVolumeLevel; i > volumeLevel; i--) {
					volume *= mVolumeStepMultiplier;
				}
			}
		}
		return volume;
	}
	
	
	public int getVolumeLevel() {
		return mVolumeLevel;
	}
	
	
	public void setVolumeLevel(int newVolumeLevel, boolean fade) {
		// TODO: Must this be done in a thread to have effect?
		int oldVolumeLevel = mVolumeLevel;
		mVolumeLevel = newVolumeLevel;
		if (mVolumeLevel < mMinVolumeLevel) {
			mVolumeLevel = mMinVolumeLevel;
		} else if (mVolumeLevel > mMaxVolumeLevel) {
			mVolumeLevel = mMaxVolumeLevel;
		}
		
		float oldVolume = calcVolumeScalar(oldVolumeLevel);
		float newVolume = calcVolumeScalar(mVolumeLevel);

		// fail-safe when volume should be totally muted
		if (mVolumeLevel == 0) {
			newVolume = 0.0f;
		}
		
		// gradually modify the volume when playing and set to fade
		if (mPlayer != null) {
			if (D) {
				String msg = String.format("Changing volume from level %d (%1.5f) to level %d (%1.5f)", oldVolumeLevel, oldVolume, mVolumeLevel, newVolume);
				RWHtmlLog.i(TAG, msg, null); 
			}
			if (fade) {
				if (oldVolume < newVolume) {
					for (float v = oldVolume; v < newVolume; v += 0.001f) {
						mPlayer.setVolume(v, v);
					}
				} else {
					for (float v = oldVolume; v > newVolume; v -= 0.001f) {
						mPlayer.setVolume(v, v);
					}
				}
				// make sure to reach the final new volume
				mPlayer.setVolume(newVolume, newVolume);
			} else {
				mPlayer.setVolume(newVolume, newVolume);
			}
		} else {
			if (D) {
				String msg = String.format("Volume set to level %d (%1.5f) but MediaPlayer not initialized!", mVolumeLevel, newVolume);
				RWHtmlLog.i(TAG, msg, null); 
			}
		}
	}
	
}
