import std.file;
import std.path;
import std.json;
import std.stdio;
import std.format;
import std.string;
import std.process;
import util;

void PackageManager_Init() {
	CheckIfFolderIsProject();

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

	config["run"] = "cc %S -c -o %B -I.ypm";
	writeln("Compiler/Interpreter configuration");
	writeln("Type %S for source file and %B for out file, both do not need to be present");
	writef("Run command [%s]: ", config["run"].str);
	input = readln().strip();
	if (input != "") {
		config["run"] = JSONValue(input);
	}

	config["dependencies"] = JSONValue(cast(string[]) []);

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

			string command = format(
				"git submodule add -f %s %s",
				val.str, getcwd() ~ "/.ypm/" ~ baseName(val.str)
			);
			
			auto status = executeShell(command);

			if (status.status != 0) {
				stderr.writefln("Something has gone wrong:");
				stderr.writeln(status.output);
			}
		}
	}

	executeShell("git submodule update --remote --init --recursive");

	writeln("Finished updating");
}
