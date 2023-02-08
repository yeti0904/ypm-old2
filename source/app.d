import std.stdio;
import std.string;
import packageManager;
import buildSystem;

const string appHelp = "
YPM Package manager
Options:
    init   - create project
    add    - add library
    update - update dependencies
    build  - build project
";

void main(string[] args) {
	if (args.length == 1) {
		writeln(appHelp.strip());
		return;
	}

	switch (args[1]) {
		case "init": {
			PackageManager_Init();
			return;
		}
		case "add": {
			if (args.length < 3) {
				stderr.writeln("Need 1 extra parameter for add (repo link");
				return;
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
		default: {
			stderr.writefln("Unknown operation %s", args[1]);
			return;
		}
	}
}
