Note: This tool is high experimental and gives no gaurentees.

## Description
A small "gcloud"-based script that prints some usage stats about Artifact Registry for a given project. This script may be most useful for observing Artifact Registry stats during a migration.

## Requirements
* gcloud
* unbuffer

## Usage
1. Open Cloud Shell in your Google Cloud Console
2. Clone the repository
```BASH
$ git clone https://github.com/willsu/gcp-artifact-registry-utils.git
```
3. Run the script
``` BASH
# Install "unbuffer" if not currently installed
$ sudo apt-get install expect

$ ./run-ar-project-report.sh

Artifact Registry totals for project: my-project
Total repositories: 3
Total images: 3
Total size:  251.536 MB
Total human readable size: 252MB
```

For continuous monitoring use:
``` BASH
$ watch ./run-ar-project-report.sh
```
