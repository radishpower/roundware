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
package com.halseyburgund.roundware.server;

import java.io.File;
import java.io.IOException;
import java.util.List;
import java.util.Map;

import android.location.Location;

import com.halseyburgund.roundware.R;
import com.halseyburgund.roundware.services.RWService;
import com.halseyburgund.roundware.util.RWHtmlLog;
import com.halseyburgund.roundware.util.RWList;
import com.halseyburgund.roundware.util.RWListItem;

public class RWActionFactory {

	// debugging
	private final static String TAG = "RWActionFactory";
	private static boolean ENABLE_RECORDING_SUBMIT = true;

	// fields
	private RWService mService;
	
	
	public RWActionFactory(RWService service) {
		mService = service;
	}

	
	private RWAction create(RWActionData data) {
		return new RWAction(null, data);
	}

	
	private RWActionData createDefaultActionData(boolean addSessionId) {
		RWActionData data = new RWActionData(mService);
		data.add(R.string.rw_key_label, R.string.roundware_notification_default_text)
			.add(R.string.rw_key_server_url, mService.getServerUrl())
			.add(R.string.rw_key_config, R.string.rw_spec_config)
			.add(R.string.rw_key_category_id, R.string.rw_spec_category_id)
			.add(R.string.rw_key_sub_category_id, R.string.rw_spec_sub_category_id);
		
		if (addSessionId) {
			String sessionId = mService.getSessionId();
			if ((sessionId != null) && (sessionId.length() > 0)) {
				data.add(R.string.rw_key_session_id, sessionId);
			}
		}
		
		return data;
	}

	
	public RWAction createMoveListenerAction() {
		RWActionData data = createDefaultActionData(true);
		data.add(R.string.rw_key_label, R.string.roundware_notification_updating_location)
			.add(R.string.rw_key_operation, R.string.rw_op_move_listener);
		addCoordinates(data);
		return create(data);
	}
	
	
	public RWAction createHeartbeatAction() {
		RWActionData data = createDefaultActionData(true);
		data.add(R.string.rw_key_label, R.string.roundware_notification_heartbeat)
			.add(R.string.rw_key_operation, R.string.rw_op_heartbeat);
		addCoordinates(data);
		return create(data);
	}
	
	
	public RWAction createServerNotificationAction(int eventTypeResId, String message) {
		RWActionData data = createDefaultActionData(true);
		data.add(R.string.rw_key_label, R.string.roundware_notification_event)
			.add(R.string.rw_key_operation, R.string.rw_op_log_event)
			.add(R.string.rw_key_event_type, eventTypeResId)
			.add(R.string.rw_key_message, message);
		addCoordinates(data);
		return create(data);
	}
	
	
	public RWAction createNumberOfRecordingsAction() {
		RWActionData data = createDefaultActionData(true);
		data.add(R.string.rw_key_label, R.string.roundware_notification_number_of_recordings)
			.add(R.string.rw_key_operation, R.string.rw_op_number_of_recordings);
		addCoordinates(data);
		return create(data);
	}


	
	public RWAction createNumberOfRecordingsAction(RWList selections) {
		RWActionData data = createDefaultActionData(true);
		data.add(R.string.rw_key_label, R.string.roundware_notification_number_of_recordings)
			.add(R.string.rw_key_operation, R.string.rw_op_number_of_recordings);
		addSelections(data, selections);
		addCoordinates(data);
		return create(data);
	}
	

	public RWAction createWhatQuestionsAction() {
		RWActionData data = createDefaultActionData(true);
		data.add(R.string.rw_key_label, R.string.roundware_notification_retrieving_questions)
			.add(R.string.rw_key_operation, R.string.rw_op_get_questions);
		addCoordinates(data);
		return create(data);
	}
	

	public RWAction createRequestStreamAction(RWList selections) {
		RWActionData data = createDefaultActionData(false);
		data.add(R.string.rw_key_label, R.string.roundware_notification_requesting_stream)
			.add(R.string.rw_key_operation, R.string.rw_op_get_stream);
		addSelections(data, selections);

		// can skip adding coordinates for debugging purposes
		String str = mService.getString(R.string.rw_debug_open_audio_stream_without_location_yn);
		if ((str != null) && ("N".equals(str.toUpperCase()))) {
			addCoordinates(data);
		}
		
		return create(data);
	}


	public RWAction createModifyStreamAction(RWList selections) {
		RWActionData data = createDefaultActionData(true);
		data.add(R.string.rw_key_label, R.string.roundware_notification_modifying_stream)
			.add(R.string.rw_key_operation, R.string.rw_op_modify_stream);
		addSelections(data, selections);
		addCoordinates(data);
		return create(data);
	}
	
	
	@Deprecated
	public RWAction createCommentAction(RWList selections, String filename) throws IOException {
		// create a temporary copy of the recording file
		File queueFile = createTemporaryQueueFile(filename);

		// create the action for uploading and processing of the file
		RWActionData data = createDefaultActionData(true);
		data.add(R.string.rw_key_label, R.string.roundware_notification_uploading)
			.add(R.string.rw_key_operation, R.string.rw_op_upload_and_process)
			.add(R.string.rw_key_filename, queueFile.getPath())
			.add(R.string.rw_key_submitted, ENABLE_RECORDING_SUBMIT ? "Y" : "N");

		addSelections(data, selections);
		addCoordinates(data);

		return create(data);
	}

	
	public RWAction createUploadRecordingAction(RWList selections, String filename) throws Exception {
		
		// TODO: better to move the processing part to the RWService
		
		// create a temporary copy of the recording file
		File queueFile = createTemporaryQueueFile(filename);
		
		// create an enter_recording action and perform it directly
		RWActionData data = createDefaultActionData(true);
		data.add(R.string.rw_key_label, R.string.roundware_notification_announcing_recording)
			.add(R.string.rw_key_operation, R.string.rw_op_enter_recording)
			.add(R.string.rw_key_submitted, "N");
		addSelections(data, selections);
		addCoordinates(data);

		String response = mService.perform(create(data), true);
		String resultKey = mService.getString(R.string.rw_key_server_result);
		String recordingId = null;
		List<Map<String, String>> kvMap = mService.retrieveKvMapFromServerResponse(response);
		if (kvMap.size() > 0) {
			if (kvMap.get(0).containsKey(resultKey)) {
				recordingId = kvMap.get(0).get(resultKey);
			}
		}

		if (recordingId == null) {
			String msg = mService.getString(R.string.roundware_error_announcing_recording);
			RWHtmlLog.e(TAG, msg, null);
			RWHtmlLog.e(TAG, "Server response: " + response, null);
			throw new Exception(msg);
		}
		
		// create an upload_recording action to be put into the queue for later processing
		data = createDefaultActionData(true);
		data.add(R.string.rw_key_label, R.string.roundware_notification_uploading_recording)
			.add(R.string.rw_key_operation, R.string.rw_op_upload_recording)
			.add(R.string.rw_key_recording_id, recordingId)
			.add(R.string.rw_key_filename, queueFile.getPath());
		return create(data);
	}

	
	private File createTemporaryQueueFile(String filename) throws IOException {
		// move the recorded comment to the queued folder. It might not actually be queued
		// but it needs to be moved to prevent possibly being overwritten by a new recording
		// and the queued folder is a good interim location.
		File scratchFile = new File(filename);
		
		int numQueued;
		String queueFilename;
		File dir = new File(RWActionQueue.NOTE_QUEUE_PATH);
		if (!dir.exists()) {
			numQueued = 0;
			dir.mkdirs();
		} else {
			numQueued = dir.listFiles().length;
		}

		// Move scratch file to new directory with a unique name
		String queuedFileBaseName = mService.getString(R.string.rw_spec_queued_file_basename);
		String queuedFileExtension = mService.getString(R.string.rw_spec_queued_file_extension);
		queueFilename = queuedFileBaseName + String.valueOf(numQueued) + queuedFileExtension;
		
		File queueFile = new File(dir, queueFilename);
		boolean success = scratchFile.renameTo(queueFile);

		if (!success) {
			String msg = mService.getString(R.string.roundware_error_could_not_create_temp_queue_file);
			RWHtmlLog.e(TAG, msg, null);
			RWHtmlLog.e(TAG, "Name of file attempted to create: " + queueFilename, null);
			throw new IOException(msg);
		}
		
		return queueFile;
	}
	
	
	private RWActionData addCoordinates(RWActionData data) {
		if (data != null) {
			// check if location needs to be added
			String str = mService.getString(R.string.rw_spec_include_location_in_requests_yn);
			if ((str != null) && ("Y".equals(str.toUpperCase()))) {
				// get last known location from service
				Location loc = mService.getLastKnownLocation();
				if (loc != null) {
					// 6 decimal places -> approx dec. degrees accuracy = 0.111 meters (with 5 = 1.11 meters)
					String lon = String.format("%.6f", loc.getLongitude());
					String lat = String.format("%.6f", loc.getLatitude());
					String acc = String.format("%.1f", loc.getAccuracy());
					if (!("NaN".equals(lat) && "NaN".equals(lon))) {
						data.add(R.string.rw_key_longitude, lon);
						data.add(R.string.rw_key_latitude, lat);
					}
					data.add(R.string.rw_key_accuracy, acc);
					data.add(R.string.rw_key_location_provider_name, loc.getProvider());
				}
			}
		}
		return data;
	}

	
	private RWActionData addSelections(RWActionData data, RWList selections) {
		if ((data != null) && (selections != null)) {
			addChoicesSelection(data, R.string.rw_key_question_id, selections.filter(RWListItem.Category.QUESTION));
			addChoicesSelection(data, R.string.rw_key_user_type_id, selections.filter(RWListItem.Category.USERTYPE));
			addChoicesSelection(data, R.string.rw_key_demographic_id, selections.filter(RWListItem.Category.DEMOGRAPHIC));
		}
		return data;
	}
	
	
	private RWActionData addChoicesSelection(RWActionData data, int keyResId, List<RWListItem> choices) {
		if ((data != null) && (choices != null) && (!choices.isEmpty())) {
			StringBuilder sb = new StringBuilder();
			for (RWListItem item : choices) {
				if (item.isOn()) {
					appendWithSeparator(sb, item.getId());
				}
			}
			data.add(keyResId, sb.toString());
		}
		return data;
	}
	
	
	/**
	 * Append the specified text to the StringBuilder, inserting a tab
	 * first if the StringBuilder is not empty.
	 * 
	 * @param sb StringBuilder to append text to
	 * @param text to append
	 * @return reference to the updated StringBuilder
	 */
	private StringBuilder appendWithSeparator(StringBuilder sb, String text) {
		if ((sb != null) && (text != null)) {
			if (sb.length() > 0) {
				sb.append("\t");
			}
			sb.append(text);
		}
		return sb;
	}
	
}
