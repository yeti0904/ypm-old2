import std.file;
import std.stdio;
import core.stdc.stdlib;

void CheckIfFolderIsProject() {
	if (!exists("ypm.json")) {
		stderr.writefln("This folder does not contain a YPM project");
		exit(1);
	}
}
