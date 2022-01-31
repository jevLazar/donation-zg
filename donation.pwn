/*
				created with <3 for Zara Gaming RPG by Lazar Jevtic :)
*/

#include <a_samp>                      
#include <a_mysql>                      
#include <sscanf2>
#include <YSI_Data\y_iterate>
#include <YSI_Coding\y_va>
#include <YSI_Visual\y_commands>
#include <YSI_Coding\y_stringhash>
#include <YSI_Coding\y_inline>

#define YSI_NO_OPTIMISATION_MESSAGE
#define YSI_NO_HEAP_MALLOC
#define YSI_NO_VERSION_CHECK
#define YSI_NO_MODE_CACHE

new MySQL:gSQL;
new gString[312], gQuery[512], gDialog[656];

#define SQL_HOSTNAME "localhost"
#define SQL_USERNAME "root"
#define SQL_PASSWORD ""
#define SQL_DATABASE "zgdb"

#define MAX_DONATION 5
enum { threadDonations, threadDonationsDesc }

enum donationEnum {
	donationBaseID, donationName[44], donationDesc[256]
};
new donationInfo[MAX_DONATION][donationEnum],
	Iterator:i_Donation<MAX_DONATION>;


main() {}

forward ConnectWithBase();
public ConnectWithBase() {
	gSQL = mysql_connect(SQL_HOSTNAME, SQL_USERNAME, SQL_PASSWORD, SQL_DATABASE);
	return true;
}

forward LoadServerDonation();
public LoadServerDonation() {
	if(!cache_num_rows()) return print("[server]: nema donacija u bazi.");
	for(new index = 1; index < (cache_num_rows() +1); index++) {
	    Iter_Add(i_Donation, index);
		cache_get_value_name_int(index - 1, "donationID", donationInfo[index][donationBaseID]);
		cache_get_value_name(index - 1, "donationName", gString), format(donationInfo[index][donationName], 44, gString);
		cache_get_value_name(index - 1, "donationDesc", gString), format(donationInfo[index][donationDesc], 256, gString);
	}
	return printf("[server]: ucitano %d donacija.", Iter_Count(i_Donation));
}

public OnGameModeInit() {
	ConnectWithBase();
	mysql_log(ERROR);
	mysql_format(gSQL, gQuery, sizeof(gQuery), "SELECT * FROM `zg.donations` ORDER BY `donationID` ASC"), mysql_tquery(gSQL, gQuery, "LoadServerDonation", "");
	return true;
}

public OnGameModeExit() {
	mysql_close(gSQL);
	return true;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[]) {
	switch(dialogid) {
	    case threadDonations: {
	        if(!response) return 1;
	        if(response) {
	            switch(listitem) {
					case 0: {
						strdel(gDialog, 0, sizeof(gDialog));
						foreach(new i : i_Donation) {
						    if(donationInfo[i][donationBaseID] > 0) {
						        format(gDialog, sizeof(gDialog), "%s%s", gDialog, donationInfo[i][donationDesc]);
							}
						}
						ShowPlayerDialog(playerid, threadDonationsDesc, DIALOG_STYLE_MSGBOX, "Donacije", gDialog, "Zatvori", "");
						strdel(gDialog, 0, sizeof(gDialog));
					}
				}
    		}
		}
	}
	return 1;
}

YCMD:dodajdonaciju(playerid, params[], help) {
	new dName[44], dDesc[256];
	if(Iter_Count(i_Donation) >= MAX_DONATION) return SendClientMessage(playerid, -1, "(greska): Limit je dostignut.");
	if(sscanf(params, "s[44]s[256]", dName, dDesc)) return SendClientMessage(playerid, -1, "(koristi): /dodajdonaciju [ime donacije] [opis donacije]");
	inline insertDonationToBase() {
	    if(!cache_affected_rows()) return SendClientMessage(playerid, -1, "(greska): Neuspesno dodavanje donacije!");
		new i = (Iter_Count(i_Donation) +1);
		Iter_Add(i_Donation, i);
		donationInfo[i][donationBaseID] = cache_insert_id();
		format(donationInfo[i][donationName], 44, dName), format(donationInfo[i][donationDesc], 256, dDesc);
		return 1;
	}
	MySQL_PQueryInline(gSQL, using inline insertDonationToBase, "INSERT INTO `zg.donations` (`donationName`, `donationDesc`) VALUES ('%e','%e')", dName, dDesc);
	return true;
}

YCMD:donacije(playerid, params[], help) {
	if(Iter_Count(i_Donation) < 1) return SendClientMessage(playerid, -1, "(greska): Nema dodatih donacija.");
	strdel(gDialog, 0, sizeof(gDialog));
	foreach(new i : i_Donation) {
		if(donationInfo[i][donationBaseID] > 0) {
		    format(gDialog, sizeof(gDialog), "%s%s", gDialog, donationInfo[i][donationDesc]);
		}
	}
	ShowPlayerDialog(playerid, threadDonations, DIALOG_STYLE_LIST, "Lista Donacija", gDialog, "Vidi", "Odustani");
	strdel(gDialog, 0, sizeof(gDialog));
	return true;
}
