###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

# mostused: Display a list of the most used commands from history.
mostused() {
    history | awk '{ a[$4]++ } END { for (i in a) print a[i], i }' \
    | sort -rn | head -n10 \
    | awk '{
          if (NR==1) { max=$1 }
          bar="";
          for (i=0; i<int(($1/max)*10); i++) { bar=bar "#"; }
          printf "%25s %15d %s\n", $2, $1, bar;
      }'
}
