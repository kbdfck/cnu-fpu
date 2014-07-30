cnu-fpu
=======

Cisco IP phones firmware packer/unpacker (794X, 796X and others)

Description
===========
This is an utility for packing/unpacking of Cisco IP Phone firmwares based on CNU_File_Archive_3.0 format, called so after strings found in firmware files. Phones using this firmware format are 7911/7906, 7941/7961, 7970/7971 and others for 79xx series phones. Firmwares for 3911, 7931 and some newer models have different format and can't be unpacked with this utility. Some development history and firmware format description will be availeble soon, partly translated from Russian.

You can contact the author at kbdfck@virtualab.ru

Few things to note
==================

Original firmware files are distributed with digital signature placed at beginning of file. To unpack firmware file you should remove signature with tool included in distribution, see README. Actually, repacked files should be signed too, but phones accept unsigned firmwares by default. In case you use Cisco Call Manager with firmware security features enabled, you should disable this on per phone basis or find the way to sign modified firmwares with correct keys, possibly found in Call Manager. I don't really know.

<a href="http://virtualab.ru/projects/cnu-fpu/cnu_fpu-0.2.tar.gz">Download cnu_cpu-0.2.tar.gz</a>

How to use it
=============
See README in archive.

OMFG I just bricked my phone!!!!111
===================================
Take another $200 and buy new phone. Or better take your $200 and pay it to electronics guru who will fix phone bootloader with JTAG, and you then publish his research on the web. What you are not supposed to do is asking me why this tool turned your shiny phone into the brick. 7941 and higher models are viable ones, I have strange feeling they automatically revert to previous successful firmware after 10 tries to upgrade from TFTP. Possible this is not true, because I saw too much reboots of this devices while debugging my firmware, so I can be wrong interpreting its behavior.
