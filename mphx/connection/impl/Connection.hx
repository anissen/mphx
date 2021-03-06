package mphx.connection.impl ;

import haxe.io.Eof;
import haxe.io.Input;
import haxe.io.Bytes;
import mphx.serialization.impl.HaxeSerializer;
import mphx.serialization.ISerializer;
import mphx.connection.IConnection;
import mphx.server.IServer;
import mphx.server.room.Room;
import mphx.utils.event.impl.ServerEventManager;
import haxe.io.Error;

class Connection implements IConnection
{
	private var server:IServer;
	public var cnx:NetSock;
	public var serializer:ISerializer;
	public var events:ServerEventManager;
	public var room:Room = null;
	public var data:Dynamic;

	public function new ()
	{
	}

	public function clone() : IConnection
	{
		return new Connection();
	}

	public function configure(_events : ServerEventManager, _server:IServer, _serializer : ISerializer = null) : Void
	{
		events = _events;
		server = _server;

		if (_serializer == null)
			this.serializer = new HaxeSerializer();
		else
			serializer = _serializer;
	}

	public function isConnected():Bool { return cnx != null && cnx.isOpen(); }
	public function getContext() :NetSock {return cnx;}

	public function putInRoom (newRoom:mphx.server.room.Room)
	{
		if (newRoom.full){
			return false;
		}
		if (room != null){
			room.onLeave(this);
		}

		room = newRoom;
		newRoom.onJoin(this);

		return true;
	}

	public function onAccept(cnx:NetSock) : Void
	{
		this.cnx = cnx;

		if (server.onConnectionAccepted != null)
			server.onConnectionAccepted("accept : " + this.getContext().peerToString(), this);
	}

	//difference with onAccept ?
	public function onConnect(cnx:NetSock) : Void
	{
		this.cnx = cnx;

		//if (server.onConnectionAccepted != null)
			//server.onConnectionAccepted("connect : " + this.getContext().peerToString(), this);
	}

	public function loseConnection(?reason:String)
	{
		trace("Client disconnected with code: " + reason);
		if (server.onConnectionClose != null)
			server.onConnectionClose(reason, this);

		if (room != null){
			room.onLeave(this);
		}

		if (cnx != null)
		{
			cnx.clean();
			this.cnx = null;
		}
	}

	public function send(event:String, ?data:Dynamic):Bool
	{
		var object = {
			t: event,
			data:data
		}

		var serialiseObject = serializer.serialize(object);
		var result = cnx.writeBytes(Bytes.ofString(serialiseObject + "\r\n"));
		return result;
	}

	public function recieve(line:String)
	{
		var msg = serializer.deserialize(line);
		events.callEvent(msg.t,msg.data,this);
	}

	public function dataReceived(input:Input):Void
	{
		//Convert Input to string then process.
		var line = "";
		var done : Bool = false;
		var data : String = "";
		while (!done)
		{
			try
			{
				data = input.readLine();

				try
				{
					recieve(data);
				}
				catch (e:Dynamic)
				{
					trace("CRITICAL - can't use data : " + data);
					trace("because : " + e);
					throw Error.Blocked;
				}
			}
			catch (e : Eof)
			{
				done = true;
			}
			catch (e : Error)
			{
				//nothing special, continue.
			}
			catch (e:Dynamic)
			{
				trace("CRITICAL - data can't be read");
				trace("" + e);
				trace("Skip Data");
			}
		}
	}
}
