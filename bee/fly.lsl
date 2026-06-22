#include "src/updater/include/controlstack.h"
#include "src/updater/include/update.h"

#define MAX_JUMPS 411
#define JUMP_MAX 10.0

warpPos( vector destpos )  { 
  integer jumps = (integer)(llVecDist(destpos, llGetPos()) / JUMP_MAX) + 1;
  if (jumps > MAX_JUMPS)  jumps = MAX_JUMPS;
  // Chain the rules so it sleeps only once
  list rules = [ PRIM_POSITION, destpos ];  
  integer count = 1;
  while ( ( count = count << 1 ) < jumps) rules = (rules=[]) + rules + rules; 
  llSetPrimitiveParams( rules + llList2List( rules, (count - jumps) << 1, count) );
  if ( llVecDist( llGetPos(), destpos ) > .001 ) while ( --jumps ) llSetPos( destpos );
}

default {
  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan != flyBee) return;
    GET_CONTROL;
    string loc;
    POP(loc);
    warpPos((vector) loc);
    NEXT_STATE;
  }
}
