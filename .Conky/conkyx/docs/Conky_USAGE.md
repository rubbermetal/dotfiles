# Detailed Usage Instructions for Conky Custom Setup

## Configurations (`config/`)

The `config` directory contains all the necessary configuration files for this Conky setup. To apply a specific configuration:

1. Copy the desired `.conkyrc` file to your home directory.
2. Run `conky` in the terminal.

## Binaries (`bin/`)

The `bin` directory contains executable files that can be used to extend Conky's functionality. To use them:

1. Make sure they are executable (`chmod +x filename`).
2. Update your `.conkyrc` to reference the appropriate scripts.

## Fonts (`fonts/`)

The `fonts` directory contains custom fonts for the Conky display. To install them:

1. Copy the fonts to `~/.fonts/`.
2. Update the `.conkyrc` file to use the new fonts.

## Scripts (`scripts/`)

The `scripts` directory contains additional scripts that provide more complex functionalities like weather updates, system statistics, etc. To use them:

1. Make the scripts executable (`chmod +x script_name`).
2. Update `.conkyrc` to call these scripts where needed.

## Utilities (`utilities/`)

This directory contains helper scripts and utilities to assist with Conky management. These may include tools for debugging, logging, or other tasks.

To use a utility:

1. Make the utility executable (`chmod +x utility_name`).
2. Run the utility from the terminal as needed.
