# AppImaGen
A script that generates a custom AppImage from Debian or from a PPA of your choice for the previous (not the oldest) and still supported Ubuntu LTS

# Usage
### Download it and made it executable

    wget https://raw.githubusercontent.com/ivan-hc/AppImaGen/main/appimagen
    chmod a+x ./appimagen
    ./appimagen [package1] [package2] [package3] [package4] ...
During the build the script will ask you to choose between Debian or the previous Ubuntu LTS:
- By choosing **debian** the script will ask if you what branch you want choose (stable, testing, oldstable, oldoldstable, unstable...);
- By choosing **ubuntu** the script will ask if you want add one or more PPAs.

Example, suppose you want to build the Chromium web browser from the ppa:[savoury1/chromium](https://launchpad.net/~savoury1/+archive/ubuntu/chromium) including the language pack:

    ./appimagen chromium-browser chromium-browser-l10n
    
Then choose `2` (i.e. "Ubuntu"), press `Y` to add a PPA and past `savoury1/chromium` (more PPAs are listed at [https://launchpad.net/~savoury1](https://launchpad.net/~savoury1).

During the build you will choose if you want to include [libunionpreload](https://github.com/project-portable/libunionpreload), if you want to rely also on the system libraries and if the AppImage has a binary executable into another `$PATH`.
