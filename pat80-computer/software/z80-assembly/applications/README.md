# Pat80 Applications

## Intro
This folder contains some example applications.
The folder `brief` contains little applications that can be entered directly via keyboard in the memory monitor.
The folder `big` contains complete applications to be loaded via sdcard or tape.

## How to write an application
When the Pat80 operating system is built, a `abi-generated.asm` file is built along with the rom binary. This file contains the description of the OS available API.
An application targeting the last version of the OS should include this file, to make the system calls labels available inside the application code.
The application can obtain the operating system ABI version (ABI -> https://en.wikipedia.org/wiki/Application_binary_interface) via the Sys_ABI call (it is a 16 bits integer returned in BC).
The application's first command should be an ABI check: if the OS version is not compatible with the app, the app should exit displaying an error message.