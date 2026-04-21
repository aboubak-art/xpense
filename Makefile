.PHONY: help install generate build test coverage clean lint format ci

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

install: ## Install dependencies
	flutter pub get

generate: ## Run code generation
	flutter pub run build_runner build --delete-conflicting-outputs

watch: ## Run code generation in watch mode
	flutter pub run build_runner watch --delete-conflicting-outputs

build: ## Build Android dev APK
	flutter build apk --flavor dev

build-ios: ## Build iOS simulator
	flutter build ios --simulator --flavor dev

test: ## Run all tests
	flutter test

test-unit: ## Run unit tests only
	flutter test test/unit/

test-widget: ## Run widget tests only
	flutter test test/widget/

test-integration: ## Run integration tests
	flutter test integration_test/

coverage: ## Run tests with coverage
	flutter test --coverage
	genhtml coverage/lcov.info -o coverage/html

lint: ## Run static analysis
	flutter analyze

format: ## Format code
	dart format lib test

format-check: ## Check code formatting
	dart format --set-exit-if-changed lib test

ci: lint format-check test ## Run full CI pipeline locally

pipeline: ## Run development pipeline script
	./scripts/dev-pipeline.sh full

pipeline-build: ## Run build phase only
	./scripts/dev-pipeline.sh build

pipeline-review: ## Run review phase only
	./scripts/dev-pipeline.sh review

pipeline-test: ## Run test phase only
	./scripts/dev-pipeline.sh test

clean: ## Clean build artifacts
	flutter clean
	cd ios && pod deintegrate 2>/dev/null || true
	cd android && ./gradlew clean 2>/dev/null || true
	rm -rf coverage/

run-dev: ## Run in development mode
	flutter run --flavor dev

run-staging: ## Run in staging mode
	flutter run --flavor staging

splash: ## Generate splash screen
	flutter pub run flutter_native_splash:create

icons: ## Generate app icons
	flutter pub run flutter_launcher_icons

release-android: ## Build production AAB
	flutter build appbundle --flavor prod

release-ios: ## Build production IPA
	flutter build ipa --flavor prod
