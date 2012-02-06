/*
 things that don't change
 */

#define kHOME_TITLE					@"Home"
#define kLISTEN_TITLE				@"Listen"
#define kSPEAK_TITLE				@"Speak"
#define kTHANKYOU_TITLE				@"Thank You!"

#define kABOUT_SCAPES				@"\nCONCEPT\nHalsey Burgund\n\nARTWORK\nBenjamin Dauer\nHalsey Burgund\n\nPROGRAMMING\nJoe Zobkiw (iPhone)\nMike MacHenry (server)\n\n"
#define kSCAPES_WEBSITE				@"http://halseyburgund.com/scapes/"
#define kAGREEMENT					@"I agree that any recordings I make using the Scapes app will become a part of the Scapes exhibit and can be used by Halsey Burgund for any related purpose.\n\nThanks and enjoy!"

// EVENTS // [(ScapesAppDelegate *)[[UIApplication sharedApplication] delegate] submitEvent: kEVENT_START_STREAM];
#define kEVENT_UPLOAD				0	// used during upload event
#define kEVENT_GPS_FIX				1
#define	kEVENT_GPS_IDLE				2	// still send even when no gps accessible
#define kEVENT_START_STREAM			3
#define kEVENT_STOP_STREAM			4
#define kEVENT_START_RECORD			5
#define kEVENT_STOP_RECORD			6
#define kEVENT_START_UPLOAD			7
#define kEVENT_STOP_UPLOAD_SUCCESS	8
#define kEVENT_STOP_UPLOAD_FAIL		9
#define kEVENT_START_SESSION		10
#define kEVENT_STOP_SESSION			11
#define kEVENT_MODIFY_STREAM		12	// based on timer?

// GPS
#define kGPSIdleTimerInterval		35	// seconds (change back to 30 at some point)

// ANIMATION
#define kAnimationMultiplier		.0015	// 480 * .0015 = .72 seconds for a 480 pixel high sub-view to slide into place, smaller views finish their animation faster making them seem to go the same speed
// AUDIO
#define kBufferDurationSeconds		.5
#define katRecordedFileName			@"scapesRecordedAudio.caf"
#define kcfstrRecordedFileName		"scapesRecordedAudio.caf"
#define kMaxRecordingTimeSeconds	30

// URLs
//#define kListenQuestionsURL		@"http://halseyburgund.com/scapes/listenQuestions_iPhone.php" // @"http://halseyburgund.com/scapes/listenQuestions.plist" // @"http://zobkiw.com/scapes/listenQuestions.plist"
//#define kSpeakQuestionsURL		@"http://halseyburgund.com/scapes/speakQuestions_iPhone.php" // @"http://halseyburgund.com/scapes/speakQuestions.plist" // @"http://zobkiw.com/scapes/speakQuestions.plist"
//#define kUploadURL				@"http://halseyburgund.com/scapes/operation8080.php" // @"http://zobkiw.com/scapes/upload/index.php"
//#define kDefaultStreamURL			@"http://aevidence2.dyndns.org:8000/ov.mp3"
#define kEventURL					@"http://scapesaudio.dyndns.org:80/roundware/roundware.py" // @"http://halseyburgund.com/scapes/operation.php"
#define kAudioFormatURL				@"http://scapesaudio.dyndns.org/scapes/audio_format.php"
#define kMaxRecordingTimeSecondsURL	@"http://scapesaudio.dyndns.org/scapes/maxRecordingTimeSeconds.php"

#define kEventURL_					@"http://scapesaudio.dyndns.org:80/roundware/roundware.py?"
#define kEventURL__					@"http://scapesaudio.dyndns.org:80/roundware/roundware.py"

// NEW CONSTANTS
#define kConfig						@"scapes"
#define kCategoryID					@"8"	// Scapes constant
#define kSubcategoryID				@"9"	// Scapes constant
#define kScapesBaseParams			@"config=scapes&categoryid=8&subcategoryid=9&"
#define kScapesMuseumVisitor		@"17"

// NEW OPERATIONS
#define kGetQuestionsOperation		@"operation=get_questions"

// TAGS
#define kWomanTag	@"1"
#define kManTag		@"2"
#define kGirlTag	@"3"
#define kBoyTag		@"4"

// PREFS
//#define kUndefinedPrefZero			0
//#define kDefaultListenGenderAgePref	(kWomanTag + kManTag + kGirlTag + kBoyTag) // All by default

#define kListenGenderAgePref		@"listen_genderage"
#define kListenQuestionPref			@"listen_question"
#define kSpeakGenderAgePref			@"speak_genderage"
#define kSpeakQuestionPref			@"speak_question"

#define kHalseyModeGPSPingPref		@"hm_gpsping"

// LISTS
#define kQuestionSection			0
#define kQuestionSections			1
#define kDemoSection				0
#define kDemoSections				1

#define kUncheckedChevron			@"gray-chevron.png"
#define kCheckedChevron				@"green-chevron.png"
