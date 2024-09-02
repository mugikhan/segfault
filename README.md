# powersync_segfault

Minimal replication of powersync segfault issue. The code runs correctly locally but causes a segfault when run in github actions with macos-latest.


## Running code locally

```shell
asdf install # optional - installs flutter 3.22.2
dart ./scripts/init_powersync_core_binary.dart
flutter test --dart-define SQLITE_BIN=$(which sqlite3)
```