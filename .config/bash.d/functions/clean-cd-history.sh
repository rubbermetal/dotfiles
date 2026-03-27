###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi
###############################################################################
# cleanup_cd_history: Remove the cd history file for this shell on exit.
#
# This function is automatically invoked when the shell exits.
# The cd history file used in the cd function is unique to the shell and 
# located at $DATA_DIR/cd-history-$$.
###############################################################################
clean-cd-history() {
    local cd_hist="$DATA_DIR/cd-history-$$"
    if [[ -f "$cd_hist" ]]; then
        rm -f "$cd_hist"
        # Optionally, you could print a debug message:
        # echo "Removed cd history file: $cd_hist"
    fi
}

# Register the cleanup_cd_history function to run when the shell exits.
trap clean-cd-history EXIT

