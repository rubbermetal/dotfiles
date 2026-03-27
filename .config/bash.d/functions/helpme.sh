###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

###############################################################################
# Helper: Functions Help
###############################################################################
# functions_help
#
# Displays a comprehensive list of available functions along with a short
# description of what each does.
###############################################################################
helpme() {
    echo -e "${fg_bright_cyan}==============================================${clr_restore}"
    echo -e "${fg_bright_cyan}            Available Functions               ${clr_restore}"
    echo -e "${fg_bright_cyan}==============================================${clr_restore}"
    echo ""

    echo -e "${fg_bright_blue}[Weather and IP Functions]${clr_restore}"
    echo -e "  ${fg_bright_green}weather <location>${clr_restore}"
    echo "      Displays weather information for a given location."
    echo -e "  ${fg_bright_green}getip${clr_restore}"
    echo "      Retrieves your external (WAN) IP address."
    echo ""

    echo -e "${fg_bright_blue}[Dictionary and Directory Functions]${clr_restore}"
    echo -e "  ${fg_bright_green}define <word>${clr_restore}"
    echo "      Looks up a definition for the given word."
    echo -e "  ${fg_bright_green}mkcd <directory>${clr_restore}"
    echo "      Creates the specified directory (with parents) and changes into it."
    echo -e "  ${fg_bright_green}extract <archive_file>${clr_restore}"
    echo "      Extracts various archive file types (tar.*, zip, rar, 7z, etc.)."
    echo ""

    echo -e "${fg_bright_blue}[Package Search]${clr_restore}"
    echo -e "  ${fg_bright_green}package-search <search_terms>${clr_restore}"
    echo "      Searches for packages via pacman with highlighted output."
    echo ""

    echo -e "${fg_bright_blue}[Audio Conversion]${clr_restore}"
    echo -e "  ${fg_bright_green}convert_mp3 <file>${clr_restore}"
    echo "      Converts a single file to MP3 and removes the original."
    echo -e "  ${fg_bright_green}batch_convert_mp3 <extension>${clr_restore}"
    echo "      Converts all files with the specified extension to MP3."
    echo ""

    echo -e "${fg_bright_blue}[Navigation]${clr_restore}"
    echo -e "  ${fg_bright_green}up <levels>${clr_restore}"
    echo "      Moves up the specified number of directory levels."
    echo -e "  ${fg_bright_green}back <levels>${clr_restore}"
    echo "      Moves back along a stored path."
    echo ""

    echo -e "${fg_bright_blue}[Enhanced Sudo]${clr_restore}"
    echo -e "  ${fg_bright_green}sudo <command...>${clr_restore}"
    echo "      A wrapper for sudo that processes command aliases."
    echo ""

    echo -e "${fg_bright_blue}[Custom Tar Wrapper]${clr_restore}"
    echo -e "  ${fg_bright_green}tarx <options and files>${clr_restore}"
    echo "      A wrapper for tar that processes options and filters STDERR."
    echo ""

    echo -e "${fg_bright_blue}[PATH Modification]${clr_restore}"
    echo -e "  ${fg_bright_green}addpath <dir> [first|remove] [verbose]${clr_restore}"
    echo "      Adds or removes a directory from an environment variable (default: PATH)."
    echo ""

    echo -e "${fg_bright_blue}[Session and History Helpers]${clr_restore}"
    echo -e "  ${fg_bright_green}mostused${clr_restore}"
    echo "      Displays a list of your most frequently used commands."
    echo -e "  ${fg_bright_green}runfree <command...>${clr_restore}"
    echo "      Runs a command in the background and disowns it."
    echo -e "  ${fg_bright_green}csvview <file>${clr_restore}"
    echo "      Views a CSV file with aligned columns."
    echo ""

    echo -e "${fg_bright_blue}[Trash Management]${clr_restore}"
    echo -e "  ${fg_bright_green}trash <files>${clr_restore}"
    echo "      Moves file(s) to the trash folder."
    echo -e "  ${fg_bright_green}trashlist${clr_restore}"
    echo "      Lists the contents of the trash folder."
    echo -e "  ${fg_bright_green}trashempty${clr_restore}"
    echo "      Empties the trash folder."
    echo ""

    echo -e "${fg_bright_blue}[Checksum and Copy with Progress]${clr_restore}"
    echo -e "  ${fg_bright_green}checksha256 <file> <checksum_file>${clr_restore}"
    echo "      Checks a file's SHA256 checksum against a provided checksum."
    echo -e "  ${fg_bright_green}cpp <source> <destination>${clr_restore}"
    echo "      Copies a file with a progress bar using rsync (or fallback via cp)."
    echo ""

    echo -e "${fg_bright_blue}[File/Directory Copy & Move]${clr_restore}"
    echo -e "  ${fg_bright_green}cpg <source> <destination>${clr_restore}"
    echo "      Copies a file and changes into the destination if it exists."
    echo -e "  ${fg_bright_green}mvg <source> <destination>${clr_restore}"
    echo "      Moves a file and changes into the destination if it exists."
    echo -e "  ${fg_bright_green}mkdirg <directory>${clr_restore}"
    echo "      Creates a directory and changes into it."
    echo -e "  ${fg_bright_green}repeat <n> <command>${clr_restore}"
    echo "      Repeats the given command n times."
    echo ""

    echo -e "${fg_bright_blue}[Color Output]${clr_restore}"
    echo -e "  ${fg_bright_green}colors${clr_restore}"
    echo "      Displays basic foreground/background color combinations."
    echo -e "  ${fg_bright_green}colors256${clr_restore}"
    echo "      Displays a list of 256 colors."
    echo -e "  ${fg_bright_green}colors24bit${clr_restore}"
    echo "      Tests for 24bit true color support."
    echo ""

    echo -e "${fg_bright_blue}[User Interaction]${clr_restore}"
    echo -e "  ${fg_bright_green}ask <prompt> [Y|N]${clr_restore}"
    echo "      Prompts for a Yes/No answer until a valid response is given."
    echo ""

    echo -e "${fg_bright_blue}[Permission Calculators and Fixers]${clr_restore}"
    echo -e "  ${fg_bright_green}chmodcalc <octal> | <owner> <group> <other>${clr_restore}"
    echo "      Displays file permissions based on numeric or symbolic values."
    echo -e "  ${fg_bright_green}chmodfiles <mode> [directory]${clr_restore}"
    echo "      Recursively changes permissions for files."
    echo -e "  ${fg_bright_green}chmoddirs <mode> [directory]${clr_restore}"
    echo "      Recursively changes permissions for directories."
    echo -e "  ${fg_bright_green}chfix [directory]${clr_restore}"
    echo "      Recursively fixes permissions for code files and directories."
    echo -e "  ${fg_bright_green}chmodcopy <source_file> <destination_file>${clr_restore}"
    echo "      Copies file permissions from one file to another."
    echo ""

    echo -e "${fg_bright_blue}[User Home & Config]${clr_restore}"
    echo -e "  ${fg_bright_green}fixuserhome [username]${clr_restore}"
    echo "      Fixes permissions for a user's home folder."
    echo -e "  ${fg_bright_green}configcopy <from_user> <to_user>${clr_restore}"
    echo "      Copies configuration files from one account to another."
    echo ""

    echo -e "${fg_bright_blue}[Miscellaneous]${clr_restore}"
    echo -e "  ${fg_bright_green}trim <string>${clr_restore}"
    echo "      Trims leading and trailing whitespace from a string."
    echo -e "  ${fg_bright_green}update_firefox [--clean] [--run]${clr_restore}"
    echo "      Updates and builds the Firefox source; optionally cleans and runs it."
    echo -e "  ${fg_bright_green}update_chromium [--run]${clr_restore}"
    echo "      Updates and builds the Chromium source; optionally runs it."
    echo ""
    echo -e "${fg_bright_yellow}For more details, refer to the documentation within the functions file.${clr_restore}"
}

