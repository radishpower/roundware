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
package com.halseyburgund.roundware.util;

public class RWListItem {
	
	public enum Category { QUESTION, DEMOGRAPHIC, USERTYPE }
	
	private Category mCategory;
	private String mText;
	private boolean mOn;
	private String mId; // may not be used by the list

	
	public static RWListItem create(Category category, String id, String text, boolean on) {
		RWListItem result = new RWListItem(category, id, text);
		result.set(on);
		return result;
	}
	
	
	public static RWListItem create(RWListItem template) {
		RWListItem result = new RWListItem(template.getCategory(), template.getId(), template.getText());
		result.set(template.isOn());
		return result;
	}
	
	
	public static RWListItem create(Category category, String text) {
		return create(category, null, text, false);
	}
	

	public RWListItem(Category category, String id, String text) {
		mCategory = category;
		mId = id;
		mText = text;
		mOn = false;
	}

	
	public Category getCategory() {
		return mCategory;
	}

	
	public String getId() {
		return mId;
	}

	
	public String getText() {
		return mText;
	}

	
	public boolean isOn() {
		return mOn;
	}

	
	public void setOn() {
		mOn = true;
	}

	
	public void setOff() {
		mOn = false;
	}

	
	public void set(boolean val) {
		if (val)
			setOn();
		else
			setOff();
	}
}
