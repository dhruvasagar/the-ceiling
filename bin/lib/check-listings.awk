# Emit one record per listing line to verify, for bin/check:
#   FILES<TAB>LINE   FILES is the comma-separated list from "# capture: ..."
#   ERR<TAB>REASON   a listing with no "# capture:" comment right above it
# Side-by-side listings (columns separated by 3+ spaces) are split into
# their columns. Elision lines ("..."), and a first line that only holds the
# column headers YJIT / ZJIT, are skipped. Only #+begin_example blocks are
# listings; #+results output blocks are not (they follow a "#+results:" line).

function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }

{
  if (!inblock && $0 ~ /^#\+begin_example/) {
    inblock = 1; first = 1
    if (prev ~ /^#\+results:/) { skip = 1 }
    else if (prev ~ /^# capture: /) { skip = 0; files = prev; sub(/^# capture: /, "", files); gsub(/[ \t]/, "", files) }
    else { skip = 0; files = ""; printf "ERR\tlisting without a source at line %d (add '# capture: FILE' above it)\n", NR }
    prev = $0; next
  }
  if (inblock && $0 ~ /^#\+end_example/) { inblock = 0; prev = $0; next }
  if (inblock && !skip && files != "") {
    line = trim($0)
    if (first && line ~ /^YJIT[ \t]+ZJIT$/) { first = 0; prev = $0; next }
    first = 0
    n = split($0, cols, /   +/)
    for (i = 1; i <= n; i++) {
      c = trim(cols[i])
      if (c == "" || c == "...") continue
      printf "%s\t%s\n", files, c
    }
  }
  prev = $0
}
