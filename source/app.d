import std.file;
import std.stdio;
import std.string;
import core.stdc.stdlib;
import packageManager;
import buildSystem;
import util;

const string appHelp = "
YPM:  Package manager and build system
Options:
    init   - create project
    add    - add library
    update - update dependencies
    build  - build project
    clear  - clear final/source cache
    setup  - create ypm private folder and install dependencies
    preset - list project presets
";

void main(string[] args) {
	CheckPath();

	InitPresets();

	if (args.length == 1) {
		writeln(appHelp.strip());
		return;
	}

	switch (args[1]) {
		case "init": {
			bool   usePreset = false;
			string preset;

			if (args.length > 2) {
				usePreset = true;
				preset    = args[2];

				if (!PresetExists(args[2])) {
					stderr.writefln("Unknown preset %s", args[2]);
					exit(1);
				}
			}
		
			PackageManager_Init(usePreset, preset);
			return;
		}
		case "add": {
			if (args.length < 3) {
				stderr.writeln("Need 1 extra parameter for add (repo link");
					exit(1);
			}
			PackageManager_Add(args[2]);
			break;
		}
		case "update": {
			PackageManager_Update();
			break;
		}
		case "build": {
			BuildSystem_Build();
			break;
		}
		case "clear": {
			BuildSystem_ClearCache();
			break;
		}
		case "setup": {
			if (!exists(".ypm")) {
				mkdir(".ypm");
			}
			PackageManager_Update();
			break;
		}
		case "presets": {
			foreach (ref preset ; GetPresets()) {
				writeln(preset);
			}
			break;
		}
		default: {
			stderr.writefln("Unknown operation %s", args[1]);
			exit(1);
		}
	}
}
