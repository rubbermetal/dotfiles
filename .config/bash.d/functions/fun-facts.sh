#!/bin/bash

fun-facts() {
	# Get the number of lines in the file
	NUM_LINES=$(wc -l < "${FACTS_FILE}")

	# Generate a random line number
	RANDOM_LINE=$((1 + RANDOM % ${NUM_LINES}))

	# Print the random fun fact
	sed "${RANDOM_LINE}q;d" "${FACTS_FILE}"
}
