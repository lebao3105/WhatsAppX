<div align="center">
<img src="Xcode%20Project/WhatsApp%20Legacy/Images/logo_large.png" width=20% height=20%>
<h1>WhatsAppX</h1>

This project is currently in beta. Please report bugs or ask for help in bag-xml’s Discord server -> `#whatsapp`. When reporting bugs or asking for help, please give **as much detail as you can.** Simply writing “my app crashes” or “chats don’t pop up” won’t help much in diagnosing the issue.

</div>

## Compilation

- Install Bun
- Go to `Server/`
- Download FFmpeg from:
  * Windows: https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-lgpl.zip
  * macOS: https://evermeet.cx/ffmpeg/
  * Linux: https://johnvansickle.com/ffmpeg/
- Create `ffmpeg` folder in the folder that has the newly made executable
- Move the previously downloaded `ffmpeg` and its dependencies into that `ffmpeg` folder
- Run `bun install`
- Run `bun server.ts`
- Profit

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
    <td style="vertical-align: middle; padding-left: 12px; font-size: 16px;">
      iOS client, Server
    </td>
  </tr>
  <tr>
    <td style="vertical-align: middle;">
      <img src="https://cdn.discordapp.com/avatars/274765047342039040/71631003d16f8893dc72f789c1c992d6.png" style="width:60px; height:60px; border-radius:50%;">
    </td>
    <td style="vertical-align: middle; padding-left: 12px; font-size: 16px;">
      zemonkamin
    </td>
    <td style="vertical-align: middle; padding-left: 12px; font-size: 16px;">
      Windows 10 mobile client, Contributed to Windows Phone 8.1 client, Server
    </td>
  </tr>

</table>

## Disclaimers
This project is **not affiliated** with “WA for Legacy iOS” by Alwin Lubbers, “Meta Platforms Inc.”, or “WhatsApp Inc.”

This is an **unofficial client** for WhatsApp and is **not affiliated with**, **endorsed by**, or **supported** by WhatsApp Inc. in any way.
By using this application, you acknowledge and agree that:
- **You** are **solely responsible** for the **use** of **your WhatsApp account** with this app.
- **I** (calvink19) assume **no responsibility** for **any actions** taken by _WhatsApp Inc._ against your account, including (but not limited to) suspension, banning, or data loss.

**Use at your own risk!**
If you do not agree with these terms, **do not use this application.** A pop-up is also presented in the iOS application.
