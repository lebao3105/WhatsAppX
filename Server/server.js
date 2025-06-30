const express = require("express");
const axios = require("axios");
const {
    Client,
    RemoteAuth,
    MessageMedia,
    LocalAuth
} = require("whatsapp-web.js");
const qrcode = require("qrcode-terminal");
const net = require("net");
const crypto = require("crypto");
const ffmpeg = require("fluent-ffmpeg");
const { exec } = require('child_process');
const path = require("path");
const fs = require("fs");
const os = require("os");
const QRCode = require('qrcode');
const isPkg = typeof process.pkg !== 'undefined';
const baseDir = isPkg ? path.dirname(process.execPath) : __dirname;
let ffmpegPath = path.join(baseDir, 'ffmpeg', 'ffmpeg.exe');

if (!fs.existsSync(ffmpegPath)) {
    try {
        const staticFfmpeg = require('ffmpeg-static');
        if (staticFfmpeg && fs.existsSync(staticFfmpeg)) {
            ffmpegPath = staticFfmpeg;
            console.log('[FFmpeg] Using ffmpeg-static:', ffmpegPath);
        } else {
            ffmpegPath = 'ffmpeg';
            console.log('[FFmpeg] Using system ffmpeg from PATH');
        }
    } catch (e) {
        ffmpegPath = 'ffmpeg';
        console.log('[FFmpeg] Using system ffmpeg from PATH');
    }
} else {
    console.log('[FFmpeg] Using local ffmpeg:', ffmpegPath);
}
ffmpeg.setFfmpegPath(ffmpegPath);

// Initialize Express app
const app = express();

// Middleware setup
app.use(express.json({ limit: "100mb" }));
app.use(express.urlencoded({ limit: "100mb", extended: true }));

// Configure FFmpeg
// ffmpeg.setFfmpegPath(ffmpegStatic); // Removed this in favor of env variable

// WhatsApp Client configuration
const configPath = path.join(__dirname, "config.json");
const SERVER_CONFIG = require(configPath);

let clients = [];
let queueClients = [];
let presences = {};
let reInitializeCount = 1;

const client = new Client({
                          puppeteer: {
                          headless: true,
                          args: [
                                 "--no-sandbox",
                                 "--disable-setuid-sandbox",
                                 "--log-level=3",
                                 "--no-default-browser-check",
                                 "--disable-site-isolation-trials",
                                 "--no-experiments",
                                 "--ignore-gpu-blacklist",
                                 "--ignore-certificate-errors",
                                 "--ignore-certificate-errors-spki-list",
                                 "--enable-gpu",
                                 "--disable-default-apps",
                                 "--enable-features=NetworkService",
                                 "--disable-webgl",
                                 "--disable-threaded-animation",
                                 "--disable-threaded-scrolling",
                                 "--disable-in-process-stack-traces",
                                 "--disable-histogram-customizer",
                                 "--disable-gl-extensions",
                                 "--disable-composited-antialiasing",
                                 "--disable-canvas-aa",
                                 "--disable-3d-apis",
                                 "--disable-accelerated-2d-canvas",
                                 "--disable-accelerated-jpeg-decoding",
                                 "--disable-accelerated-mjpeg-decode",
                                 "--disable-app-list-dismiss-on-blur",
                                 "--disable-accelerated-video-decode",
                                 "--window-position=-200,-200",
                                 "--window-size=1,1"
                                 ],
                          ...(SERVER_CONFIG.CHROME_PATH ? { executablePath: SERVER_CONFIG.CHROME_PATH } : {})
                          },
                          authStrategy: new LocalAuth()
                          });

const TOKENS = {
SERVER: "3qGT_%78Dtr|&*7ufZoO",
CLIENT: "vC.I)Xsfe(;p4YB6E5@y"
};

// Utility functions
const delay = (ms) => new Promise(resolve => setTimeout(resolve, ms));

function reconnect(socket) {
    console.log(`Attempting to reconnect with ${socket.name}`);
    setTimeout(() => {
               if (queueClients.indexOf(socket) === -1 && clients.indexOf(socket) === -1) {
               socket.connect(SERVER_CONFIG.PORT, SERVER_CONFIG.HOST, () => {
                              console.log(`${socket.name} reconnected`);
                              queueClients.push(socket);
                              });
               }
               }, 5000);
}

function buildContactId(id, isGroup = false) {
    return id + (isGroup ? "@g.us" : "@c.us");
}

async function processMessageForCaption(message) {
    if (message._data && message._data.caption) {
        message._data.body = undefined;
        message.body = message._data.caption;
        message._data.caption = undefined;
    }
    return message;
}

async function processLastMessageCaption(chat) {
    let lastMessage = chat.lastMessage;
    if (lastMessage && lastMessage._data && lastMessage._data.caption) {
        lastMessage._data.body = undefined;
        lastMessage.body = lastMessage._data.caption;
        lastMessage._data.caption = undefined;
    }
    chat.lastMessage = lastMessage;
    return chat;
}

async function downloadAndConvertAudio(audioBuffer, outputFormat = 'mp3') {
    const tempInputPath = path.join(os.tmpdir(), `temp_audio_input_${Date.now()}.ogg`);
    const tempOutputPath = path.join(os.tmpdir(), `converted_audio_output_${Date.now()}.${outputFormat}`);
    
    return new Promise((resolve, reject) => {
                       fs.writeFile(tempInputPath, audioBuffer, (err) => {
                                    if (err) {
                                    console.error('Error writing temp audio file:', err);
                                    return reject(err);
                                    }
                                    
                                    const command = `"${ffmpegPath}" -i "${tempInputPath}" -acodec libmp3lame "${tempOutputPath}"`;
                                    
                                    exec(command, (error, stdout, stderr) => {
                                         // Always delete the temp input file
                                         fs.unlink(tempInputPath, (unlinkErr) => {
                                                   if (unlinkErr) console.error('Error deleting temp input file:', unlinkErr);
                                                   });
                                         
                                         if (error) {
                                         console.error('FFmpeg execution error:', error.message);
                                         console.error('FFmpeg stderr:', stderr);
                                         // Attempt to delete the (possibly empty) output file on error
                                         fs.unlink(tempOutputPath, (unlinkErr) => {
                                                   if (unlinkErr && unlinkErr.code !== 'ENOENT') {
                                                   console.error('Error deleting temp output file on error:', unlinkErr);
                                                   }
                                                   });
                                         return reject(error);
                                         }
                                         
                                         resolve(tempOutputPath);
                                         });
                                    });
                       });
}

async function generateVideoThumbnail(videoBuffer) {
    const tempVideoPath = path.join(os.tmpdir(), `tmp_${Date.now()}.mp4`);
    const thumbnailName = `thumbnail_${Date.now()}.png`;
    const thumbnailPath = path.join(os.tmpdir(), thumbnailName);
    
    return new Promise((resolve, reject) => {
                       try {
                       fs.writeFileSync(tempVideoPath, videoBuffer);
                       
                       ffmpeg(tempVideoPath)
                       .on('end', () => {
                           fs.unlinkSync(tempVideoPath);
                           resolve(thumbnailPath);
                           })
                       .on('error', (error) => {
                           if (fs.existsSync(tempVideoPath)) fs.unlinkSync(tempVideoPath);
                           reject(error);
                           })
                       .screenshots({
                                    timestamps: [0],
                                    filename: thumbnailName,
                                    folder: os.tmpdir()
                                    });
                       } catch (error) {
                       reject(error);
                       }
                       });
}

// Socket server setup
const socketServer = net.createServer((socket) => {
                                      socket.name = socket.remoteAddress + ":" + socket.remotePort;
                                      queueClients.push(socket);
                                      console.log(socket.name + " is connected\n");
                                      
                                      // Send server token
                                      socket.write(JSON.stringify({
                                                                  sender: "wspl-server",
                                                                  token: TOKENS.SERVER
                                                                  }));
                                      
                                      // Set up WhatsApp client event listeners for this socket
                                      setupWhatsAppEventListeners(socket);
                                      
                                      // Handle socket data
                                      socket.on("data", (data) => {
                                                if (clients.indexOf(socket) === -1) {
                                                try {
                                                const parsedData = JSON.parse(data);
                                                if (parsedData.sender === "wspl-client" && parsedData.token === TOKENS.CLIENT) {
                                                queueClients.splice(queueClients.indexOf(socket), 1);
                                                clients.push(socket);
                                                socket.write(JSON.stringify({
                                                                            sender: "wspl-server",
                                                                            response: "ok"
                                                                            }));
                                                } else {
                                                socket.write(JSON.stringify({
                                                                            sender: "wspl-server",
                                                                            response: "reject"
                                                                            }));
                                                socket.destroy();
                                                queueClients.splice(queueClients.indexOf(socket), 1);
                                                }
                                                } catch (error) {
                                                console.error("Error parsing socket data:", error);
                                                socket.destroy();
                                                }
                                                }
                                                });
                                      
                                      // Handle socket end
                                      socket.on("end", () => {
                                                queueClients.splice(queueClients.indexOf(socket), 1);
                                                clients.splice(clients.indexOf(socket), 1);
                                                console.log(socket.name + " left connection.\n");
                                                });
                                      
                                      // Handle socket error
                                      socket.on("error", (error) => {
                                                console.error(`Error with ${socket.name}:`, error.code);
                                                reconnect(socket);
                                                });
                                      });

function setupWhatsAppEventListeners(socket) {
    client.setMaxListeners(16);
    
    client.on("message", async (message) => {
              if (message.broadcast === true) {
              socket.write(JSON.stringify({
                                          sender: "wspl-server",
                                          response: "NEW_BROADCAST_NOTI"
                                          }));
              } else {
              socket.write(JSON.stringify({
                                          sender: "wspl-server",
                                          // NEW_MESSAGE
                                          response: "NEW_MESSAGE_NOTI",
                                          body: {
                                          msgBody: message.body,
                                          from: message.from.split("@")[0],
                                          author: message.author ? message.author.split("@")[0] : "",
                                          type: message.type
                                          }
                                          }));
              }
              });
    
    client.on("message_ack", async (message, ack) => {
              socket.write(JSON.stringify({
                                          sender: "wspl-server",
                                          response: "ACK_MESSAGE",
                                          body: {
                                          from: message.from.split("@")[0],
                                          msgId: message.id,
                                          ack: ack
                                          }
                                          }));
              });
    
    client.on("message_revoke_me", async (message) => {
              socket.write(JSON.stringify({
                                          sender: "wspl-server",
                                          response: "REVOKE_MESSAGE"
                                          }));
              });
    
    client.on("message_revoke_everyone", async (message, revokedMessage) => {
              socket.write(JSON.stringify({
                                          sender: "wspl-server",
                                          response: "REVOKE_MESSAGE"
                                          }));
              });
    
    client.on("group_join", async (notification) => {
              socket.write(JSON.stringify({
                                          sender: "wspl-server",
                                          response: "NEW_MESSAGE"
                                          }));
              });
    
    client.on("group_update", async (notification) => {
              socket.write(JSON.stringify({
                                          sender: "wspl-server",
                                          response: "NEW_MESSAGE"
                                          }));
              });
    
    client.on("chat_state_changed", ({ chatId, chatState }) => {
              socket.write(JSON.stringify({
                                          sender: "wspl-server",
                                          response: "CONTACT_CHANGE_STATE",
                                          body: {
                                          status: chatState,
                                          from: chatId.split("@")[0]
                                          }
                                          }));
              });
}

global.loggedin = 0;
global.qrDataUrl = null;

// WhatsApp Client event listeners
client.on("qr", async (qr) => {
          try {
          global.qrDataUrl = await QRCode.toDataURL(qr);
          qrcode.generate(qr, { small: true });
          } catch (err) {
          console.error("Failed to generate QR code data URL:", err);
          }
          });


client.on("ready", () => {
          global.loggedin = 1;
          console.log("Server A and B are ready.");
          });

client.on("disconnected", (reason) => {
          console.log("Disconnected");
          if (reInitializeCount === 1 && reason === "NAVIGATION") {
          reInitializeCount++;
          client.initialize();
          }
          });

client.on("remote_session_saved", () => {
          console.log("Session saved");
          });

// HTTP Routes
app.get("/", async (req, res) => {
        res.send("WhatsApp Legacy for iOS 3.1 - 6.1.6");
        });

app.get("/loggedInYet", (req, res) => {
        res.send(global.loggedin ? "true" : "false");
        });

app.get("/qr", async (req, res) => {
        if (global.loggedin) {
        res.send("Success");
        } else {
        res.send(global.qrDataUrl);
        }
        });

app.all("/getChats", async (req, res) => {
        try {
        const allChats = await client.getChats();
        let chatList = [];
        const chatsWithMessages = allChats.filter(chat => chat.timestamp || chat.lastMessage);
        
        chatList = await Promise.all(chatsWithMessages.map(processLastMessageCaption));
        
        const groupChats = chatList.filter(chat => chat.isGroup);
        const groupListPromises = groupChats.map(async (chat) => {
                                                 const fullChat = await client.getChatById(chat.id._serialized);
                                                 fullChat.groupDesc = fullChat.description;
                                                 return fullChat;
                                                 });
        
        const groupList = await Promise.all(groupListPromises);
        
        res.json({ chatList, groupList });
        } catch (error) {
        res.status(500).send("Failed to get chats: " + error.message);
        }
        });

app.post("/syncChat/:contactId", async (req, res) => {
         try {
         const contactId = buildContactId(req.params.contactId, req.query.isGroup == 1);
         const chat = await client.getChatById(contactId);
         chat.syncHistory();
         res.json({});
         } catch (error) {
         res.status(500).send(error.message);
         }
         });

app.all("/getBroadcasts", async (req, res) => {
        try {
        const broadcasts = await client.getBroadcasts();
        const filteredBroadcasts = broadcasts.filter(broadcast => broadcast.msgs.length > 0);
        res.json({ broadcastList: filteredBroadcasts });
        } catch (error) {
        res.status(500).send("Failed to get broadcasts: " + error.message);
        }
        });

app.all("/getContacts", async (req, res) => {
        try {
        const allContacts = await client.getContacts();
        const waContacts = allContacts.filter(contact =>
                                              contact.id.server === "c.us" && contact.isWAContact
                                              );
        
        const contactList = await Promise.all(waContacts.map(async (contact) => {
                                                             if (contact.isMyContact === true && contact.isWAContact === true) {
                                                             const about = await contact.getAbout();
                                                             const commonGroups = await contact.getCommonGroups();
                                                             contact.profileAbout = about;
                                                             contact.commonGroups = commonGroups;
                                                             }
                                                             const formattedNumber = await contact.getFormattedNumber();
                                                             contact.formattedNumber = formattedNumber;
                                                             return contact;
                                                             }));
        
        contactList.sort((a, b) => {
                         const nameA = (a.name || "").toLowerCase();
                         const nameB = (b.name || "").toLowerCase();
                         if (nameA < nameB) return -1;
                         if (nameA > nameB) return 1;
                         return 0;
                         });
        
        res.json({ contactList });
        } catch (error) {
        res.status(500).send("Failed to get contacts: " + error.message);
        }
        });

app.all("/getGroups", async (req, res) => {
        try {
        const allChats = await client.getChats();
        const groupChats = allChats.filter(chat => chat.isGroup);
        
        const groupListPromises = groupChats.map(async (chat) => {
                                                 const fullChat = await client.getChatById(chat.id._serialized);
                                                 fullChat.groupDesc = fullChat.description;
                                                 return fullChat;
                                                 });
        
        const groupList = await Promise.all(groupListPromises);
        res.json({ groupList });
        } catch (error) {
        res.status(500).send("Failed to get groups: " + error.message);
        }
        });

app.all("/getProfileImg/:id", async (req, res) => {
        try {
        const profilePicUrl = await client.getProfilePicUrl(req.params.id + "@c.us");
        const response = await axios.get(profilePicUrl, { responseType: "arraybuffer" });
        const buffer = Buffer.from(response.data, "binary");
        
        res.set("Content-Type", response.headers["content-type"]);
        res.send(buffer);
        } catch (error) {
        res.status(500).send(error.message);
        }
        });

app.all("/getGroupImg/:id", async (req, res) => {
        try {
        const profilePicUrl = await client.getProfilePicUrl(req.params.id + "@g.us");
        const response = await axios.get(profilePicUrl, { responseType: "arraybuffer" });
        const buffer = Buffer.from(response.data, "binary");
        
        res.set("Content-Type", response.headers["content-type"]);
        res.send(buffer);
        } catch (error) {
        res.status(500).send(error.message);
        }
        });

app.all("/getProfileImgHash/:id", async (req, res) => {
        try {
        const profilePicUrl = await client.getProfilePicUrl(req.params.id + "@c.us");
        const response = await axios.get(profilePicUrl, { responseType: "arraybuffer" });
        const buffer = Buffer.from(response.data, "binary");
        const hash = crypto.createHash("md5").update(buffer).digest("hex");
        res.send(hash);
        } catch (error) {
        res.send(null);
        }
        });

app.all("/getGroupImgHash/:id", async (req, res) => {
        try {
        const profilePicUrl = await client.getProfilePicUrl(req.params.id + "@g.us");
        const response = await axios.get(profilePicUrl, { responseType: "arraybuffer" });
        const buffer = Buffer.from(response.data, "binary");
        const hash = crypto.createHash("md5").update(buffer).digest("hex");
        res.send(hash);
        } catch (error) {
        res.send(null);
        }
        });

app.all("/getGroupInfo/:id", async (req, res) => {
        try {
        const chat = await client.getChatById(req.params.id + "@g.us");
        chat.groupDesc = chat.description;
        res.json(chat);
        } catch (error) {
        res.status(500).send(error.message);
        }
        });

app.all("/getChatMessages/:contactId", async (req, res) => {
        try {
        const contactId = buildContactId(req.params.contactId, req.query.isGroup == 1);
        const chat = await client.getChatById(contactId);
        const limit = req.query.isLight == 1 ? 100 : 4294967295;
        const messages = await chat.fetchMessages({ limit });
        
        const filteredMessages = messages.filter(message => message.type !== "notification_template");
        const processedMessages = await Promise.all(filteredMessages.map(processMessageForCaption));
        
        res.setHeader("Content-Type", "application/json");
        res.json({
                 chatMessages: processedMessages,
                 fromNumber: contactId.split("@")[0]
                 });
        } catch (error) {
        res.status(500).send(error.message);
        }
        });

app.post("/setTypingStatus/:contactId", async (req, res) => {
         try {
         const contactId = buildContactId(req.params.contactId, req.query.isGroup == 1);
         const chat = await client.getChatById(contactId);
         
         if (req.query.isVoiceNote == 1) {
         await chat.sendStateRecording();
         } else {
         await chat.sendStateTyping();
         }
         
         res.json({});
         } catch (error) {
         res.status(500).send(error.message);
         }
         });

app.post("/clearState/:contactId", async (req, res) => {
         try {
         const contactId = buildContactId(req.params.contactId, req.query.isGroup == 1);
         const chat = await client.getChatById(contactId);
         await chat.clearState();
         res.json({});
         } catch (error) {
         res.status(500).send(error.message);
         }
         });

app.post("/seenBroadcast/:messageId", async (req, res) => {
         try {
         const messageId = decodeURIComponent(req.params.messageId);
         await client.getMessageById(messageId);
         res.json({});
         } catch (error) {
         res.status(500).send(error.message);
         }
         });

app.all("/getAudioData/:audioId", async (req, res) => {
        try {
        const audioId = decodeURIComponent(req.params.audioId);
        const message = await client.getMessageById(audioId);
        const media = await message.downloadMedia();
        
        if (media) {
        const audioBuffer = Buffer.from(media.data, "base64");
        const convertedAudioPath = await downloadAndConvertAudio(audioBuffer);
        
        res.set("Content-Type", "audio/mpeg");
        res.sendFile(convertedAudioPath, (error) => {
                     if (error) {
                     console.error("Error sending file:", error);
                     if (!res.headersSent) {
                     res.status(500).send("Error sending converted file.");
                     }
                     } else {
                     fs.unlinkSync(convertedAudioPath);
                     }
                     });
        } else {
        res.status(404).send("Audio not found");
        }
        } catch (error) {
        if (!res.headersSent) {
        res.status(500).send(error.message);
        }
        }
        });

app.all("/getDocument/:documentId", async (req, res) => {
        try {
        const documentId = decodeURIComponent(req.params.documentId);
        const message = await client.getMessageById(documentId);
        if (!message || !message.hasMedia) {
        return res.status(404).send("Message not found or it has no media.");
        }
        
        const media = await message.downloadMedia();
        if (media) {
        res.set("Content-Type", media.mimetype);
        // Include filename for the client
        res.set("Content-Disposition", `attachment; filename*=UTF-8''${encodeURIComponent(media.filename)}`);
        res.send(Buffer.from(media.data, "base64"));
        } else {
        res.status(404).send("Document not found.");
        }
        } catch (error) {
        console.error(`Error fetching document: ${error.message}`);
        if (!res.headersSent) {
        res.status(500).send(error.message);
        }
        }
        });

/*app.all("/getMediaData/:mediaId", async (req, res) => {
 try {
 const message = await client.getMessageById(req.params.mediaId);
 const media = await message.downloadMedia();
 
 if (media) {
 res.set("Content-Type", media.mimetype);
 res.send(Buffer.from(media.data, "base64"));
 } else {
 res.status(404).send("Media not found");
 }
 } catch (error) {
 if (!res.headersSent) {
 res.status(500).send(error.message);
 }
 }
 });*/

app.all("/getMediaData/:mediaId", async (req, res) => {
        console.log("Downloading media from ID");
        try {
        const messageId = decodeURIComponent(req.params.mediaId);
        const message = await client.getMessageById(messageId);
        const media = await message.downloadMedia();
        
        if (!media) {
        console.log(`Failed to download media for message ID: ${messageId}`);
        return res.status(404).send("Media not found");
        }
        console.log(`Downloaded media for ID ${messageId}. Mimetype: ${media.mimetype}`);
        
        const isVideo = media.mimetype.startsWith("video/");
        
        if (isVideo) {
        console.log("is mp4, starting conversion for iOS 3");
        const tempDir = os.tmpdir();
        
        const safeFilename = messageId.replace(/[^a-zA-Z0-9.-]/g, '_');
        const rawFile = path.join(tempDir, `${safeFilename}.mp4`);
        const movFile = path.join(tempDir, `${safeFilename}.mov`);
        
        fs.writeFileSync(rawFile, Buffer.from(media.data, "base64"));
        
        console.log("Converting video for iOS 3 standards")
        const cmd = `"${ffmpegPath}" -y -i "${rawFile}" -vf "scale='min(640,iw)':'min(480,ih)':force_original_aspect_ratio=decrease,fps=30,yadif" -c:v libx264 -preset veryfast -crf 23 -c:a aac -b:a 160k -ar 48000 -ac 2 -movflags +faststart "${movFile}"`;
        
        const child = exec(cmd, (err) => {
                           if (err) {
                           console.error("FFmpeg error:", err);
                           fs.unlink(rawFile, () => {});
                           fs.unlink(movFile, () => {});
                           return res.status(500).send("Failed to convert MP4 to MOV");
                           }
                           
                           res.setHeader("Content-Type", "video/quicktime");
                           const stream = fs.createReadStream(movFile);
                           stream.pipe(res);
                           
                           stream.on("close", () => {
                                     fs.unlink(rawFile, () => {});
                                     fs.unlink(movFile, () => {});
                                     });
                           stream.on("error", (streamErr) => {
                                     console.error("Stream error:", streamErr);
                                     fs.unlink(rawFile, () => {});
                                     fs.unlink(movFile, () => {});
                                     if (!res.headersSent) {
                                     res.status(500).end();
                                     }
                                     });
                           });
        child.stdout && child.stdout.on('data', data => console.log('ffmpeg stdout:', data));
        child.stderr && child.stderr.on('data', data => console.error('ffmpeg stderr:', data));
        } else {
        // Send all other media types as-is
        res.setHeader("Content-Type", media.mimetype);
        res.send(Buffer.from(media.data, "base64"));
        }
        } catch (error) {
        console.error("Media error:", error);
        if (!res.headersSent) {
        res.status(500).send(error.message);
        }
        }
        });

app.all("/getVideoThumbnail/:mediaId", async (req, res) => {
        try {
        const messageId = decodeURIComponent(req.params.mediaId);
        const message = await client.getMessageById(messageId);
        
        if (message && message.type === "video") {
        const media = await message.downloadMedia();
        
        if (media && media.mimetype.startsWith("video/")) {
        const videoBuffer = Buffer.from(media.data, "base64");
        const thumbnailPath = await generateVideoThumbnail(videoBuffer);
        
        res.set("Content-Type", "image/png");
        res.sendFile(thumbnailPath, (error) => {
                     if (error) {
                     console.error("Error sending thumbnail:", error);
                     if (!res.headersSent) {
                     res.status(500).send("Error sending thumbnail file.");
                     }
                     } else {
                     fs.unlinkSync(thumbnailPath);
                     }
                     });
        } else {
        res.status(404).send("Video not found.");
        }
        } else {
        res.status(404).send("Message not found or it is not a video.");
        }
        } catch (error) {
        if (!res.headersSent) {
        res.status(500).send(error.message);
        }
        }
        });

app.post("/sendMessage/:contactId", async (req, res) => {
         try {
         const contactId = buildContactId(req.params.contactId, req.query.isGroup == 1);
         const chat = await client.getChatById(contactId);
         
         // Handle text message
         if (req.body.messageText) {
         if (req.body.replyTo) {
         const replyMessage = await client.getMessageById(req.body.replyTo);
         await replyMessage.reply(req.body.messageText);
         } else {
         await chat.sendMessage(req.body.messageText);
         }
         }
         
         // Handle voice note
         if (req.body.sendAsVoiceNote) {
         const audioData = req.body.mediaBase64;
         const audioBuffer = Buffer.from(audioData, "base64");
         const tempAudioPath = path.join(os.tmpdir(), `temp_audio_${Date.now()}.caf`);
         const convertedAudioPath = path.join(os.tmpdir(), `test_out_${Date.now()}.mp3`);
         
         fs.writeFileSync(tempAudioPath, audioBuffer);
         
         ffmpeg(tempAudioPath)
         .toFormat("mp3")
         .on("end", async () => {
             fs.unlinkSync(tempAudioPath);
             const media = await MessageMedia.fromFilePath(convertedAudioPath);
             await chat.sendMessage(media, { sendAudioAsVoice: true });
             fs.unlinkSync(convertedAudioPath);
             })
         .on("error", (error) => {
             console.error("Error during conversion:", error);
             })
         .save(convertedAudioPath);
         }
         
         // Handle photo
         if (req.body.sendAsPhoto) {
         const imageData = req.body.mediaBase64;
         const imageBuffer = Buffer.from(imageData, "base64");
         const tempImagePath = path.join(os.tmpdir(), `temp_img_${Date.now()}.jpg`);
         
         fs.writeFileSync(tempImagePath, imageBuffer);
         const media = await MessageMedia.fromFilePath(tempImagePath);
         await chat.sendMessage(media);
         fs.unlinkSync(tempImagePath);
         }
         
         res.status(200).json({ response: "ok" });
         } catch (error) {
         if (!res.headersSent) {
         res.status(500).send(error.message);
         }
         }
         });

app.post("/setMute/:contactId/:muteLevel", async (req, res) => {
         try {
         const contactId = buildContactId(req.params.contactId, req.query.isGroup == 1);
         const chat = await client.getChatById(contactId);
         const muteLevel = parseInt(req.params.muteLevel);
         
         console.log(muteLevel);
         
         switch (muteLevel) {
         case -1:
         await chat.unmute();
         break;
         case 0:
         await chat.mute(8 * 60 * 60 * 1000); // 8 hours
         break;
         case 1:
         await chat.mute(7 * 24 * 60 * 60 * 1000); // 1 week
         break;
         case 2:
         await chat.mute(); // Forever
         break;
         }
         
         res.status(200).json({ response: "ok" });
         } catch (error) {
         if (!res.headersSent) {
         res.status(500).send(error.message);
         }
         }
         });

app.post("/setBlock/:contactId", async (req, res) => {
         try {
         const contactId = buildContactId(req.params.contactId, req.query.isGroup == 1);
         const contact = await client.getContactById(contactId);
         
         if (contact.isBlocked) {
         await contact.unblock();
         } else {
         await contact.block();
         }
         
         res.status(200).json({ response: "ok" });
         } catch (error) {
         if (!res.headersSent) {
         res.status(500).send(error.message);
         }
         }
         });

app.post("/deleteChat/:contactId", async (req, res) => {
         try {
         const contactId = buildContactId(req.params.contactId, req.query.isGroup == 1);
         const chat = await client.getChatById(contactId);
         await chat.delete();
         res.status(200).json({ response: "ok" });
         } catch (error) {
         if (!res.headersSent) {
         res.status(500).send(error.message);
         }
         }
         });

app.post("/readChat/:contactId", async (req, res) => {
         try {
         const isGroup = req.query.isGroup == 1;
         const rawId = req.params.contactId;
         const contactId = buildContactId(rawId, isGroup);
         
         console.log("Contact:", rawId, "isGroup:", req.query.isGroup);
         console.log("Built ID:", contactId);
         
         const chat = await client.getChatById(contactId);
         console.log("Unread count:", chat.unreadCount);
         
         if (chat.unreadCount > 0) {
         await chat.sendSeen();
         console.log("Marked as seen!");
         } else {
         console.log("No unread messages.");
         }
         
         await client.resetState();
         
         res.status(200).json({ response: "ok" });
         } catch (error) {
         console.error("Error in readChat:", error);
         if (!res.headersSent) {
         res.status(500).send(error.message);
         }
         }
         });


app.post("/leaveGroup/:groupId", async (req, res) => {
         try {
         const groupId = req.params.groupId + "@g.us";
         const chat = await client.getChatById(groupId);
         await chat.leave();
         res.status(200).json({ response: "ok" });
         } catch (error) {
         if (!res.headersSent) {
         res.status(500).send(error.message);
         }
         }
         });

app.all("/getQuotedMessage/:messageId", async (req, res) => {
        try {
        const messageId = decodeURIComponent(req.params.messageId);
        const message = await client.getMessageById(messageId);
        
        if (!message) {
        return res.status(404).send("Message not found");
        }
        
        if (message.hasQuotedMsg) {
        const quotedMessage = await message.getQuotedMessage();
        return res.json({
                        originalMessage: message.body,
                        quotedMessage: {
                        id: quotedMessage.id._serialized,
                        body: quotedMessage.body,
                        from: quotedMessage.from
                        }
                        });
        }
        
        return res.status(404).send("No quoted message found");
        } catch (error) {
        if (!res.headersSent) {
        res.status(500).send(error.message);
        }
        }
        });

app.post("/setStatusInfo/:statusMsg", async (req, res) => {
         try {
         await client.setStatus(req.params.statusMsg);
         res.status(200).json({ response: "ok" });
         } catch (error) {
         if (!res.headersSent) {
         res.status(500).send(error.message);
         }
         }
         });

app.post("/deleteMessage/:messageId/:everyone", async (req, res) => {
         try {
         const messageId = decodeURIComponent(req.params.messageId);
         const message = await client.getMessageById(messageId);
         
         if (!message) {
         return res.status(404).send("Message not found");
         }
         
         const deleteForEveryone = req.params.everyone == 2;
         const result = await message.delete(deleteForEveryone);
         
         res.status(200).json({ response: result });
         } catch (error) {
         if (!res.headersSent) {
         res.status(500).send(error.message);
         }
         }
         });

// Start servers
socketServer.listen(SERVER_CONFIG.PORT, SERVER_CONFIG.HOST);
client.initialize();
app.listen(SERVER_CONFIG.HTTP_PORT);