Overall Goals
=============

The Goal of the SLAC test is to test the readouts of cold SQUIDs and obtain their noise
performance with the RevD DCRC.  Further, we want to test the operation of all of the DAQ
subsustems with the RevD DCRC, this includes: tuning tools; javascript UI interface, drivers,
sequencer, and production data operation.  In short, after getting usable data on the SQUIDs we
want to put in place the full RevD DAQ chain at SLAC and come away with a condensed procedure for
doing so at other test facilities.  See the
[schedule](https://docs.google.com/spreadsheets/d/1VAQoLa731FfMSn3HfJ6pI_jqgKuAKb9sYWb9WtMWHzI/edit#gid=1478419570)
for task details.

Subsystems and WBS Tasks
========================

Tuning Tools/SQUID Data (Bruno/Bill/Bruce)
------------------------------------------

**Overview:** We would like to get an overall picture of the noise performance of the SQUIDs with
the RevD board and work out the bugs in the tuning of SQUIDs with RevD, and HEMPT performance if
possible.  Some SQUID work has been done already with the RevD, so we wish to compare to those
results from Bruce.

 1. connect to SQUIDs using the DCRC RevD interface and the ROOT tuning GUI
 2. tune each available SQUID form maximum modulation depth (1.6.8.3.3 and 1.6.8.3.6)
 3. obtain PSDs for the SQUIDs referred to input current (1.6.8.3.4)
 4. save modulation curves for the SQUIDs (1.6.8.3.4 and 1.6.8.3.6)
 5. compare modulation curves and PSDs to previous values obtained by Bruce (1.6.8.3.5)
 6. connect to HEMPTs (1.6.8.3.3) 
 7. get PSDs from HEMPTs (1.6.8.3.4) 

RevD Driver/ODB (Belina/Scott)
------------------------------

**Overview:** We want to be sure the driver works to control the DCRC RevD via the ODB without
bugs.  The work should be eventually condensed into a comprehensive script that tests this
functionality in any setup.  We would also like to develop a way to check the ODB for the correct
directory structure and prune any extraneous directories, this check can also be used by the other
subsystems in the future. 

DCRC RevD Javascript UI (Amy/Xuji)
----------------------------------

Python Sequencer Interface (Amy/Anthony)
----------------------------------------

File Naming, Throughput, and Processing (Anthony/Amy)
-----------------------------------------------------
