import { Chat, Message } from "whatsapp-web.js";
import path from "node:path";
import fs from "fs";
import os from "os";
import { exec } from "child_process";
import ffmpeg from "fluent-ffmpeg";

export const SERVER_CONFIG = JSON.parse(
  fs.readFileSync(path.join(process.cwd(), "config.json"), "utf-8"),
);

console.log(`Using ${path.join(process.cwd(), "config.json")}`);

export const ffmpegPath: string =
  !SERVER_CONFIG.ffmpegPath || fs.existsSync(SERVER_CONFIG.ffmpegPath)
    ? path.join(process.cwd(), "ffmpeg", "ffmpeg.exe")
    : SERVER_CONFIG.ffmpegPath;

export function buildContactId(id: string, isGroup = false) {
  return id + (isGroup ? "@g.us" : "@c.us");
}

export function processMessageForCaption(message: Message) {
  // if (message._data && message._data.caption) {
  //   message._data.body = undefined;
  //   message.body = message._data.caption;
  //   message._data.caption = undefined;
  // }
  return message;
}

export function processLastMessageCaption(chat: Chat) {
  chat.lastMessage = chat.lastMessage
    ? processMessageForCaption(chat.lastMessage)
    : chat.lastMessage;
  return chat;
}

export async function downloadAndConvertAudio(
  audioBuffer: string | NodeJS.ArrayBufferView,
  outputFormat = "mp3",
): Promise<string> {
  const tempInputPath = path.join(
    os.tmpdir(),
    `temp_audio_input_${Date.now()}.ogg`,
  );
  const tempOutputPath = path.join(
    os.tmpdir(),
    `converted_audio_output_${Date.now()}.${outputFormat}`,
  );

  return new Promise((resolve, reject) => {
    fs.writeFile(tempInputPath, audioBuffer, (err) => {
      if (err) {
        console.error("Error writing temp audio file:", err);
        return reject(err);
      }

      const command = `"${ffmpegPath}" -i "${tempInputPath}" -acodec libmp3lame "${tempOutputPath}"`;

      exec(command, (error, _, stderr) => {
        // Always delete the temp input file
        fs.unlink(tempInputPath, (unlinkErr) => {
          if (unlinkErr)
            console.error("Error deleting temp input file:", unlinkErr);
        });

        if (error) {
          console.error("[FFmpeg] Execution error:", error.message);
          console.error("[FFmpeg] stderr:", stderr);
          // Attempt to delete the (possibly empty) output file on error
          fs.unlink(tempOutputPath, (unlinkErr) => {
            if (unlinkErr && unlinkErr.code !== "ENOENT") {
              console.error(
                "Error deleting temp output file on error:",
                unlinkErr,
              );
            }
          });
          return reject(error);
        }

        resolve(tempOutputPath);
      });
    });
  });
}

export async function generateVideoThumbnail(
  videoBuffer: string | NodeJS.ArrayBufferView,
): Promise<string> {
  const tempVideoPath = path.join(os.tmpdir(), `tmp_${Date.now()}.mp4`);
  const thumbnailName = `thumbnail_${Date.now()}.png`;
  const thumbnailPath = path.join(os.tmpdir(), thumbnailName);

  return new Promise((resolve, reject) => {
    try {
      fs.writeFileSync(tempVideoPath, videoBuffer);

      ffmpeg(tempVideoPath)
        .on("end", () => {
          fs.unlinkSync(tempVideoPath);
          resolve(thumbnailPath);
        })
        .on("error", (error) => {
          if (fs.existsSync(tempVideoPath)) fs.unlinkSync(tempVideoPath);
          reject(error);
        })
        .screenshots({
          timestamps: [0],
          filename: thumbnailName,
          folder: os.tmpdir(),
        });
    } catch (error) {
      reject(error);
    }
  });
}
