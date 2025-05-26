# AppImaGen
Generates Debian and Ubuntu based AppImage packages on any distro

https://github.com/user-attachments/assets/d9f754ed-d163-46ee-a3b1-0034131065ba

# Dependencies
The scripts already contain functions to download the following tools while building
- [appimagetool](https://github.com/AppImage/appimagetool)
- [pkg2appimage](https://github.com/AppImageCommunity/pkg2appimage)

if you use "[AM](https://github.com/ivan-hc/AM)" package manager, you can install them using the following command
```
am -i appimagetool pkg2appimage
```

# Usage
1. Download the "appimagen" script and made it executable
```
wget -q https://raw.githubusercontent.com/ivan-hc/AppImaGen/main/appimagen && chmod a+x ./appimagen
```
if you use "[AM](https://github.com/ivan-hc/AM)" package manager, you can install them using the following command
```
am -i appimagen
```

2. Use the following syntax to create a build script for an Ubuntu or debian based AppImage
```
appimagen appname
```
where "appname" is the name of the package in APT. For example
```
appimagen audacity
```
The script will be saved to the Desktop. If there is no XDG directory for the Desktop, it will be saved to $HOME.

3. Follow the on screen instructions:
   - by default, the script uses Debian as the base, but selecting 2 will allow you to set an Ubuntu base
   - enter the "codename" (in lowercase) of the Debian/Ubuntu version you want to use as the base
   - enter the additional packages you want to force into the build, or leave nothing at all
   - if you selected Ubuntu, you can add one or more additional PPAs or leave none at all
   - choose whether to allow the AppImage to see the host libraries (recommended for personal use only)

At the end, choose whether to run the script. If the build was successful, you can select "y" to launch the newly created AppImage directly from the AppImaGen CLI.

# Repeat
If the build was not successful, you can simply repeat the command
```
appimagen appname
```
and then, add the packages and/or PPAs you need. You don't have to download everything again!

------------------------------------------------------------------------
# My other projects
- *"[AM](https://github.com/ivan-hc/AM)", Database & solutions for all AppImages and portable apps for GNU/Linux*
- *[ArchImage](https://github.com/ivan-hc/ArchImage), create AppImages for all distributions using Arch Linux packages. Powered by JuNest*
- *[Firefox for Linux scripts](https://github.com/ivan-hc/Firefox-for-Linux-scripts), easily install the official releases of Firefox for Linux*
- *[My AppImage packages](https://github.com/ivan-hc#my-appimage-packages) the complete list of packages managed by me and available in this database*
- *[Snap2AppImage](https://github.com/ivan-hc/Snap2AppImage), try to convert Snap packages to AppImages*

------------------------------------------------------------------------

###### *You can support me and my work on [**ko-fi.com**](https://ko-fi.com/IvanAlexHC) and [**PayPal.me**](https://paypal.me/IvanAlexHC). Thank you!*

--------

*© 2020-present Ivan Alessandro Sala aka 'Ivan-HC'* - I'm here just for fun! 

------------------------------------------------------------------------

| [**ko-fi.com**](https://ko-fi.com/IvanAlexHC) | [**PayPal.me**](https://paypal.me/IvanAlexHC) |
| - | - |

------------------------------------------------------------------------
