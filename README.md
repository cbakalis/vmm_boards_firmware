# NSW Electronics - Readout Firmware

# Contents

* [How to use my VMM board?](#intro)
* [Recommended Release](#recommended-release)
* [Development Requirements](#development-requirements)
* [Deployment](#deployment)
* [Useful Links](#useful-links)
* [Contact Information](#contact)

## How to use my VMM board?
If you want to use your VMM board and do not want to dive into the firmware developments, just pick your .bin file from the bitstream directory and flash it into your board. Then follow the instructions on the [VMM Readout Software][1] git repo on how to install the software and operate the board.

## Recommended Release
Every version that has been tested thoroughly enough is tagged and a bin file has been stored into the bitstream directory. Look into the available tags and choose the latest for the board that the firmware is to be used. Currently both VMM2 and VMM3 boards are supported. If you are brave enough you can use one of the versions in the development branches but this is not supported!

## Development Requirements

The firmware team tries to use the most up to date tools for our developments. The firmware has been developed in Vivado 2016. If you would like to fork out the code and you use a Vivado version > 2016.2 you will need to upgrade the corresponding IP cores.

## Deployment
The deployment of the project can be done in a single step. Add the name of the board that you want to use in the following script and just run:

```
./deploy.sh
```

The script will take care of cleaning up and build the project. After that Vivado will open the freshly deployed project ready for new firmware adventures!

Another approach would be to open up Vivado's .tcl console, and source the .tcl script. Before doing that however, it is requred to enter the following commnad in the .tcl console:

```
set argv [list <board>]
```

And because this is the VMM2 version of the firmware, the 'board' field of the above command can only be: mmfe8_vmm2 .


## Useful links

   * [NSWVmmDaqSoftware git repo][1]
   * [NSWelectronics twiki][2]

## Contact

Questions, comments, suggestions, or help?

**Christos Bakalis**: <christos.bakalis@cern.ch>

**Panagiotis Gkountoumis**: <panagiotis.gkountoumis@cern.ch>

**Paris Moschovakos**: <paris.moschovakos@cern.ch>

[1]: https://gitlab.cern.ch/NSWelectronics/vmm_readout_software
[2]: https://twiki.cern.ch/twiki/bin/viewauth/Atlas/NSWelectronics
