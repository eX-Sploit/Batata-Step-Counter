# Batata Step Counter

Count your character's steps as you adventure through WoW Forever. Batata Step
Counter keeps your total in a small Blizzard-style window, with a potato minimap
icon for easy access. No other addons are required.

## Getting Started

1. Put the **Batata Step Counter** folder inside your game's `Interface/AddOns` folder.
2. Restart WoW Forever and enable **Batata Step Counter** in the character selection AddOns list.
3. Log in and start walking or running. Counting starts automatically the first time you use the addon.

## Controls

- **Pause / Play:** Stop or resume counting without losing your steps.
- **Circular arrow:** Reset your total to zero. If counting is paused, it stays paused.
- **Potato minimap icon:** Click to show or hide the counter. Drag it to move it around the minimap.
- **Counter window:** Drag to move it. Click its close button or press Escape to hide it.

**Hiding the window does not stop counting.** Use Pause when you want to take a break.

You can also type `/steps` or `/batatasteps` in chat to show or hide the counter.

## Your Progress

Your step total is saved **separately for each character**, so you can pick up
where you left off next time you play. Your window position, minimap icon position,
and pause setting are remembered too.

## What Counts

Walking and running on foot count towards your total. Riding mounts or taxis,
swimming, flying, jumping, falling, using vehicles, and moving as a ghost do not.

Steps are **an estimate based on your movement speed**, not a count of your
character's footstep animations. The same estimate is used for every race and
form. Running against an obstacle may still add steps. Very short movements and
lag can also make the count less accurate.

If combat hides your current speed, the counter keeps estimating while you move
and shows **Tracking (estimated)**. It uses your last known on-foot speed, or
normal running speed if none is available. It still stops when you stop moving,
but slows and speed boosts may make this estimate less accurate.

## Troubleshooting

- **Can't find the window?** Click the potato minimap icon or type `/steps` in chat.
- **The total isn't changing?** Check that counting isn't paused, get off your mount, and walk for a few seconds.
- **Seeing "Waiting for movement data"?** Try stopping and starting again. Counting resumes when the game provides movement information.
- **The addon isn't in the AddOns list?** Check that you haven't placed an extra folder inside the addon folder, then restart the game.

## License

Batata Step Counter is licensed under Creative Commons Attribution-NonCommercial
4.0 International (CC BY-NC 4.0). See [LICENSE](LICENSE).