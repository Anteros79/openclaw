# OpenClaw iOS Capabilities & API Reference

Complete reference of all device capabilities available to your agent when running on iOS iPad/iPhone.

## Quick Reference

| Capability    | Method              | What It Does                            |
| ------------- | ------------------- | --------------------------------------- |
| **Location**  | `location.get`      | Get current GPS coordinates             |
|               | `location.watch`    | Stream continuous location updates      |
| **Camera**    | `camera.snap`       | Take a photo                            |
|               | `camera.clip`       | Record a video clip                     |
| **Contacts**  | `contacts.search`   | Search your contacts                    |
|               | `contacts.add`      | Add a new contact                       |
| **Calendar**  | `calendar.events`   | List upcoming events                    |
|               | `calendar.add`      | Create a new event                      |
| **Reminders** | `reminders.list`    | Get your reminders                      |
|               | `reminders.add`     | Create a reminder                       |
| **Photos**    | `photos.latest`     | Get recent photos                       |
| **Screen**    | `screen.record`     | Record your screen                      |
| **Device**    | `device.status`     | Battery, network, storage info          |
|               | `device.info`       | Model, OS version, etc.                 |
| **Motion**    | `motion.activities` | Detect current activity (walking, etc.) |
|               | `motion.pedometer`  | Step count and distance                 |

---

## Location Services

### `location.get` - Get Current Location

```json
{
  "jsonrpc": "2.0",
  "method": "node.invoke",
  "params": {
    "command": "location.get",
    "params": {
      "accuracy": "precise", // "coarse", "balanced", or "precise"
      "maxAgeMs": 30000, // Accept cached location if < 30 seconds old
      "timeoutMs": 10000 // Max wait time for fresh location
    }
  }
}
```

**Permissions Required:**

- `NSLocationWhenInUseUsageDescription` (foreground only)
- For background: `NSLocationAlwaysAndWhenInUseUsageDescription` + "Always" permission

**Response:**

```json
{
  "latitude": 37.7749,
  "longitude": -122.4194,
  "accuracy": 5.0, // Accuracy in meters
  "altitude": 52.0,
  "heading": 180.5,
  "speed": 2.5,
  "timestamp": 1704067200000
}
```

**Accuracy Levels:**

- `coarse`: ~1000m (WiFi-based, battery efficient)
- `balanced`: ~100m (typical GPS)
- `precise`: ~5-10m (high-accuracy GPS)

---

### `location.watch` - Stream Location Updates

```json
{
  "jsonrpc": "2.0",
  "method": "node.invoke",
  "params": {
    "command": "location.watch",
    "params": {
      "accuracy": "balanced",
      "significantChangesOnly": false, // true = only major movements
      "maxDurationMs": 300000 // Auto-stop after 5 minutes
    }
  }
}
```

**Returns:** Stream of location updates, same format as `location.get`

**Note:** Battery intensive. Use `significantChangesOnly: true` for background use.

---

## Camera Services

### `camera.snap` - Take a Photo

```json
{
  "jsonrpc": "2.0",
  "method": "node.invoke",
  "params": {
    "command": "camera.snap",
    "params": {
      "facing": "back", // "front" or "back"
      "flashMode": "auto", // "on", "off", "auto"
      "compression": 0.8 // 0-1 (higher = better quality)
    }
  }
}
```

**Permissions Required:**

- `NSCameraUsageDescription`

**Response:**

```json
{
  "format": "jpeg",
  "base64": "iVBORw0KGgoAAAANSUhEUgAAAAEA...",
  "width": 2048,
  "height": 1536,
  "timestamp": 1704067200000,
  "facingMode": "back"
}
```

---

### `camera.clip` - Record Video Clip

```json
{
  "jsonrpc": "2.0",
  "method": "node.invoke",
  "params": {
    "command": "camera.clip",
    "params": {
      "facing": "back",
      "durationSeconds": 10, // Max 30 seconds
      "quality": "high", // "low", "medium", "high"
      "includeAudio": true
    }
  }
}
```

**Response:**

```json
{
  "format": "mp4",
  "base64": "AAAA...", // Video data (base64)
  "durationMs": 10000,
  "width": 1920,
  "height": 1080,
  "hasAudio": true,
  "fileSize": 5242880
}
```

---

## Contacts Services

### `contacts.search` - Search Contacts

```json
{
  "jsonrpc": "2.0",
  "method": "node.invoke",
  "params": {
    "command": "contacts.search",
    "params": {
      "query": "Alice Smith", // Search term
      "maxResults": 10,
      "includeDetails": true // Include phone, email, address
    }
  }
}
```

**Permissions Required:**

- `NSContactsUsageDescription`

**Response:**

```json
{
  "contacts": [
    {
      "id": "contact-123",
      "firstName": "Alice",
      "lastName": "Smith",
      "displayName": "Alice Smith",
      "phone": "+1-555-123-4567",
      "email": "alice@example.com",
      "address": "123 Main St, Springfield, IL",
      "thumbnail": "iVBORw0KGgoAAAANSUhEUgAAAAEA..." // Optional base64 image
    }
  ],
  "totalMatches": 1
}
```

---

### `contacts.add` - Add New Contact

```json
{
  "jsonrpc": "2.0",
  "method": "node.invoke",
  "params": {
    "command": "contacts.add",
    "params": {
      "firstName": "Bob",
      "lastName": "Johnson",
      "phone": "+1-555-987-6543",
      "email": "bob@example.com",
      "organization": "ACME Corp",
      "address": "456 Oak Ave, Portland, OR"
    }
  }
}
```

**Response:**

```json
{
  "contactId": "contact-456",
  "displayName": "Bob Johnson",
  "created": true
}
```

---

## Calendar Services

### `calendar.events` - List Calendar Events

```json
{
  "jsonrpc": "2.0",
  "method": "node.invoke",
  "params": {
    "command": "calendar.events",
    "params": {
      "startDate": "2024-01-15", // ISO 8601 format
      "endDate": "2024-01-31",
      "calendars": ["work", "personal"], // Optional filter
      "includeAttendees": true,
      "maxResults": 50
    }
  }
}
```

**Permissions Required:**

- `NSCalendarsUsageDescription`

**Response:**

```json
{
  "events": [
    {
      "id": "event-123",
      "title": "Team Meeting",
      "startTime": "2024-01-15T10:00:00Z",
      "endTime": "2024-01-15T11:00:00Z",
      "duration": 3600,
      "location": "Conference Room A",
      "isAllDay": false,
      "attendees": [
        {
          "name": "Alice Smith",
          "email": "alice@example.com",
          "rsvp": "accepted"
        }
      ],
      "calendar": "work",
      "notes": "Q1 planning"
    }
  ],
  "totalCount": 5
}
```

---

### `calendar.add` - Create Calendar Event

```json
{
  "jsonrpc": "2.0",
  "method": "node.invoke",
  "params": {
    "command": "calendar.add",
    "params": {
      "title": "AI Standup",
      "startDate": "2024-01-20",
      "startTime": "14:00", // 24-hour format
      "duration": 30, // Minutes
      "location": "Zoom",
      "calendar": "work",
      "notes": "Daily sync with team",
      "addAlert": true,
      "alertMinutesBefore": 15,
      "invitees": ["alice@example.com"]
    }
  }
}
```

**Response:**

```json
{
  "eventId": "event-456",
  "title": "AI Standup",
  "created": true,
  "startTime": "2024-01-20T14:00:00Z"
}
```

---

## Reminders Services

### `reminders.list` - Get Reminders

```json
{
  "jsonrpc": "2.0",
  "method": "node.invoke",
  "params": {
    "command": "reminders.list",
    "params": {
      "lists": ["today", "work"], // Optional filter
      "includeCompleted": false,
      "maxResults": 50
    }
  }
}
```

**Permissions Required:**

- `NSRemindersUsageDescription`

**Response:**

```json
{
  "reminders": [
    {
      "id": "reminder-123",
      "title": "Buy groceries",
      "dueDate": "2024-01-15",
      "dueTime": "18:00",
      "priority": 1, // 0-4, 0=none, 1=low, 4=high
      "completed": false,
      "list": "personal",
      "notes": "Milk, eggs, bread"
    }
  ],
  "totalCount": 3
}
```

---

### `reminders.add` - Create Reminder

```json
{
  "jsonrpc": "2.0",
  "method": "node.invoke",
  "params": {
    "command": "reminders.add",
    "params": {
      "title": "Call Mom",
      "dueDate": "2024-01-20",
      "dueTime": "19:00",
      "priority": 2,
      "list": "personal",
      "notes": "Weekly check-in",
      "setAlert": true,
      "alertMinutesBefore": 30
    }
  }
}
```

**Response:**

```json
{
  "reminderId": "reminder-456",
  "title": "Call Mom",
  "created": true,
  "dueDate": "2024-01-20"
}
```

---

## Photos Services

### `photos.latest` - Get Recent Photos

```json
{
  "jsonrpc": "2.0",
  "method": "node.invoke",
  "params": {
    "command": "photos.latest",
    "params": {
      "count": 5, // Number of photos to return
      "includeMetadata": true,
      "includeLocation": true,
      "resolution": "thumbnail" // "thumbnail", "screen", "original"
    }
  }
}
```

**Permissions Required:**

- `NSPhotoLibraryUsageDescription`

**Response:**

```json
{
  "photos": [
    {
      "id": "photo-123",
      "base64": "iVBORw0KGgoAAAANSUhEUgAAAAEA...",
      "width": 1920,
      "height": 1080,
      "timestamp": 1704067200000,
      "location": {
        "latitude": 37.7749,
        "longitude": -122.4194
      },
      "isFavorite": false,
      "filename": "IMG_0123.jpg"
    }
  ],
  "totalCount": 5
}
```

---

## Screen Services

### `screen.record` - Record Screen

```json
{
  "jsonrpc": "2.0",
  "method": "node.invoke",
  "params": {
    "command": "screen.record",
    "params": {
      "durationSeconds": 30,
      "fps": 30,
      "quality": "high", // "low", "medium", "high"
      "includeAudio": false,
      "excludeAppAudio": false
    }
  }
}
```

**Response:**

```json
{
  "format": "mp4",
  "base64": "AAAA...",
  "durationMs": 30000,
  "width": 2048,
  "height": 1536,
  "fps": 30,
  "fileSize": 52428800
}
```

**Note:** Screen recording works in foreground only.

---

## Device Services

### `device.status` - Get Device Status

```json
{
  "jsonrpc": "2.0",
  "method": "node.invoke",
  "params": {
    "command": "device.status",
    "params": {}
  }
}
```

**Response:**

```json
{
  "battery": {
    "level": 85, // Percentage
    "state": "unplugged", // "charging", "unplugged", "full"
    "isLowPowerMode": false
  },
  "network": {
    "wifi": {
      "connected": true,
      "ssid": "Home WiFi",
      "signalStrength": -40 // dBm, higher is better
    },
    "cellular": {
      "connected": false,
      "carrier": "Verizon",
      "type": "lte" // "2g", "3g", "4g", "lte", "5g"
    }
  },
  "storage": {
    "totalBytes": 128000000000,
    "availableBytes": 64000000000,
    "percentageUsed": 50
  },
  "thermalState": "nominal" // "critical", "serious", "nominal"
}
```

---

### `device.info` - Get Device Info

```json
{
  "jsonrpc": "2.0",
  "method": "node.invoke",
  "params": {
    "command": "device.info",
    "params": {}
  }
}
```

**Response:**

```json
{
  "model": "iPad Pro (12.9-inch)",
  "modelIdentifier": "iPad13,1",
  "systemVersion": "18.2",
  "systemName": "iPadOS",
  "processorCount": 8,
  "processorCores": 8,
  "processorType": "Apple M1",
  "screenSize": 12.9,
  "screenResolution": "2048x1536",
  "screenDensity": 264,
  "hardwareCaps": ["lidar", "faceId", "touchId", "gpu", "npu"],
  "isSimulator": false,
  "uptime": 86400000, // Milliseconds since last boot
  "supportedOrientations": ["portrait", "landscape"]
}
```

---

## Motion Services

### `motion.activities` - Get Current Activity

```json
{
  "jsonrpc": "2.0",
  "method": "node.invoke",
  "params": {
    "command": "motion.activities",
    "params": {
      "includeConfidence": true,
      "windowSize": "60s" // Time window for classification
    }
  }
}
```

**Permissions Required:**

- `NSMotionUsageDescription`

**Response:**

```json
{
  "currentActivity": "walking",
  "confidence": 0.95, // 0-1
  "alternatives": [
    {
      "activity": "running",
      "confidence": 0.04
    }
  ],
  "stationary": false,
  "timestamp": 1704067200000
}
```

**Activity Types:**

- `walking` - User is walking
- `running` - User is running
- `cycling` - User is on a bike
- `automotive` - User is in a vehicle
- `stationary` - User is not moving
- `unknown` - Activity cannot be determined

---

### `motion.pedometer` - Get Step Count

```json
{
  "jsonrpc": "2.0",
  "method": "node.invoke",
  "params": {
    "command": "motion.pedometer",
    "params": {
      "period": "today", // "today", "week", "month", or ISO date range
      "includeFloors": true
    }
  }
}
```

**Response:**

```json
{
  "steps": 8432,
  "distance": 6.2, // Kilometers
  "floorsClimbed": 12,
  "floorsDescended": 12,
  "activeEnergy": 245, // Calories
  "startTime": "2024-01-15T00:00:00Z",
  "endTime": "2024-01-15T23:59:59Z"
}
```

---

## Voice Services

### Voice Wake

Voice wake is always-on when enabled. No explicit API needed.

**Configuration:**

- Enable in app Settings → Voice Wake
- Grant Microphone permission
- Grant Speech Recognition permission

The app will continuously listen for your custom wake word or phrase.

---

### Talk Mode (Push-to-Talk)

**Activation:** Hold the microphone button or use voice command

**Workflow:**

1. Wake app with voice or button
2. Speak your request
3. Speech is transcribed on-device
4. Request sent to gateway
5. Response plays via speaker

**Supported:**

- Multiple language detection
- Custom voice wake words
- Configurable silence timeout
- Audio feedback during recording

---

## Error Responses

All capabilities return errors in standard format:

```json
{
  "jsonrpc": "2.0",
  "id": "request-id",
  "error": {
    "code": -32000,
    "message": "Permission denied",
    "data": {
      "permission": "NSCameraUsageDescription",
      "action": "Grant camera access in Settings"
    }
  }
}
```

**Common Error Codes:**

- `-32600` - Invalid request
- `-32601` - Method not found
- `-32602` - Invalid parameters
- `-32000` - Permission denied
- `-32001` - Service unavailable
- `-32002` - Operation timeout
- `-32003` - Resource busy

---

## Permission Status

Check if a capability is available:

```json
{
  "jsonrpc": "2.0",
  "method": "node.invoke",
  "params": {
    "command": "device.permissions",
    "params": {
      "check": ["camera", "location", "contacts"]
    }
  }
}
```

**Response:**

```json
{
  "camera": "granted", // "granted", "denied", "not_determined"
  "location": "granted_when_in_use",
  "contacts": "denied",
  "actions": {
    "camera": "Settings > Privacy > Camera",
    "contacts": "Re-enable in app settings"
  }
}
```

---

## Batch Operations

Some operations support batching for efficiency:

```json
{
  "jsonrpc": "2.0",
  "method": "node.invoke",
  "params": {
    "command": "batch",
    "params": {
      "operations": [
        { "command": "location.get", "params": {} },
        { "command": "device.status", "params": {} },
        { "command": "contacts.search", "params": { "query": "Alice" } }
      ]
    }
  }
}
```

**Response:** Array of results in order

---

## Rate Limiting & Quotas

**Per-session limits:**

- Location updates: 1 per 2 seconds (background: 1 per 60 seconds)
- Camera operations: 1 at a time, 10 per minute
- Screen recording: 1 at a time, 2 per hour
- Calendar/Reminders: 100 read ops per hour
- Contacts: 50 search ops per hour

**Reset:** Limits reset on session reconnection

---

## Performance Notes

- **Foreground:** Full speed, no restrictions
- **Background:** Command execution limited by iOS
- **Low Power Mode:** Some features disabled, location coarsens to 1km
- **Thermal State:** Operations degrade if device overheats
- **Memory:** Heavy operations (screen record, clips) may fail on constrained devices

---

For more detailed examples, see the [iOS Integration Guide](./ios-integration-guide.md).
