import 'dart:ffi';
import 'dart:io';

final sqliteUrl = 'https://github.com/powersync-ja/powersync-sqlite-core/releases/download/v0.2.1';

void main() async {
  final flutterPath = await _getFlutterInstallationPath();
  if (flutterPath != null) {
    print('Flutter is installed at: $flutterPath');
  } else {
    print('Flutter installation not found.');
    return;
  }

  final sqliteCoreFilename = getLibraryForPlatform();
  final powersyncPath = await findWritablePath(flutterPath);
  if (powersyncPath == null) {
    print('No writable path found for placing the dynamic library.');
    return;
  }

  final sqliteCorePath = '$powersyncPath/$sqliteCoreFilename';

  // Download dynamic library
  await downloadFile("$sqliteUrl/$sqliteCoreFilename", sqliteCorePath);

  final originalFile = File(sqliteCorePath);

  try {
    final newFileName = getFileNameForPlatform();
    if (await originalFile.exists()) {
      final targetPath = '$newFileName';
      try {
        // Rename the original file to the new file name within the writable directory
        await originalFile.rename(targetPath);
        print('File moved successfully to $targetPath');
      } catch (e) {
        throw Exception('Error moving file: $e');
      }
    } else {
      throw Exception('File $sqliteCoreFilename does not exist.');
    }
  } on Exception catch (e) {
    print(e.toString());
  }
}

Future<String?> _getFlutterInstallationPath() async {
  final result = await Process.run(Platform.isWindows ? 'where' : 'which', ['flutter']);

  if (result.exitCode == 0) {
    return result.stdout.trim();
  }

  return null;
}

String getFileNameForPlatform() {
  switch (Abi.current()) {
    case Abi.macosArm64:
    case Abi.macosX64:
      return 'libpowersync.dylib';
    case Abi.linuxX64:
    case Abi.linuxArm64:
      return 'libpowersync.so';
    case Abi.windowsX64:
      return 'powersync.dll';
    default:
      throw Exception(
        'Unsupported processor architecture "${Abi.current()}". '
        'Please open an issue on GitHub to request it.',
      );
  }
}

Future<void> downloadFile(String url, String savePath) async {
  print('Downloading: $url');
  var httpClient = HttpClient();
  var request = await httpClient.getUrl(Uri.parse(url));
  var response = await request.close();
  if (response.statusCode == HttpStatus.ok) {
    var file = File(savePath);
    await response.pipe(file.openWrite());
  } else {
    print('Failed to download file: ${response.statusCode} ${response.reasonPhrase}');
  }
}

String getLibraryForPlatform() {
  switch (Abi.current()) {
    case Abi.macosArm64:
      return 'libpowersync_aarch64.dylib';
    case Abi.macosX64:
      return 'libpowersync_x64.dylib';
    case Abi.linuxX64:
      return 'libpowersync_x64.so';
    case Abi.linuxArm64:
      return 'libpowersync_aarch64.so';
    case Abi.windowsX64:
      return 'powersync_x64.dll';
    case Abi.windowsArm64:
      throw Exception('ARM64 Windows is not supported. '
          'Please use an x86_64 Windows machine or open a GitHub issue to request it');
    default:
      throw Exception(
        'Unsupported processor architecture "${Abi.current()}". '
        'Please open an issue on GitHub to request it.',
      );
  }
}

Future<String?> findWritablePath(String flutterPath) async {
  final flutterDir = Directory(flutterPath).parent.parent;
  final engineDir = getEngineDirForPlatform();

  final pathsToCheck = [
    flutterDir.path + '/bin/cache/artifacts/engine/$engineDir/',
    flutterDir.path + '/bin/cache/artifacts/engine/$engineDir/Frameworks/',
    flutterDir.path + '/bin/cache/artifacts/engine/$engineDir/../../../',
    Directory(flutterPath).parent.path + '/lib',
  ];

  for (final path in pathsToCheck) {
    final directory = Directory(path);
    if (await directory.exists() && directory.statSync().modeString().contains('w')) {
      print('Found writable path: $path');
      return path;
    }
  }

  return null;
}

String getEngineDirForPlatform() {
  switch (Abi.current()) {
    case Abi.macosArm64:
    case Abi.macosX64:
      return 'darwin-x64';
    case Abi.linuxX64:
      return 'linux-x64';
    case Abi.linuxArm64:
      return 'linux-arm64';
    case Abi.windowsX64:
      return 'windows-x64';
    case Abi.windowsArm64:
      throw Exception('ARM64 Windows is not supported. '
          'Please use an x86_64 Windows machine or open a GitHub issue to request it');
    default:
      throw Exception(
        'Unsupported processor architecture "${Abi.current()}". '
        'Please open an issue on GitHub to request it.',
      );
  }
}
