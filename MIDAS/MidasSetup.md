These modules need cables to talk
=================================
(Wireless would be a bad idea.)

The DCRC board has an ethernet port, and the computer

```
jiajin.spa.umn.edu
```

has two network cards.  With one connected to the DCRC board and the other connected to the network, you're in business.

Note that each DCRC board has an IP address printed on its cover; jiajin can talk to these addresses and is instructed to do so by MIDAS, which needs to be told - by you - what DCRC boards (and thus what IP addresses) are plugged in.  You can set the IP addresses on the MIDAS web interface for the ODB at /Equipment/Tower01/Settings/DCRC1/.

As of Sept. 27, 2014, the DCRC with IP address 131.225.53.84 is using version 3.

Setting up Midas at UMN
=======================

First thought: we'd like to install the most recent version of MIDAS.

So we checked out the current MIDAS DAQ from the repository into our local directory and tried to

```
villaa@vegemite$ make all
```

Sadly, this failed.  So we scrapped the idea of installing the most recent version and instead copied Scott Oser's DAQ directory over.

```
villaa@vegemite$ cp -r /home/oser/MidasDAQ ~/MidasDAQ/oser
```

To get from here to a (nominally) working MIDAS install, we had to
1. change the shell script so its environmental variables point to directories writeable by user villaa
2. make clean, followed by make all
3. use the MIDAS web interface to change the data and logger directories stored in ODB/Logger

MIDAS shell script
==================
You need a shell script to start the necessary parts of the MIDAS DAQ.  We put our script in ~/MidasDAQ.

```bash
# set up some environment variables for using MIDAS

export MIDASSYS=/local/cdms/MidasDAQ/packages/midas
export ROOTSYS=/local/cdms/MidasDAQ/packages/root
export MIDAS_EXPTAB=/home/villaa/MIDASdaq/trunk/MidasDAQ/online/exptab

# define the location of the MIDAS mserver

if [[ `hostname -s` = jiajin* ]]; then
    unset MIDAS_SERVER_HOST
else
    export MIDAS_SERVER_HOST=jiajin.spa.umn.edu:7071
fi

# select 64-bit MIDAS and ROOT

    export ROOTSYS=/local/cdms/MidasDAQ/packages/root
    export PATH=.:$MIDASSYS/linux/bin:$PATH

export PATH=.:/local/cdms/MidasDAQ/online/bin:$ROOTSYS/bin:$PATH
```



Making the executables
======================

The makefile is (like you might expect) in the directory containing the source code.  In our case,

```
villaa@vegemite$ cd ~/MIDASdaq/oser/online/src
villaa@vegemite$ make clean
villaa@vegemite$ make all
```

made the necessary excutables.

Now, running the above shell script will start the services mhttpd, mlogger, and mserver.  These are all MIDAS functions that come from the system MIDAS install in /local/cdms and don't require any recompilation or changing.

You'll notice that the mlogger service will complain that it can't write to the log file and stops.  You'll need to fix this by changing paths specified in the web-browser ODB.

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



Taking data
===========
To take data, you'll need at least these programs running:

dcrc_driver: translates between DCRC board and the MIDAS odb
trigger_fe2: fetches trigger information from the board and makes a decision (trigger or no) based on the user-set trigger logic
tower_fe3_01: fetches waveform data when it recieves a trigger

Note that if MIDAS thinks it should be communicating with a particular DCRC board and it can't, all these programs will stop.  In other words, make sure that only your plugged-in boards are set to 'enabled' in the ODB /Equipment/Tower01/Settings/DCRC1/.

In general, if things aren't behaving as expected, take a look at the message file (whose path is specified in the ODB /Logger directory).


[[Important: Alert at some point ]]
[[Important: We added a varible to /Runinfo in the ODB and that totally crashed mhttpd.  We'd added variables while mhttpd was running previously and also added the additional variable while mhttpd was stopped - the extra /Runinfo var still broke mhttpd.]]

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
