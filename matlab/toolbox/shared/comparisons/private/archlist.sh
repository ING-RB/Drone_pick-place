#
# usage:        archlist.sh
#
# abstract:     This Bourne Shell script creates the variable ARCH_LIST.
#
# note(s):      1. This file is always imbedded in another script
#
# Copyright 1997-2013 The MathWorks, Inc.
#----------------------------------------------------------------------------
#
    ARCH_LIST='glnxa64 linux-arm-64 maca64 maci64'
#=======================================================================
# Functions:
#   check_archlist ()
#=======================================================================
    check_archlist () { # Sets ARCH. If first argument contains a valid
			# arch then ARCH is set to that value else
		        # an empty string. If there is a second argument
			# do not output any warning message. The most
			# common forms of the first argument are:
			#
			#     ARCH=arch
			#     MATLAB_ARCH=arch
			#     argument=-arch
			#
                        # Always returns a 0 status.
                        #
                        # usage: check_archlist arch=[-]value [noprint]
                        #
	if [ $# -gt 0 ]; then
	    arch_in=`expr "$1" : '.*=\(.*\)'`
	    if [ "$arch_in" != "" ]; then
	        ARCH=`echo "$ARCH_LIST EOF $arch_in" | awk '
#-----------------------------------------------------------------------
	{ for (i = 1; i <= NF; i = i + 1)
	      if ($i == "EOF")
		  narch = i - 1
	  for (i = 1; i <= narch; i = i + 1)
		if ($i == $NF || "-" $i == $NF) {
		    print $i
		    exit
		}
	}'`
#-----------------------------------------------------------------------
	       if [ "$ARCH" = "" -a $# -eq 1 ]; then
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
echo ' '
echo "    Warning: $1 does not specify a valid architecture - ignored . . ."
echo ' '
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	       fi
	    else
		ARCH=""
	    fi
	else
	    ARCH=""
	fi
#
	return 0
    }
#=======================================================================
