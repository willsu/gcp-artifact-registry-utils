#!/bin/bash
set -euo pipefail

# REQUIRED ENV VARS:
PROJECT_ID=$(gcloud config get project 2>/dev/null)

total_repos=0
total_images=0
total_size_mb=0

# Create a temporary file for communication
results_pipe=$(mktemp -u)
mkfifo "$results_pipe"

# Get a list of repositories and their locations
repositories=$(unbuffer gcloud artifacts repositories list --project="$PROJECT_ID" --format="value(name, name.segment(3), sizeBytes)" | tail -n +3)

# Parse the output and process in parallel
count=0
while IFS=$'\n' read -r line; do
    if [[ -z "$line" ]]; then
        continue # Skip empty lines
    fi

    repo=$(echo "$line" | awk '{print $1}')
    location=$(echo "$line" | awk '{print $2}')
    size_in_mb=$(echo "$line" | awk '{print $3}')

    # Fork a process to get image count
    (
        image_count=$(unbuffer gcloud artifacts docker images list "$location-docker.pkg.dev/$PROJECT_ID/$(basename "$repo")" --format="value(digest)" | tail -n +3 | wc -l)
        echo "$image_count $size_in_mb" > "$results_pipe" # Write results to the temp pipe
    ) &
    count=$((count + 1)) # count the background processes
    total_repos=$((total_repos + 1))
done <<< "$repositories"

# Read results while the background processes are still running
read_count=0
while [[ $read_count -lt $count ]]; do
    read -r result < "$results_pipe"
    if [[ -n "$result" ]]; then
        image_count=$(echo "$result" | awk '{print $1}')
        size_in_mb=$(echo "$result" | awk '{print $2}')

        total_images=$((total_images + image_count))
        total_size_mb=$(echo "${total_size_mb} ${size_in_mb}" | awk '{print $1+$2}')
        read_count=$((read_count + 1))
    fi
done

# Wait for all background processes to finish.
wait

# Remove the temporary pipe
rm "$results_pipe"

echo "Artifact Registry totals for project: ${PROJECT_ID}"
echo "Total repositories: $total_repos"
echo "Total images: $total_images"
echo "Total size:  $total_size_mb MB"
echo "Total human readable size: $(echo "${total_size_mb}M" | numfmt --from=iec --to=iec)B"

