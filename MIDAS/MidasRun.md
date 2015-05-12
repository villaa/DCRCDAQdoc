These modules need cables to talk
=================================
(Wireless would be a bad idea.)

The DCRC board has an ethernet port, and the computer

```
jiajin.spa.umn.edu
```

has two network cards.  With one connected to the DCRC board and the other connected to the network, you're in business.

Note that each DCRC board has an IP address printed on its cover; jiajin can talk to these addresses and is instructed to do so by MIDAS, which needs to be told - by you - what DCRC boards (and thus what IP addresses) are plugged in.  You can set the IP addresses on the MIDAS web interface for the ODB at /Equipment/Tower01/Settings/DCRC1/.

Running up Midas at UMN
=======================
These directions assume a couple things about your user account.  We're assuming that you have a UMN physics account and also that you belong to the group cdmssoft.

Without belonging to cdmssoft, you won't have sudo privelage, and the following won't work.  Talk to Anthony if you need to be added to the group.

First, log in to jiajin.spa.umn.edu.  From there, change to sudoer cdmssoft and go to the scdmsDAQ directory:
```
jiajin:your/current/dir you$ sudo -u cdmssoft -s
[sudo] password for you: <your password goes here>
jiajin:you/current/dir cdmssoft$ cd ~
jiajin:~ cdmssoft$ cd scdmsDAQ/
```


CDMS-specific DAQ
-----------------
The MIDAS DAQ consists of a system-wide, generic MIDAS program and a set of local programs describing our particular detector.  You'll need to update these local programs and compile:
```
jiajin:scdmsDAQ cdmssoft$ cd ~
jiajin:~ cdmssoft$ cd scdmsDAQ/MidasDAQ/online/src
jiajin:src cdmssoft$ svn update
jiajin:src cdmssoft$ make
```
If make is successful, you should have three executable files, triggerfeX.exe, towerfeX.exe, and dcrc_driver.exe.

If you've run before, the ODB will be set up so that pressing 'Start Run' will trigger execution of these programs as deamon services.  But if you haven't run before, you'll need to run these programs from the command line.  These programs will do two things: check that the ODB is set up properly (and if it's not, set it up properly) and also run as DAQ services.  Because they set up the ODB, the order in which they're run is important: dcrc_driver.exe must execute first, or towerfe3.exe will throw errors.

Environment Variables
---------------------
Running the script midasUMN.env will set up necessary environmental variables.  Note that a new $ROOTSYS is prefixed to the path, so you may find your ROOT version has changed.
[[Important: The script midasUMN.env contains absolute paths, making it unsuitable for automatic installation.]]
```
jiajin:scdmsDAQ cdmssoft$ source midasUMN.env
```

The exptab file
---------------
One of the environment variables set in the midasUMN.env script is $MIDAS_EXPTAB.

The Midas DAQ searches for a file (usually called 'exptab') that contains information about the experiment.  Specifically,
1. The name of the experiment
2. The directory where Midas will put its shared memory
3. The username

It is incredibly, unbelievably important to give your an experiment a unique name.  By 'unique,' I mean a name that will not be a duplicate of any of the ODB files created by other users in the /dev/shm/ directory.

An experiment name that matches another user's will result in file errors from Midas and will prevent critical Midas programs from running - no DAQ for you!

[[Important: The experiment-name constraint is unsuitable for automatic installation.]]


Essential DAQ services
----------------------
Now, the shell script MidasDAQ/online/bin/start_daq.sh will start the services mhttpd, mlogger, and mserver.  Note that these are all MIDAS functions that come from the system MIDAS install in /local/cdms and don't require any recompilation or changing.  Except that you need to change the path to point to your MidasDAQ/online and also the server from dcrc01 (which is the server at triumf) to jiajin.

[[Important: The script start_daq.sh contains absolute paths, making it unsuitable for automatic installation.]]
[[Important: The script start_daq.sh needs the experiment name, making it unsuitable for auto-install.]]

If this is the first time starting these Midas services with an experiment name, you'll need to run the script twice because the first round will throw errors.

You'll notice that the mlogger service may complain that it can't write to the log file and stops.  You'll need to fix this by changing paths specified in the web-browser ODB.

Change paths with the MIDAS web interface
=========================================
Open the web browser and point to

```
jiajin.spa.umn.edu:8081/Programs
```

In the ODB menu, you'll need to look at the /Logger directory and change the paths to the log file and data directory.

Also the /Sequencer/State directory.

Also the /Custom.

Also /Script/Save DCRC settings and /Script/Load DCRC settings.

One way to check that you've set all the files correctly is to start a run and to check the resulting .odb file - are all the paths what you need?

*Update* Anthony made a script to do all these things at once, you have to manually set the `EXP_NAME` and `MIDAS_DIR` variables:

```
#!/bin/sh

#script to set up specifics of ODB after dcrc_server.exe, towerfe3.exe, triggerfe2.exe
#initialization. 

EXP_NAME=cdms_UMN
MIDAS_DIR=/home/hep/cdmssoft/scdmsDAQ/MidasDAQ/online

odbedit -e ${EXP_NAME} -c 'create STRING "/Logger/History dir"[256]'
odbedit -e ${EXP_NAME} -c 'set "/Logger/History dir" "/home/hep/cdmssoft/scdmsDAQ/MidasDAQ/online/history/"'
odbedit -e ${EXP_NAME} -c 'create STRING "/Logger/Elog dir"[256]'
odbedit -e ${EXP_NAME} -c 'set "/Logger/Elog dir" "/home/hep/cdmssoft/scdmsDAQ/MidasDAQ/online/elog/"'
odbedit -e ${EXP_NAME} -c 'set "/Logger/ODB Dump" y'
odbedit -e ${EXP_NAME} -c 'set "/Programs/dcrc_driver01/Start command" "'${MIDAS_DIR}'/src/dcrc_driver.exe -i 1 -D"'
odbedit -e ${EXP_NAME} -c 'set "/Programs/dcrc_driver01/Required" y'
odbedit -e ${EXP_NAME} -c 'set "/Programs/towerfe3_01/Start command" "'${MIDAS_DIR}'/src/towerfe3.exe -i 1 -D"'
odbedit -e ${EXP_NAME} -c 'set "/Programs/towerfe3_01/Required" y'
odbedit -e ${EXP_NAME} -c 'set "/Programs/triggerfe2/Start command" "'${MIDAS_DIR}'/src/triggerfe2.exe -D"'
odbedit -e ${EXP_NAME} -c 'set "/Programs/triggerfe2/Required" y'
odbedit -e ${EXP_NAME} -c 'create STRING "/Playground/Run sequence"[256]'
odbedit -e ${EXP_NAME} -c 'set "/Playground/Run sequence" no_flash'
#odbedit -e ${EXP_NAME} -c 'del "/Playground/Run sequence"'
```


Taking data
===========
To take data, you'll need at least these programs running:

dcrc_driver: translates between DCRC board and the MIDAS odb
trigger_fe2: fetches trigger information from the board and makes a decision (trigger or no) based on the user-set trigger logic
tower_fe3_01: fetches waveform data when it recieves a trigger

Note that if MIDAS thinks it should be communicating with a particular DCRC board and it can't, all these programs will stop.  In other words, make sure that only your plugged-in boards are set to 'enabled' in the ODB /Equipment/Tower01/Settings/DCRC1/.

In general, if things aren't behaving as expected, take a look at the message file (whose path is specified in the ODB /Logger directory).

Stopping MIDAS
==============
To stop Midas, stop its processes.  Currently we do this with some version of the commands
```
$ ps aux | grep cdmssoft
(Midas processes are mserver, mlogger, and mhttpd)
$ kill -9 pid_mserver
$ kill -9 pid_mlogger
$ kill -9 pid_mhttpd
```

Maybe we could make a script to do this?


You are a unique butterfly: says MIDAS
======================================
We'd like to understand how MIDAS picks up on previous settings.

The MIDAS setup guide explains that the exptab file allows the definition of multiple experiments, each with their own ODB.

From https://midas.psi.ch/htmldoc/Q_Linux.html#Q_Linux_Expt_Setup,

```
The exptab file defines each experiment on the machine, with one line per experiment. Each line contains three parameters, i.e: experiment name, experiment directory name and user name. For example:

  #
  # Midas experiment list
  test   /home/johnfoo/online     johnfoo
  decay  /home/jackfoo/decay_daq  jackfoo
```

When you specify your directory but use an old experiment name, MIDAS somehow grabs the ODB from the old experiment name.

Where exactly is the ODB?

You local ODB is in the .../online as .ODB.SHM.

Another version is in /dev/shm.

Your experiments are unique butterflys: says Scott Oser
=======================================================
MIDAS wants to be able to run multiple experiments at the same time without interference, and you probably want to be able to apply different settings to the DCRC board without starting a new experiment node.

Scott Oser uses scripts in the ...online/scripts directory to load DCRC settings in the ...online/DCRCSettings directory.

Congratulations!
================
Go forth and take data!
