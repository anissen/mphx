package;

import luxe.Input;
import luxe.Vector;

import mphx.client.Client;

typedef Position = { x :Float, y :Float };

class Main extends luxe.Game {
    var client :Client;
    var playerData :Map<String, Position>;
    var myPlayerId :String;
    var joined :Bool;

    override function config(config :luxe.AppConfig) {
        config.render.antialiasing = 2;
        return config;
    }

    override function ready() {
        joined = false;
        playerData = new Map();

        function handler(event :ClientEvent) {
            switch (event) {
                case Accepted(playerId): myPlayerId = myPlayerId; joined: true;
                case Moved(playerId, pos): playerData[playerId] = pos;
            }
        }

        client = new Client<ClientEvent, ServerEvent>('127.0.0.1', 8001, handler);
		client.connect();

        client.send();
    }

    override function onmousedown(e :MouseEvent) {
        if (!joined) return;
        client.send(Move(myPlayerId, { x: e.pos.x, y: e.pos.y }));
    }

    override function onrender() {
        client.update();
        if (!joined) return;
        var sides = 3;
        for (playerId in playerData.keys()) {
            var player = playerData[playerId];
            Luxe.draw.ngon({
                immediate: true,
                pos: new Vector(player.x, player.y),
                sides: sides++,
                r: 100,
                solid: true,
                color: new luxe.Color(0.5, sides / 10, 1 - sides / 10)
            });

            Luxe.draw.text({
                immediate: true,
                pos: new Vector(player.x, player.y),
                text: playerId + (playerId == myPlayerId ? '\n(You)' : ''),
                align: luxe.Text.TextAlign.center,
                align_vertical: luxe.Text.TextAlign.center
            });
        }
    }

    override function onkeyup(e :KeyEvent) {
        if (e.keycode == Key.escape) {
            Luxe.shutdown();
        }
    }
}
