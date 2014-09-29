#!/bin/sh
# Copyright: ATI Technologies Incorporated - 2006
# atigetsysteminfo.sh: System configuration recording tool
# This tool generates a system configuration report file.  Please run this tool and append the generated file to your problem reports.

alias echo=/bin/echo

# Configure output redirection
if [ -z "${_ARCHIVEDIR}" ]; then
    _ARCHIVEDIR=${HOME}
fi

if [ -z "${_REPORTFILE}" ]; then
    _REPORT=${_ARCHIVEDIR}/atisysteminfo-report.txt
    echo "Configuration Report can be found at: ${_ARCHIVEDIR}/atisysteminfo-report.txt"
else
    _REPORT=${_ARCHIVEDIR}/${_REPORTFILE}
fi

echo "Starting configuration collection ..."

if [ ! -d ${_ARCHIVEDIR} ]; then
	mkdir -p ${_ARCHIVEDIR}
fi

echo "ATI System configuration report started `date` on `hostname`." >${_REPORT}

# Run a command and output to the report file
report_cmd()
{
	echo -e "\n==========${1}==========\n" >>${_REPORT}
	eval $1 >>${_REPORT} 2>&1
}

# cat a file and output to the report file
report_file()
{
	_filedate=`ls --full-time $1 2>/dev/null | cut -d " " -f 7,8 | cut -d ":" -f 1,2`
	echo -e "\n==========${1} (${_filedate})==========\n">>${_REPORT}
	cat $1 >>${_REPORT} 2>&1
}

# Reports processes of interest
report_processes()
{
	echo -e "\n==========Processes==========" >>${_REPORT}
	`which ps` aux | grep -e xdm -e gdm -e kdm -e gnome-settings-daemon -e gnome-session -e kde -e "/X " -e "/Xorg " -e xinit -e metacity -e kwin -e xfwm -e compiz -e wm -i | grep -v grep 2>&1 >>${_REPORT}
}

# output the value of an environment variable to the report file
report_env()
{
	echo -e "\$$1=$2\n" >>${_REPORT}
}

# This function locates the current OS release file and outputs it to the report file.
report_OS()
{

	#Currently only opens the main supported distribution release labels.
	#For example, RHEL4, RHEL5, OpenSuSE 10.2, etc.

	if [ -f /etc/redhat-release ]; then
		report_file /etc/redhat-release
	elif [ -f /etc/SuSE-release ]; then
		report_file /etc/SuSE-release
	elif [ -f /etc/novell-release ]; then
		report_file /etc/novell-release
	elif [ -f /etc/issue ]; then
		report_file /etc/issue
	fi
}

# Request verbose libGL information
export LIBGL_DEBUG=verbose
export DISPLAY=:0.0

# Basic system info
report_cmd "uname -a"
report_OS
report_file /proc/version
report_cmd "gcc --version"
report_cmd `which fglrxinfo`
report_cmd "ldd `which fglrxinfo`"

# install log 
echo -e "\n\n==========INSTALLATION LOG========\n" >>${_REPORT}
report_file /usr/share/ati/fglrx-install.log

# Environment variable values
echo -e "\n\n==========ENVIRONMENT VARIABLES==========\n" >>${_REPORT}
report_env PATH ${PATH}
report_env LD_LIBRARY_PATH ${LD_LIBRARY_PATH}
report_env LD_CONFIG_PATH ${LD_CONFIG_PATH}
report_env LIBGL_DRIVERS_PATH ${LIBGL_DRIVERS_PATH}

echo -e "\n\n==========PROC DEVICES==========\n" >>${_REPORT}
# More system info
report_file /proc/cpuinfo 
report_file /proc/meminfo
report_cmd `which lspci`
report_file /proc/pci 
report_file /proc/ati/major
_PROC_ATI=`ls /proc/ati/*/* | grep -v interrupt`
for _proc_ati in ${_PROC_ATI}; do
	report_file ${_proc_ati}
done


echo -e "\n\n==========X SERVER INFORMATION==========\n" >>${_REPORT}
# X Window System state information
_X_LOGS=`ls /var/log/X*.0.log | grep -e "X[oF]r[ge]"` 
for _x_log in ${_X_LOGS}; do
	_X_CONFIG=`grep 'Using config' ${_x_log} | sed -e "s/.*\"\(.*\)\"$/\1/g"`
	if [ -z "${_X_CONFIG}" ]; then
		echo -e "\n\n========== xorg.conf ==========\nFile not found\n" >>${_REPORT}
	else
		report_file ${_X_CONFIG}
	fi
	# For each .0.log, fetch all logs for all displays
	_ALL_LOGS=`echo ${_x_log} | sed -e "s/\.0\.log/\.\*\.log/"`
	_ALL_LOGS=`ls ${_ALL_LOGS}`
	for _log in ${_ALL_LOGS}; do
		report_file ${_log} 
	done
done

# X Windows information
if [ -n ${DISPLAY} ]; then
#xdpyinfo
    report_cmd "`which xdpyinfo` -ext XINERAMA -queryExtensions"
# running processes (i.e. gnome-settings-daemon, compiz)
    report_processes
    
# xrandr
    if xrandr >/dev/null 2>&1; then
        for i in `xdpyinfo | grep "^screen #.:" | cut -d# -f 2 | cut -d: -f 1`; do    
            report_cmd "`which xrandr` --screen ${i} -q"
        done
    fi
fi

# kernel state information
echo -e "\n\n==========KERNEL RELATED==========\n" >>${_REPORT}
report_file /var/log/dmesg
report_cmd `which dmesg`
report_cmd `which lsmod`

# ldconfig information
echo -e "\n\n==========LDCONFIG INFORMATION==========\n" >>${_REPORT}
report_cmd "ldconfig -p | grep -E 'fglrx|libati|libGL|libEGL|dri|OpenCL|libAMD|libamd|libXvBA'"

# amdpcsdb information
echo -e "\n\n==========AMDPCSDB INFORMATION==========\n" >>${_REPORT}
report_file /etc/ati/amdpcsdb

# amdpcsdb.default information
echo -e "\n\n==========AMDPCSDB.DEFAULT INFORMATION==========\n" >>${_REPORT}
report_file /etc/ati/amdpcsdb.default

echo "Created Configuration Report: ${_REPORT}"
echo "Please attach generated Report file to problem reports."

exit 0
