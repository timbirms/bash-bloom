# * Shared.BASH                                            :ignore:
#!/bin/bash
# ** [[elisp:(org-content 2)][d2]] [[elisp:(org-content 3)][d3]] [[elisp:(org-content 4)][d4]] [[elisp:(org-content 5)][d5]]                                          :ignore:
# #+TITLE:      Shared.bash
# #+SUBTITLE:   Functions for bash scripts
# #+AUTHOR:     Michael Ax
# #+EMAIL:      MichaelAx@gmail.com
# #+STARTUP:    headlines
# #+OPTIONS:    tex:verbatim ^:nil
# #+EXPORT_FILE_NAME: /home/opt/.out/shared-bash

# # +HTML_HEAD: <link rel="stylesheet" href="lib/css/styles.css" type="text/css" />
# #+OPTIONS:    toc:2 prop:t pri:t p:t stat:t tags:t tasks:t

# # +INFOJS_OPT: view:showall toc:2
# # +INFOJS_OPT: path:"lib/js/org-info-min.js"
# # +HTML_HEAD: <link rel="stylesheet" href="lib/css/stylesheet.css" type="text/css" />
# ** Includes
#sourcing the profile colors to aid the linter. hmm.
source colors.bash

# ** Usage
# # use $0 like this:
# source /home/opt/ubin/shared.bash
# set-default-flags

# # with either error-trapping choice
# # provide a replacement cleanup method

# ende() { return $1; }

# # and choose the simple kill/quit handler
# # which is usually all you need for a script-finalizer.
# set-exit-traps

# # or the RETURN EXIT & ERR handling set-all-traps handler.
# # this includes the functionality of set-exit-traps and
# # lets a function trap its own exit on return/exit or err.
# # rename to 'finally'.
# # requires that you provide a __trapall function from which
# # the return etc hooks are unbound. deref vars from there if
# # you need more than one function-finalizer (no exit involved).

# __trapall() { set-all-traps -; return $?; }
# set-all-traps


# ** Exports
# and more about them all
export REPLY=""
export retval=${retval:-0}        #retval is a global
export retmsg=""
export debug=${debug:-1}          # call debugon 0 to 'set -xv'
export notifyd_on=${notifyd_on:1} #start with zenity/notifications enabled

# ** Initializers
# library users would want to call these and a trap-handler from below.

set-default-flags () {
    #inspired by http://redsymbol.net/articles/unofficial-bash-strict-mode/
    set +e #exit on all non-zero return values. DONT want.
    set -u #alert when referencing undeclared vars. WANT.
    set -o pipefail # WANT.. using. yet testing $? anyway seems gooder.
    set -o emacs # or vi. whatever. needs to be set in order to use 'bind' without warnings.
    #IFS=$'\n\t'  #safer IFS fallback, dont split on space. LIKE to have.
}

# ** Stubs
# library users would define their own versions of these function to replace these.
# *** ende()   - usually silent errror-exit reserved by set-exit-traps.
# letting the rest of the world know about your demise.

ende(){
    [ -n "${2:-}" ] && echo "ende: $2" 1>&2
    exit "${1:-0}"
}
# ende () {
#	msg-step "$1" -----
#	exit "$1"
# }

# *** errorexit()  - signal an error and exit with failure-status
errorexit(){
    local retval=1
    local prefix=""
    [ "0" == "$1" ] && retval=$1 && shift
    [ "0" -ne "$retval" ] && prefix="ERROR: "
    [ -n "$1" ] && myecho "$prefix$*" && echo
    exit "$retval"
}


# ** Trap-Handlers
# *** Note
# `kill -l` lists all posix signals.

# these are the most common aliases:
# | SIGHUP  |  1 | Hang up, parent process is gone.                      |
# | SIGINT  |  2 | interrupt signal (Ctrl + C)                           |
# | SIGQUIT |  3 | quit signal (Ctrl + D)                                |
# | SIGFPE  |  8 | Floating point error                                  |
# | SIGKILL |  9 | quit immediately without clean-up                     |
# | SIGALRM | 14 | Alarm clock signal (used for timers)                  |
# | SIGTERM | 15 | Software termination signal (sent by kill by default) |
# *** all-traps    'for some notion of all trap', insure that an 'ende' function is called.
# - param '-' removes the traps
# - reserves '__trapall' as name for what it wants to use as a global error-handler.
set-all-traps () {
    if [ "${1:-}" == "-" ]; then
        set-exit-traps
        trap - RETURN
        trap - EXIT
        trap - ERR
    else
        set-all-traps -
        #shellcheck disable=SC2048
        for t in $* SIGHUP SIGINT SIGTERM; do
            #echo trap '__trapall;' $t
            trap '__trapall;' $t
        done
    fi
}

# *** exit-traps    simple, trap-setter triggering an 'ende' function.
set-exit-traps () {
    #provide a way out of running shell scripts.
    trap 'echo trap-hup; ende 1'   SIGHUP
    trap 'echo trap-int; ende 2'   SIGINT
    trap 'echo trap-term; ende 15' SIGTERM
}

# *** code-fragments
# #debugps4(){ echo "(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }" $@ }
# #
# #function trap-debug  { echo trap-debug.  }; trap trap-debug   DEBUG
# #+end_src
# https://seasonofcode.com/posts/debug-trap-and-prompt_command-in-bash.html #technique
# http://stromberg.dnsalias.org/~strombrg/PS0-prompt/                       # and its limits
#
#function trap-return { echo trap-return. }; trap trap-return  RETURN
#
#function trap-err {
#	local rv=$?
#	echo "(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}($@): }" "\$?=$rv:trap-err. '$here'"
#	return 0
#}; trap trap-err    ERR
#
#trap -p

# ** myBash
# *** Note
# this sub-module
# - provides generic idioms for use in bash programming.
# - it reserves as globals the following state variables:
#   - rv -- integer for passing status-codes.
#   - out -- string holding last subshell output.
#   - ready -- a tokenized expression run through a subshell. may contain pipes.
# - by way of idioms it provides:
#   - try -- evals what you give it and returns the status-code.
#     - eval just messes with the strings like run does and it has very little
#       impact on performance. noo judgements. try it.. and then just use eval sometime.
#   - istrue -- signals the boolean state of a named var. for 'if' clauses.

# *** Globals
declare -i  rv                                # global 'last return value' - bool int
declare -x  out                               # global 'last subshell output' - string

# *** Idiomatics
# **** istrue()
istrue(){                                     # test if the variable returns 'true'
    #$1- name of var with integer-value
    declare -n x="${1:-rv}"
    return "$x"
}
# **** isrvtrue()
isrvtrue(){                                   # test $?s 'true'
    rv=$?
    return "$rv"
}
# **** try()
try(){                                        # run function and set rv.
    #$@- statement-to-run                     # best used to catch status-codes in an 'if'!
    declare statement="${*}";
    if [ -z "${statement}" ]; then
        rv=1;
    else
        #shellcheck disable=2086
        eval $statement;
        rv=$?;
    fi;
    return "$rv";
}

# ** Debug-aids
# *** debugon/debugoff()
# control debug-flags along with a variable to enable conditional output/exec during development.
# - option to make '-v' conditional?
debugon(){
    debug=${1:-0}
    if istrue debug; then
        export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
        set -xv
    else # elif [[ $debug = 1 ]]; then
        set +xv
    fi
}
debugoff(){
    debugon 1
}

# *** debugout()
# conditional text
# - might be sensible to give it an option to use eval on the remaining params.

debugout(){
    if istrue debug; then
        echo "$@" 1>&2
    else
        :
    fi
}
# *** debugme()
# conditional execution
# - might be sensible to give it an option to use eval on the remaining params.
debugme(){
    if istrue debug; then
        "$@"
    else
        :
    fi
}
# ** Permissions-check
# *** assert-root()
assert-root(){
    if [ "$(id -u)" -ne 0 ]; then
        echo "${0##*/}: needs root access!"
        exit 1
    fi
}

# ** File and disk related

# *** script's path
# #+begin_src emacs-lisp
# script-path(){
#   declare -n var="$1"
#   pushd "$(dirname "$(readlink -f "$BASH_SOURCE")")" > /dev/null && {
#     var="$PWD"; popd > /dev/null ; }
# }
# #+end_src

# *** TEMP-FILE name-generation functions
# needs a trap to insure that the temp file is killed!

tmpfilename(){
    # makes up a name and path for a temp-file.
    # to be stored on ram-disk, in shared memory, or the tmp dir.
    #
    # usage: local a=$(tmpfilename ${BASH_SOURCE})
    # alternative: tmpfilename ${BASH_SOURCE} a
    # (both assign to a. main pattern allows for 'local')
    local base; base=$(basename "${1:-${BASH_SOURCE[0]}}")
    local tmpf="tmp-$base.$$"
    if [ -d "/ram" ]; then			tmpf="/ram/$tmpf"
    elif [ -d "/dev/shm" ]; then	tmpf="/dev/shm/$tmpf"
    else							tmpf="/var/tmp/$tmpf"
    fi
    [ -n "$2" ] && eval "$2=$tmpf" || echo "$tmpf"
}
# *** disk/file functions
is-mounted(){
    #echo $1 && mount | grep "$1 "
    mount | grep "$1 " >>/dev/null
    retval=$?
    [ $retval -eq 0 ] && retmsg="(is mounted)" || retmsg="(not mounted)"
}

mymkdir(){
    [ -n "$1" ] && [ ! -d "$1" ] && echo mkdir -p "$1" && mkdir -p "$1"
}
# **** mkdestdirs()
# make sure the subdirs of a path are there

function mkdestdirs () {
    #$1- root to check, with trailing /
    #$rest - list of paths to check/make
    local dest=$1
    local pn p
    shift
    for pn in "$@"; do
        p="${dest}${pn}"
        [ ! -d "${p}" ] && mkdir "${p}"
    done
}

# *** tcp-get
# tcp-get <url>

tcp-get(){
    #$1- http://<host>/query
    #$2- port:-80
    # parse
    local host query
    # ignoring proto z
    IFS=/ read -r _ _ host query <<< "${1:-localhost}"
    # open
    exec 3< "/dev/tcp/$host/${2:-80}"
    # write
    {
        echo "GET /$query HTTP/1.1"
        echo "connection: close"
        echo "host: $host"
        echo
    } >&3
    # read
    cat <&3
}



# ** Reading standard-input
# *** input processors

foreachp(){
    # process and print the input lines one by one.
    # callees, use nameref $1: fun(){ declare -n var=$1; ... }
    [ "${#1}" -gt 0 ] && while read -r
      do $1 REPLY; echo -e "$REPLY"
      #do set -x;  $1 REPLY; echo -e "$REPLY" ; set -x
    done
}

foreach(){
    # process the list of files one by one.
    # callees, process $1: fun(){ declare val="$1"; ... }
    [ "${#1}" -gt 0 ] && while read -r
      do $1 $REPLY
    done
}

# *** input readers

read-into(){
    # set var to output of shell command
    # append all lines
    declare -n var=$1; var=""
    shift; declare cmd="$*"
    while read -r
      do if [ "${#var}" = "0" ]; then var="$REPLY"; else var="$var\n$REPLY"; fi
    done <<<"$(eval $cmd)"
    # shell check disable=SC2086 - ignore linter msg above. syntax does not allow directive to be placed.
}
# ** Stream convsersions
# *** values into b64 digits
# ok.. this is the standard: https://www.ietf.org/rfc/rfc4648.txt
# used here is this a non-standard b64 charset.. and its value-list.
declare b64="0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz+="
declare -A r64=(); for ((i=0;i<${#b64};i++)); do r64["${b64:$i:1}"]="$i"; done

# interpret an array of numbers as digits of a number up to base64
stringlist-as-string64(){
    #base-translation for bc/obase>10 output. handles up to base=64
    #b64 is not in standard order. is has caps first for b16 compatibility with bc.
    declare a o="" i j  # expecting $1="01 12 42"
    read -r a || return 1
    for i in $a; do
        j="$i"
        if [ "${j:0:1}" = "0" ]; then j="${j:1}"; fi
        o="$o${b64:$j:1}"
    done
    echo $o
}
# ** String functions
# *** using nameref
# **** generic trim routines with explicit names

chs-after-initial(){ declare -n a=$1; declare -i i=0 n1=${#a} n2=${#2};
  if [ "$n2" -eq 0 ]; then return 1; fi
  for ((;i<n1;)); do if [ "${a:$i:$n2}" = "$2" ]
     then i=$((i+n2)); else a="${a:$i}"; return ; fi
  done
}

chs-before-final(){ declare -n a=$1; declare -i i=0 n1=${#a} n2=${#2};
  if [ "$n2" -eq 0 ]; then return 1; fi
  for ((i=n1-n2;i>0;)); do if [ "${a:$i:$n2}" = "$2" ]
     then i=$((i-n2)); else i=$((i+n2)); a="${a:0:$i}"; return ; fi
  done
}

# **** character oriented trim routines defaulting to 'space'.

chs-triml(){ chs-after-initial "$1" "${2:-" "}"; }
chs-trimr(){ chs-before-final "$1" "${2:-" "}"; }
chs-trim(){ chs-triml "$1" "${2:-" "}"; chs-trimr "$1" "${2:-" "}"; }

# **** substring matching 'trim' routines

chs-upto(){ declare -n a=$1; a="${a%%$2*}"; }
chs-upto_(){ set -x; declare -n a=$1; echo "$a"; a="${a%%$2*}"; set +x ; }

chs-upto-last(){ declare -n a=$1; a="${a%$2*}"; }

chs-after(){ declare -n a=$1; a="${a#*$2}"; }
chs-after-last(){ declare -n a=$1; a="${a##*$2}"; }

# *** instring( string, char) -- is char in string 0/1?
# true if char (default @) is in the string.
# really, the semantics should be ${string/${substring}}<>${string} in bash4.

# but.. we're abusing $rv to track the position of the [first] instance of char.
# if the char's not found, rv will be the string length.

instring(){
    local -i n="${#1}"
    local    a="${2:-"@"}"
    for ((rv=0;rv<n;rv++)); do
        [ "${1:$rv:1}" == "$a" ] && return 0
    done
    return 1
}
# *** gethostpart()
# where i might as well have used a regexp
# intended to pull just the host from an ssh login [user@host[:path]]

gethostpart(){
    # 0/1 assert that there's a hostname in $1
    # return the host-name in $REPLY if there is one.
    REPLY=""
    [ -z "$1" ] && return 1
    # assert user@
    if ! instring "$1" "@" ||  [ $rv -eq 0 ]; then return 1; fi
    # and that there's something following that
    rv+=1
    if [ $rv -eq "${#1}" ]; then return 1; fi
    #now it gets interesting
    local srv=${1:$rv}
    if instring "$srv" ":"; then
        REPLY=${srv:0:$rv}
    else
        REPLY="$srv"
    fi
    return 0
}
# *** givetrailingslash()

# ugh, use nameref
givetrailingslash(){
    # modifies var named in $1 to have a trailing slash. always true
    local  val="${!1}"
    local -i n="${#val}"
    [ "${val:$n-1:1}" != "/" ] && eval "$1=$val/"
    return 0
}
# ** Character functions
# *** chr() and ord()
chr() {
    # the character for the octal form of the integer in $1
    #shellcheck disable=SC2059
    printf "\\$(printf '%03o' "$1")"
}

ord() {
    # the decimal value of the quoted char
    printf '%d' "'$1"
}
# *** repeat-char()
repeat-char(){
    local num=$1
    [ "$1" -lt 0 ] && return
    local char=${2:--}
    if [ " " == "$char" ]; then
        # the space printed to the fixed width
        printf "%${num}s"
    else
        # spaces printed to a fixed width, replaced with the char
        printf "%${num}s" | sed "s/ /${char}/g"
    fi
}

# ** Integer-functions
# *** is-integer()
is-integer() {
    #> 0 - yes.
    #> 1 - no.
    #! clobbers the value of global 'out' with the numeric value as a side-effect
    #  provide $2 to store it elsewhere.
    #the retval of the built-in's strtoint() library call.
    printf -v "${2:-out}" "%d" "${1:-}" 2>/dev/null
}


# *** sqrt and log
# limited to integers but useful to give a script a quick idea.
# via http://phodd.net/gnu-bc/bcfaq.html

sqrt(){ local x=$1 s=$1 os=0;while ((s!=os));do os=$s;s=$(((s+x/s)/2));if((s>os));then s=$os;fi;done;echo "$s"; }
log() { local x=$1 n=2 l=-1;if [ "$2" != "" ];then n=$x;x=$2;fi;while((x));do let l+=1 x/=n;done;echo $l; }

# ** Out-putting


# *** ANSI codes
# unspecific enough to work in xterm and all our consoles.

# **** ANSI colors

#(already sourced at top)
#source /home/opt/ubin/profile.d/colors.bash

# *** ANSI control codes

export cCLR="\e[K"   # clear to end of line
export cCLL="\e[1K"  # clear to start of line

# *** ANSI adverbs
xterm_clear() { echo -e -n "\e[2J"; }
xterm_clear_eol() { echo -e -n "$cCLR"; }
xterm_clear_line() { echo -e -n "\r$cCLR"; }

xterm_line_up() { echo -e -n "\e[${1:-1}A"; }
xterm_line_down() { echo -e -n "\e[${1:-1}B"; }
xterm_line_right() { echo -e -n "\e[${1:-1}C"; }
xterm_line_left() { echo -e -n "\e[${1:-1}D"; }

xterm_save_curpos() { echo -e -n "\e[s"; }
xterm_rest_curpos() { echo -e -n "\e[u"; }
xterm_set_curpos() { echo -e -n "\e[${1:-0};${2:-0}H"; }

xterm_active_rows() { echo -e -n "\e[${1:-1};${2:-$LINES}r"; }
# *** XTERM/status update function

# pass a string as $1 and get a decent looking terminal title.
# requires that you use the debug wrappers
# if you want to stay in debug mode after calling this!

xterm_title(){
    set +xv
    case "$TERM" in
        xterm*|rxvt*)
            local a=""
            if [ -n "$UV_XTT" ]; then
                a=${UV_XTT/\\u/$USER}
                a=${a/\\h/$HOSTNAME}
                a=${a/\\w/$(pwd)}
                a=${a/\\t/$(date +%H:%M:%S)}"  "
            fi
            echo -ne '\e]2;'"$a$1"'\a'
            ;;
        *)  ;;
    esac
    debugon "$debug"
}

# *** Things that write to the screen
# **** MINI-MESSAGE
#  required by the exit-traps.

# #!/bin/bash
# # ** SAMPLE OF NESTED STEPS
# source /home/opt/ubin/shared.bash
# set-exit-traps
# msg-step 1 3 . abc
# msg-step 1 3 . bcd
# msg-step 2 3 . bcd
# msg-step 3 3 . bcd
# msg-step 0 -----
# msg-step 2 3 . abc
# msg-step 3 3 . abc
# msg-step 0 -----

# **** somewhat enables nesting.
# requires that you close a sequence of calls to msg-step with one passing a '0'
export msgstepdepth=-1
# **** msg-step
msg-step(){
    # msg-step(i [n cmd [msg]]):
    #  shows >[i/n] --------- cmd< (where the length of the [i/n] part is up to you to track)
    #  shows >i + --- script-name< (where i would be as long as [1/n] was.
    local aborting=0
    local pre
    local msg
    local cmd=""
    #
    # work out how to signal where we are
    if [ "$1" != "0" ]; then
        [[ $2 =~ [0-9]* ]]
        [ -n "${BASH_REMATCH[0]}" ]
        aborting=$?
        [ "$1" == "1" ] && msgstepdepth=$(( msgstepdepth + 1 ))
    fi
    if [ "$aborting" -ne 0 ]; then
        msg="${0##*/} aborting/${cbPURPLE}${1}${cEND}."
        pre="$2"
        msgstepdepth=-1
    elif [ "$1" == "0" ]; then
        msg="${0##*/} done."
        pre="$2"
        msgstepdepth=$(( msgstepdepth - 1 ))
    else
        pre="[$1/$2]"
        cmd="$3"
        [ "." == "$cmd" ] && cmd=""
        msg="${4:-$cmd}"
    fi
    # signal where we are
    pre="$(repeat-char $msgstepdepth)$pre"
    echo -e "${cGREEN}${pre}-------------------------- ${msg}${cEND}"
    # nothing more to do? done.
    [ -z "$cmd" ] && return 0
    # run the command and insure that we exit this script if it fails.
    $cmd
    aborting=$?
    [ "$aborting" -ne 0 ] && ende "$aborting"
}
# *** NOTIFICATIONS
# in flux. exploring dunst to replace the xfce4-notifyd crasher
# with something that can stay running by itself.

# **** fixnotifyd()
fixnotifyd(){
    if [ -n "$DISPLAY" ] && [[ $notifyd_on = 1 ]];  then
        local d="/usr/lib/x86_64-linux-gnu/xfce4/notifyd/xfce4-notifyd"
        #shellcheck disable=SC2009
        #shellcheck disable=SC2126
        if [ $(( $(ps aux | grep $d | wc -l) -1 )) -lt 1 ]; then
            $d&
            sleep 0.5
            return $?
        fi
    fi
    return 1
}
# **** mynotify()
# i hate this so much
# zenity keeps crashing and yet i still need these bits.
# replace with the friggn cow for all i care.

mynotify(){
    [ -z "$DISPLAY" ] && return 1 # x isnt running
    [[ $notifyd_on = 0 ]] && return 1 # notifyd_on off
    zenity --notification --text "$@" #2>&1 >>/dev/null
    if [ $? -ne 0 ]; then
        fixnotifyd
        [ $? -eq 0 ] && zenity --notification --text "$@" #2>&1 >>/dev/null
    fi
    if [ $? -ne 0 ]; then
        echo "(Notifyd_On reported error, disabling)"
        echo
        notifyd_on=0
    fi
}

if [[ $notifyd_on = 1 ]]; then
    fixnotifyd || notifyd_on=0            #notifyd_on=1  # assert daemon, disable on error
fi

# **** ECHO with notify
# notifies by echoing messages to the console and/or xcow
# - reads params in sequence. e.g. -x must come after -t etc.
# - will echo control codes to the terminal. use with -c to make console-exclusive.
# - -d will render png/svg/etc in the bubble. give it a path. turns off console output.
# - -{t,s,f} will render via the console and xcow. add -x to make x-exclusive.
# - and -b is for 'big', using figlet to output multiline ascii.

# you can pass a mess of parms to xcow and figlet before the text if you like.
# and hey, dont use ansi codes unless you're just printing to the console!

myecho(){
    local cow=xcowthink xonly=1
    if [ "$1" = "-t" ]; then shift; fi
    if [ "$1" = "-s" ]; then shift; cow=xcowsay; fi
    if [ "$1" = "-d" ]; then shift; cow=xcowdream; fi
    if [ "$1" = "-f" ]; then shift; cow=xcowfortune; xonly=0; fi
    # output on proper channels.
    if [ "$1" = "-c" ]; then shift; cow=""; fi
    #shellcheck disable=SC2034
    if [ "$1" = "-x" ]; then shift; xonly=0; fi
    if [ "${#cow}" -ne 0 ]; then ( $cow "$@" & ); fi
    if ! istrue xonly && [ "$cow" != "xcowdream" ]; then
        if [ "$1" = "-b" ]; then
            shift;
            figlet "$@"
        else
            echo -e "$@"
        fi
    fi
}

# ** User-interactions

# *** Exports
# exporting the 'a global' REPLY makes it 'the global' REPLY.
# - that's great for sharing.
export REPLY=""
# *** ECHO and wait for user
mywait(){
    [ -n "$1" ] && echo "$@"
    echo [Enter] to start
    read -r
}

# *** Single char input

# **** char-waiting()
# a terminal lookahead-reader.
char-waiting(){
    #> 0 - yes, char is in $REPLY (read through the non-zero timeout)
    #> 1 - no
    read -rsn1 -t0.001
}

# **** inkey()
# single char input capable of handling all(?almost?) Ctrl-codes
# of course it recognizes \n. limit chars by the params you pass,
# the key pressed will be in $REPLY.  see code for retval rules.

inkey(){
    #$1-list of chars to accept
    # returns the number's value if it only had digits to pick from.
    #$2-optional truelist of chars representing true
    # with 'true-chars', it return 0/1 to signal truthyness.
    #
    while true; do
        # read single chars silently into 'c'
        IFS="" read -rsn1
        #[ "$c" == "\n" ] && echo enter
        # one? can't read \n with read.
        #[ "$(printf "\x0a")" == "$c" ]
        #[ "$(printf "\x0a")" == "$REPLY" ]
        #if [ "$REPLY" = " " ]; then echo "SPACE"; fi
        #if [ "${#REPLY}" -eq 0 ]; then echo "ENTER"; fi
        if [ "${#REPLY}" -eq 0 ]; then REPLY="\n"; fi

        if [ "${1:-}" = "" ]; then
            return 0
        elif [ "${1/$REPLY}" != "$1" ]; then
            break
        else
            :
        fi
        #echo "READ: ${#REPLY}:$REPLY:"
    done
    if [ -z "${2:-}" ]; then
        if is-integer "$1"; then
            # with all keys numbers, return value
            return "$REPLY"
        fi
        #echo "$REPLY"
        return 0
    fi
    # with a true/false list check if what we choose was value from the truelist
    [ "${2/$REPLY}" != "$2" ]
    return  $?
}

# echo inkey  asdynAS
# inkey  asdynAS
# echo $?
# echo inkey  asdynAS aA
# inkey  asdynAS aA
# echo $?
# echo inkey  1234567890
# inkey  1234567890
# echo $?
# exit 0
# *** Line Editing
# Requires Bash >= 4.0 for read -i and ${!name}
((BASH_VERSINFO[0] >= 4)) || return

# **** Edit variable
# from https://sanctum.geek.nz/arabesque/shell-config-subfiles/
# via https://sanctum.geek.nz/cgit/dotfiles.git/tree/bash/bashrc.d

# Edit named variables' values
ui_vared() {
    #$1 - name of var to edit
    # if you want a prompt, set it via '-p prompt'
    # unbinds ^L for the duration of the line-edit so that forms wont get messed up by it.
    local __opt __prompt=""
    local OPTERR OPTIND OPTARG
    while getopts 'p:' __opt ; do
        case $__opt in
            p)
                __prompt=$OPTARG
                ;;
            \?)
                printf 'bash: %s: -%s: invalid option\n' \
                    "${FUNCNAME[0]}" "$__opt" >&2
                return 2
                ;;
        esac
    done
    shift "$((OPTIND-1))"
    #
    __prompt=( "-p" "${__prompt:-"${1}="}" )
    #
    if ! (($#)) ; then
        printf 'bash: %s: No variable names given\n' \
            "${FUNCNAME[0]}" >&2
        return 2
    fi
    #
    local name
    bind -r '"\C-l"'
    if ! isrvtrue; then exit $rv; fi

    for name ; do
        IFS= read -e -i "${!name}" "${__prompt[@]}" -r -- "$name"
    done
    bind '"\C-l": clear-screen'
}


# **** line editing with feedback

# ***** formatting
ui_edifinal(){  echo -e -n "\r${cWHITE}${cINV}$1 ${cEND}${cCLR} $2"; }
ui_edifoot(){  echo -e -n "\r${cBLUE}${cINV}${cYELLOW}>$1 ${2:-"?"}                         \r>$1 ${cEND}"; }
ui_edifoot-done(){ echo -e -n "\r${cWHITE}${cINV}$1  ${2:-}                       ${cEND}${cCLR}"; }
ui_edifoot-quit(){   echo -e -n "\r${cRED}${cINV}${1:-quit}                                   ${cEND}${cCLR}"; }

# ***** ui_edivar()
# like ui_vared, but with a droll background during the edit.
ui_edivar(){
    local txt="$1"
    declare -n var="$2"

    ui_edifoot "$txt"
    ui_vared -p "" "$2"
    if ! isrvtrue; then
        ui_edifoot-quit ""
        echo
        return $rv
    fi
    xterm_line_up 1
    ui_edifoot-done  "$txt" "$var"
    echo
}

# ***** ui_edilist()
# edit each var in turn. does not paint ahead or play with the cursor beyind what edivar does.
# nothing special besides the capability of editing just a few of the fields in its input array.
# - its used internally and works fine when called to wrap a few calls to edivar.

ui_edilist(){
    #$1-nameref array
    declare -n fields="$1"
    if [ -z "$2" ]; then
        for field in "${!fields[@]}"; do
            ui_edivar "${fields[$field]}" "$field"
            rv=$?; [ $rv -ne 0 ] && break
        done
    else
        for field in $2; do
            ui_edivar "${fields[$field]}" "$field"
            rv=$?; [ $rv -ne 0 ] && break
        done
    fi
}

# ***** ui_ediform()
# paint a form on the screen with all edit-fields
# then jumps to top and do a single run through the fields before returning.
ui_ediform(){
    #$1-nameref array
    #$2-list/order of fields
    # takes a couple of options that have to appear before the regular params:
    # -n   -- just paint, no edit.
    # -f   -- like -n but renders the fields as 'final' after an edit.
    local noedi; [ "$1" == '-n' ]; noedi=$?; [ $noedi -eq 0 ] && shift 1
    local final; [ "$1" == '-f' ]; final=$?; [ $final -eq 0 ] && shift 1
    # a painter is a simple parameterized output routine that does the details.
    local painter=ui_edifoot
    [ $final -eq 0 ] &&  painter=ui_edifinal
    # ok, grab a reference to the array we're to work with
    declare -n fields="$1"
    local -i n=0
    # and drive the output
    if [ -z "$2" ]; then
        # all fields alpha order
        for field in "${!fields[@]}"; do
            declare -n value="$field"
            $painter "${fields[$field]}" "$value"
            echo
            n+=1
        done
    else
        # fields in order of param
        for field in $2; do
            declare -n value="$field"
            $painter "${fields[$field]}" "$value"
            echo
            n+=1
        done
    fi
    # unless we're done done, now to the top of what we just painted and start editing!
    [ $noedi -eq 0 ] && return 0
    [ $final -eq 0 ] && return 0
    xterm_line_up "$n"
    ui_edilist "$1" "$2"
}

# *** Multi-line editing
# **** edisess()
# simple edit as new, until you accept what's there.

edisess(){
    #$1-nameref array
    #$2-list/order of fields
    local -i n
    while true; do
        ui_ediform "$1" "$2"
        #ediem2 r "device alias ring"
        if accept -n "Values"; then
            break
        else
            n=0; for field in $2; do n+=1; done
            xterm_line_up "$n"
        fi
    done
    echo
}

# **** edisess2()
# edit session wrapped with 'accept/cancel/edit editing'
# custom prompts?

edisess2(){
    local new; [ "$1" == '-n' ]; new=$?; [ "$new" -eq 0 ] && shift 1
    # edit a fieldset with confirmation menu
    # -n will begin editing a 'new' record
    # without -n get a confirmation menu before being made to edit.
    #
    #$1-nameref array
    #$2-list/order of fields
    local -i n=0; for field in $2; do n+=1; done
    local -i rv=0
    [ "$new" -ne 0 ] && ui_ediform -n "$1" "$2"
    while true; do
        [ "$new" -eq 0 ] && ui_ediform "$1" "$2"
        make_choice -n "a)ccept c)ancel e)dit: " " ae" cq
        rv=$?; [ $rv -ne 0 ] && break
        [ "$REPLY" != "e" ] && break
        xterm_clear_line        # remove interaction
        xterm_line_up "$n"      # and start again from the top
        [ "$new" -ne 0 ] && ui_ediform "$1" "$2"
    done
    if [ $rv -eq 0 ]; then
        # draw a finalized version of the form
        xterm_line_up "$n"
        ui_ediform -f "$1" "$2"
        xterm_clear_line  # free up interaction line and stay on it.
        return $rv
    fi
    echo                  # leave the interaction line negative exit status visibly in place
    return $rv
}
# *** Menus
# Why do these even exit??
# - because they do not wipe out and take over the screen
# - because they do not take control and force actions on you
# - because they work with single/least keys, save space and look ok+.

# - or, because, in the case of the dmenu wrapper, they just look
#   better while taking over X's focus and drawing on top of whats there.

# **** X11/dmenus
# ***** ui_dmenu()
# useful and almost good.
# - needs to know when its being piped to!

ui_dmenu_params=("-i" "-b" "-fn" 'Pragmata Pro-18')
ui_dmenu_vert=1

# is blocking because dmenu works through x irrespective of what terminal
# triggered the task.

# DONT use to bring up any interactive 'end-of-script' questions .. you never know
# when they get triggered and would block further input without guaranteeing that
# you see the demand for it

# https://tools.suckless.org/dmenu/ has all sorts of patches, none i'd use? .. and
# the only workaround i see it just making the menu take over-full screen. but
# then i'd have better looking alternatives that stick to their terminal.  very
# useful with that caveat in mind!

# trigger/use from through .desktops to stay in the same mode as the caller and
# avoid the need for a terminal like the 'pick' util.

ui_dmenu(){
    local vert=""
    if [ $ui_dmenu_vert -eq 0 ]; then
        vert="-l $(($1-1))"
        shift
    fi
    #shellcheck disable=SC2086
    echo -e "$@" | dmenu "${ui_dmenu_params[@]}" $vert -p "$(basename "${0^^}")"
}

# **** Multi-line menu
# numerically pick colored choices

# ***** ui-visuals
# prints simple, fuzzy & 'obvious' state for the menu and choice.

# printed bounded by reverse text lines
# top line initially longer than bottom
# bottom line longer after selection is made
ui_head1(){  echo -e "\r${cWHITE}${cINV}${1:-}                             ${cEND}${cCLR}"; }
ui_foot1(){  echo -e -n "\r${cWHITE}${cINV}                              ${cCLR}\r#?\r#${cEND}"; }
ui_foot-done(){ echo -e "\r${cWHITE}${cINV}Selected: $1: $2                       ${cEND}${cCLR}"; }
ui_foot-quit(){   echo -e "\r${cRED}${cINV}${1:-quit}                                   ${cEND}${cCLR}"; }

# ***** ui_show1()
# There's a list of choices, starting with a count in the params.
# Renders each choice and leaves the cursor on a formatted line at the bottom.

ui_show1(){
    local -i n="${#@}"
    local -i i=0
    # output and load
    while ((i<n)); do
        i+=1
        echo -e "${i}: ${cGREEN}${1}${cEND}"
        shift
    done
    # show the footer
    ui_foot1
}
# ***** ui_getkeys1()
# Takes a list of choices and waits for you to press or enter a number for one of them.
# - switches between single and multi-char input.
# - if you enter an invalid number for a choice, you get to try again.
# - choice becomes the exit-status or its 255, aka -1 for bad-input

ui_getkeys1(){
    local c
    local -i i=0
    local -i n="${#@}"
    # and process keystrokes
    while true; do
        if [ $n -lt 10 ]; then
            # read single chars silently into 'c'
            read -r -s -n1 c
            #echo "READ: ${#c}:$c:"
        else
            read -r c
        fi

        # non-numeric?
        if ! is-integer "$c" c; then
            i=255
            break
        else
          i=$((c))
        fi

        # see if its in the right numeric range
        if [ "$i" -ge 1 ] && [ "$i" -le "$n" ]; then
            break
        fi

        # invalid number? sure, go again.
    done

    # finally done. return the number.
    return "$i"
}

# On return, the caller can use shift $?-1 to get the chosen param.

# ***** ui_select

# takes the $@ param list, builds a menu for it and asks for a choice.

# - usually runs in non-blocking way by managing the io
#   - or runs your list through dmenu if you set this option:
ui_select_nonblocking=0   # 0-console/read; 1-dmenu, blocking while x waits for the input.

# result is alway 0/1 and the literal choice is in $REPLY.

# need/want it to
# - filter / multiselect-highlight style
# - so that i can finally type stuff without switching to using numbers.

ui_select(){
    if [ $ui_select_nonblocking -ne 0 ]; then
        local opts=""
        [ "$ui_dmenu_vert" -eq 0 ] && opts=${#}
        # transforms/guarantees the input elements to be \n delimited and calls dmenu
        REPLY="$(ui_dmenu "$opts" "$(while [ -n "${1:-}" ]; do echo "$1"; shift; done)")"
        return $?
    fi
    #
    REPLY=""
    local bn
    # make a choice from up to 9 elements
    #echo "${#@}"
    if [ ${#@} -eq 0 ]; then
        ui_head1 "Selected: EMPTY-SET"
        return 255
    fi
    if [ ${#@} -gt 9 ]; then
        ui_head1 "Selection has ${#@} choices:"
    else
        bn="$(basename "$0")"
        ui_head1 "${bn^^} Select:"
    fi
    # now do a select
    ui_show1 "$@"
    ui_getkeys1 "$@"
    #select x in "$@"; do break; done
    # produce return values
    rv=$?
    if ((rv<255)); then
        # map rv to text
        shift $((rv-1))
        ui_foot-done $((rv)) "${1:-}"
        REPLY="${1:-}"
    else
        bn="$(basename "$0")"
        ui_foot-quit "${bn^^} quit."
    fi
    return "$rv"
}

# ***** ui-test
#select1 "$@" || echo "$?: REPLY=${REPLY:-}"
#ui_select1 "$@" || echo "${REPLY}"
# **** single line menus
# non-obnoxious single line menus

# ***** make_choice()
# you pass a prompt and a list of keys for true-choices and false-exits.
# return the key in $REPLY and 0/1 tells you what list the key was
# - keys can include space and \n.

make_choice() {
    #set REPLY
    local nocr; [ "$1" == '-n' ]; nocr=$?; [ $nocr -eq 0 ] && shift 1
    #$1 prompt
    #$2 choice-keys
    #$3 quit-keys
    ui_edifoot "${1}"
    #set -x
    inkey "$2$3"
    rv=$?;
    set +x
    #xterm_line_up 1
    #set -x
    if [ "${2/$REPLY}" != "$2" ]; then
        ui_edifoot-done "${1} $REPLY"
    else
        ui_edifoot-quit ""
    fi
    [ $nocr -ne 0 ] && echo
    [ "${2/$REPLY}" != "$2" ]  # returns $?: was the accepted reply a yes?
}

# ***** accept()  - confirmation menu
# you pass a text prompt in $1 and get a 0/1 result.
accept() {
    #$1- prompt, description for what you're accepting here.
    #takes a '-n' parameter that tells it to stay on the current line on exit.
    local nocr; [ "$1" == '-n' ]; nocr=$?; [ $nocr -eq 0 ] && shift 1
    ui_edifoot "Accept ${1:-Value} (Y/n)"
    if inkey " \njJyYnNqQ" " \njJyY"; then
        ui_edifoot-done  "${1:-Value} Accepted."
        rv=0
    else
        ui_edifoot-quit "${1:-Value} Rejected."
        rv=1
    fi
    [ $nocr -ne 0 ] && echo
    return $rv
}

# ** qed.                                                 :ignore:
# ∎
