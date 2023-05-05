# AppImaGen
A script that generates a custom AppImage from a PPA of your choice for the previous (not the oldest) and still supported Ubuntu LTS

# Usage
### Download it and made it executable

    wget https://raw.githubusercontent.com/ivan-hc/AppImaGen/main/appimagen
    chmod a+x ./appimagen
### How it works
Where `[user]` and `[repository]` are related to a PPA, do:

    ./appimagen [package1] [user] [repository] [package2] [package3] [package4] ...
Example:

    ./appimagen chromium-browser savoury1 chromium 	chromium-browser-l10n
This will create an AppImage of the web browser Chromium from the ppa:[savoury1/chromium](https://launchpad.net/~savoury1/+archive/ubuntu/chromium) including the language pack.
The script also choose the previous Ubuntu LTS as a basis (today, May 05, 2023, it is Ubuntu 20.04 "Focal Fossa").

During the build you will choose if you want to include [libunionpreload](https://github.com/project-portable/libunionpreload), if you want to rely also on the system libraries and if the AppImage has a binary executable in other paths.
