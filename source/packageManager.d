import std.file;
import std.path;
import std.json;
import std.array;
import std.stdio;
import std.format;
import std.string;
import std.process;
import std.algorithm;
import core.stdc.stdlib;
import util;

static string[string] finalPresets;
static string[string] runPresets;
static bool[string]   needsLinkPresets;
static string[string] finalPrefixPresets;
static string[string] finalSuffixPresets;

void InitPresets() {
	finalPresets = [
		"C_program":       "cc .ypm/*.o -o %B",
		"C_library":       "cc .ypm/*.o -o %B",
		"C++_program":     "c++ .ypm/*.o -o %B",
		"C++_library":     "c++ .ypm/*.o -o %B",
		"header_only":     " ",
		"fortran_program": "gfortran .ypm/*.o -o %B"
	];
	
	runPresets = [
		"C_program":       "cc %S -c -o %B -I.ypm",
		"C_library":       "cc %S -c -o %B -I.ypm",
		"C++_program":     "c++ %S -c -o %B -I.ypm",
		"C++_library":     "c++ %s -c -o %B -I.ypm",
		"header_only":     " ",
		"fortran_program": "gfortran %s -c -o %B -I.ypm"
	];

	needsLinkPresets = [
		"C_program":       false,
		"C_library":       true,
		"C++_program":     false,
		"C++_library":     true,
		"header_only":     false,
		"fortran_program": false
	];

	finalPrefixPresets = [
		"C_program":       "",
		"C_library":       "lib",
		"C++_program":     "",
		"C++_library":     "lib",
		"header_only":     "",
		"fortran_program": ""
	];

	version(Windows) {
		finalSuffixPresets = [
			"C_program":       ".exe",
			"C_library":       ".lib",
			"C++_program":     ".exe",
			"C++_library":     ".lib",
			"header_only":     "",
			"fortran_program": ".exe"
		];
	}
	else {
		finalSuffixPresets = [
			"C_program":       "",
			"C_library":       ".a",
			"C++_program":     "",
			"C++_library":     ".a",
			"header_only":     "",
			"fortran_program": ""
		];
	}
}

bool PresetExists(string name) {
	return ((name in finalPresets) !is null) && ((name in runPresets) !is null);
}

string[] GetPresets() {
	string[] ret;

	foreach (ref key, value ; finalPresets) {
		if (PresetExists(key)) {
			ret ~= key;
		}
	}

	return ret;
}

void PackageManager_Init(bool presetUsed, string preset) {
	JSONValue config = "{}".parseJSON();
	string    input;
	bool      updated;

	if (exists("ypm.json")) {
		config  = readText("ypm.json").parseJSON();
		updated = true;
	}

	if (!("name" in config.objectNoRef)) {
		config["name"] = JSONValue(baseName(getcwd()));
		writef("Name [%s]: ", config["name"].str);
		input = readln().strip();
		if (input != "") {
			config["name"] = JSONValue(input);
		}
	}

	if (!("license" in config.objectNoRef)) {
		config["license"] = "propietary";
		writef("License [%s]: ", config["license"].str);
		input = readln().strip();
		if (input != "") {
			config["license"] = JSONValue(input);
		}
	}

	if (!("author" in config.objectNoRef)) {
		config["author"] = "mx_foobarbaz";
		writef("Author [%s]: ", config["author"].str);
		input = readln().strip();
		if (input != "") {
			config["author"] = JSONValue(input);
		}
	}
	if (!("run" in config.objectNoRef) || !("final" in config.objectNoRef)) {
		if (presetUsed) {
			config["run"]   = runPresets[preset];
			config["final"] = finalPresets[preset];
		}
		else {
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
		}
	}

	if (!("dependencies" in config.objectNoRef)) {
		config["dependencies"] = JSONValue(cast(string[]) []);
	}
	
	if (!("libs" in config.objectNoRef)) {
		config["libs"]         = JSONValue(cast(string[]) []);
	}
	
	if (!("sourceFolder" in config.objectNoRef)) {
		config["sourceFolder"] = JSONValue("source");
	}
	
	if (!("finalFile" in config.objectNoRef)) {
		config["finalFile"]    = config["name"];
	}

	if (!("needsLink" in config.objectNoRef)) {
		if (presetUsed) {
			config["needsLink"] = JSONValue(needsLinkPresets[preset]);
		}
		else {
			write("Is your program a library, if so does it need to be linked? [Y/N] ");
			input = readln().strip();

			if ((input == "Y") || (input == "y")) {
				config["needsLink"] = JSONValue(true);
			}
			else {
				config["needsLink"] = JSONValue(false);
			}
		}
	}

	if (!("finalPrefix" in config.objectNoRef)) {
		if (presetUsed) {
			config["finalPrefix"] = finalPrefixPresets[preset];
		}
		else {
			write("What should the prefix of the final file name's prefix be? ");
			input = readln().strip();

			config["finalPrefix"] = JSONValue(input);
		}
	}

	if (!("finalSuffix" in config.objectNoRef)) {
		if (presetUsed) {
			config["finalSuffix"] = finalSuffixPresets[preset];
		}
		else {
			write("What should the suffix of the final file name's prefix be? ");
			input = readln().strip();

			config["finalSuffix"] = JSONValue(input);
		}
	}

	if (!exists("source")) {
		mkdir("source");
	}
	if (!exists(".ypm")) {
		mkdir(".ypm");
	}

	if (!exists(".gitignore")) {
		std.file.write(".gitignore", "");
	}

	append(
		".gitignore", format(
			"%s\n.ypm/*.hash\n.ypm/*.o", config["name"].str
		)
	);
	
	std.file.write("ypm.json", config.toPrettyString());

	executeShell("git init > /dev/null");

	if (updated) {
		writefln("Updated project at %s", getcwd());
	}
	else {
		writefln("Created empty project at %s", getcwd());
	}
}

void PackageManager_Add(string url) {
	CheckIfFolderIsProject();

	auto config = readText("ypm.json").parseJSON();

	config["dependencies"] = config["dependencies"].arrayNoRef() ~ JSONValue(url);

	std.file.write("ypm.json", config.toPrettyString());

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
			if (exists(path ~ "/ypm.json")) {
				status = executeShell(format("cd %s && ypm setup && ypm build", path));
			}
			else {
				stderr.writefln("Warning: %s is not a YPM project, not setting up", baseName(path));
				continue;
			}

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

void PackageManager_Install() {
	CheckIfFolderIsProject();

	auto config = readText("ypm.json").parseJSON();

	if (!exists(config["finalFile"].str)) {
		stderr.writefln("Final file (%s) doesn't exist", config["finalFile"].str);
		exit(1);
	}

	try {
		copy(config["finalFile"].str, "/usr/bin/" ~ baseName(config["finalFile"].str));
	}
	catch (FileException e) {
		stderr.writefln("Failed to install: %s", e.msg);
		exit(1);
	}
}

void PackageManager_Remove(string toRemove) {
	CheckIfFolderIsProject();

	auto config   = readText("ypm.json").parseJSON();
	bool wasFound = false;

	foreach (i, ref element ; config["dependencies"].array) {
		if (element.str == toRemove) {
			config["dependencies"] = config["dependencies"].arrayNoRef.remove(i);
			wasFound               = true;

			std.file.write("ypm.json", config.toPrettyString());
			
			break;
		}
	}

	if (!wasFound) {
		stderr.writefln("No such dependency %s", toRemove);
		exit(1);
	}

	auto status = executeShell(format("git rm ./.ypm/%s -f", baseName(toRemove)));

	if (status.status != 0) {
		stderr.writefln("Failed to remove git submodule of dependency %s:", toRemove);
		stderr.writeln(status.output);
		exit(1);
	}

	writefln("Successfully removed dependency %s", toRemove);
}

void PackageManager_Dependencies() {
	CheckIfFolderIsProject();

	auto config = readText("ypm.json").parseJSON();

	string total = format("Total: %d", config["dependencies"].array.length);
	writeln(total);
	for (size_t i = 0; i < total.length; ++i) {
		std.stdio.write('=');
	}
	writeln();

	foreach (ref dependency ; config["dependencies"].array) {
		writeln(dependency.str);
	}
}
