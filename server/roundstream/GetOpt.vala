/* TODO
* This class has everything static. OptionEntry seems to be
  only able to be instantiated once per program. Make this
  module more functional.
* Does not make use of OptionArg.STRING_ARRAY to create int[]
* Misses "1,2, 3" because it's separated by spaces
*/

using GLib;
using Types;

namespace GetOpt {

class Options {
	public static string stream_name;
	public static int foreground;
	public static string configfile;

	private static string categoryids;
	private static string subcategoryids;
	private static string questionids;
	private static string usertypeids;
	private static string genderids;
	private static string ageids;
	private static double latitude;
	private static double longitude;

	private static const OptionEntry[] options = {
		{ "name", '\0', 0, OptionArg.STRING, ref stream_name, "Stream name", null },
		{ "foreground", '\0', 0, OptionArg.NONE, ref foreground, "Foreground", null },
		{ "configfile", '\0', 0, OptionArg.FILENAME, ref configfile, "Cofig file", null },
		{ "categoryid", '\0', 0, OptionArg.STRING, ref categoryids, "Category IDs", null },
		{ "subcategoryid", '\0', 0, OptionArg.STRING, ref subcategoryids, "Subcategory IDs", null },
		{ "questionid", '\0', 0, OptionArg.STRING, ref questionids, "Question IDs", null },
		{ "usertypeid", '\0', 0, OptionArg.STRING, ref usertypeids, "User type IDs", null },
		{ "genderid", '\0', 0, OptionArg.STRING, ref genderids, "Gender IDs", null },
		{ "ageid", '\0', 0, OptionArg.STRING, ref ageids, "Age IDs", null },
		{ "latitude", '\0', 0, OptionArg.DOUBLE, ref latitude, "Latitude", null },
		{ "longitude", '\0', 0, OptionArg.DOUBLE, ref longitude, "Longitude", null },
		{ null }
	};

	public Options (string[] args) {
		try {
			var opt_context = new OptionContext("- Play an audio stream to an icecast server");
			opt_context.set_help_enabled(true);
			opt_context.add_main_entries(options, "pags");
			opt_context.parse(ref args);
		} catch (OptionError e) {
			stderr.printf("Option parsing failed: %s\n", e.message);
		}
	}

	public Request get_request () {
		return Request () {
			categoryids = csv_to_integers(this.categoryids),
			subcategoryids = csv_to_integers(this.subcategoryids),
			questionids = csv_to_integers(this.questionids),
			usertypeids = csv_to_integers(this.usertypeids),
			genderids = csv_to_integers(this.genderids),
			ageids = csv_to_integers(this.ageids),
			latitude = this.latitude,
			longitude = this.longitude
		};
	}

	private int[] csv_to_integers (string? csv) {
		if (csv == null) {
			return {};
		} else {
			string[] los = csv.split(",");
			int[] loi = {1}; //hack for return val
			return loi;
		}
	}
}

}

