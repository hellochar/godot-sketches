# Penguin Camp Chat

Multiplayer chatroom demo with penguin avatars and a communal fire you can feed logs to. Built for Godot 4.

## Features
- Host or Join via simple UI.
- Each player spawns a controllable penguin (WASD / Arrow keys).
- RichText chat panel with sender IDs.
- Central fire that decays over time; feeding logs replenishes fuel and scales the fire.
- Fire intensity synced to all clients.

## Setup
1. Open the project in Godot 4.4.
2. Ensure `MultiplayerManager` autoload is present (added in `project.godot`).
3. Create the following input actions (Project > Project Settings > Input Map):
   - `ui_up`, `ui_down`, `ui_left`, `ui_right` (default arrow keys / WASD)
4. Create scenes for `Penguin` and `Fire` (or import provided ones if added later) and assign them in `Main` scene inspector.

## Running
- Press Host to start server (default port 4242) and spawn your penguin.
- On another instance / machine, enter host's IP and press Join.
- Type messages and press Enter or Send.
- Press Feed to add a log to the fire.

## Notes / Next Steps
- Add proper avatar art & animations.
- Add username entry and display names.
- Add security / validation on server for spam control.
- Use Scene Replication instead of ad-hoc RPC for movement for smoother sync.
