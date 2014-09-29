#!/bin/bash 

. /etc/default/xorg-driver-fglrx
if [ x$FGLRX_ACPI_SWITCH_POWERSTATES != xtrue ]; then
  exit;
fi

getXuser() {
        user=`finger| grep -m1 ":$displaynum " | awk '{print $1}'`
        if [ x"$user" = x"" ]; then
                user=`finger| grep -m1 ":$displaynum" | awk '{print $1}'`
        fi
        if [ x"$user" != x"" ]; then
                userhome=`getent passwd $user | cut -d: -f6`
                export XAUTHORITY=$userhome/.Xauthority
        else
                export XAUTHORITY=""
        fi
}

grep -q closed /proc/acpi/button/lid/*/state
if [ $? = 0 ]; then
 lid_closed=1
else
 lid_closed=0
fi

grep -q off-line /proc/acpi/ac_adapter/*/state 
if [ $? = 0 ]; then
   on_dc=1
else
   on_dc=0
fi



if [ ${lid_closed} -eq 1 -o ${on_dc} -eq 1 ]; then
    echo "fglrx: setting low power"
    for x in /tmp/.X11-unix/*; do
	displaynum=`echo $x | sed s#/tmp/.X11-unix/X##`
	getXuser;
	if [ x"$XAUTHORITY" != x"" ]; then
	    export DISPLAY=":$displaynum"	    
	    powermode=`/usr/bin/aticonfig --lsp | grep -m1 low | cut -b 3-3`
	    if [ x"$powermode" != x"" ]; then
	        su $user -c "/usr/bin/aticonfig --set-powerstate=$powermode --effective=now" &>/dev/null
	    fi
	fi
    done
else
    echo "fglrx: setting default powermode"
    for x in /tmp/.X11-unix/*; do
	displaynum=`echo $x | sed s#/tmp/.X11-unix/X##`
	getXuser;
	if [ x"$XAUTHORITY" != x"" ]; then
	    export DISPLAY=":$displaynum"
	    powermode=`/usr/bin/aticonfig --lsp | grep -m1 default | cut -b 3-3`
	    if [ x"$powermode" != x"" ]; then
	        su $user -c "/usr/bin/aticonfig --set-powerstate=$powermode --effective=now" &>/dev/null
	    fi
	fi
    done
fi
