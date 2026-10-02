# updkernel
# !! this is an experimental project that is not yet working properly !!

this project is supposed to make life of a limine bootloader user on gentoo easier by making a simpler way to modify the config  

the original plan was to link the currently used kernel (determined by `/usr/src/linux` symlink) to a file and then make the user put the paths in `limine.conf`  
although it sounds like a great idea, i forgot that basically everyone use fat32 boot partition, and fat32 does NOT support symlinks, so i had to scrap that  
this legacy branch is the implemented idea, though replaced `ln -s` with `cp`
