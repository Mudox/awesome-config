#!/bin/bash
# vim: filetype=sh foldmethod=marker

# Usage {{{1
function usage() {
cat <<EOF
awmtt [ start | stop | restart | -h | -e | -t [ get | change | list | random ]]
[ -C /path/to/rc.lua ] [ -D display ] [ -S windowsize ] [-o 'additional args to pass to awesome' ]

  start        Spawn nested Awesome via Xephyr
  stop         Stops Xephyr
    all        Stop all instances of Xephyr
  restart      Restart nested Awesome
  -N|--notest  Don't use a testfile but your actual rc.lua (i.e. $HOME/.config/awesome/rc.lua)
  -C|--config  Specify configuration file
  -D|--display Specify the display to use (e.g. 1)
  -S|--size    Specify the window size
  -e|--execute Execute command in nested Awesome
  -t|--theme   Control the current theme
  -o|--options Pass extra options to awesome command (i.e. -o '--no-argb')
    c|change     Change theme
    g|get        Get current themename
    l|list       List available themes
    r|random     Choose random theme
  -h|--help    Show this help text

examples:
awmtt start (uses defaults)
awmtt start -D 3 -C /etc/xdg/awesome/rc.lua -S 1280x800
awmtt -t change zenburn

The defaults are -D 1 -C $HOME/.config/awesome/rc.lua.test -S 1024x640.

EOF
exit 0
}
# }}}1

# Utilities {{{1
function awesome_pid() {
  pgrep -fn "/usr/bin/awesome"
}

function xephyr_pid() {
  pgrep -f "xephyr_$D"
}

function errorout() {
  echo "error: $*" >&2
  exit 1
}
# }}}1

# Executable check {{{1
AWESOME=$(which awesome)
XEPHYR=$(which Xephyr)
[[ -x "$AWESOME" ]] || errorout 'Please install Awesome first'
[[ -x "$XEPHYR" ]] || errorout 'Please install Xephyr first'
# }}}1

# Default Variables {{{1
# Display and window size

# DISPLAY setting.
D=1

# Xephyr screen size.
SIZE="1024x768"

# other options to be passed to Xephyr.
OPTIONS=""

# Path to rc.lua[.test]
if [[ -n "$XDG_CONFIG_HOME" ]]; then
  RC_FILE="$XDG_CONFIG_HOME"/awesome/rc.lua.test
else
  RC_FILE="$HOME"/.config/awesome/rc.lua.test
fi

# fallbak to the current rc.lua file.
[[ ! -f "$RC_FILE" ]] && RC_FILE="$HOME"/.config/awesome/rc.lua
[[ ! -f "$RC_FILE" ]] && errorout 'Can not find file: rc.lua.test or rc.lua.'

# Hostname Check - this is probably only useful for me. I have the same rc.lua running on two different machines
HOSTNAME=$(hostname)

# }}}1

# Core Functions {{{1

# Start {{{2
function test_start() {
  # check for free $DISPLAYs
  for (( i = 0; ; i++ )); do
    if [[ ! -f "/tmp/.X${i}-lock" ]]; then
      D=$i
      break
    fi
  done

  "$XEPHYR" -name xephyr_$D -ac -br -noreset -screen "$SIZE" :$D >/dev/null 2>&1 &
  sleep 1
  DISPLAY=:$D.0 "$AWESOME" -c "$RC_FILE" "$OPTIONS" &
  sleep 1

  # print some useful info
  if [[ "$RC_FILE" =~ '.test$' ]]; then
    echo "Using a test file ($RC_FILE)"
  else
    echo "Caution: NOT using a test file ($RC_FILE)"
  fi

  echo "Display: $D, Awesome PID: $(awesome_pid), Xephyr PID: $(xephyr_pid)"
}
# }}}2

# Stop {{{2
function test_stop() {
  if [[ "$1" == all ]]; then
    echo "Stopping all instances of Xephyr"
    kill $(pgrep Xephyr) >/dev/null 2>&1
  elif [[ $(xephyr_pid) ]]; then
    echo "Stopping Xephyr for display $D"
    kill $(xephyr_pid)
  else
    echo "Xephyr is not running or you did not specify the correct display with -D"
    exit 0
  fi
}
# }}}2

# Restart {{{2
function test_restart() {
  echo -n "Restarting Awesome... "
  for i in $(pgrep -f "/usr/bin/awesome -c"); do
    kill -s SIGHUP $i
  done
}
#}}}2

# Run {{{2
function test_run() {
  #shift
  DISPLAY=:$D.0 "$@" &
  LASTPID=$!
  echo "PID is $LASTPID"
}
# }}}2

# Parse options {{{2
function parse_options() {
while [[ -n "$1" ]]; do
  case "$1" in
    -N|--notest)
      RC_FILE="$HOME"/.config/awesome/rc.lua                                ;;
    -C|--config)
      shift
      RC_FILE="$1"                                                          ;;
    -D|--display)
      shift
      D="$1"
      [[ ! "$D" =~ ^[0-9] ]] && errorout "$D is not a valid display number" ;;
    -S|--size)
      shift
      SIZE="$1"                                                             ;;
    -h|--help)
      usage                                                                 ;;
    start)
      input='start'                                                         ;;
    stop)
      input='stop'                                                          ;;
    restart|reload)
      input='restart'                                                       ;;
    -e|--execute)
      input='run'                                                           ;;
    -o|--options)
      shift
      OPTIONS="$1"                                                          ;;
    *)
      args+=( "$1" )                                                        ;;
  esac
  shift
done
}
# }}}2

# }}}1

# Main {{{1
main() {
  case "$input" in
    start)
      test_start "${args[@]}"                      ;;
    stop)
      test_stop "${args[@]}"                       ;;
    restart)
      test_restart "${args[@]}"                    ;;
    run)
      test_run "${args[@]}"                        ;;
    *)
      echo "Option missing or not recognized"      ;;
  esac

}
# }}}1

[ "$#" -lt 1 ] && usage
parse_options "$@"
main
