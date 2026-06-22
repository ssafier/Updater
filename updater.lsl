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

GLOBAL_DATA;

default {
  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan != updateItem) return;
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
  }

  dataserver(key request, string data) {
    if (request != read_key) return;
    integer count = (integer)data;
    integer index;
    key xyzzy = NULL_KEY;
    integer skip_item = FALSE;
    
    for (index = 0; index <= count; ++index) {
      string line = llGetNotecardLineSync(NOTECARD_NAME, index);
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
	  string it = (string) cmd[1];
	  skip_item = ((it != "default") && (item_name != it));
	  break;
	}
	case "add": {
	  break;
	}
	case "delete": {
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
  }
}
