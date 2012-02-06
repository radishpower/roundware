/*
 * Copyright (C) 2011 WiFiSLAM, Inc.
 * All rights reserved.
 *
 * http://wifislam.com
 *
 * NOTICE:  All information contained herein is, and remains
 * the property of WiFiSLAM, Inc. and its suppliers,
 * if any.  The intellectual and technical concepts contained
 * herein are proprietary to WiFiSLAM, Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents,
 * patents in process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material
 * is strictly forbidden unless prior written permission is obtained
 * from WiFiSLAM, Inc.
 */
package com.wifislam.example;

import android.app.Activity;
import android.content.ComponentName;
import android.content.ServiceConnection;
import android.os.Bundle;
import android.os.IBinder;
import android.util.Log;
import android.widget.TextView;
import com.wifislam.indoorlocation.IndoorLocation;
import com.wifislam.indoorlocation.IndoorLocationListener;
import com.wifislam.indoorlocation.IndoorLocationManager;
import com.wifislam.indoorlocation.IndoorLocationManager.IndoorLocationStatus;


/**
 * A sample application that binds to WiFiSLAM's Indoor Location Service, and in displays the real-time location (and some other properties) as text.
 *
 */
public class ExampleLoginActivity extends Activity {

    private static final String TAG = ExampleLoginActivity.class.getSimpleName();

    /**
     * An instance of the IndoorLocationManager.  This handles all of the service management and callbacks.
     */
    private IndoorLocationManager indoorLocationManager;

    /**
     * The location that we will select for indoor positioning.
     *
     * Note: To find your location ID, log into your web portal at demo.wifislam.com, switch to "Location Editor" mode, and read the field labeled "ID".
     * It should be a string containing a single number.
     */
    private static final String LOCATION_ID = "11";
    
    /**
     * Login with this username/password combination. 
     */
    private static final String USERNAME = "roundware";
    private static final String PASSWORD = "exploratorium2012";


    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        this.setContentView(R.layout.main);

        // set up the location manager service
        indoorLocationManager = new IndoorLocationManager(this, new ServiceConnection() {
            public void onServiceConnected(ComponentName name, IBinder service) {
                // once we're connected to the indoor location service, login
                indoorLocationManager.login(USERNAME, PASSWORD, onLoggedIn);
            }

            public void onServiceDisconnected(ComponentName name) {
                Log.e(TAG, "service disconnected");
            }
        });

        /**
         * Attach to the indoor location service.  This creates the service if it doesn't already exist.
         */
        indoorLocationManager.bind();
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();

        indoorLocationManager.removeUpdates(indoorLocationListener);
        indoorLocationManager.unbind();
    }

    private final IndoorLocationManager.LoginListener onLoggedIn = new IndoorLocationManager.LoginListener() {
        public void onComplete() {
            // once we're logged in, set the location we're using and start receiving location updates
            indoorLocationManager.setLocation(LOCATION_ID);
            indoorLocationManager.requestLocationUpdates(indoorLocationListener);
        }

        public void onError(String error) {
            Log.e(TAG, "error logging in: "+error);
        }
    };

    private final IndoorLocationListener indoorLocationListener = new IndoorLocationListener() {
        /**
         * Callback that is triggered whenever WiFiSLAM has an update for your location.
         */
        public void onIndoorLocationChanged(IndoorLocation indoorLocation) {
            final IndoorLocation i = indoorLocation;

            // This callback is called from a different thread, but we want to we want to make sure that the UI is only modified from the UI thread.
            ExampleLoginActivity.this.runOnUiThread(new Runnable(){
                public void run() {
                    updateDisplay(i);
                }
            });
        }


        /**
         * Callback that is triggered whenever the WiFiSLAM Indoor Location Service status changes.
         * For example, status changes when loading a location from disk or downloading updates from the web.
         */
        public void onStatusChanged(IndoorLocationStatus status) {
            switch(status) {
            case LOADING:
                Log.i(TAG, "Status changed to 'Loading'");
                break;
            case STARTED:
                Log.i(TAG, "Status changed to 'Started'");
                break;
            case STOPPED:
                Log.i(TAG, "Status changed to 'Stopped'");
                break;

            }
        }
    };

    /**
     * Do something when your localizer has produced a new "pose" (e.g. your location, and any other configuration space information that it has inferred)
     *
     * In this example, we update some text fields.
     */
    private void updateDisplay(IndoorLocation indoorLocation) {
        final TextView displayAccuracy = (TextView)findViewById(R.id.pose_accuracy);
        final TextView displayLocation = (TextView)findViewById(R.id.pose_location);
        final TextView displayPosition = (TextView)findViewById(R.id.pose_position);
        final TextView displayTimestamp = (TextView)findViewById(R.id.pose_timestamp);

        displayLocation.setText(indoorLocation.getLocationId());
        String x = String.format("%.2f", indoorLocation.getRelativeX());
        String y = String.format("%.2f", indoorLocation.getRelativeY());
        displayPosition.setText("("+x+", "+y+")");

        double seconds = System.nanoTime() / 1.0e9;
        displayTimestamp.setText(String.format("%.2f", seconds));

        displayAccuracy.setText(String.format("%.2f", indoorLocation.getAccuracy()));
    }

}
