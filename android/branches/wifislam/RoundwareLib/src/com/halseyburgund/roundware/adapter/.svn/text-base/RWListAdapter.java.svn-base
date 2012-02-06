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
package com.halseyburgund.roundware.adapter;

import com.halseyburgund.roundware.util.RWList;
import com.halseyburgund.roundware.util.RWListItem;

import android.R;
import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.BaseAdapter;
import android.widget.ImageView;
import android.widget.TextView;

/**
 * Customized adapter for displaying items from a RWList, filtered by a
 * specified category (a property of the RWListItem).
 * 
 * @author Rob Knapen
 */
public class RWListAdapter extends BaseAdapter {
	
	private Context mContext;
	private RWList mAllItems;
	private RWListItem.Category mdisplayedCategory;
	private RWList mDisplayedItems;
	private int mListItemLayoutId;

	
	public RWListAdapter(Context context, RWList items, RWListItem.Category category, int listItemLayoutId) {
		super();
		mContext = context;
		mAllItems = items;
		mdisplayedCategory = category;
		mListItemLayoutId = listItemLayoutId;
		initDisplayedItems();
	}
	
	
	private void initDisplayedItems() {
		if (mDisplayedItems == null) {
			mDisplayedItems = new RWList();
		} else {
			mDisplayedItems.clear();
		}
		
		mDisplayedItems = mAllItems.filter(mdisplayedCategory);
	}
	
	
	@Override
	public View getView(int position, View convertView, ViewGroup parent) {
		View v = convertView;
		if (v == null) {
			LayoutInflater vi = (LayoutInflater) mContext.getSystemService(Context.LAYOUT_INFLATER_SERVICE);
			v = vi.inflate(mListItemLayoutId, null);
		}

		ImageView image = (ImageView) v.findViewById(R.id.icon);
		TextView text = (TextView) v.findViewById(R.id.text1);

		RWListItem q = getItem(position);
		if (q != null) {
			if (text != null) {
				text.setText(q.getText());
			}
		}

		if (q.isOn()) {
			image.setSelected(true);
			text.setSelected(true);
		} else {
			image.setSelected(false);
			text.setSelected(false);
		}

		return v;
	}


	@Override
	public int getCount() {
		if (mDisplayedItems != null) {
			return mDisplayedItems.size();
		} else {
			return 0;
		}
	}


	@Override
	public RWListItem getItem(int index) {
		return mDisplayedItems.get(index);
	}


	@Override
	public long getItemId(int index) {
		// TODO: using the order in the sublist as id (for now)
		return index;
	}
	
	
	public void clearSelection() {
		if (mDisplayedItems != null) {
			mDisplayedItems.clearSelection();
		}
	}
	
	
	public void selectAll() {
		if (mDisplayedItems != null) {
			mDisplayedItems.selectAll();
		}
	}
}
