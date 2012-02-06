using Gst;

void dump_message (Gst.Message message) {
	stdout.printf("%s: ", message.src.get_name());
	switch (message.type) {
		case MessageType.STATE_CHANGED:
			Gst.State oldstate;
			Gst.State newstate;
			Gst.State pending;
			message.parse_state_changed (
				out oldstate,
				out newstate,
				out pending);
			stdout.printf ("STATE_CHANGED: %s->%s:%s\n",
			oldstate.to_string (), newstate.to_string (),
			pending.to_string ());
			break;
		default:
			stdout.printf("%s\n",
				message_type_to_string(message.type));
			break;
	}
}

string message_type_to_string (MessageType type) {
	switch (type) {
		case Gst.MessageType.ANY: return "ANY";
		case Gst.MessageType.APPLICATION: return "APPLICATION";
		case Gst.MessageType.ASYNC_DONE: return "ASYNC_DONE";
		case Gst.MessageType.ASYNC_START: return "ASYNC_START";
		case Gst.MessageType.BUFFERING: return "BUFFERING";
		case Gst.MessageType.CLOCK_LOST: return "CLOCK_LOST";
		case Gst.MessageType.CLOCK_PROVIDE: return "CLOCK_PROVIDE";
		case Gst.MessageType.DURATION: return "DURATION";
		case Gst.MessageType.ELEMENT: return "ELEMENT";
		case Gst.MessageType.EOS: return "EOS";
		case Gst.MessageType.ERROR: return "ERROR";
		case Gst.MessageType.INFO: return "INFO";
		case Gst.MessageType.LATENCY: return "LATENCY";
		case Gst.MessageType.NEW_CLOCK: return "NEW_CLOCK";
		case Gst.MessageType.SEGMENT_DONE: return "SEGMENT_DONE";
		case Gst.MessageType.SEGMENT_START: return "SEGMENT_START";
		case Gst.MessageType.STATE_CHANGED: return "STATE_CHANGED";
		case Gst.MessageType.STATE_DIRTY: return "STATE_DIRTY";
		case Gst.MessageType.STEP_DONE: return "STEP_DONE";
		case Gst.MessageType.STREAM_STATUS: return "STREAM_STATUS";
		case Gst.MessageType.STRUCTURE_CHANGE:
			return "STRUCTURE_CHANGE";
		case Gst.MessageType.TAG: return "TAG";
		case Gst.MessageType.UNKNOWN: return "UNKNOWN";
		case Gst.MessageType.WARNING: return "WARNING";
		default: return "INVALID_MESSAGE_TYPE";
	}
}

