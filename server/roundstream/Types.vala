namespace Types {
	public struct Request {
		int[] categoryids;
		int[] subcategoryids;
		int[] questionids;
		int[] usertypeids;
		int[] genderids;
		int[] ageids;
		double? latitude;
		double? longitude;
	}

	public struct Category {
		string name;
		//char imagefile[50];
		//char bcfile[30];
		string musicuri;
		float musicvolume;
		//char activeyn;
		//int projectid;
	}

	public struct Speaker {
		string uri;
		double latitude;
		double longitude;
		int mindistance;
		int maxdistance;
		float minvolume;
		float maxvolume;
	}

	public struct Recording {
		string filename;
		uint audiolength;
		float volume;
		double latitude;
		double longitude;
	}

	public struct Composition {
		float minvolume;
		float maxvolume;
		uint minduration;
		uint maxduration;
		uint mindeadair;
		uint maxdeadair;
		uint minfadeintime;
		uint maxfadeintime;
		uint minfadeouttime;
		uint maxfadeouttime;
		float minpanpos;
		float maxpanpos;
		uint minpanduration;
		uint maxpanduration;
		char repeatrecordings;
	}
}

