# WhatsApp Server Documentation

This documentation covers all features of the WhatsApp server, including HTTP endpoints and TCP server implementation details. If you need any extra clarification, please let me know.

## Table of Contents

1. Server Overview
2. HTTP Endpoints
    2.1 Authentication & Status
    2.2 Event Handling
    2.3 Chat Management
    2.4 Contact Management
    2.5 Group Management
    2.6 Media Handling
    2.7 Message Handling
3. TCP Server
    3.1 Connection Lifecycle
    3.2 Message Protocol
    3.3 Notification Types
    3.4 Error Handling
    3.5 Connection Management
4. Event System

## Server Overview

The WhatsApp server is built using Node.js with Express for HTTP endpoints and net for TCP socket connections. It uses the whatsapp-web.js library to interface with WhatsApp Web.

Key Features:
 - Multiple client support via TCP sockets
 - Event queue system for message tracking
 - Media conversion for compatibility
 - Full WhatsApp Web feature support
 - HTTP API for remote clients

## HTTP Endpoints

Most routes will return code 200 on success, 500 on failure.

### 2.1 Authentication & Status

#### GET `/`
 - Returns: Basic server identification string
 - Use: Simple server status check

#### GET `/loggedInYet`
 - Returns: a boolean as a string
 - Use: Check if WhatsApp session is authenticated

#### GET `/qr`
 - Returns: QR code data URL or "Success" if already logged in
 - Use: Get QR code for initial authentication

#### GET `/code` (not implemented)
 - Same as `/qr` but uses pairing code instead

### 2.2 Event Handling

#### GET `/getUpdates` (not implemented)
 - Parameters:
    - since: timestamp (optional)
 - Returns: JSON with new events since specified timestamp
 - Use: Poll for new events (messages, status changes, etc.)

#### GET `/getUpdatesPolling` (not implemented)
 - Parameters:
    - since: timestamp (optional)
    - timeout: milliseconds (optional, default 5000)
 - Returns: JSON with new events (long polling implementation)
 - Use: More efficient event polling with timeout

### 2.3 Chat Management

#### Request parameters
 - IDs are usually un-"serialized" ones (WWebJS's `ContactId::user`)
 - Booleans are represented as 0 (false) and 1 (true)

#### GET `/getChats`
 - Returns: JSON with all chats (individual only)
 - Serialized WWebJS Chat objects

#### GET `/getGroups`
 - Returns: The same as `/getChats`, but with groups
 - Serialized WWebJS Group objects, which are derived from Chat

#### POST `/syncChat/:contactId`
 - Parameters:
    - contactId: chat ID
    - isGroup: boolean (query parameter)
 - Returns: Status code 200 on success
 - Use: Sync chat history with server

#### GET `/getChatMessages/:contactId`
 - Parameters:
    - contactId: chat ID
    - isGroup: boolean (query parameter)
    - limit: integer, defaults to 100 (query parameter, optional)
 - Returns: JSON with last `limit` messages in chat
 - Use: Retrieve message history for specific chat

#### POST `/ReadChat/:contactId`
 - Parameters:
    - contactId: chat ID
    - isGroup: boolean (query parameter)
 - Returns: JSON with operation status
 - Use: Mark chat as read OR not read

#### POST `/ArchiveChat/:contactId`
  - Parameters:
    - contactID
    - archive: boolean (query parameter)
  - Use: (un)archives chat

#### POST `/DeleteChat/:contactId`
 - Parameters:
    - contactId: chat ID
    - isGroup: boolean (query parameter)
 - Returns: JSON with operation status
 - Use: Delete chat from list

#### POST `/Mute/:contactId`
  - Parameters:
    - contactId
    - mute: boolean (query parameter)
    - expirationData: string presentation of a specific time&date (query parameter) - optional. If empty and `mute` is true, a permanent mute.
  - Use: (un)mute a chat

### 2.4 Contact Management

#### GET `/getContacts`
 - Returns: JSON with all contacts
 - Use: Retrieve complete contact list

#### GET `/getProfileImg/:id`
 - Returns: Contact profile image binary data
 - Use: Get contact profile picture

#### GET `/getProfileImgHash/:id`
 - Returns: MD5 hash of profile image or null
 - Use: Check if profile image changed

#### POST `/setBlock/:contactId`
 - Parameters:
    - contactId: contact ID
    - isGroup: boolean (query parameter)
 - Returns: JSON with operation status
 - Use: Block/unblock contact

#### POST `/profileSetName/:name`
 - Parameters:
    - name: new display name
 - Use: Set your own profile name

#### POST `/profileSetStatus/:status`
 - Parameters:
    - status: new status text
 - Use: Set your own profile status message

#### POST `/profileSetPicture/:mediaBase64`
 - Parameters:
    - mediaBase64: base64-encoded image
 - Use: Set your own profile picture

#### POST `/profileDeleteAvatar`
 - Use: Delete your own profile picture

### 2.5 Group Management

#### GET `/getGroups`
 - Returns: JSON with all groups
 - Use: Retrieve complete group list

#### GET `/getGroupInfo/:id`
 - Returns: JSON with group details
 - Use: Get group metadata

#### GET `/getGroupImg/:id`
 - Returns: Group image binary data
 - Use: Get group profile picture

#### GET `/getGroupImgHash/:id`
 - Returns: MD5 hash of group image or null
 - Use: Check if group image changed

#### POST `/leaveGroup/:groupId`
 - Returns: JSON with operation status
 - Use: Leave specified group

### 2.6 Broadcast Management

#### GET `/getBroadcasts`
 - Returns: JSON list of broadcast lists with messages
 - Use: Retrieve broadcast lists that contain at least one message

#### POST `/seenBroadcast/:messageId`
 - Parameters:
    - messageId: broadcast message ID
 - Use: Mark broadcast message as seen

### 2.7 Media Handling

#### GET `/getAudioData/:audioId`
 - Returns: Converted audio in MP3 format
 - Use: Get audio message with iOS-compatible format

#### GET `/getDocument/:documentId`
 - Returns: Original document with proper headers
 - Use: Download document attachments

#### GET `/getMediaData/:mediaId`
 - Returns: Media file with proper headers
 - Use: Download media attachments (with video conversion)

#### GET `/getVideoThumbnail/:mediaId`
 - Returns: PNG thumbnail for video
 - Use: Get preview image for videos

### 2.8 Messaging

#### POST `/sendMessage/:contactId`
 - Parameters:
    - contactId: chat ID
    - isGroup: boolean (query parameter)
 - Body options:
    - messageText (string)
    - replyTo (message ID)
    - sendAsVoiceNote + mediaBase64
    - sendAsPhoto + mediaBase64
    - sendAsVideo + mediaBase64
    - sendAsSticker + mediaBase64
 - Returns: JSON with operation status
 - Use: Send messages and media

#### POST `/deleteMessage/:messageId`
 - Parameters:
    - messageId: message ID
    - everyone: boolean (query parameter)
 - Use: Delete a message for self or everyone

#### GET `/getQuotedMessage/:messageId`
 - Parameters:
    - messageId: message ID
 - Returns: JSON with original and quoted message details
 - Use: Retrieve quoted message content

### 2.9 Presence & Typing State

#### POST `/setTypingStatus/:contactId`
 - Parameters:
    - contactId: chat ID
    - isGroup: boolean (query parameter)
    - isVoiceNote: boolean (query parameter)
 - Use: Set typing or recording state in a chat

#### POST `/clearState/:contactId`
 - Parameters:
    - contactId: chat ID
    - isGroup: boolean (query parameter)
 - Use: Clear typing/recording state

### 2.10 Session Management

#### POST `/setStatusInfo/:statusMsg`
 - Parameters:
    - statusMsg: new status string
 - Use: Update account status message

#### ALL `/logout`
 - Use: Log out from the WhatsApp session

## TCP Server

### 3.1 Connection Lifecycle

1. Connection Initiation:
    - Client connects to configured port (default: 3001)
    - Server creates new socket instance
    - Server assigns unique client ID (IP:PORT combination)
    - Client added to connection queue

2. Authentication Handshake:
    - Server immediately sends auth token
        ```json
        {
            "sender": "wspl-server",
            "token": "3qGT_%78Dtr|&*7ufZoO"
        }
        ```
    - Client must respond within 5 seconds with:
        ```json
        {
            "sender": "wspl-client",
            "token": "vC.I)Xsfe(;p4YB6E5@y"
        }
        ```
    - Failed auth results in immediate disconnect

3. Client Promotion:
    - On successful auth, client moved from queue to active list
    - Server sends confirmation:
        ```json
        {
            "sender": "wspl-server",
            "response": "ok"
        }
        ```

### 3.2 Message Protocol

#### Message Format:
 - All messages are JSON strings
 - Must be newline (`\n`) delimited
 - Maximum message size of 1MB

#### Server --> Client
```json
{
    "sender": "wspl-server",
    "response": [MESSAGE_TYPE],
    "body": {
        <message speciffic data>
    }
}
```

#### CLIENT --> Server
```json
{
    "sender": "wspl-client",
    "request": [REQUEST_TYPE],
    "data": {
        <request data>
    }
}
```

### 3.3 Notification Types

#### `NEW_MESSAGE_NOTI`
```json
{
  sender: "wspl-server",
  response: "NEW_MESSAGE_NOTI",
  body: {
    msgBody: string,
    from: string (phone number),
    author: string (group messages only),
    type: string (message type)
  }
}
```

#### `ACK_MESSAGE`
```json
{
  sender: "wspl-server",
  response: "ACK_MESSAGE",
  body: {
    from: string,
    msgId: string,
    ack: number (1-3)
  }
}
```

#### `REVOKE_MESSAGE`
```json
{
  sender: "wspl-server",
  response: "REVOKE_MESSAGE"
}
```

#### `CONTACT_CHANGE_STATE`
```json
{
  sender: "wssp-server",
  response: "CONTACT_CHANGE_STATE",
  body: {
    status: "composing"|"recording"|"paused",
    from: string
  }
}
```

### 3.4 Error Handling

#### Timeout Handling
- 5 second inactivity timeout
- 3 failed reconnection attempts before giving up

#### Error Messages
```json
{
  sender: "wspl-server",
  response: "error",
  code: [ERROR_CODE],
  message: string
}
```

#### Common Error Codes:
`100` - Authentication failed
`101` - Invalid message format
`102` - Rate limit exceeded
`103` - Server busy

### 3.5 Connection Management

#### Heartbeat
 - Clients should send empty JSON {} every 30 seconds
 - Server will respond with
    ```json
    {
        "sender": "wspl-server",
        "response": "pong"
    }
    ```

#### Reconnection Strategy
1. On disconnect, client waits random interval (1-5s)
2. Attempts reconnection with exponential backoff
3. After 3 failures, waits 60 seconds before retrying

## Event System

The server maintains an event queue for all WhatsApp activities.

#### Event Types:
 - `MESSAGE_RECEIVED` - New message
 - `MESSAGE_ACK` - Message read receipt
 - `MESSAGE_REVOKED` - Message deleted
 - `GROUP_JOIN` - User joined group
 - `GROUP_UPDATE` - Group settings changed
 - `CHAT_STATE_CHANGED` - Typing/recording status

#### Queue Management:
 - Maximum 1000 events stored (FIFO)
 - Events include timestamp for synchronization
 - Clients can poll for events since specific timestamp
