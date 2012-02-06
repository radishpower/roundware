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

import java.util.ArrayList;
import java.util.Iterator;


public class RWList extends ArrayList<RWListItem> {

	private static final long serialVersionUID = 1L;

	
	public RWList filter(RWListItem.Category category) {
		RWList result = new RWList();
		if (category != null) {
			for (RWListItem item : this) {
				if (category.equals(item.getCategory())) {
					result.add(item);
				}
			}
		}
		return result;
	}


	public RWList createSublist(RWListItem.Category category) {
		RWList result = new RWList();
		if (category != null) {
			for (RWListItem item : this) {
				if (category.equals(item.getCategory())) {
					result.add(RWListItem.create(item));
				}
			}
		}
		return result;
	}
	
	
	public void removeAll(RWListItem.Category category) {
		if (category == null) {
			this.clear();
		} else {
			Iterator<RWListItem> iterator = this.iterator();
			while (iterator.hasNext()) {
				RWListItem item = iterator.next();
				if (category.equals(item.getCategory())) {
					iterator.remove();
				}
			}
		}
	}
	
	
    public RWList clearSelection() {
    	for (RWListItem item : this) {
    		item.setOff();
    	}
    	return this;
    }

    
    public RWList clearSelection(RWListItem.Category category) {
    	if (category == null) {
    		clearSelection();
    	} else {
	    	for (RWListItem item : this) {
	    		if (category.equals(item.getCategory())) {
	    			item.setOff();
	    		}
	    	}
    	}
    	return this;
    }
    
    
    public RWList selectAll() {
    	for (RWListItem item : this) {
    		item.setOn();
    	}
    	return this;
    }

    
    public RWList selectAll(RWListItem.Category category) {
    	if (category == null) {
    		selectAll();
    	} else {
	    	for (RWListItem item : this) {
	    		if (category.equals(item.getCategory())) {
	    			item.setOn();
	    		}
	    	}
    	}
    	return this;
    }
    
    
    public RWList autoSelectSingleItemInCategories() {
    	for (RWListItem.Category category : RWListItem.Category.values()) {
    		autoSelectSingleItemInCategory(category);
    	}
    	return this;
    }
    
    
    public RWList autoSelectSingleItemInCategory(RWListItem.Category category) {
		RWList catItems = new RWList();
		if (category != null) {
			for (RWListItem item : this) {
				if (category.equals(item.getCategory())) {
					catItems.add(item);
				}
			}
			if (catItems.size() == 1) {
				catItems.get(0).setOn();
			}
		}
		return this;
    }
}
