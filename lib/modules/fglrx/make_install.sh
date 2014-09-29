#!/bin/bash
# (C) 2001, 2009 - ATI Technologies
# (c) 2011 Advanced Micro Devices, Inc.
# installation script for the Linux kernel modules repository

# ==============================================================
# misc initialized values (not customizeable)
exit_val=1

# default values for all customizeable values (will remain here permanently)
#BEGIN-DEFAULT
module=fglrx 
OS_MOD=/lib/modules
#END-DEFAULT

# customized values (this section gets filled in by the installer)
#BEGIN-CUSTOM
#END-CUSTOM

# vendor options
CHECK_P3=0

# check if there was a custom specific values during install start
if [ -f /etc/ati/inst_path_default -a -f /etc/ati/inst_path_override ]; then
    . /etc/ati/inst_path_default
    . /etc/ati/inst_path_override
    if [ -n "${ATI_KERN_MOD}" ]; then
        module=`basename ${ATI_KERN_MOD}`
        OS_MOD=`dirname ${ATI_KERN_MOD}`
    fi
fi

# ==============================================================
# check if we are running as root with typical login shell paths
if [ `id -u` -ne 0 ]
then
  echo "You must be logged in as root to run this script."
  exit 1
fi

which depmod >/dev/null 2>&1
if [ $? -ne 0 ];
then
#  echo "(completing current path to be a root path)"
#  echo ""
  PATH=/usr/local/sbin:/usr/sbin:/sbin:${PATH}
  which depmod >/dev/null 2>&1
  if [ $? -ne 0 ];
  then
    echo "You arent running in a 'login shell'."
    echo "Please login directly from a console"
    echo "or use 'su -l' to get the same result."
    exit 1
  fi
fi


# ==============================================================
#BEGIN-MAIN
# central script code
    if [ $CHECK_P3 -ne 0 ]
    then
	    # determine platform name for which to load the module
        if [ ! -e $XF_BIN/cpu_check ]
        then
            echo "required driver component \"cpu_check\" is missing."
            echo "symlink creation failed."
            exit 1
        fi
    fi

    if [ $CHECK_P3 -ne 0 ]
    then

	$XF_BIN/cpu_check >/dev/null
	case "$?" in
	    0) iii=     ;;
	    1) iii=     ;;
	    2) iii=.iii ;;
	    3) iii=     ;;
	    4) iii=     ;;
	    5) iii=.iii ;;
	    6) iii=.iii ;;
	    *) iii=     ;;
	esac

    else
      iii=
    fi

	OsName="`uname -r`"
	OsRelease=$OsName
	SMP=0

    # break down OsRelease string into its components
    major=${OsRelease%%.*}
    kernel_release_rest=${OsRelease#*.}
    minor=${kernel_release_rest%%-*}
    minor=${minor%%.*}

    # determine which install system we do use 
    # note: we do not support development kernel series like the 2.5.xx tree 
    if [ $major -gt 2 ]; then
        kernel_is_26x=1
    else
      if [ $major -eq 2 ]; then
        if [ $minor -gt 5 ]; then
            kernel_is_26x=1
        else
            kernel_is_26x=0
        fi
      else
        kernel_is_26x=0
      fi
    fi

    if [ $kernel_is_26x -eq 1 ]; then
        kmod_extension=.ko
    else
        kmod_extension=.o
    fi
	
  if [ -f ${module}.${OsRelease}${iii}${kmod_extension} ]
  then
    # we already have a module with an exactly matching name.
    # therefore we dont need any further name manipulation.
    # its up to Red Hat, SuSE and the user to name its kernels unique.
    dummy=0
  else
	if [ `echo $OsName | grep -c smp` -gt 0 ]
	then
	    SMP=1
	    OsRelease=`echo $OsRelease | sed -e 's/-smp//g' `
	    OsRelease=`echo $OsRelease | sed -e 's/\.smp/\./g' `
	    OsRelease=`echo $OsRelease | sed -e 's/smp//g' `
	fi
	if [ `echo $OsName | grep -c SMP` -gt 0 ]
	then
	    SMP=1
	    OsRelease=`echo $OsRelease | sed -e 's/-SMP//g' `
	    OsRelease=`echo $OsRelease | sed -e 's/\.SMP//g' `
	    OsRelease=`echo $OsRelease | sed -e 's/SMP//g' `
	fi
	OsVersion="`uname -v`"
	if [ `echo $OsVersion | grep -c smp` -gt 0 ]
	then
	    SMP=1
	    OsRelease=`echo $OsRelease | sed -e 's/-smp//g' `
	    OsRelease=`echo $OsRelease | sed -e 's/\.smp/\./g' `
	    OsRelease=`echo $OsRelease | sed -e 's/smp//g' `
	fi
	if [ `echo $OsVersion | grep -c SMP` -gt 0 ]
	then
	    SMP=1
	    OsRelease=`echo $OsRelease | sed -e 's/-SMP//g' `
	    OsRelease=`echo $OsRelease | sed -e 's/\.SMP//g' `
	    OsRelease=`echo $OsRelease | sed -e 's/SMP//g' `
	fi
    if [ -e /proc/ksyms ]
	then
        if [ `fgrep smp /proc/ksyms -c` -gt 10 ]                                              
        then                                                                                  
            SMP=1                                                                               
        fi
    fi
    if [ -e /proc/kallsyms ]
	then
        if [ `fgrep smp /proc/kallsyms -c` -gt 10 ]                                              
        then                                                                                  
            SMP=1                                                                               
        fi
    fi
  fi
	
    # break down OsRelease string into its components
    major=${OsRelease%%.*}
    kernel_release_rest=${OsRelease#*.}
    minor=${kernel_release_rest%%-*}
    minor=${minor%%.*}

    # determine which install system we do use 
    # note: we do not support development kernel series like the 2.5.xx tree 
    if [ $major -gt 2 ]; then
        kernel_is_26x=1
    else
      if [ $major -eq 2 ]; then
        if [ $minor -gt 5 ]; then
            kernel_is_26x=1
        else
            kernel_is_26x=0
        fi
      else
        kernel_is_26x=0
      fi
    fi

    if [ $kernel_is_26x -eq 1 ]; then
        kmod_extension=.ko
    else
        kmod_extension=.o
    fi

    ModuleDir=.
	if [ $SMP = 1 ]
	then
	    ModuleName=${module}.${OsRelease}${iii}-SMP${kmod_extension}
	else
	    ModuleName=${module}.${OsRelease}${iii}${kmod_extension}
	fi
	ModuleFQN=${ModuleDir}/${ModuleName}
    AliasFQN=${ModuleDir}/${module}${kmod_extension}
	if [ "$2" = "verbose" ]
	then
	    echo ModuleFQN=$ModuleFQN
	    echo AliasFQN=$AliasFQN
	fi
	
	ModuleLogDir=$OS_MOD/$module
	if [ $SMP = 1 ]
	then
	    ModuleLogName=make.${OsRelease}${iii}-SMP.log
	else
	    ModuleLogName=make.${OsRelease}${iii}.log
	fi
	ModuleLogFQN=${ModuleLogDir}/${ModuleLogName}
	if [ "$2" = "verbose" ]
	then
	    echo ModuleLogFQN=$ModuleLogFQN
	fi
	
    
    TargetDir=${OS_MOD}/${OsName}/video
    NonTarDir=${OS_MOD}/${OsName}/kernel/drivers/char/drm
    if [ $major -gt 2 ]
    then
        TargetDir=${OS_MOD}/${OsName}/kernel/drivers/char/drm
        NonTarDir=${OS_MOD}/${OsName}/video
    else
        if [ $major -eq 2 ]
        then
            if [ $minor -ge 4 ]
            then
                TargetDir=${OS_MOD}/${OsName}/kernel/drivers/char/drm
                NonTarDir=${OS_MOD}/${OsName}/video
            fi
        fi
    fi

    # if there is a customized path for the kernel module, use that instead
    if [ -n "${ATI_KERN_INST}" ]; then
        TargetDir=${ATI_KERN_INST} 
    fi

	TargetName=${module}${kmod_extension}
	TargetFQN=${TargetDir}/${TargetName}
	NonTarFQN=${NonTarDir}/${TargetName}
	if [ "$2" = "verbose" ]
	then
	    echo TargetFQN=$TargetFQN
	fi
	
	# check for presence of module in determined path
	if [ -f "$ModuleFQN" ]
	then
		if [ -e "$TargetFQN" ]
		then
			rm -f $TargetFQN
		fi
		if [ -e "$NonTarFQN" ]
		then
			rm -f $NonTarFQN
		fi
		
	    # module is present at determined location
        if [ "$2" = "verbose" ]
        then
            # be verbose about build origin of that module
            if [ -e "$ModuleLogFQN" ]
            then
                echo "kernel module was compiled by the FGL Module Generator"
                uname_module=`fgrep "uname -a =" $ModuleLogFQN | cut -d'=' -f2`
                uname_a=`uname -a`
                if [ "$uname_a" = "$uname_module" ]
                then
                    echo "kernel module matches current kernel exactly"
                else
                    # this exact module was built against a different kernel
                    echo "kernel module is only a rough match to kernel"
                fi
            else
                echo "kernel module was provided by hardware vendor, OEM or Linux distribution."
            fi
        fi
      
        #find kernel module info in modules.dep, and delete the old one if exists
        if test -f ${OS_MOD}/${OsName}/modules.dep; then
            cat ${OS_MOD}/${OsName}/modules.dep | grep -e "${module}${kmod_extension}" > /dev/null  #If our kernel module has been installed already
            if [ $? -eq 0 ]
            then
                module_in_depfile=`cat ${OS_MOD}/${OsName}/modules.dep | grep -e "${module}${kmod_extension}" | cut -d':' -f1` #If has installed before, delete it first
                if test -f $module_in_depfile; then
                    rm $module_in_depfile
                fi
            fi
        fi


        # create symlink now
        if [ "$2" = "verbose" ]
        then
            echo "** ln -s $ModuleFQN $TargetFQN"
	    echo "- creating symlink"
	fi
        
        rm -f $AliasFQN >/dev/null
        ln -s $ModuleFQN $AliasFQN
        /sbin/rmmod ${module} >/dev/null 2>/dev/null
        mkdir -p $TargetDir
        rm -f $TargetFQN >/dev/null

        KernelListFile=/usr/share/ati/KernelVersionList.txt             #File where kernel versions are saved
        if [ -f ${KernelListFile} ]                                     #If our List of Kernel Versions already exists
        then
            cat ${KernelListFile} | grep -e "^${TargetDir}$" >/dev/null         #Check for the TargetDir in the File			
            if [ $? -eq 1 ]
            then
                echo "${TargetDir}" >> ${KernelListFile}                          #If it's not in there Add it
            fi
        else									
            echo "${TargetDir}" > ${KernelListFile}                      #And add the TargetDir to the new file
        fi

        cp $AliasFQN $TargetFQN
        exit_val=$?

        if [ $exit_val -eq 0 ]
		then
		    # recreate dependencies now
            if [ "$2" = "verbose" ]
            then
                echo "** depmod"
    		else
    		    echo "- recreating module dependency list"
    		fi
            depmod
            exit_val=$?
		fi
        
        if [ $exit_val -eq 0 ]
        then
            # recreate dependencies now
            if [ "$2" = "verbose" ]
            then
                echo "** modprobe"
            else
                echo "- trying a sample load of the kernel modules"
            fi
            modprobe $module
            exit_val=$?
	        if [ $exit_val -eq 0 ]
			then
        	    rmmod $module
        	else
        	    if [ "`lsmod | grep radeon`" != "" -o "`lsmod | grep drm`" != "" ]
                then
        	        #modprobe failed and radeon detected to be loaded
        	        #request reboot to rebuild
        	        #return different exit code
        	        exit_val=2
        	    fi
			fi
        fi
	else
	    # special module not present, advice administrator to build his module
	    echo "*** WARNING ***"
		echo "Tailored kernel module for $module not present in your system."
		echo "You must go to ${OS_MOD}/${module}/build_mod subdir"
		echo "and execute './make.sh' to build a fully customed kernel module."
		echo "Afterwards go to ${OS_MOD}/${module} and run './make_install.sh'"
		echo "in order to install the module into your kernel's module repository."
		echo "(see readme.txt for more details.)"
		echo ""
		echo "As of now you can still run your XServer in 2D, but hardware accelerated"
		echo "OpenGL will not work and 2D graphics will lack performance."
		echo ""

		# indicate fault
        exit_val=1
	fi
#END-MAIN
# ==============================================================

if [ $exit_val -eq 0 ]
then
    echo "done."
else
    echo "failed."
fi

exit $exit_val
