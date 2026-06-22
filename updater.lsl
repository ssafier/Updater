#include "include/controlstack.h"
#include "src/updater/include/controlstack.h"
#include "src/updater/include/update.h"

#ifndef debug
#define debug(x)
#endif

string item_name;
float version;
key item_key;

key read_key;

integer pin;
integer channel;
integer handle;

integer index;
integer skip_item;
integer count;

GLOBAL_DATA;

process() {
  string line = llGetNotecardLineSync(NOTECARD_NAME, index);
  key xyzzy = NULL_KEY;
  if (line == EOF)  {
    NEXT_STATE;
    return;
  }  else if (line != NAK)  {
    list parsed = llParseString2List(line,["|"],[]);
    string cmd = (string) parsed[0];
    if (skip_item && cmd != "item") cmd = "";
    switch (cmd) {
    case "version": { // version check
      float v = (float)(string)parsed[1];
      if (v >= version) {
	NEXT_STATE;
	return;
      }
      break;
    }
    case "item": { // test item name and skip til end
      string it = (string) parsed[1];
      skip_item = ((it != "default") && (item_name != it));
      break;
    }
    case "add": {
      string type = (string) parsed[1];
      string itemName = (string) parsed[2];

      if (llGetInventoryType(item_name) == INVENTORY_NONE) {
	llOwnerSay("Warning: '" + item_name + "' not found in updater. Skipping.");
	// Fake an ACK to ourselves to keep the chain moving
	++index;
	process();
	return;
      } else {
	if (type == "script") {
	  llRemoteLoadScriptPin(item_key, item_name, pin, FALSE, 0);
	} else {
	  llGiveInventory(item_key, item_name);
	}
	// Send the VERIFY command so the receiver knows to watch for it and ACK
	llRegionSayTo(item_key, channel, "verify|" + itemName);
      }
      break;
    }
    case "delete": {
      llRegionSayTo(item_key, channel,
		    "delete|"+ (string) parsed[1] + "|" + (string) parsed[2]);
      break;
    }
    case "stop": {
      llRegionSayTo(item_key, channel, "stop");
      break;
    }
    case "start": {
      llRegionSayTo(item_key, channel, "start");
      break;
    }
    default: {
      llSay(0, "Unknown command.");
      break;
    }
    }
  }
  if (index <= count) {
    ++index;
  } else {
    NEXT_STATE;
  }
}


default {
  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan != updateItems) return;
    GET_CONTROL_GLOBAL;
    string item_name;
    POP(item_name);
    string temp;
    POP(temp);
    version = (float) temp;
    item_key = xyzzy;
    channel = (integer) ("0x"+llGetSubString((string) llGetKey() ,-4,-1));
    handle = llListen(-channel, "", item_key, "");
    pin = (integer) ("0x"+llGetSubString((string) item_key,-2,-1)) +
      (channel & 0xFF00);
    llRegionSayTo(item_key,UPDATE_CHANNEL,
		  "update|"+
		  (string)(channel & 0xFF00) + "|" + (string) channel);
  }

  state_exit() {
    llListenRemove(handle);
    handle = 0;
  }

  listen(integer chan, string name, key xyzzy, string msg) {
    list parsed = llParseString2List(msg,["|"],[]);
    switch ((string) parsed[0]) {
    case "ready": {
      read_key = llGetNumberOfNotecardLines(NOTECARD_NAME);
      break;
    }
    case "fail": 
    case "ack": {
      process();
      break;
    }
    default: break;
    }
  }

  dataserver(key request, string data) {
    if (request != read_key) return;
    count = (integer)data;
    skip_item = FALSE;
    index = 0;
    process();
  }
}
