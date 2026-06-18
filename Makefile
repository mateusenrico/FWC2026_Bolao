.PHONY: run profile analyze test build-web update-data

run:
	flutter run -d chrome --profile

profile: run

analyze:
	flutter analyze

test:
	flutter test

build-web:
	flutter build web --release

update-data:
	dart run tools/update_sportsdb.dart
