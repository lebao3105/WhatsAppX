<div align="center">
<img src="Xcode%20Project/WhatsApp%20Legacy/Images/logo_large.png" width=20% height=20%>
<h1>WhatsAppX</h1>

This project is currently in beta. Please report bugs or ask for help in bag-xml’s Discord server -> `#whatsapp`. When reporting bugs or asking for help, please give **as much detail as you can.** Simply writing “my app crashes” or “chats don’t pop up” won’t help much in diagnosing the issue.

</div>

## Compilation
#### Windows
- In the server folder, enter `npm install -g pkg`
- Run `build.bat`
- Download the compiled `ffmpeg` executable [here](https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-lgpl.zip), an `x86_64` .EXE is linked
- Create an `ffmpeg` folder in the folder with the compiled NodeJS code (app.exe)
- Transfer the previously downloaded `ffmpeg.exe` and its dependencies to the `ffmpeg` folder

#### MacOS
- In the server folder, enter `npm install -g pkg`
- For Intel Macs, run `pkg . --targets node18-macos-x64 --output app-macos`
- For Apple Silicon Macs, run `pkg . --targets node18-macos-arm64 --output app-macos-arm64`
- Download the compiled `ffmpeg` executable [here](https://evermeet.cx/ffmpeg/). Make sure to download for the right architecture.
- Create an `ffmpeg` folder in the folder with the compiled NodeJS code
- Transfer the previously downloaded `ffmpeg` and its dependencies to the `ffmpeg` folder
- Run with `./app-macos`.

#### Linux
- In the server folder, enter `npm install -g pkg`
- Run `pkg . --targets node18-linux-x64 --output app-linux`
- Download the compiled `ffmpeg` executable [here](https://johnvansickle.com/ffmpeg/). Make sure to download for the right architecture.
- Create an `ffmpeg` folder in the folder with the compiled NodeJS code
- Transfer the previously downloaded `ffmpeg` and its dependencies to the `ffmpeg` folder
- Run with `./app-linux`.

## Special thanks to...
- **Gian Luca Russo**: the original developer of this project
- **Zemonkamin**: improved much of the server code (such as fixing voice notes and video messages)
- **saturngod**: for the `tcpSocketChat` library
- **John Engelhart**: for the `JSONKit` library
- **Dustin Voss** & **Deusty Designs**: for the `AsyncSocket` library
- **Matej Bukovinski**: for the `MBProgressHUD` library
- **Sam Soffes**, **Hexed Bits**, & **Jesse Squires**: for the `SSMessagesViewController` library
- **Skal**: for the `WebP` framework
- **SenteSA**: for the `SenTestingKit` framework

## Developers
<table style="border-collapse: separate; border-spacing: 0 10px;">
  <tr>
    <td style="vertical-align: middle;">
      <img src="Xcode%20Project/WhatsApp%20Legacy/Images/pfp.jpeg" style="width:60px; height:60px; border-radius:50%;">
    </td>
    <td style="vertical-align: middle; padding-left: 12px; font-size: 16px;">
      calvink19
    </td>
  </tr>
  <tr>
    <td style="vertical-align: middle;">
      <img src="https://cdn.discordapp.com/avatars/274765047342039040/71631003d16f8893dc72f789c1c992d6.png" style="width:60px; height:60px; border-radius:50%;">
    </td>
    <td style="vertical-align: middle; padding-left: 12px; font-size: 16px;">
      zemonkamin
    </td>
  </tr>
</table>

***

## Disclaimers
This project is **not affiliated** with “WA for Legacy iOS” by Alwin Lubbers, “Meta Platforms Inc.”, or “WhatsApp Inc.”

This is an **unofficial client** for WhatsApp and is **not affiliated with**, **endorsed by**, or **supported** by WhatsApp Inc. in any way.  
By using this application, you acknowledge and agree that:
- **You** are **solely responsible** for the **use** of **your WhatsApp account** with this app.
- **I** (calvink19) assume **no responsibility** for **any actions** taken by _WhatsApp Inc._ against your account, including (but not limited to) suspension, banning, or data loss.

**Use at your own risk!**  
If you do not agree with these terms, **do not use this application.** A pop-up is also presented in the iOS application.
