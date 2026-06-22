#ifndef UPDATE_CHANNEL
#define UPDATE_CHANNEL 120125
#endif
#ifndef

#ifndef UPDATER_NAME
#define UPDATER_NAME "Update Bee"
#endif

#ifndef ITEM_NAME
#define ITEM_NAME ""
#endif

#ifndef NOTECARD_NAME
#define NOTECARD_NAME "!UPDATE"
#endif

#define READ_VERSION llLinksetDataRead("version_4_bee")
#define WRITE_VERSION(x) llLinksetDataWrite("version-4-bee",(string) x)

// Updater
#define flyBee 500
#define updateItem 501
#define incrementUpdate 502

#define sUpdateItem "501"
#define sIncrementUpdate "502"

