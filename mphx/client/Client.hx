package mphx.client;

typedef Client<TClient,TServer> = #if js WebsocketClient<TClient,TServer>; #elseif flash TcpFlashClient; #else TcpClient; #end
