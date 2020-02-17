# * colors
# never set: (it gets handled somehow)
# export TERM=xterm-256color

# ** the basic 8*2 colors 'regular and bold'
export cBLACK='\e[0;30m'
export cWHITE='\e[1;37m'
export cRED='\e[0;31m'
export cbRED='\e[1;31m'
export cGREEN='\e[0;32m'
export cbGREEN='\e[1;32m'
export cBROWN='\e[0;33m'
export cYELLOW='\e[1;33m'
export cBLUE='\e[0;34m'
export cbBLUE='\e[1;34m'
export cPURPLE='\e[0;35m'
export cbPURPLE='\e[1;35m'
export cCYAN='\e[0;36m'
export cbCYAN='\e[1;36m'
export cGRAY='\e[1;30m'
export cbGRAY='\e[0;37m'
export cINV='\E[7m' # invert
export cEND='\e[0m' # end colored text.
export CLICOLOR=1
export LSCOLORS=ExFxCxDxBxegedabagacad

# ** color sequences
# color sequences in a prompt need to be ended individually
# or bash gets confused about the true length of the prompt
# which messes up the display when scrolling through history.

# elsewhere, you can just switch colors as you like and end
# all the colors with a single $cEND
