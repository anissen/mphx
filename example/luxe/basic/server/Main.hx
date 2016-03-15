package;

class Main {

    public static function main() {
        var players = 0;
        var server :mphx.server.Server<ServerEvent> = null;

        function handler(event :ServerEvent, client :mphx.tcp.IConnection) {
            switch (event) {
                case Join: client.send(Accepted('Player ' + (++players)));
                case Move(playerId, pos): server.broadcast(Moved(playerId, pos));
            }
		}

		server = new mphx.server.Server<ClientEvent, ServerEvent>('127.0.0.1', 8001, handler);
		server.start();
	}
}
