/*
 things that don't change
 */

#define kHOME_TITLE					@"Home"
#define kLISTEN_TITLE				@"Listen"
#define kSPEAK_TITLE				@"Add a Story"
#define kTHANKYOU_TITLE				@"Thank You!"

#define kABOUT_SCAPES				@"Stories from Main Street is the Smithsonian’s digital archive for stories that tell the rich history of America’s rural communities.\n\nGRAPHICS\nHeather Foster Shelton\n\nPHOTO CREDITS\nMain screen: Steve Minor (Creative Commons License)\n\nListen screen: Philip Gould\n\nAdd a Story screen: courtesy of Belton Area Museum Association\n\nThis app is built using the Roundware platform with contributions from Halsey Burgund, Joe Zobkiw, Mike MacHenry, Ben McAllister and Benjamin Dauer"
#define kSCAPES_WEBSITE				@"http://www.storiesfrommainstreet.org"
#define kAGREEMENT					@"I agree that any recording I make using this app will become a part of the Stories from Main Street exhibition series and the recording, story and my voice can be used, reproduced and distributed by the Smithsonian and its authorized representatives for any educational purpose. For Smithsonian's privacy policy, see www.si.edu/privacy.\n\nThanks and enjoy!"

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
#define katRecordedFileName			@"moms.caf"
#define katConvertedFileName		@"moms.m4a"
//#define kcfstrRecordedFileName		"moms.caf" // unused
#define kMaxRecordingTimeSeconds	90

// URLs
#define kEventURL					@"http://simainst.dyndns.org/roundware/roundware.py"
#define kAudioFormatURL				@"http://simainst.dyndns.org/sfms/moms_audio_format.php"
#define kConversionFormatURL		@"http://simainst.dyndns.org/sfms/moms_audio_conversion_format.php"
#define kMaxRecordingTimeSecondsURL	@"http://simainst.dyndns.org/sfms/moms_maxRecordingTimeSeconds.php"
#define kSubmittedYNURL				@"http://simainst.dyndns.org/sfms/moms_submittedyn.php"

#define kEventURL_					@"http://simainst.dyndns.org/roundware/roundware.py?"
#define kEventURL__					@"http://simainst.dyndns.org/roundware/roundware.py"

// NEW CONSTANTS
#define kConfig						@"moms"
#define kProjectID                  @"1"	// MoMS constant
#define kCategoryID					@"1"	// MoMS constant
#define kSubcategoryID				@"1"	// MoMS constant
#define kScapesBaseParams			@"config=moms&projectid=1&categoryid=1&subcategoryid=1&"
#define kScapesMuseumVisitor		@"1\t2"

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
