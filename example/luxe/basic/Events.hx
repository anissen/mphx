package;

enum ClientEvent {
    Accepted(playerId :String);
    Moved(playerId: String, pos: { x: Int, y: Int });
}

enum ServerEvent {
    Join;
    Move(playerId: String, pos: { x: Int, y: Int });
}
