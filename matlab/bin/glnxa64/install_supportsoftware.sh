#!/bin/sh
#
# Name:
#    install_supportsoftware -  script file for invoking the Multi-platform installer on Linux.
#
#    Usage: install_supportsoftware [-h|help]
#                              [-matlabroot <directory>] |
#                              [-archives <directory>] |
#                              [-logfile <file>]
#                              -h|-help        - Display arguments.
#                              -matlabroot <directory>   - Must provide a path to MATLAB Installation location(matlabroot).
#                              -archives <directory>     - Override default support package directory.
#                              -logfile <file>           - To pass a matlab logfile.
#
#              The default settings when no override inputs are supplied are:
#              -archives = <directory containing this script>
#
#
# Copyright 2015-2024 The MathWorks, Inc.
#__________________________________________________________________________

    trap "exit 1" 1 2 3 15
#========================= archlist_template.sh (start) ============================
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
#========================= archlist_template.sh (end) ==============================
ARCH=
#========================= arch_template.sh (start) ============================
#!/bin/sh
#
# usage:        arch.sh
#
# abstract:     This Bourne Shell script determines the architecture
#               of the the current machine.
#
#               ARCH      - Machine architecture
#
#               IMPORTANT: The shell function 'check_archlist' is used
#                          by this routine and MUST be loaded first.
#                          This can be done by sourcing the file,
#
#                              archlist.sh
#
#                          before using this routine.
#
# note(s):      1. This routine must be called using a . (period)
#
#               2. Also returns ARCH_MSG which may contain additional
#                  information when ARCH returns 'unknown'.
#
# Copyright 1986-2016 The MathWorks, Inc.
#----------------------------------------------------------------------------
#
#=======================================================================
# Functions:
#   realfilepath ()
#   matlab_arch ()
#=======================================================================
    realfilepath () { # Returns the actual path in the file system
                      # of a file. It follows links. It returns an
                      # empty path if an error occurs.
                      #
                      # Returns a 1 status if the file does not exist
                      # or appears to be a circular link. Otherwise,
                      # a 0 status is returned.
                      #
                      # usage: realfilepath filepath
                      #
    filename=$1
#
# Now it is either a file or a link to a file.
#
    cpath=`pwd`

#
# Follow up to 8 links before giving up. Same as BSD 4.3
#
      n=1
      maxlinks=8
      while [ $n -le $maxlinks ]
      do
#
# Get directory correctly!
#
	newdir=`echo "$filename" | awk '
                        { tail = $0
                          np = index (tail, "/")
                          while ( np != 0 ) {
                             tail = substr (tail, np + 1, length (tail) - np)
                             if (tail == "" ) break
                             np = index (tail, "/")
                          }
                          head = substr ($0, 1, length ($0) - length (tail))
                          if ( tail == "." || tail == "..")
                             print $0
                          else
                             print head
                        }'`
	if [ ! "$newdir" ]; then
	    newdir="."
	fi
	(cd "$newdir") > /dev/null 2>&1
	if [ $? -ne 0 ]; then
	    return 1
	fi
	cd "$newdir"
#
# Need the function pwd - not the built in one
#
	newdir=`/bin/pwd`
#
	newbase=`expr //"$filename" : '.*/\(.*\)' \| "$filename"`
        lscmd=`ls -ld "$newbase" 2>/dev/null`
	if [ ! "$lscmd" ]; then
	    return 1
	fi
#
# Check for link portably
#
	if [ `expr "$lscmd" : '.*->.*'` -ne 0 ]; then
	    filename=`echo "$lscmd" | awk '{ print $NF }'`
	else
#
# It's a file
#
	    dir="$newdir"
	    command="$newbase"
#
	    cd "$dir"
#
# On Mac OS X, the -P option to pwd causes it to return a resolved path, but
# on 10.5 and later, -P is no longer the default, so we are now passing -P explicitly.
#
            if [ "$ARCH" = 'maca64' -o "$ARCH" = 'maci64' ]; then
                echo `/bin/pwd -P`/$command
#
# The Linux version of pwd returns a resolved path by default, and there is
# no -P option
#
            else
                echo `/bin/pwd`/$command
            fi
	    break
	fi
	n=`expr $n + 1`
      done
      if [ $n -gt $maxlinks ]; then
	return 1
      fi

    cd "$cpath"
    }
#
#
#=======================================================================
    matlab_arch () {  # Determine the architecture for MATLAB
                      # It returns the value in the ARCH variable.
                      # If 'unknown' is returned then sometimes a
                      # diagnostic message is returned in ARCH_MSG.
                      #
                      # Always returns a 0 status.
                      #
                      # usage: matlab_arch
                      #
        ARCH="unknown"
        
        HOST_ARCH="$ARCH"
        TARGET_ARCH="$HOST_ARCH"
#
        if [ -f /bin/uname ]; then
            case "`/bin/uname`" in
                Linux)
                    case "`/bin/uname -m`" in
                        x86_64)
                            HOST_ARCH="glnxa64"
                            TARGET_ARCH="$HOST_ARCH"
                            ;;
                        aarch64)
                            HOST_ARCH="linux-arm-64"
                            TARGET_ARCH="$HOST_ARCH"
                            ;;
                    esac
                    ;;
            esac
        elif [ -f /usr/bin/uname ]; then
            case "`/usr/bin/uname`" in
                Darwin)                                 # Mac OS X
                    case "`/usr/bin/uname -p`" in
                        i386)
                            HOST_ARCH="maci64"
                            TARGET_ARCH="$HOST_ARCH"
                            ;;
                        arm)
                            HOST_ARCH="maca64"
                            TARGET_ARCH="$HOST_ARCH"
                            
                            # Compute TARGET ARCH based on mode of install (Rosetta vs. native)
                            #   Note: If the use of `pwd` below doesn't return a valid matlab dir,
                            #         it means this script is running outside the matlab context,
                            #         so that's fine - it's why we default to the native arch above.
                            #         In other words, this code should not affect non-matlab use cases.
                            #
                            pwd_matlab_root=`pwd`
                            if [ -d "$pwd_matlab_root/bin/maci64" ]; then
                                if [ -d "$pwd_matlab_root/bin/maca64" ]; then
                                    # Use Case 1 :
                                    #   Both Intel and ARM binaries are present, 
                                    #   so default to the native arch
                                    TARGET_ARCH="maca64"
                                else
                                    # Use Case 2 :
                                    #   maci64 binaries are present but maca64 are not,
                                    #   which means we're in a Rosetta-based Apple silicon install
                                    TARGET_ARCH="maci64"
                                fi
                            fi
                            # Use Case 3 : (accounted for by default)
                            #   maca64 binaries are present but maci64 are not,
                            #   which means we're in a native Apple silicon install
                            
                            
                            ;;
                    esac
                    ;;
            esac
        fi
        ARCH="$TARGET_ARCH"
        return 0
    }
#=======================================================================
#
# The local shell function check_archlist is assumed to be loaded before this
# function is sourced.
#
    ARCH_MSG=''
    check_archlist ARCH=$ARCH
    if [ "$ARCH" = "" ]; then
        if [ "$MATLAB_ARCH" != "" ]; then
            check_archlist MATLAB_ARCH=$MATLAB_ARCH
        fi
        if [ "$ARCH" = "" ]; then
            matlab_arch
        fi
    fi
    Arch=$ARCH
#========================= arch_template.sh (end) ==============================

#========================= Launch MATLAB (start) ============================
    launchMATLAB() {

	#Reading in the arguments
	matlabInstallLoc=$1
	spkgLoc=$2
	instloc=$3
	mllogfile=$4
	extra=$5

	matlabLoc="$matlabInstallLoc/bin/matlab"

    # Preload glibc_shim in case of RHLE7 variants
    test -e /usr/bin/ldd &&  /usr/bin/ldd --version |  grep -q "(GNU libc) 2\.17"  \
            && export LD_PRELOAD="$LD_PRELOAD:$matlabInstallLoc/bin/glnxa64/glibc-2.17_shim.so"

	mllogfilecmd=""
	if [ "$mllogfile" != "" ]; then
		mllogfilecmd="-logfile $mllogfile"
	fi

	"$matlabLoc" "$mllogfilecmd" "-r  \"obj = matlab.internal.SupportSoftwareInstallerLauncher(); obj.launchWindow('INSTALLFROMFOLDER','$spkgLoc',$instloc); $extra ; clear obj;\""

    }
#========================= Launch MATLAB (end) ==============================

#
# Parse the arguments
#
    stat="OK"
    matlabroot=
    SETUP_FILE=`realfilepath "$0"`
    archives=`dirname "$SETUP_FILE"`
    logfile=""
    installLoc="matlabshared.supportpkg.getSupportPackageRoot"


#   Set default values for some variables if they are not set yet.

    while [ "$stat" = "OK" -a  $# -gt 0 ]; do
        case "$1" in
            -h|-help)
                stat=""
                ;;
            -matlabroot)
                if [ $# -eq 1 ]; then
                    echo "The MATLAB installation location must be specified with -matlabroot."
                    stat=""
                else
                    shift
                    matlabroot="$1";
                    if [ ! -d "$matlabroot" ]; then
                        echo "The directory $1 does not exist."
                        stat=""
                    else
                        # Remove all trailing slashes from matlabroot
                        matlabroot=$(echo $matlabroot | sed 's:/*$::');
                        matlabroot=`realfilepath "$matlabroot"`;
                        if [ ! -f "$matlabroot/bin/matlab" ]; then
                            echo "The $1 directory does not appear to be a valid MATLAB directory."
                            stat=""
                        fi
                    fi
                fi
                ;;
            -archives)
                if [ $# -eq 1 ]; then
                    echo "The support package directory must be specified with -archives."
                    stat=""
                else
                    shift
                    if [ ! -d "$1" ]; then
                        echo "The directory $1 does not exist."
                        stat=""
                    else
                        archives=$(echo $1 | sed 's:/*$::');
                        archives=`realfilepath "$archives"`;
                    fi
                fi
                ;;
            -logfile)
                if [ $# -eq 1 ]; then
                    echo "A file name must be specified with -logfile."
                    stat=""
                else
                    shift
                    logdir="$(dirname "$1")"
                    if [ ! -d "$logdir" ]; then
                        mkdir -p "$logdir"
                    fi
                    logdirpath=`realfilepath "$logdir"`;
                    logfile="$logdirpath/$(basename "$1")"
                fi
                ;;
            -extra)
                shift
                extra=$1;
                ;;
            -installLoc)
                shift
                installLoc="'$1'";
                ;;
            -psn*)
                # Apple passes this in with things that are double clicked. Ignore.
                ;;
		esac
        shift
    done

	if [ "$matlabroot" = "" ]; then
		echo "Please specify a path to MATLAB installation location with -matlabroot."
		stat=""
	fi

#
# Check for errors
#
    if [ "$stat" != "OK" ]; then        # An error occurred.
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    echo ""
	echo ""
    echo "   Usage: install_supportsoftware [-h|help]"
    echo "                             [-matlabroot <directory>] |"
	echo "                             [-archives <directory>] |"
    echo "                             [-logfile <file>]"
    echo ""
    echo "    -h|-help        - Display arguments."
    echo "    -archives <directory>     - Override default support package directory."
    echo "    -matlabroot <directory>   - Must provide a path to MATLAB installation location."
    echo "    -logfile <file>           - To pass a matlab logfile."
    echo ""
    echo "    The default settings when no override inputs are supplied are: "
    echo "    -archives = <directory containing this script>"
    echo ""
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        exit 1
    fi
#
# Call the launchMatlab method to start the SSC
#

    echo "Starting Support Package Installation..."
	launchMATLAB "$matlabroot" "$archives" "$installLoc" "$logfile" "$extra"
    echo "Finished"

