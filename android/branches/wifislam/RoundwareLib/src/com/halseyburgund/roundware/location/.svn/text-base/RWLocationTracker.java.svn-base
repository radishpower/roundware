/*
 	This file is part of RoundwareLib. Originally developed for the
 	Android OS by Rob Knapen, based on earlier work by Dan Latham.
 	
    RoundwareLibe is free software: you can redistribute it and/or modify
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
package com.halseyburgund.roundware.location;

import java.util.List;
import java.util.Locale;
import java.util.Observable;

import com.halseyburgund.roundware.R;
import com.halseyburgund.roundware.util.RWHtmlLog;

import android.content.Context;
import android.location.Address;
import android.location.Criteria;
import android.location.Geocoder;
import android.location.GpsStatus;
import android.location.Location;
import android.location.LocationListener;
import android.location.LocationManager;
import android.location.LocationProvider;
import android.os.Bundle;
import android.util.Log;
import android.widget.Toast;


/**
 * Singleton class providing GPS/Location functionality. It extends Observable
 * so it can be observed to get updates on location changes. For testing
 * purposes, amongst others, it can be fixed at a specific location.
 * 
 * For this singleton class you need to call the init method first, and then
 * can call the startLocationUpdates method to active the updates. Use the
 * stopLocationUpdates to cancel the updates (and save the battery).
 * 
 * @author Rob Knapen
 */
public class RWLocationTracker extends Observable {

	// debugging
	private final static String TAG = "RWLocationTracker";
	private final static boolean D = false;
	
	private static RWLocationTracker mSingleton;
	
	private Context mContext;
	private Geocoder mGeocoder;
	private LocationManager mLocationManager;
	private String mCoarseLocationProvider;
	private String mGpsLocationProvider;
	private boolean mGpsLocationAvailable;
	private long mMinUpdateTime;
	private float mMinUpdateDistance;
	private Location mLastLocation;
	private boolean mFixedLocation;
	private boolean mUsingGpsLocation;
	private boolean mUsingCoarseLocation;

	
    private final LocationListener mCoarseLocationProviderListener = new LocationListener() {
    	
		public void onStatusChanged(String provider, int status, Bundle extras) {
			if (D) { Log.d(TAG, "Coarse location provider status changed"); }
		}
		
		public void onProviderEnabled(String provider) {
			if (D) { Log.d(TAG, "Coarse location provider enabled - finding last know location"); }
			gotoLastKnownLocation();
		}
		
		public void onProviderDisabled(String provider) {
			if (D) { Log.d(TAG, "Coarse location provider disabled"); }
			updateWithNewLocation(null);
		}
		
		public void onLocationChanged(Location location) {
			if (D) { Log.d(TAG, "Coarse location provider location changed"); }
			if (mUsingCoarseLocation) {
				gotoLastKnownLocation();
			}
		}
	};

	
    private final LocationListener mGpsLocationProviderListener = new LocationListener() {
    	
		public void onStatusChanged(String provider, int status, Bundle extras) {
			if (D) { Log.d(TAG, "GPS location provider status changed"); }
		}
		
		public void onProviderEnabled(String provider) {
			if (D) { Log.d(TAG, "GPS location provider enabled"); }
			// not switching yet, waiting for first fix
		}
		
		public void onProviderDisabled(String provider) {
			if (D) { Log.d(TAG, "GPS location provider disabled"); }
		}
		
		public void onLocationChanged(Location location) {
			if (D) { Log.d(TAG, "GPS location provider location update"); }
			if (mUsingGpsLocation) {
				gotoLastKnownLocation();
			}
		}
	};
	
	
	private final GpsStatus.Listener mGpsStatusListener = new GpsStatus.Listener() {
		@Override
		public void onGpsStatusChanged(int event) {
			if (D) { 
				switch (event) {
				case GpsStatus.GPS_EVENT_FIRST_FIX:
					Log.d(TAG, "GPS first fix");
					mGpsLocationAvailable = true;
					swithToGpsLocationUpdates();
					break;
				case GpsStatus.GPS_EVENT_STARTED:
					Log.d(TAG, "GPS started");
					mGpsLocationAvailable = false;
					break;
				case GpsStatus.GPS_EVENT_STOPPED:
					Log.d(TAG, "GPS stopped");
					mGpsLocationAvailable = false;
					switchToCoarseLocationUpdates();
					break;
				}
			}
		}
	};
	
	
	public static RWLocationTracker instance() {
		if (mSingleton == null) {
			mSingleton = new RWLocationTracker();
		}
		return mSingleton;
	}

	
	private RWLocationTracker() {
		mFixedLocation = false;
		mMinUpdateTime = -1;
		mMinUpdateDistance = -1;
		mUsingGpsLocation = false;
		mUsingCoarseLocation = false;
	}
	
	
	public boolean isUsingFixedLocation() {
		return mFixedLocation;
	}

	
	public void fixLocationAt(Double latitude, Double longitude) {
		Location l = new Location(mCoarseLocationProvider);
		l.setLatitude(latitude);
		l.setLongitude(longitude);
		fixLocationAt(l);
	}

	
	public void fixLocationAt(Location location) {
		updateWithNewLocation(location);
		mFixedLocation = true;
	}
	
	
	public void releaseFixedLocation() {
		mFixedLocation = false;
		gotoLastKnownLocation();
	}
	
	
	public boolean isGpsEnabled() {
        LocationManager lm = (LocationManager) mContext.getSystemService(Context.LOCATION_SERVICE);
		if (lm != null) {
			return lm.isProviderEnabled(LocationManager.GPS_PROVIDER);
		}
		return false;
	}
	
	
	public boolean isNetworkLocationEnabled() {
        LocationManager lm = (LocationManager) mContext.getSystemService(Context.LOCATION_SERVICE);
		if (lm != null) {
			return lm.isProviderEnabled(LocationManager.NETWORK_PROVIDER);
		}
		return false;
	}


	public boolean init(Context c) {
		if (mLocationManager != null) {
			stopLocationUpdates();
			mLocationManager = null;
			mCoarseLocationProvider = null;
			mGpsLocationProvider = null;
		}

		mContext = c;
		mGeocoder = new Geocoder(mContext, Locale.getDefault());
		
        mLocationManager = (LocationManager) mContext.getSystemService(Context.LOCATION_SERVICE);
        if (mLocationManager == null) {
    		Toast.makeText(c, R.string.roundware_no_location_service, Toast.LENGTH_SHORT).show();
    		return false;
        }
        
        return getLocationProviders();
	}
	
	
	public boolean getLocationProviders() {
		// get the GPS location provider info
        LocationProvider provider = mLocationManager.getProvider(LocationManager.GPS_PROVIDER);
        if (provider != null) {
            if (D) { Log.d(TAG, "GPS location provider name : " + mGpsLocationProvider); }
        	mGpsLocationProvider = provider.getName();
        } else {
            if (D) { Log.d(TAG, "GPS location provider not found on this device"); }
        	mGpsLocationProvider = null;
        }
        mGpsLocationAvailable = false;
        
        // get a coarse (usually the network) location provider as backup
        Criteria coarseCriteria = new Criteria();
        coarseCriteria.setAccuracy(Criteria.ACCURACY_COARSE);
        coarseCriteria.setAltitudeRequired(false);
        coarseCriteria.setBearingRequired(false);
        coarseCriteria.setCostAllowed(false);
        coarseCriteria.setPowerRequirement(Criteria.NO_REQUIREMENT);
        
        mCoarseLocationProvider = mLocationManager.getBestProvider(coarseCriteria, true);
        if (D) { Log.d(TAG, "Coarse location provider name : " + mCoarseLocationProvider); }
    	
        // need to have at least one
    	if ((mGpsLocationProvider == null) && (mCoarseLocationProvider == null)) {
    		Toast.makeText(mContext, R.string.roundware_no_location_signal, Toast.LENGTH_SHORT).show();
            return false;
    	}
    	
    	return true;
	}
	
	
	public Location getLastLocation() {
		return mLastLocation;
	}
	
	
	private void updateWithNewLocation(Location location) {
		if (mFixedLocation)
			return;

		mLastLocation = location;

        if (D) {
        	if (location != null) {
	        	String msg = String.format(
	        			"%s: (%.6f, %.6f) %.1fm", 
	        			location.getProvider(), 
	        			location.getLatitude(), location.getLongitude(), 
	        			location.getAccuracy());
	        	
	        	Toast.makeText(mContext, msg, Toast.LENGTH_SHORT).show();
        	} else {
	        	Toast.makeText(mContext, "No location info", Toast.LENGTH_SHORT).show();
        	}
        }
		
		setChanged();
		notifyObservers();
		
	}
	
	
	public void gotoLastKnownLocation() {
		if (mLocationManager != null) {
			Location l;
			// check most accurate first
			if (mUsingGpsLocation && mGpsLocationAvailable && (mGpsLocationProvider != null)) {
				l = mLocationManager.getLastKnownLocation(mGpsLocationProvider);
				updateWithNewLocation(l);
				return;
			}
			
			// use less accurate network location
			if (mCoarseLocationProvider != null) {
				l = mLocationManager.getLastKnownLocation(mCoarseLocationProvider);
				updateWithNewLocation(l);
				return;
			}
		}
		
		if (mContext != null) {
			Toast.makeText(mContext, R.string.roundware_lost_location_signal, Toast.LENGTH_SHORT).show();
		}
	}
	
	
	public void startLocationUpdates(long minTime, float minDistance) {
		mMinUpdateTime = minTime;
		mMinUpdateDistance = minDistance;
		mUsingGpsLocation = false;
		mUsingCoarseLocation = false;
		switchToCoarseLocationUpdates();
		if (mLocationManager != null) {
	        mLocationManager.addGpsStatusListener(mGpsStatusListener);
		}
	}
	
	
	public void swithToGpsLocationUpdates() {
		if (mUsingGpsLocation) {
			return;
		}
		if (mLocationManager != null) {
			if (D) { Log.d(TAG, "Using GPS location updates. minTime=" + mMinUpdateTime + ", minDistance=" + mMinUpdateDistance); }
			// clean up first
			mLocationManager.removeUpdates(mCoarseLocationProviderListener);
			mLocationManager.removeUpdates(mGpsLocationProviderListener);
			mUsingGpsLocation = false;
	        mUsingCoarseLocation = false;
			
			// set new listeners
			if (mGpsLocationProvider != null) {
				mLocationManager.requestLocationUpdates(mGpsLocationProvider, mMinUpdateTime, mMinUpdateDistance, mGpsLocationProviderListener);
		        mUsingGpsLocation = true;
			}
			
	        // update location info
	        gotoLastKnownLocation();
		}
	}
	
	
	public void switchToCoarseLocationUpdates() {
		if (mUsingCoarseLocation) {
			return;
		}
		if (mLocationManager != null) {
			if (D) { Log.d(TAG, "Using coarse location updates and monitoring GPS status. minTime=" + mMinUpdateTime + ", minDistance=" + mMinUpdateDistance); }
			// clean up first
			mLocationManager.removeUpdates(mCoarseLocationProviderListener);
			mLocationManager.removeUpdates(mGpsLocationProviderListener);
	        mUsingCoarseLocation = false;
	        mUsingGpsLocation = false;

	        // set new listeners
			if (mCoarseLocationProvider != null) {
				mLocationManager.requestLocationUpdates(mCoarseLocationProvider, mMinUpdateTime, mMinUpdateDistance, mCoarseLocationProviderListener);
		        mUsingCoarseLocation = true;
			}
			
			if (mGpsLocationProvider != null) {
				mLocationManager.requestLocationUpdates(mGpsLocationProvider, mMinUpdateTime, mMinUpdateDistance, mGpsLocationProviderListener);
			}
			
	        // update location info
	        gotoLastKnownLocation();
		}
	}
	
	
	public void stopLocationUpdates() {
		mUsingGpsLocation = false;
		mUsingCoarseLocation = false;
		if (mLocationManager != null) {
			if (D) { Log.d(TAG, "Stopping coarse and GPS location updates"); }
			mLocationManager.removeUpdates(mCoarseLocationProviderListener);
			mLocationManager.removeUpdates(mGpsLocationProviderListener);
			mLocationManager.removeGpsStatusListener(mGpsStatusListener);
		}
	}
	
	
    public String[] geocodeToAddress(double lat, double lon) {
    	String[] result = new String[2];
		try {
    		List<Address> addresses = mGeocoder.getFromLocation(lat, lon, 1);
    		if ((addresses != null) && (addresses.size() > 0)) {
    			Address address = addresses.get(0);
    			result[0] = address.getFeatureName();
    			if (result[0] == null) {
	    			int max = address.getMaxAddressLineIndex();
	    			if (max >= 1) {
	    				result[0] = address.getAddressLine(0);
	    			}
    			}
    			result[1] = address.getCountryName();
    			return result;
    		}
    		return null;
		} catch (Exception e) {
			RWHtmlLog.e(TAG, "Could not get address from lat,lon coordinates", e);
			return null;
		}
    }
	
	
    
    public Location lookupLocationName(String locationName) {
    	try {
    		List<Address> addresses = mGeocoder.getFromLocationName(locationName, 1);
    		if ((addresses != null) && (addresses.size() > 0)) {
    			Address address = addresses.get(0);
				if ((!address.hasLatitude()) || (!address.hasLongitude())) {
    				RWHtmlLog.e(TAG, "Address found, but missing longitude or latitude coordinate(s).", null);
    				return null;
				} else {
    				Location l = new Location(mCoarseLocationProvider);
    				l.setLatitude(address.getLatitude());
    				l.setLongitude(address.getLongitude());
    				mFixedLocation = false;
    				updateWithNewLocation(l);
    				mFixedLocation = true;
    				return l;
				}
    		}
    		return null;
    	} catch (Exception e) {
    		RWHtmlLog.e(TAG, "Could not get valid location from specified search input", e);
    		return null;
    	}
    }
	
}
