# Family Safety Tracker — Design Spec

## Overview
A mobile app for live GPS tracking within family circles. Parents can see real-time location of family members, receive SOS alerts, set geofences, view location history, and monitor battery status.

---

## Architecture

- **Client:** Flutter (iOS + Android, single codebase)
- **Backend:** Firebase (Firestore, Auth, Cloud Functions, Cloud Messaging)
- **Maps:** `google_maps_flutter` plugin
- **Location:** `location` + `geolocator` Flutter packages

Location updates flow: device GPS → Firestore realtime sync → push to circle members.

---

## Auth & Onboarding
1. Parent creates account → creates Family Circle
2. Generates invite link (deep link with circle code)
3. Child opens link → downloads app → enters phone number → SMS OTP verification
4. Explicit consent prompt: "Allow [Parent Name] to see your location?"
5. Once accepted, all members appear in the circle

---

## Data Model (Firestore)

```
/families/{familyId}
  name, createdAt

/members/{memberId}
  familyId, phone, name, role ("parent"|"child"),
  consented, batteryLevel, lastSeen

/locations/{memberId}
  lat, lng, accuracy, timestamp, speed

/location_history/{memberId}/points/{pointId}
  lat, lng, timestamp (TTL: 30 days)

/geofences/{geofenceId}
  familyId, name, lat, lng, radius,
  triggerOnEnter, triggerOnExit
```

---

## Features

### Live Tracking
- Updates every 5–30s (configurable per family)
- Background location via WorkManager (Android) / BGTaskScheduler (iOS)
- Map view with member avatars, auto-center on selection

### SOS/Panic Alert
- Long-press (2s) red button on child's app
- Sends push notification to all parents with current location + 30s trail
- "Call child" shortcut in notification

### Geofencing
- Parents define zones: drop pin + set radius
- Client-side check on each location update; Cloud Functions validate and push on enter/exit
- Rate-limited to avoid spam

### Battery Status
- Device battery read every 15 min, written to member doc
- Push notification if battery < 20%
- Battery icon next to member name on map

### Location History
- Points written every 5 min (or significant change) to subcollection
- TTL auto-delete after 30 days
- Parents view polyline trace for past 24h

---

## Key Design Decisions
- **Flutter + Firebase** for fastest time-to-ship with real-time capabilities
- **Invite + consent** model to address privacy/legal requirements
- **Adaptive polling** to balance accuracy and battery life
- **Firestore TTL** for history to avoid storage bloat
