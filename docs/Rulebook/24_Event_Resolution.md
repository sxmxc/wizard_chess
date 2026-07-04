# Event Resolution

Wizard Chess uses a deterministic Event Queue.

Player actions generate Game Events.

Game Events resolve in order until the queue is empty.

Triggered abilities may create additional Game Events.

The game never advances to the next phase while unresolved events remain.
