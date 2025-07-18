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

## 1. Server Overview

The WhatsApp server is built using Node.js with Express for HTTP endpoints and net for TCP socket connections. It uses the whatsapp-web.js library to interface with WhatsApp Web.

Key Features:
 - Multiple client support via TCP sockets
 - Event queue system for message tracking
 - Media conversion for compatibility
 - Full WhatsApp Web feature support
 - HTTP API for remote clients

## 2. HTTP Endpoints

### 2.1 Authentication & Status

#### GET `/`
 - Returns: Basic server identification string
 - Use: Simple server status check

#### GET `/loggedInYet`
 - Returns: "true" or "false" string
 - Use: Check if WhatsApp session is authenticated

#### GET `/qr`
 - Returns: QR code data URL or "Success" if already logged in
 - Use: Get QR code for initial authentication

### 2.2 Event Handling

#### GET `/getUpdates`
 - Parameters:
    - since: timestamp (optional)
 - Returns: JSON with new events since specified timestamp
 - Use: Poll for new events (messages, status changes, etc.)

#### GET `/getUpdatesPolling`
 - Parameters:
    - since: timestamp (optional)
    - timeout: milliseconds (optional, default 5000)
 - Returns: JSON with new events (long polling implementation)
 - Use: More efficient event polling with timeout

#### POST `/testEvent`
 - Returns: JSON with queue status
 - Use: Test event system by adding a test event

#### GET `/queueStatus`
 - Returns: JSON with current event queue status
 - Use: Monitor event queue health

#### GET `/clearQueue`
 - Returns: JSON with operation result
 - Use: Clear all events from queue (debug/maintenance)

### 2.3 Chat Management

#### GET `/getChats`
 - Returns: JSON with all chats (individual and groups)
 - Use: Retrieve complete chat list

#### POST `/syncChat/:contactId`
 - Parameters:
    - contactId: chat ID
    - isGroup: boolean (query parameter)
 - Returns: Empty JSON on success
 - Use: Sync chat history with server

#### GET `/getChatMessages/:contactId`
 - Parameters:
    - contactId: chat ID
    - isGroup: boolean (query parameter)
    - isLight: boolean (query parameter, limits messages)
 - Returns: JSON with all messages in chat
 - Use: Retrieve message history for specific chat

#### POST `/readChat/:contactId`
 - Parameters:
    - contactId: chat ID
    - isGroup: boolean (query parameter)
 - Returns: JSON with operation status
 - Use: Mark chat as read

#### POST `/deleteChat/:contactId`
 - Parameters:
    - contactId: chat ID
    - isGroup: boolean (query parameter)
 - Returns: JSON with operation status
 - Use: Delete chat from list

### Contact Management

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

### 2.6 Media Handling

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

### Message Handling

#### POST /sendMessage/:contactId
 - Parameters:
    - contactId: recipient ID
    - isGroup: boolean (query parameter)
 - Body:
    - messageText: text to send
    - replyTo: message ID to reply to (optional)
    - sendAsVoiceNote: boolean (optional)
    - mediaBase64: base64 media data (optional)
    - sendAsPhoto: boolean (optional)
 - Returns: JSON with operation status
 - Use: Send text/media messages

#### POST /setTypingStatus/:contactId
 - Parameters:
    - contactId: chat ID
    - isGroup: boolean (query parameter)
    - isVoiceNote: boolean (query parameter)
 - Returns: JSON with operation status
 - Use: Set typing/recording indicator

#### POST /clearState/:contactId
 - Parameters:
    - contactId: chat ID
    - isGroup: boolean (query parameter)
 - Returns: JSON with operation status
 - Use: Clear chat state indicators

#### POST /seenBroadcast/:messageId
 - Returns: JSON with operation status
 - Use: Mark broadcast message as seen

#### GET /getQuotedMessage/:messageId
 - Returns: JSON with quoted message details
 - Use: Retrieve message being replied to

#### POST /deleteMessage/:messageId/:everyone
 - Parameters:
    - messageId: message ID to delete
    - everyone: 2 for everyone, other for just you
 - Returns: JSON with operation status
 - Use: Delete messages (optionally for everyone)

#### POST /setStatusInfo/:statusMsg
 - Returns: JSON with operation status
 - Use: Set user's status message

#### POST /setMute/:contactId/:muteLevel
 - Parameters:
    - contactId: chat ID
    - muteLevel: -1=unmute, 0=8h, 1=1w, 2=1y
    - isGroup: boolean (query parameter)
 - Returns: JSON with operation status
 - Use: Mute/unmute chats

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
