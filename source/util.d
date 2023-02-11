import std.file;
import std.json;
import std.array;
import std.stdio;
import std.process;
import core.stdc.stdlib;
import packageManager;

void CheckIfFolderIsProject() {
	if (!exists("ypm.json")) {
		stderr.writefln("This folder does not contain a YPM project");
		exit(1);
	}
}

void CheckPath() {
	string[] folders = environment.get("PATH").split(":");

	foreach (ref folder ; folders) {
		if (exists(folder ~ "/ypm")) {
			return;
		}
	}

	stderr.writeln("YPM needs to be in a folder in PATH to run");
	exit(1);
}

void UpdateConfig() {
	CheckIfFolderIsProject();

	auto     config   = readText("ypm.json").parseJSON();
	string[] required = [
		"name", "license", "author", "run", "final", "dependencies", "libs",
		"sourceFolder", "finalFile"
	];

	foreach (ref key ; required) {
		if (!(key in config.objectNoRef)) {
			writeln("Missing keys detected in ypm.json, running init");
			PackageManager_Init(false, "");
			return;
		}
	}
}
