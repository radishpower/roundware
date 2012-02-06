/*
 things that don't change
 */

#define kHOME_TITLE					@"Home"
#define kLISTEN_TITLE				@"Listen"
#define kSPEAK_TITLE				@"Speak"
#define kTHANKYOU_TITLE				@"Thank You!"

#define kABOUT_OCEANVOICES			@"A collaboration between Halsey Burgund and Wallace J. Nichols\n\nArtwork by:\nHalsey Burgund and \nBenjamin Dauer\n\nProgramming by:\nJoe Zobkiw (iPhone) and\nMike MacHenry (server)\n\nSponsored by:\nMonkey Business\nwww.monkeybusiness.com\n"
#define kPOST_RECORD_POPUP_TEXT		@"Please take a moment to tell us about your experience using the Ocean Voices iPhone App!\n"
#define kOCEANVOICES_WEBSITE		@"http://oceanvoices.org/"
#define kOCEANVOICES_ITUNESURL		@"http://itunes.apple.com/us/app/scapes/"

// EVENTS // [(OceanVoicesAppDelegate *)[[UIApplication sharedApplication] delegate] submitEvent: kEVENT_START_STREAM];
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
#define kGPSIdleTimerInterval		30	// seconds (change back to 30 at some point)

// ANIMATION
#define kAnimationMultiplier		.0015	// 480 * .0015 = .72 seconds for a 480 pixel high sub-view to slide into place, smaller views finish their animation faster making them seem to go the same speed
// AUDIO
#define kBufferDurationSeconds		.5
#define katRecordedFileName			@"ovRecordedAudio.caf"
#define kcfstrRecordedFileName		"ovRecordedAudio.caf"
#define kMaxRecordingTimeSeconds	121

// URLs
// Please use 'usertype' as the variable name when posting since that is what we are using on the server-side.

#define kUserTypesURL				@"http://halseyburgund.com/oceanvoices/phone/userTypes.php"
#define kListenQuestionsURL			@"http://halseyburgund.com/oceanvoices/phone/listenQuestions.php" // @"http://halseyburgund.com/scapes/listenQuestions.plist" // @"http://zobkiw.com/scapes/listenQuestions.plist"
#define kSpeakQuestionsURL			@"http://halseyburgund.com/oceanvoices/phone/speakQuestions.php" // @"http://halseyburgund.com/scapes/speakQuestions.plist" // @"http://zobkiw.com/scapes/speakQuestions.plist"
#define kUploadURL					@"http://halseyburgund.com/oceanvoices/phone/operation.php" // @"http://zobkiw.com/scapes/upload/index.php"
//#define kDefaultStreamURL			@"http://aevidence2.dyndns.org:8000/ov.mp3"
#define kEventURL					@"http://halseyburgund.com/oceanvoices/phone/operation.php"
#define kMovieURL					@"http://halseyburgund.com/oceanvoices/phone/ov_phone.mov"

// TAGS
#define kWomanTag	@"1"
#define kManTag		@"2"
#define kGirlTag	@"3"
#define kBoyTag		@"4"

// PREFS
//#define kUndefinedPrefZero			0
//#define kDefaultListenGenderAgePref	(kWomanTag + kManTag + kGirlTag + kBoyTag) // All by default

#define kListenUserTypePref			@"listen_usertype"
#define kListenGenderAgePref		@"listen_genderage"
#define kListenQuestionPref			@"listen_question"
#define kSpeakUserTypePref			@"speak_usertype"
#define kSpeakGenderAgePref			@"speak_genderage"
#define kSpeakQuestionPref			@"speak_question"

#define kHalseyModeGPSPingPref		@"hm_gpsping"

// LISTS
#define kQuestionSection			0
#define kQuestionSections			1
#define kDemoSection0				0	// used in both speak and listen
#define kDemoSection1				1	// used only in listen, speak has a separate list of user types
//#define kDemoSections				2

#define kUncheckedChevron			@"gray-chevron.png"
#define kCheckedChevron				@"blue-chevron.png"
#define kCheckedChevronAlternate	@"brown-chevron.png"
