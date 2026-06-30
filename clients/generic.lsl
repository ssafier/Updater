#include "src/updater/include/update.h"

#ifndef debug
#define debug(x)
#endif

list scripts;
list objects;
list textures;
list animations;
list notecards;

integer initialized = FALSE;

integer handle;
integer scriptkey;
integer update_channel;
key update_bee;

integer count;

string received_item_type;
string received_item_name;

initialize() {
  if (initialized) return;
  initialized = TRUE;
  scripts = objects = textures = animations = notecards = [];
  integer i;
  count = llGetInventoryNumber(INVENTORY_SCRIPT);
  for (i = 0; i < count; ++i) {
    string name = llGetInventoryName(INVENTORY_SCRIPT, i);
    if (name != llGetScriptName()) {
      if (llSubStringIndex(name, "FURWARE text") == -1)
	scripts = [name] + scripts;
      else
	scripts = scripts + [name];
    }
  }
  count = llGetInventoryNumber(INVENTORY_ANIMATION);
  for (i = 0; i < count; ++i) {
    animations += [llGetInventoryName(INVENTORY_ANIMATION, i)];
  }
  count = llGetInventoryNumber(INVENTORY_OBJECT);
  for (i = 0; i < count; ++i) {
    objects += [llGetInventoryName(INVENTORY_OBJECT, i)];
  }
  count = llGetInventoryNumber(INVENTORY_TEXTURE);
  for (i = 0; i < count; ++i) {
    textures += [llGetInventoryName(INVENTORY_TEXTURE, i)];
  }
  count = llGetInventoryNumber(INVENTORY_NOTECARD);
  for (i = 0; i < count; ++i) {
    notecards += [llGetInventoryName(INVENTORY_NOTECARD, i)];
  }
  if (llLinksetDataFindKeys("version_4_bee",0,10) == []) {
    debug((string) llGetListLength(llLinksetDataFindKeys(VERSION,0,10)) + " " +
	  llDumpList2String(llLinksetDataFindKeys(VERSION,0,1), ","));
    integer x = WRITE_VERSION(0);
    if (x != 0) {
      llSay(0, "Version data creation failed.  This shouldn't happen. " + (string) x);
    }
  }
}

default {
  on_rez(integer x) {
    initialize();
  }

  state_entry() {
    initialize();
    state listening;
  }
  
  changed(integer x) {
    if (x & CHANGED_INVENTORY) {
      initialized = FALSE;
      llSleep(1.0);
      state default;
    }
  }
}

state listening {
  state_entry() {
    debug(llGetObjectName() + " starting.");
    integer l = llGetListLength(scripts);
    integer i;
    for (i = 0; i < l; ++i) {
      llSetScriptState((string)scripts[i],TRUE);
      llResetOtherScript((string)scripts[i]);
    }
    handle = llListen(UPDATE_CHANNEL, UPDATER_NAME, NULL_KEY, "");
  }
  
  changed(integer x) {
    if (x & CHANGED_INVENTORY) {
      initialized = FALSE;
      llSleep(1.0);
      state default;
    }
  }

  listen(integer chan, string name, key xyzzy, string msg) {
    list cmd = llParseString2List(msg, ["|"],[]);
      switch ((string) cmd[0]) {
      case "locate": {
	debug("locate "+(string) cmd[1] + " " + (string) cmd[2] + " " +
	      llGetObjectName() + "|" + READ_VERSION + "|"+ (string) llGetPos() + "|" + (string) llGetKey());
	llRegionSayTo((key) cmd[1], (integer) cmd[2],
		      llGetObjectName() + "|" + READ_VERSION + "|"+ (string) llGetPos() + "|" + (string) llGetKey());
	break;
      }
      case "update": {
	debug("update "+msg);
	scriptkey = (integer )(string) cmd[1] + (integer) ("0x"+llGetSubString((string) llGetKey(),-2,-1));
	update_channel = (integer) (string) cmd[2];
	update_bee = xyzzy;
	state doUpdate;
	break;
      }
      default: break;
      }
  }

  state_exit() {
    llListenRemove(handle);
    handle = 0;
  }
}

state doUpdate {
  state_entry() {
    handle = llListen(update_channel, "", update_bee, "");
    llSetRemoteScriptAccessPin(scriptkey);
    debug("ready");
    llRegionSayTo(update_bee, -update_channel, "ready");
  }
  listen(integer chan, string name, key xyzzy, string msg) {
    debug(msg);
    list cmd = llParseString2List(msg, ["|"],[]);
    switch ((string) cmd[0]) {
    case "version": {
      if (WRITE_VERSION(cmd[1]) == 0) {
	llRegionSayTo(update_bee, -update_channel, "ack|version");
      } else {
	llRegionSayTo(update_bee, -update_channel, "fail|version");
      }
      break;
    }
    case "start": {
      integer c = llGetInventoryNumber(INVENTORY_SCRIPT);
      integer i;
      for (i = 0; i < c; ++i) {
	string name = llGetInventoryName(INVENTORY_SCRIPT, i);
	if (name != llGetScriptName()) {
	  llSetScriptState(name,TRUE);
	}
      }
      llRegionSayTo(update_bee, -update_channel, "ack|start");
      break;
    }
    case "stop": {
      integer i = llGetListLength(scripts);
      while (i > 0) {
	--i;
	llSetScriptState((string)scripts[i],FALSE);
      }
      llRegionSayTo(update_bee, -update_channel, "ack|stop");
      break;
    }
    case "verify": {
      received_item_type = (string) cmd[1];
      received_item_name =(string) cmd[2];
      llSetTimerEvent(0.5);
      break;
    }
    case "fail": {
      llSetTimerEvent(0);
      break;
    }
    case "delete": {
      switch ((string) cmd[1]) {
      case "script": {
	if (llListFindList(scripts,[(string)cmd[2]]) != -1)
	  llRemoveInventory((string)cmd[2]);
	break;
      }
      case "notecard": {
	if (llListFindList(notecards,[(string)cmd[2]]) != -1)
	  llRemoveInventory((string)cmd[2]);
	break;
      }
      case "texture": {
	if (llListFindList(textures,[(string)cmd[2]]) != -1)
	  llRemoveInventory((string)cmd[2]);
	break;
      }
      case "animation": {
	if (llListFindList(animations,[(string)cmd[2]]) != -1)
	  llRemoveInventory((string)cmd[2]);
	break;
      }
      case "object": {
	if (llListFindList(objects,[(string)cmd[2]]) != -1)
	  llRemoveInventory((string)cmd[2]);
	break;
      }
      default: break;
      }
      llRegionSayTo(update_bee, -update_channel,"ack|deleted|"+(string)cmd[2]);
      break;
    }
    case "restart": {
      llSetRemoteScriptAccessPin(0);
      initialized = FALSE;
      state default;
    }
    default: break;
    }
  }
  timer() {
    // Check if the item we are waiting for has finally arrived
    integer item = llGetInventoryType(received_item_name);
    debug((string) item + " " + received_item_type);
    if (item != INVENTORY_NONE &&
	((item == INVENTORY_SCRIPT && received_item_type == "script") ||
	 (item == INVENTORY_NOTECARD && received_item_type == "notecard") ||
	 (item == INVENTORY_TEXTURE && received_item_type == "texture") ||
	 (item == INVENTORY_ANIMATION && received_item_type == "animation") ||
	 (item == INVENTORY_OBJECT && received_item_type == "object"))) {
      llSetTimerEvent(0.0);
      debug("verified");
      llRegionSayTo(update_bee, -update_channel,
		    "ack|"+received_item_type+"|"+received_item_name);
    }
  }
}

