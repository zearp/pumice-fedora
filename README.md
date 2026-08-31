# Pumice Fedora 44
![pumice-penguin](https://github.com/zearp/pumice-fedora/blob/main/pumice-penguin.jpg?raw=true)

This repo has a simplified version of the Fedora kiwi description repo found [here](https://pagure.io/fedora-kiwi-descriptions/). I've just simplified it to produce an offline installable desktop with a small selection of software running Gnome with a few extensions. It is easy to modify and expand upon. I have tested this on Fedora 44 and Rocky/RHEL 10 and Ubuntu 26.04 hosts but building the iso should work on any distro with ```podman``` installed. It will download a Fedora container to build the iso in. 

## Building the iso
Install ```podman``` and ```git``` as we need both.
```
sudo dnf -y install podman git
```
Clone the repo and edit the packages (config.xml), build script (config.sh) and check out the root folder and make adjustments where needed.
```
git clone https://github.com/zearp/pumice-fedora && cd pumice-fedora
nano config.sh && nano config.xml && ls -lha root
```
If installed/enabled set SELinux in permissive mode, if you still get SELinux related errors it is needed to completely disable it in ```/etc/selinux/config``` or manually allow whatever trips it up. Cockpit provides an easy way to check and fix SELinux related issues.
```
sudo setenforce permissive
```
Download and enter the Fedora container and install some needed packages. You can skip this step when on Fedora but if you do make sure to install packages listed below like ```kiwi``` and ```dosfstools``` if not already installed.
```
sudo mkdir -p /var/cache/kiwi
sudo podman run --privileged --rm -it --network=host -v /dev:/dev -v $PWD:/code:z -v /var/cache/kiwi:/var/cache/kiwi:z -w /code quay.io/fedora/fedora:44-x86_64 /bin/bash
```
```
dnf -y install kiwi policycoreutils dosfstools erofs-utils isomd5sum qemu-img xorriso nano
sed -i "s/NPROC_PLACEHOLDER/$(nproc)/" config.xml
```
Run the following command to build the ```iso``` file. This will take a while, if you don't exit the container and only delete the ```outdir``` directory, a new build will be done faster as it doesn't have to download already downloaded packages again when you edit the config or make changes to the ```root``` directory.
```
kiwi-ng --type=iso --profile="Pumice" --color-output system build --description="." --target-dir ./build-tmp && kiwi-ng result bundle --target-dir ./build-tmp --bundle-dir ./outdir --id build
rm -rf ./build-tmp
```
 To track progress in a more detailed way tail the log file in a new session or terminal by running the ```tail -f pumice-fedora/build-tmp/image-root.log``` command.

## Finishing up:
Copy the generated image from ```outdir```.
Rebuilds will be go faster when `/var/cache/kiwi/dnf` is not deleted.
```
sudo rm -rf /replace/with/path/to/pumice-fedora
sudo podman system prune --all --volumes --force
sudo rm -rf /var/cache/kiwi/dnf
```
## Misc
A collection of different things.

### Check for updates/clean orphans/upgrade:
```
sudo dnf --refresh update
```
Remove unused dependencies/orphans:
```
sudo dnf autoremove
```
To update to a new release, from say 44 to 45 do the following:
```
sudo dnf --refresh update
```
Run the following command but if there were kernel updates reboot the system first and then run:
```
sudo dnf system-upgrade download --releasever=45
```
Please check [this](https://docs.fedoraproject.org/en-US/quick-docs/upgrading-fedora-offline/) page as well before upgrading to a new major version.

### Stop apps sorting automatically at login
Delete or move the ```~/.config/autostart/org.pumice.sort-app-grid.desktop``` file.

### Sync screen setting with login screen (gdm):
```
sudo cp ~/.config/monitors.xml /var/lib/gdm/.config/
```

### Remove brightness slider
This command will remove it if shows and doesn't work with your screen. It should always work on laptops. If it doesn't check the Fedora community or Arch Linux wiki [here](https://wiki.archlinux.org/title/Backlight) for pointers.
```
sudo grubby --update-kernel ALL --args acpi_backlight=none
```

### Check sleep mode
This step is optional but I never skip it. There are differnet sleep modes and the available modes depend on your machine and BIOS settings. For desktops I try to use ```S0``` (s2idle) sleep if possible and for laptops ```S3``` (deep). Some sleep modes use more energy than others, set sleep to ```S3``` to suspend to RAM which is usally available on all systems. For maximum savings ```S4``` suspend to disk could be used but it may not work on all systems.

To check which sleep state is currently used run ```cat /sys/power/mem_sleep``` and check the active and available modes the active sleep mode is surrounded by ```[ ]``` brackets. 

If it is set to how you like it do a sleep cycle test by suspending the machine and make sure it actually enters sleep. Often indicated by the power led chaging state to slowly pulsing or it's colour chaging to amber. If your preffered sleep mode  works we're done.

If it doesn't boot into the BIOS and look for a ACPI options related to sleep. For example to enable ```S0``` a setting called "S0 idle capability" or something similar will be listed. On some systems the ```S0``` setting might be called "S0ix" or "modern standby" and these settings usally but not always found in ACPI and/or power related setting menu's. Enable the settings you wish to be available and reboot and run the command to see sleep states again. It might be needed to set a kernel flag to select the default you want if not done automatically.
```
sudo grubby --update-kernel=ALL --args="mem_sleep_default=s2idle"
```

Replace ```s2idle``` with the sleep mode you want to use by default and reboot. It is possible sleep seems working but sleep will be "fake" in a sense that it doesn't go into any deep sleep mode. Often easy to spot by the power led not going into a fading or colour change state and fans not turning off. On some passivle cooled systems it may be difficult to test this without fans as not all systems change the power led on sleep. If it wakes near instantly it's most likely not working. To undo just replace ```--args``` with ```--remove-args``` and reboot.


For more information about these sleep states refer to [this](https://www.kernel.org/doc/Documentation/power/states.txt) document. If you want to maximise pwoer savings use either ```S3``` which suspends to RAM which is the default when bios does not enable/set ```S0``` sleep states or ```S4``` which suspends to disk instead. Use whatever sleep mode suits best. As shown above you can add a kernel parameter to declare your preference. Just replace ```s2idle``` with either ```deep``` or ```disk``` in the ```grubby``` command.

> Make sure to always test the sleep mode when chaging it.

### Fully disable sleep
Be sure to also disable it the settings app. These commands should not be needed but I've had machines acting as server go to sleep despite it being disabled in settings.
```
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
```

# Tip and tricks:
- Explore the ```root``` folder to get an idea of the possibilities, simply delete to use defaults if applicable
- You can customise the file system by adding, removing or editing files in the ```root``` folder
- Use the ```dconf dump / > gsettings.txt ``` command to export settings of compatible apps to use in [this](https://github.com/zearp/pumice-fedora/blob/main/root/etc/dconf/db/local.d/99-pumice) file for easy customisation
- Read the ```kiwi``` docs: https://osinside.github.io/kiwi/image_description/elements.html
- On firstboot the file ```/etc/rc.d/rc.local``` is executed to clean up and change settings and then removes itself
- By changing the default boot target to text mode (```sudo systemctl set-default multi-user.target```) you can free up some resources for server usage.

## Upstream kiwi descriptions:
- https://forge.fedoraproject.org/releng/kiwi-descriptions
- https://git.resf.org/sig_core/rocky-kiwi-descriptions
- https://gitlab.com/CentOS/AltImages/releng/kiwi-descriptions
