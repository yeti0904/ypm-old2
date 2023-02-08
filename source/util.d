import std.file;
import std.array;
import std.stdio;
import std.process;
import core.stdc.stdlib;

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
