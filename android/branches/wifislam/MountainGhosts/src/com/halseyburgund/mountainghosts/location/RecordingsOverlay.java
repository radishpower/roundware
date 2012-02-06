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
package com.halseyburgund.mountainghosts.location;

import java.util.ArrayList;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.drawable.Drawable;
import android.view.MotionEvent;

import com.google.android.maps.ItemizedOverlay;
import com.google.android.maps.MapView;

public class RecordingsOverlay extends ItemizedOverlay<RecordingOverlayItem> {

	// debugging
	// private static final String TAG = "DivesOverlay";
	// private static final boolean D = false;
	
	private ArrayList<RecordingOverlayItem> items = new ArrayList<RecordingOverlayItem>();
	// private Context context;

	
	public RecordingsOverlay(Context context, Drawable defaultMarker) {
		super(boundCenterBottom(defaultMarker));
		// this.context = context;
	}

	
	public void addOverlay(RecordingOverlayItem item) {
		item.setMarker(boundCenterBottom(item.getMarker(0)));
		items.add(item);
		populate();
	}
	
	
	@Override
	protected RecordingOverlayItem createItem(int index) {
		return items.get(index);
	}

	
	@Override
	public int size() {
		return items.size();
	}

	
	@Override
	public void draw(Canvas canvas, MapView mapView, boolean shadow) {
		// add to remove the shadow
		//		if (shadow) {
		//			return;
		//		}
		super.draw(canvas, mapView, shadow);
	}


	@Override
	protected boolean onTap(int index) {
		if ((index >= 0) && (index < size())) {
			RecordingOverlayItem item = items.get(index);
			if (item != null) {
				setFocus(item);
				return true;
			}
		}
		return false;
	}
	
	
	@Override
	public boolean onTouchEvent(MotionEvent event, MapView view) {
		return super.onTouchEvent(event, view);
	}

}
