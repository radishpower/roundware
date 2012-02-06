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

import android.content.Context;
import android.graphics.drawable.Drawable;

import com.google.android.maps.GeoPoint;
import com.google.android.maps.OverlayItem;
import com.halseyburgund.mountainghosts.R;

public class RecordingOverlayItem extends OverlayItem {

	// debugging
	//private static final String TAG = "RecordingOverlayItem";
	//private static final boolean D = false;
	
	private RecordingOverlayData data;
	private Drawable drawable;
	private Drawable focussedDrawable;
	
	public RecordingOverlayItem(Context context, RecordingOverlayData data) {
		super(new GeoPoint((int)(data.getLat()*1e6), (int)(data.getLon()*1e6)),
			data.getAuthor(),
			data.getTopic()
		);
		
		this.data = data;
		
		focussedDrawable = context.getResources().getDrawable(R.drawable.map_pin_selected);
		
		switch(data.getMarker()) {
		case 0: drawable = context.getResources().getDrawable(R.drawable.map_pin_speak);
			break;
		case 1: drawable = context.getResources().getDrawable(R.drawable.map_pin_listen);
			break;
		}
		
		if (drawable != null) {
			int w = drawable.getIntrinsicWidth();
			int h = drawable.getIntrinsicHeight();
			drawable.setBounds(0, 0, w, h);
			focussedDrawable.setBounds(drawable.getBounds());
		}
	}

	
	@Override
	public Drawable getMarker(int stateBitset) {
		if ((stateBitset & OverlayItem.ITEM_STATE_FOCUSED_MASK) > 0) {
			return focussedDrawable;
		} else {
			return drawable;
		}
	}
	

	@Override
	public void setMarker(Drawable marker) {
		super.setMarker(marker);
		focussedDrawable.setBounds(marker.getBounds());
	}


	public RecordingOverlayData getData() {
		return data;
	}

	
	public void setData(RecordingOverlayData data) {
		this.data = data;
	}

}
