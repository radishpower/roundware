/*
 things that don't change
 */

#define kHOME_TITLE					@"Home"
#define kLISTEN_TITLE				@"Listen"
#define kSPEAK_TITLE				@"Speak"
#define kTHANKYOU_TITLE				@"Thank You!"

#define kABOUT_SCAPES				@"This app is your portal into the participatory audio world of the 'Mountain Ghosts' sound art installation by Halsey Burgund. \n\nThis project is commissioned by VAPA and is accessible anywhere on the Colorado Springs campus.\n\nPlease listen, add your own ghosts and explore the campus and surrounding areas.\n\nPROGRAMMING\nJoe Zobkiw (iPhone)\nMike MacHenry (server)\nBen McAllister (server)\n\nADDITIONAL GRAPHICS\nBenjamin Dauer\n"
#define kSCAPES_WEBSITE				@"http://halseyburgund.com/work/mg/"
#define kAGREEMENT					@"I agree that any recordings I make using the Mountain Ghosts app will become a part of the Mountain Ghosts exhibit and can be used by Halsey Burgund for any related purpose.\n\nThanks and enjoy!"

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
#define kGPSIdleTimerInterval		30	// seconds (change back to 30 at some point)

// ANIMATION
#define kAnimationMultiplier		.0015	// 480 * .0015 = .72 seconds for a 480 pixel high sub-view to slide into place, smaller views finish their animation faster making them seem to go the same speed
// AUDIO
#define kBufferDurationSeconds		.5
#define katRecordedFileName			@"mg.caf"
#define kcfstrRecordedFileName		"mg.caf"
#define kMaxRecordingTimeSeconds	45

// URLs
#define kEventURL					@"http://mountainghosts.dyndns.org/roundware/roundware.py" // @"http://halseyburgund.com/scapes/operation.php"
#define kAudioFormatURL				@"http://mountainghosts.dyndns.org/rw/mg_audio_format.php"
#define kMaxRecordingTimeSecondsURL	@"http://mountainghosts.dyndns.org/rw/mg_maxRecordingTimeSeconds.php"

#define kEventURL_					@"http://mountainghosts.dyndns.org/roundware/roundware.py?"
#define kEventURL__					@"http://mountainghosts.dyndns.org/roundware/roundware.py"

// NEW CONSTANTS
#define kConfig						@"mtnghosts"
#define kCategoryID					@"11"	// Mountain Ghosts constant
#define kSubcategoryID				@"11"	// Mountain Ghosts constant
#define kScapesBaseParams			@"config=mtnghosts&categoryid=11&subcategoryid=11&"
#define kScapesMuseumVisitor		@"18"

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
