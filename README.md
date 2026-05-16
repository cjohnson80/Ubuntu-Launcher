<h1 align="center">
Ubuntu Launcher
</h1>

<p align="center">
<a href="https://github.com/cjohnson80/Ubuntu-Launcher/releases">
<img src="https://img.shields.io/github/downloads/cjohnson80/ubuntu-launcher/total" />
</a>
<a href="https://github.com/cjohnson80/Ubuntu-Launcher/releases/latest">
<img src="https://img.shields.io/github/v/release/cjohnson80/ubuntu-launcher" />
</a>
<a href='https://github.com/cjohnson80/Ubuntu-Launcher/issues'>
<img src="https://img.shields.io/github/issues-raw/cjohnson80/ubuntu-launcher" />
</a>
<a herf="https://github.com/cjohnson80/Ubuntu-Launcher/blob/master/LICENSE">
<img src="https://img.shields.io/github/license/cjohnson80/ubuntu-launcher" />
</a>
<img src="https://img.shields.io/github/repo-size/cjohnson80/ubuntu-launcher" />
</p>

<hr>

## Introduction

<img src='./assets/images/logo.png' align="left"
width="150" hspace="10" vspace="10">

**Ubuntu launcher** is a custom android launcher built using Flutter with a modern, glassmorphic Lomiri (formerly Unity 8) aesthetic.
Though flutter is a cross platform UI framework, the launcher has android version only for now. Our launcher is available on github. Any update and release version will be available here.

<p align="center">
<a href="https://github.com/cjohnson80/Ubuntu-Launcher/releases">
    <img alt="Download APK"
        src="https://img.shields.io/github/downloads/cjohnson80/ubuntu-launcher/total?label=Download%20Now&logo=ubuntu&style=for-the-badge&color=E95420" />
</a>  
</p>

<br>

## About

This application is for those who want a simple, clean and fast launcher to use. Most of the launchers in the play store or any market place are full with nested UI and the most annoying thing is their ads. 

## Authors & Credits

- **Original Author**: [Mehedi Hasan Shifat](http://github.com/jspw) - Initial concept and development.
- **Modernization & Maintenance**: [Chris Johnson](https://github.com/cjohnson80) - Ported to Dart 3, updated for modern Android SDKs, and implemented glassmorphic Lomiri UI.

## Features

- Can Use as default launcher
- Simple & Fast UI with Glassmorphic design
- Modern Lomiri-inspired animations and layout
- Responsive
- Clean homeScreen
- Custom Wallpaper support with long-press
- Glassy Slide Bar (Lomiri Dock)
- Shortcut Apps on SideBar with long-press selection
- Sort apps (Alphabetical, Installation Time, Update Time)
- Auto & Manual pull to update apps
- Dash-inspired Apps Search bar
- View Apps' settings directly from the drawer
- Optimized for modern Android (Target SDK 36)

#### Latest Features

- Change shortcut apps on long pressing the icon

  ![select shortcut apps](assets/ss/select_shortcut_apps.jpg)

- Change wallpaper on long pressing home screen

  ![Options to select wallpaper](assets/ss/select_wallpaper.jpg)
  ![New Wallpaper](assets/ss/changed_wallpaper.jpg)

## Requirements

- MinSdkVersion 21 (Android 5.0)
- **TargetSdkVersion 36 (Android 15+)**
- Flutter 3.x with Dart 3 (Sound Null Safety)
- Android Gradle Plugin 8.9.1+
- Gradle 8.11.1+

## Install

- Latest : [Ubuntu Launcher 2.4.0](https://github.com/jspw/Ubuntu-Launcher/releases/tag/2.4.0) or [Google Drive](https://drive.google.com/drive/folders/1cj3CPFrVJXNjKmJYvWm6Wr4bBlWQRY3P?usp=sharing)
- Old Versions : [Releases](https://github.com/jspw/Ubuntu-Launcher/releases)

Download the apk file and install in your android device.

**Note :** Make sure, 'installation from unknown source' is turned on as this app is not from google play store.

## Screenshots

- **Loading Screen** (When app runs for the first time)

  ![loading](assets/ss/loading.png)

- **Home Screen** (Empty for simplicity)

  ![Home](assets/ss/home.png)

- **Change Wallpaper**

  ![Change Wallpaper](assets/ss/select_wallpaper.jpg)
  ![Changed Wallpaper](assets/ss/changed_wallpaper.jpg)

- **Side Bar** (Shortcut Menu Options) -> Swap from Left to Righ to open

  ![sidebar](assets/ss/sidebar.png)
  ![vertical](assets/ss/vertical_view.png)

- **Change Shortcut apps** -> Hold the app icon to change

  ![Select shortcut app](assets/ss/select_shortcut_apps.jpg)

- **App Drawer** (Installed accesible apps)

  ![apps](assets/ss/apps.png)
  ![](assets/ss/apps_vertical_view.png)

- **Sort Option** (Sort by Apps Name, Installation and Update time)

  ![SortOption](assets/ss/sorts.png)

- **Search Bar**

  ![Search Bar](assets/ss/searchbar.png)

### Demo

<p align='center'>
<img   src="./assets/ss/demo.gif" />
</p>

## Permissions

On Android version ubuntu launcher requires the following permissions:

- Run at start.
- Read access to installed apps in device.

The "Run at start" permission is required to run the app when device turn on so that the launcher can be used as default.

## Contributing

Ubuntu launcher is a free and open source project. Any contributions are welcome. Here are a few ways you can help:

- [Report bugs and make suggestions.](https://github.com/cjohnson80/Ubuntu-Launcher/issues)
- Write some code. Please follow the code style used in the project to make a review process faster.

## License

This launcher was originally created by <a href='http://github.com/jspw'>Mehedi Hasan Shifat</a> and released under GNU GPLv3 (see [LICENSE](LICENSE)).
Some of the used libraries are released under different licenses.
