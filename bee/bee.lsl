#include "src/updater/include/update.h"

#ifndef debug
#define debug(x)
#endif

#ifndef ITEM_NAME
#define ITEM_NAME ""
#endif

integer channel;
integer handle;
list responses;

#define STRIDE 4
#define ITEM_NAME 0
#define ITEM_VERSION 1
#define ITEM_LOCATION 2
#define ITEM_KEY 3
list items;

integer index;
vector home;

list filter(string name, float v) {
  integer l = llGetListLength(items);
  integer i;
  list keep = [];
  for (i = 0; i < l; i += 4) {
    if ((string) items[i] == name &&
	(float) items[i+1] < v) {
      keep += llList2List(items, i, i+STRIDE-1);
    }
  }
  return keep;
}

default {
  state_entry() {
    channel = (integer)("0x"+llGetSubString((string) llGetKey(), -5,-1));
    responses = [];
    llSetClickAction(CLICK_ACTION_TOUCH);
    llSetText("Click to update " + ITEM_NAME + ".",<1,1,0>,1);
    llSay(0, "Touch to update SPS equipment.");
  }
  
  touch_start(integer x) {
    handle = llListen(channel,"",NULL_KEY,"");
    llSetTimerEvent(5);
    llRegionSay(UPDATE_CHANNEL,"locate|"+(string)llGetKey()+"|"+(string) channel);
  }

  listen(integer channel, string name, key xyzzy, string msg) {
    responses += [msg];
  }

  timer() {
    llSetTimerEvent(0);
    integer l = llGetListLength(responses);
    llSay(0,"timer "+(string) l);
    integer i;
    items = [];
    for (i = 0; i < l; ++i) { 
      list r = llParseString2List((string) responses[i], ["|"],[]);
      if (llListFindList(items,[(vector)(string)r[2]]) == -1) {
	items += [(string) r[0], (float)(string) r[1], (vector)(string) r[2], (key)(string)r[3]];
      }
    }
    items = filter(PowerRack, 0.6); // number is THIS version
    state update;
  }
}

state update {
  state_entry() {
    index = 0;
    home = llGetPos();
    if (index < llGetListLength(items))
      llMessageLinked(LINK_THIS, flyBee,
		      sUpdateItems + "+" + sIncrementUpdate + "|" +
		      (string)(vector)items[index + ITEM_LOCATION] + "|" +
		      (string)items[index] + "|" +
		      (string)(float)items[index + ITEM_VERSION],
		      (key)items[index + ITEM_KEY]);
  }
  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan  != incrementUpdate) return;
    index += STRIDE;
    if (index < llGetListLength(items)) {
      llMessageLinked(LINK_THIS, flyBee,
		      sUpdateItems + "+" + sIncrementUpdate + "|" +
		      (string)(vector)items[index + ITEM_LOCATION] + "|" +
		      (string)items[index] + "|" +
		      (string)(float)items[index + 1],
		      (key)items[index + 3]);
    } else {
      llMessageLinked(LINK_THIS, flyBee, "|" + (string) home, NULL_KEY);
    }
  }    
}
