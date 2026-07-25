#include "src/updater/include/controlstack.h"
#include "src/updater/include/update.h"

default {
  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan != flyBee) return;
    GET_CONTROL;
    string loc;
    POP(loc);
    llSetRegionPos((vector) loc);
    NEXT_STATE;
  }
}
