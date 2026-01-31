# Testing Script Documentation

## Overview
This document describes the script created to run the Flutter tests that have been developed in the IDE.

## Script: run_tests.sh

### Location
The script is located at `docs/run_tests.sh`.

### Purpose
The script automates the execution of all Flutter unit and widget tests in the project.

### Usage
1. Open a terminal in the project root directory.
2. Make the script executable (if needed): `chmod +x docs/run_tests.sh`
3. Run the script: `./docs/run_tests.sh`

### What it does
- Executes `flutter test` command
- Runs all tests in the `test/` directory
- Displays test results in the terminal

### Output
The script will output:
- "Running Flutter tests..."
- Test execution results (passed/failed tests, coverage if configured)
- "Tests completed."

### Notes
- Ensure Flutter SDK is installed and configured
- Run this script from the project root directory
- The script assumes all dependencies are installed (`flutter pub get`)