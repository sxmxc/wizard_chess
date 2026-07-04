# Milestone 3 Validation

Use this checklist before treating Milestone 3 as complete.

## Required Outcomes

- A dedicated server starts successfully in headless mode.
- Two clients can connect to the same server and receive different seats.
- The server remains authoritative for chess actions.
- Both clients stay synchronized through a complete networked chess game.
- A disconnected client can reconnect to the same match using the same client profile.
- Networking logs are sufficient to understand startup, seat assignment, action flow, disconnects, and reconnects.

## Recommended Command Lines

```powershell
godot --headless --path . --log-file .godot/server.log --server --port=7000
godot --path . --connect=127.0.0.1 --port=7000 --profile=client_a
godot --path . --connect=127.0.0.1 --port=7000 --profile=client_b
```

## Manual Checklist

1. Start the dedicated server and confirm the log shows server startup and an initial snapshot broadcast.
2. Connect `client_a` and confirm it receives the `white` or `black` seat.
3. Connect `client_b` with a different profile and confirm it receives the remaining seat.
4. Confirm both clients display the local seat and the White/Black assignment summary.
5. Play several legal moves from both sides and confirm both clients stay synchronized.
6. Attempt an illegal move and confirm the client receives a rejection without desynchronizing the match.
7. Close one client and confirm the server logs the peer disconnect while preserving the disconnected seat.
8. Reopen that client with the same `address`, `port`, and `profile`, then confirm it reclaims its prior seat.
9. Confirm a second live client using the same profile is rejected as `session_already_active`.
10. Complete or abandon the match and confirm there are no unexplained disconnect or authority issues in the logs.

## Current Prototype Boundaries

- Dedicated server runs one match session.
- Matchmaking is not part of Milestone 3.
- Lobbies and pre-game flows are not part of Milestone 3.
- Steam or platform identity is not part of Milestone 3.
- Reconnect is session-token based and intended only to validate the server-side model.
