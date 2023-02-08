import std.file;
import std.path;
import std.json;
import std.array;
import std.stdio;
import std.format;
import std.process;
import std.algorithm;
import std.digest.md;
import util;

static string[] ignoreExt = [
	".h",
	".hh",
	".hpp",
	".hxx",
	".h++"
];

void BuildSystem_Build() {
	CheckIfFolderIsProject();

	auto config = readText("ypm.json").parseJSON();

	writefln("Building project %s", config["name"].str);

	string command = config["run"].str;

	if (command.canFind("%S")) {
		// variable source file, we must iterate through source files
		// this is probably a compiled language
		foreach (ref entry ; dirEntries(getcwd() ~ "/source", SpanMode.shallow)) {
			if (ignoreExt.canFind(entry.name.extension())) {
				continue;
			}

			string    inFile         = entry.name;
			string    inFileContents = readText(inFile);
			ubyte[16] inFileHash     = inFileContents.md5Of();
			string    inFileHashPath = getcwd() ~ "/.ypm/" ~ baseName(inFile) ~ ".hash";
			string    outFile        = getcwd() ~ "/.ypm/" ~ baseName(entry.name) ~ ".o";

			if (exists(inFileHashPath)) {
				if (std.file.read(inFileHashPath) == inFileHash) {
					continue;
				}
			}

			std.file.write(inFileHashPath, inFileHash);
			
			writefln("Compiling %s", baseName(inFile));

			auto status =
				executeShell(command.replace("%S", inFile).replace("%B", outFile));

			if (status.status != 0) {
				stderr.writeln(status.output);
				stderr.writefln("Failed, exiting now");
				return;
			}
		}


		string    finalFileHashPath = getcwd() ~ "/.ypm/final.hash";
		ubyte[16] finalFileHash;

		if (exists(finalFileHashPath)) {
			finalFileHash = std.file.read(config["name"].str).md5Of();
		}

		if (
			!exists(config["name"].str) ||
			!exists(finalFileHashPath) ||
			(std.file.read(finalFileHashPath) == finalFileHash)
		) {
			writeln("Linking..");
			auto status = executeShell(format("cc ./.ypm/*.o -o %s", config["name"].str));

			std.file.write(finalFileHashPath, finalFileHash);

			if (status.status != 0) {
				stderr.writeln(status.output);
				stderr.writefln("Failed, exiting now");
				return;
			}
		}


		writeln("Done");
	}
	else {
		executeShell(command);
	}
}

void BuildSystem_ClearCache() {
	auto status = executeShell("rm ./.ypm/*.hash ./.ypm/*.o");

	if (status.status != 0) {
		stderr.writeln("Failed to clear cache:");
		stderr.writeln(status.output);
		return;
	}

	writeln("Cleared cache");
}
