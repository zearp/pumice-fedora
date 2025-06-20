# Pumice
![pumice-penguin](https://github.com/user-attachments/assets/711c80a3-d09b-48d8-ae1e-c868921a3238)

Pumice based on Fedora 42, based on: [this great resource](https://pagure.io/fedora-kiwi-descriptions). A customised Fedora install to my liking and for you to use, modify and make into your own.

By default you'll get a very basic COSMIC install. I use this mainly for testing until COSMIC becomes stable enough for daily usage.

It should work out of the box on most hardware. Cockpit is installed as well. Open ```https://localhost:9090``` in a browser post-install to easily manage the system or virtual machines and such.

I use Flatpak a lot so there are not many default apps installed. Just use the store to install what you need.

While it should work on any Fedora and if using ```podman``` maybe EL too (CentOS/Rocky/Alma) I've tested on Fedora 42 only as I got flaky results using ```podman```.

## Initial setup
```
sudo dnf -y install kiwi policycoreutils
sudo dnf -y install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
```

## Disable SELinux:
```
sudo setenforce permissive
```

## Clone the repo:
```
git clone https://github.com/zearp/pumice-fedora && cd pumice-fedora
```

## Customise packages and file system:
```
sudo nano config.xml && ls -lha root/
```

## Building:
Run these commands inside the downloaded image:
```
sudo kiwi-ng --type=iso --profile="Pumice" --color-output system build --description="." --target-dir ./outdir
```

> You can track progress by tailing the log file in another terminal: ```tail -f outdir/build/image-root.log```

## Finishing up:
Copy the generated image from ```outdir```.

Unless you want to make another image, we can remove the repo folder:
```
sudo rm -rf pumice-fedora
```

# Tip and tricks:
- You can customise the file system by adding, removing or eding files in the ```root``` folder
- Read the ```kiwi``` docs: https://osinside.github.io/kiwi/image_description/elements.html
