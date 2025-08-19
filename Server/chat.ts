import express from "express";
import { Client } from "whatsapp-web.js";
import * as utils from "./utils";
import axios from "axios";
import crypto from "crypto";

export function setUpListGetters(app: express.Express, client: Client) {
  app.get("/getChats", async (_, res) => {
    try {
      const allChats = await client.getChats();
      res.json(allChats.filter((chat) => !chat.isGroup));
    } catch (error) {
      res.status(500).send("Failed to get chats: " + error.message);
    }
  });

  app.post("/syncChat/:contactId", async (req, res) => {
    try {
      const contactId = utils.buildContactId(
        req.params.contactId,
        req.query.isGroup === "1",
      );
      (await client.getChatById(contactId)).syncHistory();
      res.status(200);
    } catch (error) {
      res.status(500).send(error.message);
    }
  });

  app.get("/getBroadcasts", async (_, res) => {
    try {
      const broadcasts = await client.getBroadcasts();
      const filteredBroadcasts = broadcasts.filter(
        (broadcast) => broadcast.msgs.length > 0,
      );
      res.json({ broadcastList: filteredBroadcasts });
    } catch (error) {
      res.status(500).send("Failed to get broadcasts: " + error.message);
    }
  });

  app.get("/getContacts", async (_, res) => {
    try {
      const allContacts = await client.getContacts();
      const contactList = allContacts.sort((a, b) => {
        const nameA = (a.name || "").toLowerCase();
        const nameB = (b.name || "").toLowerCase();
        if (nameA < nameB) return -1;
        if (nameA > nameB) return 1;
        return 0;
      });

      res.json(contactList);
    } catch (error) {
      res.status(500).send("Failed to get contacts: " + error.message);
    }
  });

  app.get("/getGroups", async (_, res) => {
    try {
      const allChats = await client.getChats();
      res.json(allChats.filter((chat) => chat.isGroup));
    } catch (error) {
      res.status(500).send("Failed to get groups: " + error.message);
    }
  });

  app.get("/getChatMessages/:contactId", async (req, res) => {
    try {
      const contactId = utils.buildContactId(
        req.params.contactId,
        req.query.isGroup === "1",
      );
      const chat = await client.getChatById(contactId);
      const limit = req.query.isLight === "1" ? 100 : 4294967295;
      const messages = await chat.fetchMessages({ limit });

      const filteredMessages = messages.filter(
        (message) => message.type !== "notification_template",
      );

      res.json(filteredMessages);
    } catch (error) {
      res.status(500).send(error.message);
    }
  });
}

export function setUpChatGetters(app: express.Express, client: Client) {
  app.get("/getProfileImg/:id", async (req, res) => {
    try {
      const profilePicUrl = await client.getProfilePicUrl(
        req.params.id + "@c.us",
      );
      const response = await axios.get(profilePicUrl, {
        responseType: "arraybuffer",
      });
      const buffer = Buffer.from(response.data, "binary");

      res.set("Content-Type", response.headers["content-type"]);
      res.send(buffer);
    } catch (error) {
      res.status(500).send(error.message);
    }
  });

  app.get("/getGroupImg/:id", async (req, res) => {
    try {
      const profilePicUrl = await client.getProfilePicUrl(
        req.params.id + "@g.us",
      );
      const response = await axios.get(profilePicUrl, {
        responseType: "arraybuffer",
      });
      const buffer = Buffer.from(response.data, "binary");

      res.set("Content-Type", response.headers["content-type"]);
      res.send(buffer);
    } catch (error) {
      res.status(500).send(error.message);
    }
  });

  app.get("/getProfileImgHash/:id", async (req, res) => {
    try {
      const profilePicUrl = await client.getProfilePicUrl(
        req.params.id + "@c.us",
      );
      const response = await axios.get(profilePicUrl, {
        responseType: "arraybuffer",
      });
      const buffer = Buffer.from(response.data, "binary");
      const hash = crypto.createHash("md5").update(buffer).digest("hex");
      res.send(hash);
    } catch (error) {
      res.send(null);
    }
  });

  app.get("/getGroupImgHash/:id", async (req, res) => {
    try {
      const profilePicUrl = await client.getProfilePicUrl(
        req.params.id + "@g.us",
      );
      const response = await axios.get(profilePicUrl, {
        responseType: "arraybuffer",
      });
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
      res.json(chat);
    } catch (error) {
      res.status(500).send(error.message);
    }
  });
}
