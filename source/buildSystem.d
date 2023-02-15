import std.file;
import std.path;
import std.json;
import std.array;
import std.stdio;
import std.format;
import std.process;
import std.algorithm;
import std.digest.md;
import core.stdc.stdlib;
import util;
import packageManager;

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

	string   srcFolder = config["sourceFolder"].str;
	string[] libs;
	string[] libIncludes;

	foreach (ref val ; config["libs"].arrayNoRef) {
		libs ~= val.str;
	}

	foreach (ref val ; config["dependencies"].arrayNoRef) {
		string dir = "./.ypm/" ~ baseName(val.str);
		if (!exists(dir)) {
			PackageManager_Update();
		}

		auto status = executeShell(format("cd %s && ypm build", dir));

		if (status.status != 0) {
			stderr.writefln("Error building dependency %s:", baseName(val.str));
			stderr.writeln(status.output);
			exit(1);
		}

		auto dconfig = readText(dir ~ "/ypm.json").parseJSON();

		
	}

	writefln("Building project %s", config["name"].str);

	string command = config["run"].str;

	if (command.canFind("%S")) {
		// variable source file, we must iterate through source files
		// this is probably a compiled language
		string folder = getcwd() ~ "/" ~ srcFolder;

		if (!exists(folder)) {
			stderr.writefln("Error: No directory %s exists", folder);
			exit(1);
		}
		
		foreach (ref entry ; dirEntries(folder, SpanMode.shallow)) {
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
				exit(1);
			}
		}
		
		string finalCommand =
			config["final"].str.replace("%B", config["finalFile"].str);

		foreach (ref link ; libs) {
			finalCommand ~= " -l" ~ link;
		}
	
		writeln("Linking..");
		//auto status = executeShell(format("cc ./.ypm/*.o -o %s", config["name"].str));
		auto status = executeShell(finalCommand);

		std.file.write(finalFileHashPath, finalFileHash);

		if (status.status != 0) {
			stderr.writeln(status.output);
			stderr.writefln("Failed, exiting now");
			return;
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
