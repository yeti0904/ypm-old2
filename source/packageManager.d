import std.file;
import std.path;
import std.json;
import std.stdio;
import std.format;
import std.string;
import std.process;
import core.stdc.stdlib;
import util;
/*
string[string] finalPresets = [
	"C_program":   "cc .ypm/*.o -o %B",
	"C_library":   "cc .ypm/*.o -o %B -shared -fPIC",
	"C++_program": "c++ .ypm/*.o -o %B",
	"C++_library": "c++ .ypm/*.o -o %B -shared -fPIC"
];

string[string] runPresets = [
	"C_program":   "cc %S -c -o %B -I.ypm",
	"C_library":   "cc %S -c -o %B -I.ypm",
	"C++_program": "c++ %S -c -o %B -I.ypm",
	"C++_library": "c++ %s -c -o %B -I.ypm"
];
*/
void PackageManager_Init(bool presetUsed, string preset) {
	JSONValue config;
	string    input;

	config["name"] = JSONValue(baseName(getcwd()));
	writef("Name [%s]: ", config["name"].str);
	input = readln().strip();
	if (input != "") {
		config["name"] = JSONValue(input);
	}

	config["license"] = "propietary";
	writef("License [%s]: ", config["license"].str);
	input = readln().strip();
	if (input != "") {
		config["license"] = JSONValue(input);
	}

	config["author"] = "mx_foobarbaz";
	writef("Author [%s]: ", config["author"].str);
	input = readln().strip();
	if (input != "") {
		config["author"] = JSONValue(input);
	}
/*
	if (presetUsed) {
		config["run"]   = runPresets[preset];
		config["final"] = finalPresets[preset];
	}
	else {*/
		config["run"] = "";
		writeln("Compiler/Interpreter configuration");
		writeln("Type %S for source file and %B for out file, both do not need to be present");
		writeln("This command will be run for every source file");
		writef("Run command: ");
		input = readln().strip();
		config["run"] = JSONValue(input);
			
		writeln("Same as before, but this command will run after the run command has been executed for all source files");
		writef("Final command: ");
		input = readln().strip();
		config["final"] = JSONValue(input);
	//}

	config["dependencies"] = JSONValue(cast(string[]) []);
	config["sourceFolder"] = JSONValue("src");

	mkdir("source");
	mkdir(".ypm");

	std.file.write(
		".gitignore", format(
			"%s\n.ypm", config["name"].str
		)
	);
	
	std.file.write("ypm.json", config.toString());

	executeShell("git init > /dev/null");

	writefln("Created empty project at %s", getcwd());
}

void PackageManager_Add(string url) {
	CheckIfFolderIsProject();

	auto config = readText("ypm.json").parseJSON();

	config["dependencies"] = config["dependencies"].arrayNoRef() ~ JSONValue(url);

	std.file.write("ypm.json", config.toString());

	writefln("Added dependency %s", baseName(url));
	writeln("Do ypm update to install it");
}

void PackageManager_Update() {
	CheckIfFolderIsProject();

	auto config = readText("ypm.json").parseJSON();

	foreach (ref val ; config["dependencies"].arrayNoRef()) {
		if (!exists(getcwd() ~ "/.ypm/" ~ baseName(val.str))) {
			writefln("Installing %s", baseName(val.str));

			string path    = getcwd() ~ "/.ypm/" ~ baseName(val.str);
			string command = format("git submodule add -f %s %s", val.str, path);
			auto   status  = executeShell(command);

			if (status.status != 0) {
				stderr.writefln("Something has gone wrong:");
				stderr.writeln(status.output);
				exit(1);
			}

			// check if dependency is a YPM project
			if (!exists(path ~ "/ypm.json")) {
				stderr.writefln("Warning: %s is not a YPM project", baseName(path));
				continue;
			}

			status = executeShell(format("cd %s && ypm setup && ypm build"));

			if (status.status != 0) {
				stderr.writefln("Failed to set up dependency %s:", baseName(path));
				stderr.writeln(status.output);
				exit(1);
			}
		}
	}

	executeShell("git submodule update --remote --init --recursive");

	writeln("Finished updating");
}
