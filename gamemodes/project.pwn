#include <a_samp>
#include <a_mysql>
#include <zcmd>
#include <sscanf2>
#include <streamer> 
#include <foreach>

// MYSQL DATA BASE 

#define REG_DIALOG 555
#define LOG_DIALOG 777
#define TABLE_ACCOUNTS "accounts" //�������� ������� � ����������
#define SQL_HOST "localhost" //���� ����
#define SQL_USER "root" //��� ������������
#define SQL_DB "newmod" //��� ����, � ������� �� ������������
#define SQL_PASS "" //������
#define SQL_PORT 3306 //���� ����������
#define SQL_RECONNECT true //��������������� � ������ ������
#define SQL_POOLSIZE 10 //������������ �-��� ������������� ����������� (���������� ��� mysql_pquery)
#define MIN_PASS_LENGTH 6 //����������� ������ ������
#define MAX_PASS_LENGTH 64  //������������ ������ ������
#define ENCRYPT_PASS 1 //�������� 1 �������� ���������� ������ � �������. �.�. ��� ������ 123123 �����, � ������� ***123

// COLORS 

#define COLOR_WHITE {0xffffffFF}
#define COLOR_RED {0xff4d00FF}
#define COLOR_BLUE {0x259effFF}
#define COLOR_YELLOW {0xfaff40FF}
#define SCM SendClientMessage

// DEFINES ID DIALOG

#define M_BARRICADE_DIALOG 111


// Global Var's for thorns
new damage_object[MAX_PLAYERS];
new damage_area[MAX_PLAYERS] = {0, ...};

// Global Var's for study system

new name_player[MAX_PLAYERS][MAX_PLAYER_NAME];
new bool:player_status[MAX_PLAYERS];
new player_id[MAX_PLAYERS];
new pickup1;
new pickup2;

// enum for study system

enum
{
	d_teacher = 3000,
	d_teacher_status,
	d_teacher_kick,
	d_gender
};

// enum player_info 

/* ������ */
enum regdata
{
	pAcceptRules,
	pSex,
	pReferal[32+1],
	pPassword[64]
}
new RegData[MAX_PLAYERS][regdata]; //�������� ���������� ��� �����������

enum player_data
{
	pDatabaseID,
	pName[MAX_PLAYER_NAME+1],
	pPassword[64],
	pReferal[32+1],
	pLevel,
	pSex,
	pAdmin,
	bool:pLogged
}
new pData[MAX_PLAYERS][player_data]; //�������� ���������� �������������� ������
new WrongPass[MAX_PLAYERS];
new TextStr[512]; //������ ��� �������������� ������ ������� �����������

/* MYSQL */
new MySQL; //��� ������ connection handle (����� ����������)

// global massive 

main()
{
	print("\n--------------------------------------");
	print("This is the awesome script we are making");
	print("--------------------------------------\n");
}
public OnGameModeInit()
{
	switch(mysql_errno())
	{
		case 0: print("[MYSQL R39.2] Mysql work! Succesfull connected");
		case 1044: print("[ERROR] An unknown user name is specified");
		case 1045: print("[ERROR] An unknown user pass is specified");
		case 1049: print("[ERROR] An unknown user db is specified");
		case 2003: print("[ERROR] An unknown hosting and db is blocking");
		case 2005:print("[ERROR] An unknown address hosting");
	}
	pickup1 = CreatePickup(1318, 23, 1428.7810,-1916.9535,1227.8778);
	pickup2 = CreatePickup(1318, 23, 1211.6018,-1749.9564,13.5941);
	CreateVehicle(431, 1243.1399,-1728.1407,13.6714,359.6708,1, 1, 50); // Hign School Bus1
	CreateVehicle(431, 1230.5779,-1728.0806,13.6701,0.4043,1,1,50); 	// Hign School Bus2
	CreateVehicle(579,1237.2778,-1725.4673,13.4979,1.0172,30,30,50);	// Hign School Car3(Huntley) 
	CreateVehicle(411, 2005.1222,1457.6987,10.6719,298.1738, 1, 1, 50);
	CreateVehicle(541, 2026.8069,1456.9751,10.4145,263.6776, 0, 0, 50);
	CreateVehicle(541, 2026.8069+1,1456.9751,10.4145,263.6776, 3, 1, 50);
	CreateVehicle(420, 2026.8069+5,1456.9751,10.4145,263.6776, 1, 1, 50); // Taxi
	SetGameModeText("Blank Script");
	AddPlayerClass(0, 1958.3783, 1343.1572, 15.3746, 269.1425, 0, 0, 0, 0, 0, 0);
	Interior(); // ��������
	NewMap(); // ������� ������ ������
	MySQL = mysql_connect(SQL_HOST, SQL_USER, SQL_DB, SQL_PASS, SQL_PORT, SQL_RECONNECT, SQL_POOLSIZE);
    mysql_log(LOG_ALL, LOG_TYPE_HTML);
    if(mysql_errno() != 0) print("[-] MYSQL Connection does not exist");
    else
	{
		print("[+] MYSQL Connection accepted ");
		mysql_query(MySQL, "SET NAMES 'cp1251'",false);
		mysql_set_charset("cp1251", MySQL);
	}
	return 1;
}

public OnGameModeExit()
{
	mysql_close(); //��������� ����������
	return 1;
}

public OnPlayerRequestClass(playerid, classid)
{
	if(!pData[playerid][pLogged]) return 0;
	return 1;
}

public OnPlayerConnect(playerid)
{
	new db_str[128]; //������� ������ ��� ������������ �������
	RemovePlayerData(playerid); //������� ������ ����������� player_data

	GetPlayerName(playerid, pData[playerid][pName], MAX_PLAYER_NAME); //����������� ���

	/* ����������� � ���������� ������ */
	mysql_format(MySQL, db_str, sizeof(db_str), "SELECT * FROM `"TABLE_ACCOUNTS"` WHERE `Nickname` = '%e'", pData[playerid][pName]);
	mysql_pquery(MySQL, db_str, "IsValidAccount", "d", playerid);
	SetSpawnInfo(playerid, 0, 222, 1128.9762,-1488.1531,22.7690,360.0000, 0, 0, 0, 0, 0, 0); //������������� ������ ��� ������ (���������� ��� �����)
	GetPlayerName(playerid, name_player[playerid], MAX_PLAYER_NAME); 
	player_status[playerid] = false;
	RemoveObjects(playerid);
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	if(damage_object[playerid] != 0)
    {
        DestroyObject(damage_object[playerid]);
        DestroyDynamicArea(damage_area[playerid]);
    } 
	return 1;
}

public OnPlayerSpawn(playerid)
{
	//SetPlayerPos(playerid,1657.7761,-1842.0952,13.5463);
	SetPlayerPos(playerid,1402.3192,-1909.4186,1227.8029); 
	SetPlayerFacingAngle(playerid,88.7016);
	ShowPlayerDialog(playerid, d_gender, DIALOG_STYLE_MSGBOX, "Gender selection", "This dialog box was created in order for you to choose the gender of your character. \nChoose from the existing options the most appropriate option for your game nickname", "Male", "Female");
	return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
	return 1;
}

public OnVehicleSpawn(vehicleid)
{
	return 1;
}

public OnVehicleDeath(vehicleid, killerid)
{
	return 1;
}

public OnPlayerText(playerid, text[])
{
	return 1;
}

public OnPlayerEnterVehicle(playerid, vehicleid, ispassenger)
{
	return 1;
}

public OnPlayerExitVehicle(playerid, vehicleid)
{
	return 1;
}

public OnPlayerStateChange(playerid, newstate, oldstate)
{
	return 1;
}
public OnPlayerEnterDynamicArea(playerid, areaid)
{
	if(GetPlayerState(playerid) == PLAYER_STATE_DRIVER)
	{
		foreach(new i: Player)
		{
			if(areaid == damage_area[i])
			{
				new panels, doors, lights, tires;
                GetVehicleDamageStatus(GetPlayerVehicleID(playerid), panels, doors, lights, tires);
                UpdateVehicleDamageStatus(GetPlayerVehicleID(playerid), panels, doors, lights, 15);
                break;
			}
		}
	}
	return true;
}
public OnPlayerEnterCheckpoint(playerid)
{
	return 1;
}

public OnPlayerLeaveCheckpoint(playerid)
{
	return 1;
}

public OnPlayerEnterRaceCheckpoint(playerid)
{
	return 1;
}

public OnPlayerLeaveRaceCheckpoint(playerid)
{
	return 1;
}

public OnRconCommand(cmd[])
{
	return 1;
}

public OnPlayerRequestSpawn(playerid)
{
	if(!pData[playerid][pLogged]) return 0;
	return 1;
}

public OnObjectMoved(objectid)
{
	return 1;
}

public OnPlayerObjectMoved(playerid, objectid)
{
	return 1;
}

public OnPlayerPickUpPickup(playerid, pickupid)
{
	
	if(pickupid == pickup1)
	{
		Create3DTextLabel("Exit in Street", -1, 1428.7810,-1916.9535,1227.8778, 15.0, 0);
		SetPlayerPos(playerid,1211.2732,-1747.5769,13.5941);  // Street
		SetPlayerFacingAngle(playerid,15.6767); // // Street Angle Pos
	}
	if(pickupid == pickup2)
	{
		Create3DTextLabel("High School Los-Santos", -1, 1211.6018,-1749.9564,13.5941, 15.0, 0);
		SetPlayerPos(playerid,1426.9818,-1917.7054,1227.8741); 
		SetPlayerFacingAngle(playerid,86.4674);	
	}
	return 1;
}

public OnVehicleMod(playerid, vehicleid, componentid)
{
	return 1;
}

public OnVehiclePaintjob(playerid, vehicleid, paintjobid)
{
	return 1;
}

public OnVehicleRespray(playerid, vehicleid, color1, color2)
{
	return 1;
}

public OnPlayerSelectedMenuRow(playerid, row)
{
	return 1;
}

public OnPlayerExitedMenu(playerid)
{
	return 1;
}

public OnPlayerInteriorChange(playerid, newinteriorid, oldinteriorid)
{
	return 1;
}

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	if((newkeys & KEY_WALK))
	{
		if(IsPlayerInRangeOfPoint(playerid, 2.0,1386.6650,-1904.4753,1224.9299+0.35))
		{
			new string[40];
			new players_count;

			foreach(new i: Player) players_count++;
			format(string, sizeof(string), "At the moment there are %i people in the audience", players_count);
			ShowPlayerDialog(playerid, d_teacher, DIALOG_STYLE_LIST, string, !"1. Mark the missing \n2. Expel the student", !"Next",!"Close");
		}
	}
	return 1;
}

public OnRconLoginAttempt(ip[], password[], success)
{
	return 1;
}

public OnPlayerUpdate(playerid)
{
	return 1;
}

public OnPlayerStreamIn(playerid, forplayerid)
{
	return 1;
}

public OnPlayerStreamOut(playerid, forplayerid)
{
	return 1;
}
public LoadPlayerAccount(playerid)
{
	if(cache_get_row_count(MySQL) == 1)
	{
		/* ������ ������ �� �� �� ������ */
		pData[playerid][pDatabaseID] = cache_get_field_content_int(0, "ID", MySQL);
		cache_get_field_content(0, "Referal", pData[playerid][pReferal], MySQL, 64);
		pData[playerid][pLevel] = cache_get_field_content_int(0, "Level", MySQL);
		pData[playerid][pSex] = cache_get_field_content_int(0, "Sex", MySQL);
		pData[playerid][pAdmin] = cache_get_field_content_int(0, "Admin", MySQL);
		pData[playerid][pLogged] = true; //����������
		SendClientMessage(playerid, -12, "{fdd9b5}[SYSTEM] | {efdecd}Data uploaded successfully. Have a nice game!");
		SpawnPlayer(playerid);

		/* �������� ������� ��� �������� �������� */
		print("-----------------------------------");
		printf("Nickname: %s", pData[playerid][pName]);
		printf("DB: %i", pData[playerid][pDatabaseID]);
		printf("Referal: %s", pData[playerid][pReferal]);
		printf("Level: %d", pData[playerid][pLevel]);
		printf("Sex: %d", pData[playerid][pSex]);
		printf("Admin: %d", pData[playerid][pAdmin]);
		print("-----------------------------------");
	}
	return 1;
}

public IsValidAccount(playerid)
{
	if(cache_get_row_count(MySQL) == 1) //���� ����� 1 ������ ��� �������
	{
		cache_get_row(0, 2, pData[playerid][pPassword], MySQL, 64); //������������ ������ ��� ��������

		SendClientMessage(playerid, -1, "{fdd9b5}[SYSTEM] | {efdecd}Your account was successfully found in the database. Please log in:");
		ShowPlayerDialog(playerid, LOG_DIALOG, DIALOG_STYLE_INPUT, "Authorization", "Your account was found in the database\nPlease log in:", ">>", "Exit");
	}
	else //���� 1 ������ ��� ������� �� ������
	{
		SendClientMessage(playerid, -1, "{fdd9b5}[SYSTEM] | {efdecd}Your account was not found in the database. Please register:");
		ResetRegData(playerid); //�������� ������
		ShowRegisterDialog(playerid);
	}
	return 1;
}
public OnPlayerRegister(playerid)
{
	pData[playerid][pDatabaseID] = cache_insert_id(); //���������� �� �������� � ����. �� ���� �� ����� ��������� �������. � �� �� ����������� �������������
	pData[playerid][pLevel] = 1;
	pData[playerid][pAdmin] = 0;

	pData[playerid][pLogged] = true; //����������

	SpawnPlayer(playerid);
	SendClientMessage(playerid, -1, "{fdd9b5}[SYSTEM] | {efdecd}Congratulations on your successful registration!");
	return 1;
}

public OnVehicleStreamIn(vehicleid, forplayerid)
{
	return 1;
}

public OnVehicleStreamOut(vehicleid, forplayerid)
{
	return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	if(dialogid == M_BARRICADE_DIALOG)
	{
	    if(response)
		{
		    if(listitem == 0)
		    {
     			new Float:x;
				new Float:y;
				new Float:z;
				new Float:a;
				new count = 2899;
				GetPlayerPos(playerid, x, y, z);
				GetPlayerFacingAngle(playerid, a);
				damage_object[playerid] = CreateDynamicObject(count, x, y, z-0.8, 0, 0, a);
				damage_area[playerid] = CreateDynamicSphere(x, y, z, 7.0,-1,-1,-1);
				ApplyAnimation(playerid, "BOMBER", "BOM_Plant", 4.1, 0, 1, 1, 1, 1);
				new string[128];
				format(string, sizeof(string), "{00ff00}[Success]{FFFFFF} Create object - ID: %d | This Coordinate's Rotation: %f", count, a);
				SCM(playerid, 0xFFFFFFAA, string);
				return true;
		    }
		    if(listitem == 1)
		    {
		        SCM(playerid, 0xFFFFFFAA, "Ur choose listitem 2!");
		    }
		    else
		    {
		        SCM(playerid, 0xFFFFFFAA, "Test OK!");
		    }
		    	  	
		}
	}
	switch(dialogid)
	{
		case d_gender:
		{
			if(!response)
			{
				SetPlayerSkin(playerid, 11);
			}
			else
			{
				SetPlayerSkin(playerid, 46);
			}
		}
		case d_teacher:
		{
			if(!response) return true;
			switch(listitem)
			{
				case 0: 
				{
					new string[400] = "Name\tStatus";
					foreach(new i: Player)
					{
						format(string, sizeof(string), "%s\n%s\t%s", string, name_player[i],(player_status[i]) ? ("Attend") : ("Miss"));
						player_id[i] = i;
					}
					ShowPlayerDialog(playerid, d_teacher_status, DIALOG_STYLE_TABLIST_HEADERS, !"Student mark",string,!"Note",!"Exit");
				}
				case 1:
				{
					new string[400];
					foreach(new i: Player)
					{
						format(string, sizeof(string), "%s\n%s", string, name_player[i]);	
						player_id[i] = i;
					}
					ShowPlayerDialog(playerid, d_teacher_kick, DIALOG_STYLE_LIST, !"Select student",string,!"Kick",!"Exit");
				}
			}
		}
		case d_teacher_kick:
		{
			if(!response) return true;
			{
				SCM(playerid, -2, "Student kicked out");
				Kick(player_id[listitem]);
			}
		}
		case d_teacher_status:
		{
			if(!response) return true;
			player_status[ player_id[ listitem ] ] = !player_status[ player_id[ listitem ] ];

			new string[400] = "Name\tStatus";
			foreach(new i: Player)
			{
				format(string, sizeof(string), "%s\n%s\t%s", string, name_player[i],(player_status[i]) ? ("Attend") : ("Miss"));
				player_id[i] = i;
			}
			ShowPlayerDialog(playerid, d_teacher_status, DIALOG_STYLE_TABLIST_HEADERS, !"Student mark",string,!"Note",!"Exit");
		}
		case LOG_DIALOG:
		{
			new wrong_pass[8];
			new load_query[512];
			if(!response)
			{
				/*
					��� ���������� ������� �������� ��� ������ �����
					� ��� ����������� �������� ���
				*/
				Kick(playerid);
				return 1;
			}
			if(strlen(pData[playerid][pPassword]) < MIN_PASS_LENGTH || strlen(pData[playerid][pPassword]) > MAX_PASS_LENGTH)
			{
				ShowPlayerDialog(playerid, LOG_DIALOG, DIALOG_STYLE_INPUT, "Autorization", "Incorrect password length! Try again:", ">>", "Exit");
				return 1;
			}
			if(!strcmp(pData[playerid][pPassword], inputtext, true))
			{
				mysql_format(MySQL, load_query, 512, "SELECT * FROM `"TABLE_ACCOUNTS"` WHERE `Nickname` = '%s' AND `Password` = '%s'", pData[playerid][pName], pData[playerid][pPassword]);
				mysql_tquery(MySQL, load_query, "LoadPlayerAccount", "d", playerid);
				SendClientMessage(playerid, -12, "{fdd9b5}[SYSTEM] | {efdecd}Player data is being loaded..");
			}
			else
			{
				WrongPass[playerid] ++;
				if(WrongPass[playerid] > 2) //���� ������ ���� ������, �� ��!!!
				{
					/*
						��� ���������� ������� �������� ��� ���������� �������� ������������� ������
						� ����� �� ��� ����������� �������� ���
					*/
					Kick(playerid);
					return 1;
				}
				ShowPlayerDialog(playerid, LOG_DIALOG, DIALOG_STYLE_INPUT, "Autorization", "Incorrect password length! Try again:", ">>", "Exit");
				format(wrong_pass, 8, "~r~%d/3", WrongPass[playerid]);
				GameTextForPlayer(playerid, wrong_pass, 3000, 6);
			}
			return 1;
		}
		case REG_DIALOG:
		{
			switch(listitem)
			{
				case 0: //�������
				{
					if(RegData[playerid][pAcceptRules] > 1) //���� �������� ��� �������� ������
					{
						SendClientMessage(playerid, -1, "You are familiar with the rules!");
						ShowRegisterDialog(playerid);
						return 1;
					}
					ShowPlayerDialog(playerid, REG_DIALOG+1, DIALOG_STYLE_MSGBOX, "Server Rules", "Rules #1: Test\nRules #2: Test", ">>", "");
					RegData[playerid][pAcceptRules] = 1; //����� ��������� ������ ��������
				}
				case 1: //��� ���������
				{
					ShowPlayerDialog(playerid, REG_DIALOG+2, DIALOG_STYLE_MSGBOX, "Choosing a character's gender", "Choose the gender of your character", "Male", "Female");
				}
				case 2:
				{
					ShowPlayerDialog(playerid, REG_DIALOG+3, DIALOG_STYLE_INPUT, "Referal", "Enter the name of the player who invited you to the server:", ">>", "�����");
				}
				case 3:
				{
					ShowPlayerDialog(playerid, REG_DIALOG+4, DIALOG_STYLE_PASSWORD, "Password", "Come up with a password for your account:", ">>", "�����");
				}
				case 4: //���������� �����������
				{
					if(RegData[playerid][pAcceptRules] < 2) return SendClientMessage(playerid, -1, "[ERROR] You haven't read the server rules!"), ShowRegisterDialog(playerid);
					if(!RegData[playerid][pSex]) return SendClientMessage(playerid, -1, "[ERROR] You didn't specify the gender of the character!"), ShowRegisterDialog(playerid);
					if(strlen(RegData[playerid][pPassword]) < MIN_PASS_LENGTH || strlen(RegData[playerid][pPassword]) > MAX_PASS_LENGTH) return SendClientMessage(playerid, -1, "[ERROR]You didn't specify a password!"), ShowRegisterDialog(playerid);

					new add_db[512]; //�������� ���� ������ �� ���� ������, ������� �� ����������� ��� ��������, ���� �� ����

					/* ��������� ��������� ������ � ����������� ��� �������� ���������� �� �������� */

					format(pData[playerid][pReferal], 64, RegData[playerid][pReferal]);
					format(pData[playerid][pPassword], 64, RegData[playerid][pPassword]);
					RegData[playerid][pSex] = pData[playerid][pSex];

					/* ���������� ������ �� ���������� �������� � ���� */

					mysql_format(MySQL, add_db, 512, "INSERT INTO `"TABLE_ACCOUNTS"` (`Nickname`, `Password`, `Level`, `Sex`, `Referal`, `Admin`) VALUES ('%s', '%s', 1, '%d', '%s', 0)", pData[playerid][pName], pData[playerid][pPassword], pData[playerid][pSex], pData[playerid][pReferal]);
					mysql_pquery(MySQL, add_db, "OnPlayerRegister", "d", playerid);

					ResetRegData(playerid); //�������� ������ �����������

					/*
						������ �� �������� �������� � ���� ��������.
						� ������� OnPlayerRegister �������� ����������� ������ � ���������� ����� ������
					*/
				}
			}
			return 1;
		}
		case REG_DIALOG+1:
		{
			if(RegData[playerid][pAcceptRules] > 1)
			{
				SendClientMessage(playerid, -1, "You have successfully read the server rules!");
				ShowRegisterDialog(playerid);
				return 1;
			}
			ShowPlayerDialog(playerid, REG_DIALOG+1, DIALOG_STYLE_MSGBOX, "Server Rules", "Rules #3: Test\nRules #4: Test", ">>", "");
			RegData[playerid][pAcceptRules] = 2;
			return 1;
		}
		case REG_DIALOG+2:
		{
			if(response) RegData[playerid][pSex] = 1;
			else RegData[playerid][pSex] = 2;
			SendClientMessage(playerid, -1, "The sex has been successfully installed");
			ShowRegisterDialog(playerid);
			return 1;
		}
		case REG_DIALOG+3:
		{
			if(!response) return ShowRegisterDialog(playerid);

			if(strlen(inputtext) < 4 || strlen(inputtext) > 32)
			{
				SendClientMessage(playerid, -1, "The referral name must contain a minimum of 3 and a maximum of 32 characters!");
				ShowPlayerDialog(playerid, REG_DIALOG+3, DIALOG_STYLE_INPUT, "Referal", "Enter the name of the player who invited you to the server:", ">>", "Back");
				return 1;
			}
			format(RegData[playerid][pReferal], 32, inputtext);
			SendClientMessage(playerid, -1, "The referral was successfully specified!");

			ShowRegisterDialog(playerid);
			return 1;
		}
		case REG_DIALOG+4:
		{
			/*
				��� �� ������ ������������� ��� �������: ���������� ��5, ���������� ������ �� �������/��������� � �.�. � �.�. �� ��� ������
				��� ������� ������ ������� �����������, ������� � �� ���� ��������� ������� ��������, � ������� ��� ������������ ���! :)
			*/
			if(strlen(inputtext) < MIN_PASS_LENGTH || strlen(inputtext) > MAX_PASS_LENGTH)
			{
				SendClientMessage(playerid, -1, "Invalid password length");
				ShowPlayerDialog(playerid, REG_DIALOG+4, DIALOG_STYLE_INPUT, "Password", "Come up with a password for your account:", ">>", "�����");
				return 1;
			}
			format(RegData[playerid][pPassword], 64, inputtext);
			SendClientMessage(playerid, -1, "The password was successfully entered!");

			ShowRegisterDialog(playerid);
			return 1;
		}

	}
	return true;
}		
CMD:jetpack(playerid, params[])
{
	SetPlayerSpecialAction(playerid, SPECIAL_ACTION_USEJETPACK);
	return 1;
}
CMD:fix(playerid, vehicleid)
{
	if(!IsPlayerInAnyVehicle(playerid)) return SendClientMessage(playerid, -2, "[ERROR] You cannot use this command outside of the machine!");
	RepairVehicle(GetPlayerVehicleID(playerid));
	SendClientMessage(playerid, -2, "[PROCESS] Your car has been successfully repaired.");
	return true;
	
}
CMD:kill(playerid, params[])
{
	SetPlayerHealth(playerid, 0);
	return 1;
}
CMD:skin(playerid, params[])
{
	new skinid;
	if(sscanf(params, "i", skinid))
	return SCM(playerid, 0x259effFF, "Usage: /skin [ID]");
	SetPlayerSkin(playerid, skinid);

	return 1;
}
CMD:weapon(playerid, params[])
{
	new weaponid, ammo;
	if(sscanf(params, "ii", weaponid, ammo))
		return SCM(playerid, 0x259effFF, "Usage: /weapon [ID] [AMMO]");
	if(weaponid < 1 || weaponid > 46 || weaponid == 18)
		return SCM(playerid, 0x259effFF, "You have specified a invalid weapon");
	if(ammo < 1)
		return SCM(playerid, 0x259effFF, "You have specified a invalid ammo amount");
	GivePlayerWeapon(playerid, weaponid, ammo);
	return 1;
}
CMD:setbarricade(playerid, params[])
{
	// Create Dynamic Zone for barricade
	ShowPlayerDialog(playerid, M_BARRICADE_DIALOG, DIALOG_STYLE_LIST, "[POLICE SYS] Main Menu Barricades", "Special Torns System!\nTest!", "Choose", "Exit");
	return 1;
}
CMD:veh(playerid, params[])
{
	new Float:x;
	new Float:y;
	new Float:z;
	new string[128];

	if(sscanf(params, "iii", params[0], params[1], params[2]))
	{
		PlayerPlaySound(playerid, 31203, 0.0, 0.0, 0.0);
		SendClientMessage(playerid, -2, "[HELP] Use cmd: /veh [id auto] [color 1] [color 2]");
	}
	if(params[0] < 411 || params[0] > 611) // id cars
	{
		PlayerPlaySound(playerid, 31203, 0.0, 0.0, 0.0);
		SendClientMessage(playerid, -2, "[HELP] The transport ID must be between 400 - 611");	
	}
	if(params[1] < 0 || params[1] > 255 || params[2] < 0 || params[2] > 255) // id color cars 0-255
	{
		PlayerPlaySound(playerid, 31203, 0.0, 0.0, 0.0);
		SendClientMessage(playerid, -2, "[HELP] The transport color ID must be between 0 - 255");	
	}
	GetPlayerPos(playerid, x, y, z);
	format(string, sizeof(string), "[PROCESS] Vehicle ID: %d successfully created! To delete a transport, use the /delveh command", params[0]);
	SCM(playerid, -2, string);
	CreateVehicle(params[0], x+3.0, y, z+1, 0.0, params[1], params[2], 600);
	return true;
}
CMD:delveh(playerid)
{
	if(GetPlayerState(playerid) != PLAYER_STATE_DRIVER)
	{
		SCM(playerid, -2, "[HELP] You need to be in the transport");
	}
	if(GetPlayerState(playerid) == PLAYER_STATE_DRIVER)
	{
		new carid = GetPlayerVehicleID(playerid);
		DestroyVehicle(carid);	
		SCM(playerid, -2, "[INFO] The car you previously used has been deleted");
	}
	return true;
}
stock ResetRegData(playerid)
{
	RegData[playerid][pAcceptRules] = 0;
	RegData[playerid][pSex] = 0;
	RegData[playerid][pReferal] = EOS;
	RegData[playerid][pPassword] = EOS;
	return 1;
}
stock RemovePlayerData(playerid)
{
	pData[playerid][pLevel] = 1;
	pData[playerid][pSex] = 0;
	pData[playerid][pAdmin] = 0;
	pData[playerid][pLogged] = false; 
	WrongPass[playerid] = 0;
	return 1;
}

stock UpdatePlayerData(playerid)
{
	if(!pData[playerid][pLogged]) return 1; //�� ���������, ���� ����� �� �����������

	new save_query[512]; //�������� ���� ������ �� ���� ������, ������� �� ����������� ��� ��������, ���� �� ����
	new str_q[128];

	format(str_q, sizeof str_q, "UPDATE `"TABLE_ACCOUNTS"` SET "), strcat(save_query, str_q);

	format(str_q, sizeof str_q, "`Nickname` = '%s',", pData[playerid][pName]), strcat(save_query, str_q);
	format(str_q, sizeof str_q, "`Password` = '%s',", pData[playerid][pPassword]), strcat(save_query, str_q);
	format(str_q, sizeof str_q, "`Level` = '%d',", pData[playerid][pLevel]), strcat(save_query, str_q);
	format(str_q, sizeof str_q, "`Sex` = '%d',", pData[playerid][pSex]), strcat(save_query, str_q);
	format(str_q, sizeof str_q, "`Referal` = '%s',", pData[playerid][pReferal]), strcat(save_query, str_q);
	format(str_q, sizeof str_q, "`Admin` = '%d'", pData[playerid][pAdmin]), strcat(save_query, str_q);

	format(str_q, sizeof str_q," WHERE `ID` = '%i'", pData[playerid][pDatabaseID]), strcat(save_query, str_q);
	mysql_tquery(MySQL, save_query, "", "");
	return 1;
}
stock ShowRegisterDialog(playerid)
{
	new str_local[64], switch_str[32];
	TextStr = "\0"; //�������������� �������

	switch(RegData[playerid][pAcceptRules]) //��� �� ������ ���������, ������� ������� ������ ���������� �����
	{
		case 0,1: switch_str = "Not familiar with";
		default: switch_str = "Familiarized with";
	}
	format(str_local, sizeof(str_local), "Server Rules\t{86a366}%s\n", switch_str), strcat(TextStr, str_local);

	switch(RegData[playerid][pSex]) //��� �� ������ ���������, ������� ������� ������ ���������� �����
	{
		case 1: switch_str = "Male";
		case 2: switch_str = "Female";
		default: switch_str = "Not specified";
	}
	format(str_local, sizeof(str_local), "Gender of the character\t{86a366}%s\n", switch_str), strcat(TextStr, str_local);

	/*
		��� �� ������ �������, �� ��� �� ������ ����������, ���� �������� �� ����� ������ ��������
		� �� ��� ����������� ������ ���� ��������� ������ ��������
	*/
	if(strlen(RegData[playerid][pReferal]) < 4)
	{
		format(str_local, sizeof(str_local), "Referal\t{86a366}Not specified\n"), strcat(TextStr, str_local);
	}
	else format(str_local, sizeof(str_local), "Referal\t{86a366}%s\n", RegData[playerid][pReferal]), strcat(TextStr, str_local);

	if(strlen(RegData[playerid][pPassword]) < MIN_PASS_LENGTH || strlen(RegData[playerid][pPassword]) > MAX_PASS_LENGTH)
	{
		format(str_local, sizeof(str_local), "Pass\t{86a366}Not specified\n"), strcat(TextStr, str_local);
	}
	else //���� ������ �������� �� ������
	{
		#if ENCRYPT_PASS

		new encrypt_pass[64];
		strcat(encrypt_pass, RegData[playerid][pPassword], 64); //��������� �����, ����� ��� ��� ����� ���� ��������� �����������
		strdel(encrypt_pass, 0, strlen(encrypt_pass)-3); //������� ��� �������, ����� 3 ���������
		for(new s; s < strlen(RegData[playerid][pPassword])-3; s++) strins(encrypt_pass, "*", 0); //��������� ��������� � ������ ������

		format(str_local, sizeof(str_local), "Pass\t{86a366}%s\n", encrypt_pass), strcat(TextStr, str_local); //��� ���������� �������� ���������� �������

		#else

		/*
			��� �� �� ���������� ����������, ������� ��������� RegData[playerid][pPassword]
		*/
		format(str_local, sizeof(str_local), "Pass\t{86a366}%s\n", RegData[playerid][pPassword]), strcat(TextStr, str_local);

		#endif
	}
	format(str_local, sizeof(str_local), "Complete registration >>"), strcat(TextStr, str_local);

	ShowPlayerDialog(playerid, REG_DIALOG, DIALOG_STYLE_TABLIST, "Registration", TextStr, ">>",  "");
	return 1;
}
stock NewMap()
{
	// BIG
	new tmpobjid;
	tmpobjid = CreateDynamicObject(6188, 836.315002, -1866.749267, -0.541091, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 6, 1613, "alleyprop", "stuffdirtcol", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 827.476501, -2012.023559, 11.521598, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 845.423706, -2012.023559, 11.521598, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 827.476501, -2162.022216, 11.521598, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 845.423706, -2162.022216, 11.521598, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 827.476501, -2312.021484, 11.521598, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 845.423706, -2312.021484, 11.521598, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 827.476501, -2462.020019, 11.521598, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 845.423706, -2462.020019, 11.521598, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 827.476501, -2612.019775, 11.521598, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 845.423706, -2612.019775, 11.521598, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 827.476501, -2762.019287, 11.521598, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 845.423706, -2762.019287, 11.521598, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 827.476501, -2912.018310, 11.521598, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18791, 853.177490, -2876.002929, 11.521200, 0.000000, 0.000000, -67.500000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18791, 835.229370, -3026.002441, 11.521200, 0.000000, 0.000000, -67.500000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18791, 890.353576, -3081.127197, 11.521200, 0.000000, 0.000000, -22.500000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18791, 908.302307, -2931.127441, 11.521200, 0.000000, 0.000000, -22.500000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 1022.282470, -2938.881103, 11.521598, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 1172.282104, -2938.881103, 11.521598, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 1322.282104, -2938.881103, 11.521598, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 1472.282104, -2938.881103, 11.521598, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 1622.281982, -2938.881103, 11.521598, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 1772.281982, -2938.881103, 11.521598, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 1922.281005, -2938.881103, 11.521598, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 2072.279785, -2938.881103, 11.521598, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 2222.279052, -2938.881103, 11.521598, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 2372.278320, -2938.881103, 11.521598, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 2522.278320, -2938.881103, 11.521598, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 1004.334594, -3088.881103, 11.521598, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 1154.334472, -3088.881103, 11.521598, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 1304.334472, -3088.881103, 11.521598, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 1454.334960, -3088.881103, 11.521598, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 1604.334716, -3088.881103, 11.521598, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 1754.334472, -3088.881103, 11.521598, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 1904.334594, -3088.881103, 11.521598, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 2054.333984, -3088.881103, 11.521598, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 2204.333496, -3088.881103, 11.521598, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 2354.332519, -3088.881103, 11.521598, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 2504.332031, -3088.881103, 11.521598, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 2654.332275, -3088.881103, 11.521598, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 2804.331787, -3088.881103, 11.521598, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 2954.330322, -3088.881103, 11.521598, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 3104.330078, -3088.881103, 11.521598, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18791, 3218.302001, -3096.634521, 11.521750, 0.000000, 0.000000, -202.500000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18791, 3273.427246, -3151.760009, 11.521800, 0.000000, 0.000000, -247.500000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 3281.180419, -3265.735595, 11.521598, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18791, 3288.933837, -3379.719726, 11.521800, 0.000000, 0.000000, -67.500000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18791, 3344.058837, -3434.844970, 11.521800, 0.000000, 0.000000, -22.500000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 3458.039794, -3442.598632, 11.521598, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18796, 4002.408447, -3442.600830, 31.889999, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 3607.983154, -3442.598632, 14.793398, 0.000000, -2.500000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 3757.839111, -3442.598388, 21.335800, 0.000000, -2.500000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 3907.695312, -3442.598388, 27.878200, 0.000000, -2.500000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 4097.090820, -3442.598388, 27.878200, 0.000000, -2.500000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 4246.947753, -3442.598388, 21.335800, 0.000000, -2.500000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 4396.804687, -3442.598388, 14.793398, 0.000000, -2.500000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 4546.660644, -3442.598632, 8.315999, 0.000000, -2.450000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18802, 4631.479492, -3442.599121, 3.031300, 0.000000, 0.050000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(19534, 4648.979980, -3442.562500, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4648.979980, -3372.562500, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4648.979980, -3512.562255, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4718.979492, -3442.562500, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19552, 4718.979492, -3512.562255, 1.515498, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19552, 4718.979492, -3372.562500, 1.515498, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19552, 4578.979492, -3512.562255, 1.515498, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19552, 4578.979492, -3372.562500, 1.515498, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19545, 4609.321289, -3442.562011, 1.515498, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 4547.728515, -3442.562011, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4508.979003, -3442.562011, 1.323698, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 2672.277832, -2938.881103, 11.521598, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 2822.277832, -2938.881103, 11.521598, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 2972.277587, -2938.881103, 11.521598, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 3122.277099, -2938.881103, 11.521598, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 3272.276611, -2938.881103, 11.521598, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 3422.276367, -2938.881103, 11.521598, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 3572.275878, -2938.881103, 11.521598, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 3722.275634, -2938.881103, 11.521598, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 3872.274902, -2938.881103, 11.521598, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 4022.274414, -2938.881103, 11.521598, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18791, 4136.251953, -2931.127197, 11.521598, 0.000000, 0.000000, 22.500000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18791, 4191.376953, -2876.002197, 11.521598, 0.000000, 0.000000, 67.500000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 4199.130371, -2762.023193, 11.521598, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 4199.130371, -2612.023437, 11.521598, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18791, 4206.883789, -2498.049804, 11.521598, 0.000000, 0.000000, -112.500000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18791, 4262.006835, -2442.925781, 11.521598, 0.000000, 0.000000, -157.500000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 4375.992187, -2435.171875, 11.521598, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 4525.992187, -2435.171875, 11.521598, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 4675.991210, -2435.171875, 11.521598, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18791, 4789.963378, -2442.925048, 11.521598, 0.000000, 0.000000, -202.500000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18791, 4845.087402, -2498.048828, 11.521598, 0.000000, 0.000000, -247.500000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 4852.841308, -2612.025390, 11.521598, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 4852.841308, -2762.025390, 11.521598, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 4852.841308, -2912.025390, 11.521598, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(19534, 4788.979003, -3442.562500, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4788.979003, -3372.562500, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4858.979003, -3442.562500, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19552, 4858.979003, -3372.562500, 1.515498, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 4852.839355, -3061.849853, 8.250699, 0.000000, -2.500000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(19534, 4508.979003, -3302.562500, 1.323698, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 4852.841308, -3200.055419, 5.331600, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4718.979492, -3302.562500, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(18802, 4852.841308, -3285.059326, 3.239799, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(19534, 4788.979003, -3302.562500, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4858.979003, -3302.562500, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19425, 4858.499023, -3295.325683, 1.520099, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19425, 4858.499023, -3295.504882, 1.520099, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19425, 4858.499023, -3295.688964, 1.520099, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19425, 4858.499023, -3295.871093, 1.520099, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19425, 4858.499023, -3296.062988, 1.520099, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19425, 4858.499023, -3296.246826, 1.505100, 5.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19425, 4858.499023, -3296.452880, 1.455100, 8.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19425, 4858.499023, -3296.580810, 1.409100, 9.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19425, 4858.499023, -3296.786621, 1.335100, 9.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19425, 4858.499023, -3297.010498, 1.279098, 9.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19425, 4858.499023, -3295.147705, 1.520099, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19425, 4858.499023, -3294.958740, 1.520099, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19425, 4855.195800, -3294.958740, 1.520099, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19425, 4855.195800, -3295.147705, 1.520099, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19425, 4855.195800, -3295.325683, 1.520099, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19425, 4855.195800, -3295.504882, 1.520099, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19425, 4855.195800, -3295.688964, 1.520099, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19425, 4855.195800, -3295.871093, 1.520099, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19425, 4855.195800, -3296.062988, 1.520099, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19425, 4855.195800, -3296.246826, 1.505100, 5.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19425, 4855.195800, -3296.452880, 1.455100, 8.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19425, 4855.195800, -3296.580810, 1.409100, 9.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19425, 4855.195800, -3296.786621, 1.335100, 9.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19425, 4855.195800, -3297.010498, 1.279098, 9.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19425, 4847.185058, -3294.958740, 1.520099, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19425, 4847.185058, -3295.147705, 1.520099, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19425, 4847.185058, -3295.325683, 1.520099, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19425, 4847.185058, -3295.504882, 1.520099, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19425, 4847.185058, -3295.688964, 1.520099, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19425, 4847.185058, -3295.871093, 1.520099, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19425, 4847.185058, -3296.062988, 1.520099, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19425, 4847.185058, -3296.246826, 1.505100, 5.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19425, 4847.185058, -3296.452880, 1.455100, 8.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19425, 4847.185058, -3296.580810, 1.409100, 9.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19425, 4847.185058, -3296.786621, 1.335100, 9.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19425, 4847.185058, -3297.010498, 1.279098, 9.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19425, 4850.488281, -3294.958740, 1.520099, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19425, 4850.488281, -3295.147705, 1.520099, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19425, 4850.488281, -3295.325683, 1.520099, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19425, 4850.488281, -3295.504882, 1.520099, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19425, 4850.488281, -3295.688964, 1.520099, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19425, 4850.488281, -3295.871093, 1.520099, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19425, 4850.488281, -3296.062988, 1.520099, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19425, 4850.488281, -3296.246826, 1.505100, 5.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19425, 4850.488281, -3296.452880, 1.455100, 8.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19425, 4850.488281, -3296.580810, 1.409100, 9.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19425, 4850.488281, -3296.786621, 1.335100, 9.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19425, 4850.488281, -3297.010498, 1.279098, 9.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19425, 4852.840332, -3294.958740, 1.522099, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19425, 4852.840332, -3295.147705, 1.522099, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19425, 4852.840332, -3295.325683, 1.522099, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19425, 4852.840332, -3295.504882, 1.522099, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19425, 4852.840332, -3295.688964, 1.522099, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19425, 4852.840332, -3295.871093, 1.522099, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19425, 4852.840332, -3296.062988, 1.522099, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19425, 4852.840332, -3296.246826, 1.507099, 5.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19425, 4852.840332, -3296.452880, 1.457100, 8.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19425, 4852.840332, -3296.580810, 1.411100, 9.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19425, 4852.840332, -3296.786621, 1.337100, 9.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19425, 4852.840332, -3297.010498, 1.281100, 9.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4508.979003, -3512.562255, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4508.979003, -3372.562500, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4578.979492, -3302.562500, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19534, 4648.979980, 4508.979003, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19534, 4508.979003, -3582.562011, 1.323698, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4438.980468, -3582.562011, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4368.980957, -3582.562011, 1.323698, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4368.980957, -3582.562011, 1.325700, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19534, 4648.979980, -3302.562500, 1.323698, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 4648.979980, -3263.812500, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 4788.979003, -3263.812500, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4788.979003, -3225.062500, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19534, 4648.979980, -3225.062500, 1.323698, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4718.979492, -3225.062500, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19538, 4718.979492, -3263.812500, 1.515498, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 4788.979003, -3186.312500, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4788.979003, -3147.562500, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 4788.979003, -3108.812988, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 4648.979980, -3186.312500, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19534, 4648.979980, -3147.562500, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4718.979492, -3147.562500, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4788.979003, -3070.062988, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 4788.979003, -3031.313232, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4788.979003, -2992.563476, 1.323698, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4858.979003, -2992.563476, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19538, 4718.979492, -3186.312500, 1.515498, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19552, 4858.979003, -3232.564208, 1.515498, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19552, 4858.979003, -3107.564453, 1.515498, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19538, 4858.979003, -3031.313232, 1.509500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4718.979492, -3070.062988, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19538, 4718.979492, -3108.812988, 1.515498, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 4508.979003, -3263.812500, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19538, 4578.979492, -3263.812500, 1.515498, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19534, 4508.979003, -3225.062011, 1.323698, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 4470.229492, -3225.062011, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4431.479492, -3225.062011, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4578.979492, -3225.062011, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 4508.979003, -3186.312500, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 4431.479492, -3186.312500, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4431.479492, -3147.562744, 1.319700, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4578.979492, -3147.562500, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4508.979003, -3147.562500, 1.323698, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 4508.979003, -3108.812988, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 4431.479492, -3108.812988, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4431.479492, -3070.063232, 1.323698, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19534, 4508.979003, -3070.063232, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 4470.229492, -3070.063232, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 4648.979980, -3108.812988, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4431.479492, -3000.063232, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4578.979492, -3070.063232, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4648.979980, -3070.063232, 1.323698, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4431.479492, -2930.063232, 1.323698, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 4470.229492, -2930.063232, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4431.479492, -2860.063232, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4431.479492, -2790.063476, 1.323698, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 4470.229492, -2790.063476, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4431.479492, -2790.063476, 1.319700, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4508.979003, -2860.063232, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4508.979003, -2790.063476, 1.323698, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 4547.728515, -2790.063476, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4586.478515, -2790.063476, 1.323698, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4586.478515, -2860.063232, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 4625.228515, -2790.063476, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4663.978515, -2790.063476, 1.319700, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4663.978515, -2790.063476, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4663.978515, -2860.063232, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4663.978515, -2930.063232, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4663.978515, -2930.063232, 1.319700, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 4625.228515, -2930.063232, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4586.478515, -2930.063232, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 4547.728515, -2930.063232, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19534, 4508.979003, -2930.063232, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4508.979003, -3000.063232, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 4788.979003, -2953.813476, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4788.979003, -2915.063476, 1.323698, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4788.979003, -2915.063476, 1.319700, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4858.979003, -2915.063476, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19534, 4928.978515, -2915.063476, 1.323698, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 4928.978515, -2953.813476, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4998.978027, -2915.063476, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19534, 4928.978515, -2992.563476, 1.323698, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 4967.728515, -2992.563476, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 5006.478515, -2992.563476, 1.323698, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 4928.978515, -3031.313232, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4928.978515, -3070.062988, 1.323698, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 4967.728515, -3070.062988, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19534, 5006.478515, -3070.062988, 1.323698, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 5006.478515, -3031.313232, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 4928.978515, -3108.813232, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4928.978515, -3147.563232, 1.323698, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 4967.728515, -3147.563232, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19534, 5006.478515, -3147.563232, 1.323698, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 5006.478515, -3108.813232, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 4928.000000, 9785.000000, -3186.000000, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4928.978515, -3225.062500, 1.323698, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 4928.978515, -3263.812500, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19534, 4928.978515, -3302.562500, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 4967.728515, -3225.062500, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 5076.478027, -3225.062500, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 5076.478027, -3147.563232, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 5076.478027, -3070.062988, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 5076.478027, -2992.563476, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 4967.728515, -3302.562500, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19538, 4998.978027, -3263.812500, 1.515498, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4788.979003, -3512.562255, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19552, 4858.979003, -3512.562255, 1.515498, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4928.978515, -3372.562500, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19534, 4928.978515, -3442.562500, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 5006.478515, -3302.562500, 1.323698, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19538, 4967.728515, -3372.562500, 1.515498, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 5006.478515, -3372.562500, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 4967.728515, -3442.562500, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19534, 5006.478515, -3442.562500, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4928.978515, -3512.562255, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19538, 4967.728515, -3512.562255, 1.515498, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 5006.478515, -3512.562255, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 5076.478027, -3302.562500, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 5068.978027, -2915.063476, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 5107.728027, -2915.063476, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 5068.978027, -2876.313476, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 5068.978027, -2837.563720, 1.323698, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 5107.728027, -2837.563720, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 5068.978027, -2837.563720, 1.319700, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 5146.477539, -2837.563720, 1.323698, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 5146.477539, -2876.313476, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19534, 5146.477539, -2915.063476, 1.323698, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 5146.477539, -2953.813476, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 5185.227050, -2915.063476, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 5185.227050, -2837.563720, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 5223.977050, -2837.563720, 1.323698, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 5223.977050, -2876.313476, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 5223.977050, -2837.563720, 1.319700, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 5223.977050, -2915.063476, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 5146.477539, -3031.313232, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19534, 5146.477539, -2992.563476, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 5185.227050, -2992.563476, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 5223.977050, -2992.563476, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 5223.977050, -2953.813476, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 5223.977050, -2992.563476, 1.319700, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 5146.477539, -3070.062988, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 5146.477539, -3108.813232, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 5146.477539, -3147.563232, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 4928.978515, -3186.312500, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 5006.478515, -3186.312500, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 5006.478515, -3225.062500, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 5146.477539, -3186.312500, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 5146.477539, -3225.062500, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 5146.477539, -3263.812500, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 5146.477539, -3302.562500, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19552, 5076.478027, -3372.562500, 1.515498, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 5146.477539, -3372.562500, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19538, 5076.478027, -3263.812500, 1.509500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 5076.478027, -3442.562500, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19534, 5146.477539, -3442.562500, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 5216.477050, -3442.562500, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 5286.477050, -3442.562500, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 5286.477050, -3403.812744, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 5286.477050, -3442.562500, 1.319700, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19545, 5325.225585, -3427.562988, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19545, 5325.225585, -3412.563720, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19545, 5325.225585, -3397.563720, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19545, 5325.225585, -3382.562255, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 5146.477539, -3481.312744, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 5146.477539, -3520.062500, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 5107.727539, -3520.062500, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19538, 5076.478027, -3481.312744, 1.515498, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 5068.978027, -3520.062500, 1.323698, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 5068.978027, -3558.812255, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 5068.978027, -3520.062500, 1.319700, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 5146.477539, -3558.812255, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 5068.978027, -3597.562011, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 5107.727539, -3597.562011, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19534, 5146.477539, -3597.562011, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 5216.477050, -3597.562011, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 5286.477050, -3367.508300, 1.329699, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 5006.478515, -3582.562011, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4998.978027, -3597.562011, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19534, 4928.978515, -3582.562011, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 4967.728515, -3582.562011, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4858.979003, -3582.562011, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4858.979003, -3597.562011, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 5006.478515, -3582.562011, 1.319700, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19534, 4928.978515, -3597.562011, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19534, 4788.979003, -3582.562011, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19534, 4788.979003, -3597.562011, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4718.979492, -3582.562011, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4718.979492, -3597.562011, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19534, 4648.979980, -3582.562011, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19534, 4648.979980, -3597.562011, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(18802, 5146.477539, -3615.059814, 3.040298, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18804, 5146.477539, -3700.055175, 5.132500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18802, 4648.979980, -3615.059814, 3.040298, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18804, 4648.979980, -3700.055175, 5.132500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 4928.978515, -3636.311767, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4928.978515, -3675.061523, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4928.978515, -3675.061523, 1.319700, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4858.979003, -3675.061523, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4788.979003, -3675.061523, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 4788.979003, -3636.311767, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4788.979003, -3675.061523, 1.319700, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19538, 4858.979003, -3636.311767, 1.515498, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 17562, "coast_apts", "otb_floor1", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4578.979492, -3582.562011, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4578.979492, -3597.562011, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19534, 4508.979003, -3597.562011, 1.323698, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(18802, 5288.977539, -3597.562011, 3.040298, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18802, 5146.477539, -3785.058837, 3.040298, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18802, 4648.979980, -3785.058837, 3.040298, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18804, 5373.981933, -3597.562011, 5.132500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18802, 5458.978027, -3597.562011, 3.040298, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 5531.479003, -3597.562011, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 5601.478515, -3636.312011, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19534, 5601.478515, -3597.562011, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 5601.478515, -3558.812255, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19545, 5601.478515, -3698.811767, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19545, 5131.478027, -3558.812255, 1.515498, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19545, 5116.478515, -3558.812255, 1.515498, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19545, 5101.479003, -3558.812255, 1.515498, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19545, 5089.585937, -3558.812255, 1.511500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19545, 5083.948730, -3558.812255, 1.515498, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19534, 5146.477539, -3802.559326, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 4687.729980, -3802.559326, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4726.479492, -3802.559326, 1.323698, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4796.479492, -3802.559326, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4866.479492, -3802.559326, 1.323698, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4936.479003, -3802.559326, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 5006.479003, -3802.559326, 1.323698, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 5076.479003, -3802.559326, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 5216.477050, -3802.559326, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 5146.477539, -3872.559082, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 5006.479003, -3872.559082, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4866.479492, -3872.559082, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 5286.477050, -3802.559326, 1.323698, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 5286.477050, -3872.559082, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 4368.980957, -3636.311767, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19534, 4368.980957, -3675.061523, 1.323698, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 4368.980957, -3713.811279, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4438.980468, -3675.061523, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4438.980468, -3752.561279, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 4470.229003, -3597.562011, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 4407.729492, -3597.562011, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4368.980957, -3597.562011, 1.325700, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 4508.979003, -3636.311767, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4508.979003, -3675.061523, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 4508.979003, -3713.811279, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4508.979003, -3752.561279, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4368.980957, -3752.561279, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4508.979003, -3752.561279, 1.319700, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4298.980957, -3752.561279, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4298.980957, -3675.061523, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4228.980957, -3752.561279, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 4228.980957, -3713.811279, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4228.980957, -3675.061523, 1.323698, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4228.980957, -3675.061523, 1.319700, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4228.980957, -3752.561279, 1.319700, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19552, 5216.477050, -3872.559082, 1.515498, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19552, 5076.479003, -3872.559082, 1.515498, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 3653, "beachapts_lax", "eastwall4_LAe2", 0x00000000);
	tmpobjid = CreateDynamicObject(19552, 4936.479003, -3872.559082, 1.515498, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19552, 4796.479492, -3872.559082, 1.515498, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4648.979980, -3802.559326, 1.323698, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4726.479492, -3872.559082, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4648.979980, -3872.559082, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19538, 4687.729980, -3872.559082, 1.515498, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19534, 4648.979980, -3942.559082, 1.323698, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 4687.729980, -3942.559082, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19534, 4726.479492, -3942.559082, 1.323698, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 4726.479492, -3981.309082, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 4648.979980, -3981.309082, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19534, 4726.479492, -4020.059082, 1.323698, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 4687.729980, -4020.059082, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19534, 4648.979980, -4020.059082, 1.323698, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4578.979980, -3942.559082, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19538, 4578.979980, -3981.309082, 1.515498, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4578.979980, -4020.059082, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4508.980468, -3942.559082, 1.323698, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 4508.980468, -3981.309082, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4508.980468, -4020.059082, 1.323698, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4508.980468, -3942.559082, 1.319700, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 4648.979980, -4058.809082, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19538, 4578.979980, -4058.809082, 1.515498, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 4508.980468, -4058.809082, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4508.980468, -4097.558593, 1.323698, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4578.979980, -4097.558593, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19534, 4648.979980, -4097.558593, 1.323698, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 4687.729980, -4097.558593, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4726.479492, -4097.558593, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 4726.479492, -4058.809082, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4796.479492, -3942.559082, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19534, 4866.479492, -3942.559082, 1.323698, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 4866.479492, -3981.309082, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19534, 4866.479492, -4020.059082, 1.323698, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4796.479492, -4020.059082, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 4866.479492, -4058.809082, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19534, 4866.479492, -4097.558593, 1.323698, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4796.479492, -4097.558593, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19538, 4796.479492, -3981.309082, 1.515498, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19538, 4796.479492, -4058.809082, 1.515498, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4936.479003, -3942.559082, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19534, 5006.479003, -3942.559082, 1.323698, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 5006.479003, -3981.309082, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19534, 5006.479003, -4020.059082, 1.323698, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 5006.479003, -4058.809082, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4936.479003, -4020.059082, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 5006.479003, -4097.558593, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4936.479003, -4097.558593, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19538, 4936.479003, -3981.309082, 1.515498, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19538, 4936.479003, -4058.809082, 1.515498, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 4648.979980, -4136.308105, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19534, 4648.979980, -4175.058105, 1.323698, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4578.979980, -4175.058105, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19534, 4508.980468, -4175.058105, 1.323698, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 4508.980468, -4136.308105, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19538, 4578.979980, -4136.308105, 1.515498, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 4648.979980, -4213.808105, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19552, 4578.992675, -4245.042480, 1.515498, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4508.980468, -4245.058105, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4718.979492, -4175.058105, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4788.978515, -4175.058105, 1.323698, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4788.978515, -4245.058105, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 4827.728515, -4175.058105, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4866.479492, -4175.058105, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 4866.479492, -4136.308105, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4866.479492, -4245.058105, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19534, 5286.477050, -3942.559082, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 5216.477050, -3942.559082, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19534, 5146.477539, -3942.559082, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 5076.479003, -3942.559082, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 5076.479003, -4020.059082, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 5146.477539, -3981.309082, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 5146.477539, -4020.059082, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19545, 5107.728027, -4097.558593, 1.515498, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 5146.477539, -4097.558593, 1.323698, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 5146.477539, -4058.809082, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19538, 5076.479003, -3981.309082, 1.515498, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19538, 5076.479003, -4058.809082, 1.515498, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19552, 5216.477050, -4012.559082, 1.515498, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 5286.477050, -4012.559082, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 5216.477050, -4097.558593, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19534, 5286.477050, -4097.558593, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 5286.477050, -4082.559082, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 5286.477050, -4082.559082, 1.319700, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19545, 5185.227050, -4082.558349, 1.515498, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19545, 5247.726562, -4082.558349, 1.515498, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 5325.226562, -4097.558593, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 5363.976562, -4097.558593, 1.323698, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 5363.976562, -4167.558105, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 5402.727050, -4097.558593, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 5441.477050, -4097.558593, 1.323698, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 5441.477050, -4097.558593, 1.319700, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 5441.477050, -4167.558105, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 5441.477050, -4237.558105, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 5402.727050, -4237.558105, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19534, 5363.976562, -4237.558105, 1.323698, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 5441.477050, -4307.557617, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 5441.477050, -4377.557128, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 5402.727050, -4377.557128, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19534, 5363.976562, -4377.557128, 1.323698, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 5363.976562, -4307.557617, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 5325.226562, -4377.557128, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 5286.477050, -4307.557617, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19534, 5286.477050, -4237.558105, 1.323698, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 5286.477050, -4167.558105, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 5286.477050, -4377.557128, 1.323698, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 5325.226562, -4237.558105, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19552, 5216.477050, -4167.558105, 1.515498, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19538, 5325.226562, -4167.558105, 1.515498, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19538, 5325.226562, -4307.557617, 1.515498, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 5216.477050, -4237.558105, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 5146.477539, -4167.558105, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19534, 5146.477539, -4237.558105, 1.323698, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19552, 5076.479003, -4167.558105, 1.515498, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 5006.479003, -4167.558105, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19552, 4936.479003, -4167.558105, 1.515498, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 5076.479003, -4237.558105, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19534, 5006.479003, -4237.558105, 1.323698, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19552, 4718.979492, -4245.058105, 1.515498, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19538, 4796.479492, -4136.308105, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19545, 4726.479492, -4136.308105, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19545, 4711.479492, -4136.308105, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19545, 4696.479492, -4136.308105, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19545, 4681.479492, -4136.308105, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19545, 4666.479980, -4136.308105, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19545, 4663.971679, -4136.308105, 1.331500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19545, 4711.479492, -4058.809082, 1.515498, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19545, 4696.479492, -4058.809082, 1.515498, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19545, 4681.479492, -4058.809082, 1.515498, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19545, 4668.131835, -4058.809082, 1.511500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19545, 4663.971679, -4058.809082, 1.515498, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19545, 4711.479492, -3981.309082, 1.515498, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19545, 4696.479492, -3981.309082, 1.515498, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19545, 4681.479492, -3981.309082, 1.515498, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19545, 4668.419921, -3981.309082, 1.511500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19545, 4663.971679, -3981.309082, 1.515498, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19538, 4827.728515, -4245.058105, 1.515498, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19538, 4936.479003, -4261.307128, 1.515498, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 5006.479003, -4237.558105, 1.319700, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 5006.479003, -4276.308105, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19545, 4905.229492, -4300.058105, 1.515498, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19545, 4967.729003, -4300.058105, 1.515498, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19534, 5006.479003, -4315.058105, 1.323698, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4936.479003, -4315.058105, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19538, 5076.479003, -4276.308105, 1.515498, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 5076.479003, -4315.058105, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 5146.477539, -4276.308105, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 5146.477539, -4315.058105, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 5286.477050, -4447.556640, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19538, 5325.226562, -4447.556640, 1.515498, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 5363.976562, -4447.556640, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 5441.477050, -4447.556640, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4866.479492, -4315.058105, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 4827.728515, -4315.058105, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4788.978515, -4315.058105, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4718.979492, -4315.058105, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19534, 4648.979980, -4315.058105, 1.323698, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4578.979980, -4315.058105, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4508.980468, -4315.058105, 1.323698, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19534, 5286.477050, -4517.556640, 1.323698, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 5216.477050, -4517.556640, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 5325.226562, -4517.556640, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19534, 5363.976562, -4517.556640, 1.323698, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 5402.727050, -4517.556640, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 5441.477050, -4517.556640, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19534, 5146.477539, -4517.556640, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 5146.477539, -4447.556640, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 5146.477539, -4353.808105, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 5441.477050, -4556.306640, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 5441.477050, -4595.056640, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 5441.477050, -4595.056640, 1.319700, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 5402.727050, -4595.056640, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 5363.976562, -4595.056640, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 5325.226562, -4595.056640, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 5286.477050, -4595.056640, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 5216.477050, -4595.056640, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 5363.976562, -4556.306640, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 5286.477050, -4556.306640, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 5146.477539, -4556.306640, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 5146.477539, -4595.056640, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 5076.479003, -4517.556640, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 5006.479003, -4517.556640, 1.323698, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19538, 5076.479003, -4353.808105, 1.515498, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19552, 5076.479003, -4447.556640, 1.515498, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 5006.479003, -4447.556640, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 5006.479003, -4353.808105, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 5076.479003, -4595.056640, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 5006.479003, -4595.056640, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 5006.479003, -4556.306640, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 4648.979980, -4353.808105, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 4508.980468, -4353.808105, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4648.979980, -4392.557617, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4578.979980, -4392.557617, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4508.980468, -4392.557617, 1.323698, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4508.980468, -4462.557617, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4648.979980, -4462.557617, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4578.979980, -4532.557128, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4648.979980, -4532.557128, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4648.979980, -4532.557128, 1.319700, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4508.980468, -4532.557128, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 4470.230957, -4175.058105, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4431.481445, -4245.058105, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4431.481445, -4175.058105, 1.323698, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4431.481445, -4315.058105, 1.323698, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 4431.481445, -4353.808105, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4431.481445, -4392.557617, 1.323698, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4431.481445, -4462.557617, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4431.481445, -4532.557128, 1.323698, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 4470.230957, -4532.557128, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4431.481445, -4315.058105, 1.319700, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4431.481445, -4392.557617, 1.319700, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19538, 4578.979980, -4353.808105, 1.515498, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19552, 4578.979980, -4462.557617, 1.515498, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19538, 4470.230957, -4245.058105, 1.515498, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19538, 4470.230957, -4462.557617, 1.515498, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19538, 4470.230957, -4353.808105, 1.509500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 5006.479003, -4595.056640, 1.319700, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4431.481445, -4602.557128, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(18802, 4431.481445, -4675.057128, 3.040298, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 4431.481445, -4760.054199, 5.131800, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 4431.481445, -4910.052734, 5.131800, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 4431.481445, -5060.052246, 5.131800, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 4431.481445, -5210.051757, 5.131800, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 4431.481445, -5360.051757, 5.131800, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 4431.481445, -5510.052246, 5.131800, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 4431.481445, -5660.051269, 5.131800, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18791, 4423.727539, -5774.032226, 5.131800, 0.000000, 0.000000, 67.500000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18791, 4368.603515, -5829.155761, 5.131800, 0.000000, 0.000000, 22.500000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 4254.625488, -5836.909667, 5.131800, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 4104.625488, -5836.909667, 5.131800, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18789, 3954.625732, -5836.909667, 5.131800, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(19552, 3817.122802, -5836.909667, 5.477700, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19552, 3692.125488, -5836.909667, 5.477700, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19552, 3817.122802, -5899.408203, -57.021499, 90.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 19467, "speed_bumps", "vehicle_barrier01", 0x00000000);
	tmpobjid = CreateDynamicObject(19552, 3692.125488, -5899.408203, -57.021499, 90.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 19467, "speed_bumps", "vehicle_barrier01", 0x00000000);
	tmpobjid = CreateDynamicObject(19552, 3629.626953, -5836.909667, -57.021499, 90.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 19467, "speed_bumps", "vehicle_barrier01", 0x00000000);
	tmpobjid = CreateDynamicObject(19552, 3692.125488, -5774.412109, -57.021499, 90.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 19467, "speed_bumps", "vehicle_barrier01", 0x00000000);
	tmpobjid = CreateDynamicObject(19552, 3817.122802, -5774.412109, -57.021499, 90.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 19467, "speed_bumps", "vehicle_barrier01", 0x00000000);
	tmpobjid = CreateDynamicObject(19552, 3879.617187, -5836.909667, -57.021499, 90.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 19467, "speed_bumps", "vehicle_barrier01", 0x00000000);
	tmpobjid = CreateDynamicObject(3331, 837.094726, -2762.019287, 21.506900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 16644, "a51_detailstuff", "a51_secdesk", 0x00000000);
	tmpobjid = CreateDynamicObject(3330, 4852.541015, -2536.990234, -1.313899, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall01", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4361.481445, -4175.058105, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(18802, 4288.981445, -4175.058105, 3.040298, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18804, 4203.985839, -4175.058105, 5.132500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(18802, 4118.981445, -4175.058105, 3.040298, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4046.482910, -4175.058105, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19534, 3976.482910, -4175.058105, 1.323698, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 3976.482910, -4136.308105, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 3976.482910, -4097.558105, 1.323698, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 3976.482910, -4097.558105, 1.319700, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 3906.483154, -4097.558105, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 3836.483398, -4097.558105, 1.323698, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 3836.483398, -4136.308105, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 3836.483398, -4097.558105, 1.319700, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 3836.483398, -4175.058105, 1.323698, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19545, 3937.733154, -4175.058105, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 3976.482910, -4245.058105, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 3836.483398, -4245.058105, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 3836.483398, -4315.058105, 1.323698, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 3906.483154, -4315.058105, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 3976.482910, -4315.058105, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 3976.482910, -4315.058105, 1.319700, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 3836.483398, -4315.058105, 1.319700, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19538, 3906.483154, -4136.308105, 1.335500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19552, 3906.483154, -4245.058105, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19545, 3875.233154, -4175.058105, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 3836.483398, -4175.058105, 1.319700, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4431.479492, -3147.562744, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(10378, 4858.979003, -3636.311767, 1.469480, 0.059999, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 4833, "airprtrunway_las", "policeha02black_128", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 15041, "bigsfsave", "AH_grepaper2", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 15041, "bigsfsave", "AH_grepaper2", 0x00000000);
	tmpobjid = CreateDynamicObject(4690, 4964.057128, -3487.514160, 9.790960, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 4, 4552, "ammu_lan2", "sl_dtbuild02win1", 0x00000000);
	tmpobjid = CreateDynamicObject(19545, 5045.228027, -4097.558593, 1.515498, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(8420, 4619.494628, -4269.056152, 1.542700, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(9062, 4696.993652, -4269.056152, 1.542700, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(13361, 5037.934082, -3576.472900, 8.396300, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 8, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 10, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	tmpobjid = CreateDynamicObject(19545, 5021.479003, -3543.811767, 1.515498, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19545, 5036.477539, -3543.811767, 1.515498, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19545, 5051.476562, -3543.811767, 1.515498, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19545, 5053.997558, -3543.811767, 1.509500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(8079, 5109.582031, -3881.166992, 14.806838, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 2, 18063, "ab_sfammuitems02", "gun_xtra1", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 8, 7009, "vgndwntwn1", "vgnbankbld5_256", 0x00000000);
	tmpobjid = CreateDynamicObject(4016, 4839.983886, -3512.688232, 6.497098, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 8480, "csrspalace01", "ceaserwindow01_128", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 8480, "csrspalace01", "ceasersledge04_128", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 3, 4552, "ammu_lan2", "sl_dtrufrear2wall1", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 4552, "ammu_lan2", "sl_dtrufrear2wall1", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 5, 4552, "ammu_lan2", "dior", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 6, 8480, "csrspalace01", "ceaserwindow01_128", 0x00000000);
	tmpobjid = CreateDynamicObject(8419, 5218.025390, -4137.590332, 13.230298, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 14652, "ab_trukstpa", "bbar_door1", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10101, "2notherbuildsfe", "sl_vicwin02", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 3, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 6, 14652, "ab_trukstpa", "barberswindo", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 9, 14581, "ab_mafiasuitea", "barbersmir1", 0x00000000);
	tmpobjid = CreateDynamicObject(10388, 5122.579101, -3271.219726, 7.462830, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 14415, "carter_block_2", "ws_doormat", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicbrikwall01", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10101, "2notherbuildsfe", "sl_vicbrikwall01", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 3, 4833, "airprtrunway_las", "dockwall1", 0x00000000);
	tmpobjid = CreateDynamicObject(10377, 4578.802246, -3258.659667, 19.583200, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 6, 14629, "ab_chande", "ab_goldpipe", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 7, 14629, "ab_chande", "ab_goldpipe", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 8, 14629, "ab_chande", "ab_goldpipe", 0x00000000);
	tmpobjid = CreateDynamicObject(3499, 4578.750000, -3253.491455, 51.119548, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 14629, "ab_chande", "ab_goldpipe", 0x00000000);
	tmpobjid = CreateDynamicObject(5716, 4706.884277, -4063.167236, 14.859100, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 7650, "vgnusedcar", "marinadoor2_256", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "Bow_Abpave_Gen", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 19332, "balloon_texts", "balloon01", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 3, 19332, "balloon_texts", "balloon01", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 4, 19332, "balloon_texts", "balloon02", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 6, 19332, "balloon_texts", "balloon02", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 7, 19332, "balloon_texts", "balloon02", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 8, 7650, "vgnusedcar", "marinadoor2_256", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 9, 19332, "balloon_texts", "balloon01", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 10, 19332, "balloon_texts", "balloon02", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 11, 19332, "balloon_texts", "balloon02", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 12, 19332, "balloon_texts", "balloon02", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 13, 19332, "balloon_texts", "balloon01", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 14, 19332, "balloon_texts", "balloon01", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 15, 19332, "balloon_texts", "balloon02", 0x00000000);
	tmpobjid = CreateDynamicObject(3499, 4578.750000, -3253.491455, 50.331230, 0.000000, 90.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 16640, "a51", "concreteyellow256 copy", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 14629, "ab_chande", "ab_goldpipe", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4585.563476, -3442.562011, 1.325700, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 5325.226562, -3942.559082, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 5363.976562, -3942.559082, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 5363.976562, -3872.559082, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 5325.226562, -3802.559326, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 5363.976562, -3802.559326, 1.323698, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19538, 5325.226562, -3872.559082, 1.515498, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19552, 5433.977050, -3872.559082, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 5363.976562, -3802.559326, 1.319700, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 5363.976562, -3942.559082, 1.319700, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19545, 5402.726074, -3942.559082, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19545, 5465.225585, -3942.559082, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19545, 5402.726074, -3802.559326, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19545, 5465.225585, -3802.559326, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4928.978515, -2845.063720, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4928.978515, -2720.063720, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4928.978515, -2650.063720, 1.323698, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19532, 4998.978027, -2650.063720, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4928.978515, -2650.063720, 1.319700, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 4470.229492, -3302.562500, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4431.479492, -3302.562500, 1.319700, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 4392.729980, -3225.062011, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4353.979980, -3225.062011, 1.323698, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 4353.979980, -3263.812500, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19533, 4392.729980, -3302.562500, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4353.979980, -3302.562500, 1.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4353.979980, -3302.562500, 1.319700, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4353.979980, -3225.062011, 1.319700, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19538, 4438.979492, -3263.812500, 1.515498, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19535, 4431.479492, -3302.562500, 1.323698, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10756, "airportroads_sfse", "sf_junction5", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(19545, 4368.979980, -3263.812500, 1.515498, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 10765, "airportgnd_sfse", "ws_runwaytarmac", 0x00000000);
	tmpobjid = CreateDynamicObject(6866, 4953.305664, -4254.542968, 13.080100, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 2, 10850, "bakerybit2_sfse", "frate64_yellow", 0x00000000);
	tmpobjid = CreateDynamicObject(18762, 823.186096, -1937.785644, 22.493799, 0.000000, 90.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(18770, 819.685791, -1937.785644, -72.005546, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(18770, 853.374023, -1937.741333, -72.005500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(18766, 825.686279, -1937.785644, 25.493999, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(18766, 847.375610, -1937.785644, 25.493999, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(18766, 836.476501, -1937.785644, 25.493999, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(18762, 828.186096, -1937.785644, 22.493799, 0.000000, 90.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(18762, 833.186096, -1937.785644, 22.493799, 0.000000, 90.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(18762, 838.185119, -1937.785644, 22.493799, 0.000000, 90.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(18762, 843.185119, -1937.785644, 22.493799, 0.000000, 90.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(18762, 848.185119, -1937.785644, 22.493799, 0.000000, 90.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(18762, 851.860107, -1937.789550, 22.493799, 0.000000, 90.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(18770, 836.456481, -1938.025634, -83.151100, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(18766, 836.456481, -1932.026245, 14.348600, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 16640, "a51", "airvent_gz", 0x00000000);
	tmpobjid = CreateDynamicObject(18766, 836.456481, -1922.026489, 14.348600, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 16640, "a51", "airvent_gz", 0x00000000);
	tmpobjid = CreateDynamicObject(18766, 836.456481, -1912.025146, 14.348600, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 16640, "a51", "airvent_gz", 0x00000000);
	tmpobjid = CreateDynamicObject(18766, 836.456481, -1902.025756, 14.348600, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 16640, "a51", "airvent_gz", 0x00000000);
	tmpobjid = CreateDynamicObject(18766, 836.456481, -1892.027343, 14.348600, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 16640, "a51", "airvent_gz", 0x00000000);
	tmpobjid = CreateDynamicObject(18766, 836.456481, -1882.026855, 14.348600, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 16640, "a51", "airvent_gz", 0x00000000);
	tmpobjid = CreateDynamicObject(18766, 836.456481, -1872.027221, 14.348600, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 16640, "a51", "airvent_gz", 0x00000000);
	tmpobjid = CreateDynamicObject(18766, 836.456481, -1862.028442, 14.348600, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 16640, "a51", "airvent_gz", 0x00000000);
	tmpobjid = CreateDynamicObject(18766, 836.456481, -1852.028686, 14.348600, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 16640, "a51", "airvent_gz", 0x00000000);
	tmpobjid = CreateDynamicObject(18766, 852.879882, -1932.026245, 14.348600, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 16640, "a51", "airvent_gz", 0x00000000);
	tmpobjid = CreateDynamicObject(18766, 852.879882, -1922.026489, 14.348600, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 16640, "a51", "airvent_gz", 0x00000000);
	tmpobjid = CreateDynamicObject(18766, 852.879882, -1912.025146, 14.348600, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 16640, "a51", "airvent_gz", 0x00000000);
	tmpobjid = CreateDynamicObject(18766, 852.879882, -1902.025756, 14.348600, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 16640, "a51", "airvent_gz", 0x00000000);
	tmpobjid = CreateDynamicObject(18766, 852.879882, -1892.027343, 14.348600, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 16640, "a51", "airvent_gz", 0x00000000);
	tmpobjid = CreateDynamicObject(18766, 852.879882, -1882.026855, 14.348600, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 16640, "a51", "airvent_gz", 0x00000000);
	tmpobjid = CreateDynamicObject(18766, 852.879882, -1872.027221, 14.348600, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 16640, "a51", "airvent_gz", 0x00000000);
	tmpobjid = CreateDynamicObject(18766, 852.879882, -1862.028442, 14.348600, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 16640, "a51", "airvent_gz", 0x00000000);
	tmpobjid = CreateDynamicObject(18766, 852.879882, -1852.028686, 14.348600, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 16640, "a51", "airvent_gz", 0x00000000);
	tmpobjid = CreateDynamicObject(18766, 820.179321, -1932.026245, 14.348600, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 16640, "a51", "airvent_gz", 0x00000000);
	tmpobjid = CreateDynamicObject(18766, 820.179321, -1922.026489, 14.348600, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 16640, "a51", "airvent_gz", 0x00000000);
	tmpobjid = CreateDynamicObject(18766, 820.179321, -1912.025146, 14.348600, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 16640, "a51", "airvent_gz", 0x00000000);
	tmpobjid = CreateDynamicObject(18766, 820.179321, -1902.025756, 14.348600, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 16640, "a51", "airvent_gz", 0x00000000);
	tmpobjid = CreateDynamicObject(18766, 820.179321, -1892.027343, 14.348600, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 16640, "a51", "airvent_gz", 0x00000000);
	tmpobjid = CreateDynamicObject(18766, 820.179321, -1882.026855, 14.348600, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 16640, "a51", "airvent_gz", 0x00000000);
	tmpobjid = CreateDynamicObject(18766, 820.179321, -1872.027221, 14.348600, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 16640, "a51", "airvent_gz", 0x00000000);
	tmpobjid = CreateDynamicObject(18766, 820.179321, -1862.028442, 14.348600, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 16640, "a51", "airvent_gz", 0x00000000);
	tmpobjid = CreateDynamicObject(18766, 820.179321, -1852.028686, 14.348600, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 16640, "a51", "airvent_gz", 0x00000000);
	tmpobjid = CreateDynamicObject(18770, 819.685791, -1847.989379, -83.149398, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 3, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(18770, 853.377197, -1847.989379, -83.149398, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(18770, 836.456481, -1847.989379, -83.149398, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(967, 821.755615, -1847.928955, 11.782198, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 16093, "a51_ext", "corugwall_sandy", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 16093, "a51_ext", "corugwall_sandy", 0x00000000);
	tmpobjid = CreateDynamicObject(967, 851.466796, -1848.086791, 11.782198, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 16093, "a51_ext", "corugwall_sandy", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 16093, "a51_ext", "corugwall_sandy", 0x00000000);
	tmpobjid = CreateDynamicObject(967, 5355.675292, -3886.810791, 1.509449, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 14668, "711c", "CJ_CHIP_M2", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 14668, "711c", "CJ_CHIP_M2", 0x00000000);
	tmpobjid = CreateDynamicObject(7911, 836.640747, -1937.678344, 26.217237, 0.000000, 0.000000, -179.900009, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "ALBION", 120, "Arial Black", 90, 0, 0xFFFFFFFF, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(7911, 836.520751, -1937.708374, 26.137235, 0.000000, 0.000000, -179.900009, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "ALBION", 120, "Arial Black", 90, 0, 0xFF000000, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(7911, 825.642089, -1937.616333, 25.107227, 0.000000, 0.000000, -179.900009, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "WELCOME", 120, "Comic Sans MS", 80, 0, 0xFF999900, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(7911, 847.472534, -1937.709106, 25.107227, 0.000000, 0.000000, -179.900009, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "WELCOME", 120, "Comic Sans MS", 80, 0, 0xFF000000, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(7911, 847.552734, -1937.679077, 25.197229, 0.000000, 0.000000, -179.900009, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "WELCOME", 120, "Comic Sans MS", 80, 0, 0xFF999900, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(7911, 825.582397, -1937.706420, 25.007225, 0.000000, 0.000000, -179.900009, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "WELCOME", 120, "Comic Sans MS", 80, 0, 0xFF000000, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(7911, 836.520751, -1937.708374, 23.807233, 0.000000, 0.000000, -179.900009, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "CITY", 120, "Arial Black", 70, 0, 0xFF000000, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(7911, 836.610961, -1937.638305, 23.837234, 0.000000, 0.000000, -179.900009, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "CITY", 120, "Arial Black", 70, 0, 0xFFFFFFFF, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(7911, 836.358581, -1937.881103, 25.427223, 0.000000, 0.000000, 0.000007, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "Los Santos", 120, "Arial Black", 65, 0, 0xFF000000, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(7911, 836.298522, -1937.971191, 25.497224, 0.000000, 0.000000, 0.000007, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "Los Santos", 120, "Arial Black", 65, 0, 0xFFFFFFFF, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(7911, 825.508422, -1937.861206, 25.227218, 0.000000, 0.000000, 0.000007, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "WELCOME", 120, "Arial Black", 60, 0, 0xFF000000, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(7911, 825.428344, -1937.941284, 25.277219, 0.000000, 0.000000, 0.000007, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "WELCOME", 120, "Arial Black", 60, 0, 0xFFFFFFFF, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(7911, 847.418823, -1937.861206, 25.277219, 0.000000, 0.000000, 0.000007, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "WELCOME", 120, "Arial Black", 60, 0, 0xFF000000, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(7911, 847.318725, -1937.931274, 25.357221, 0.000000, 0.000000, 0.000007, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "WELCOME", 120, "Arial Black", 60, 0, 0xFFFFFFFF, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 4879.340820, -3508.573486, 12.029880, -10.699997, 0.000000, -179.399978, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10850, "bakerybit2_sfse", "frate64_yellow", 0x00000000);
	SetDynamicObjectMaterialText(tmpobjid, 0, "HALL", 120, "Monotype Corsiva", 100, 0, 0xFF000000, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 4879.272460, -3512.384033, 14.376803, 0.000000, 0.000000, -179.399978, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10850, "bakerybit2_sfse", "frate64_yellow", 0x00000000);
	SetDynamicObjectMaterialText(tmpobjid, 0, "ALBION", 80, "Impact", 100, 0, 0xFF601010, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 4879.320312, -3516.747070, 11.759683, -8.600003, 0.000000, -179.399978, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10850, "bakerybit2_sfse", "frate64_yellow", 0x00000000);
	SetDynamicObjectMaterialText(tmpobjid, 0, "CITY", 120, "Monotype Corsiva", 100, 0, 0xFF000000, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 4879.115722, -3512.334228, 14.376803, 0.000000, 0.000000, -179.399978, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10850, "bakerybit2_sfse", "frate64_yellow", 0x00000000);
	SetDynamicObjectMaterialText(tmpobjid, 0, "ALBION", 80, "Impact", 100, 0, 0xFF000000, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 4879.413574, -3516.802978, 11.750712, -8.600003, 0.000000, -179.399978, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10765, "airportgnd_sfse", "white", 0x00000000);
	SetDynamicObjectMaterialText(tmpobjid, 0, "CITY", 120, "Monotype Corsiva", 100, 0, 0xFFFFFFFF, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 4879.414550, -3508.604980, 12.024311, -10.699997, 0.000000, -179.399978, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10850, "bakerybit2_sfse", "frate64_yellow", 0x00000000);
	SetDynamicObjectMaterialText(tmpobjid, 0, "HALL", 120, "Monotype Corsiva", 100, 0, 0xFFFFFFFF, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 4700.258300, -4058.137207, 10.425497, 0.000000, 0.000000, 0.599999, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "WILD", 120, "Fixedsys", 100, 0, 0xFFFFFFFF, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 5325.409667, -3915.012939, 12.592073, 0.000000, 0.000000, -89.000068, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "DRIVING SCHOOL", 110, "Century Gothic", 45, 1, 0xFF000000, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 5325.447753, -3914.974365, 12.632074, 0.000000, 0.000000, -89.000068, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "DRIVING SCHOOL", 110, "Century Gothic", 45, 1, 0xFF202020, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 5109.553222, -3829.627441, 7.443684, 0.000000, 0.000000, -89.399932, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "ALBION MEDICAL CENTER", 120, "Impact", 60, 1, 0xFFFFFFFF, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 5109.553222, -3829.547363, 7.443684, 0.000000, 0.000000, -89.399932, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10765, "airportgnd_sfse", "white", 0x00000000);
	SetDynamicObjectMaterialText(tmpobjid, 0, "ALBION MEDICAL CENTER", 120, "Impact", 60, 1, 0xFF990000, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(18762, 5120.578613, -3830.062988, 2.942188, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 3653, "beachapts_lax", "eastwall4_LAe2", 0x00000000);
	tmpobjid = CreateDynamicObject(18762, 5098.579589, -3830.062988, 2.942189, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 3653, "beachapts_lax", "eastwall4_LAe2", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 3653, "beachapts_lax", "eastwall4_LAe2", 0x00000000);
	tmpobjid = CreateDynamicObject(4735, 5134.775390, -3897.059814, 13.333647, 0.000000, 0.000000, -179.400039, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "+", 80, "Impact", 80, 1, 0xFF990000, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 5134.697753, -3897.071777, 13.343647, 0.000000, 0.000000, -179.400039, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "+", 40, "Impact", 80, 1, 0xFFFFFFFF, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 5134.678710, -3887.910888, 13.243645, 0.000000, 0.000000, -179.400039, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "AMC", 80, "Trebuchet MS", 110, 1, 0xFFFFFFFF, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 5134.687500, -3887.851562, 13.293646, 0.000000, 0.000000, -179.400039, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10765, "airportgnd_sfse", "white", 0x00000000);
	SetDynamicObjectMaterialText(tmpobjid, 0, "AMC", 80, "Trebuchet MS", 110, 1, 0xFF990000, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 5134.624511, -3890.404541, 9.713639, 0.000000, 0.000000, -179.400039, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10765, "airportgnd_sfse", "white", 0x00000000);
	SetDynamicObjectMaterialText(tmpobjid, 0, "Main Department Ministry of Health", 130, "Trebuchet MS", 35, 1, 0xFFFFFFFF, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 5134.668945, -3890.406738, 9.713639, 0.000000, 0.000000, -179.400039, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10765, "airportgnd_sfse", "white", 0x00000000);
	SetDynamicObjectMaterialText(tmpobjid, 0, "Main Department Ministry of Health", 130, "Trebuchet MS", 35, 1, 0xFF990000, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 5109.466796, -3829.500976, 5.993637, 0.000000, 0.000000, -89.400115, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10765, "airportgnd_sfse", "white", 0x00000000);
	SetDynamicObjectMaterialText(tmpobjid, 0, "Main Department Ministry of Health", 130, "Trebuchet MS", 30, 1, 0xFFFFFFFF, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 5109.466796, -3829.460937, 5.993637, 0.000000, 0.000000, -89.400115, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10765, "airportgnd_sfse", "white", 0x00000000);
	SetDynamicObjectMaterialText(tmpobjid, 0, "Main Department Ministry of Health", 130, "Trebuchet MS", 30, 1, 0xFF990000, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 4700.218261, -4058.107666, 10.485498, 0.000000, 0.000000, 0.599999, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "WILD", 120, "Fixedsys", 100, 0, 0xFF990000, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 4700.258300, -4058.107177, 7.615491, 0.000000, 0.000000, 0.599999, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "LOTUS", 120, "Fixedsys", 90, 0, 0xFFFFFFFF, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 4700.160644, -4058.077148, 7.635491, 0.000000, 0.000000, 0.599999, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 7650, "vgnusedcar", "marinadoor2_256", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 11701, "ambulancelights1", "vehiclelights128", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 8, 7650, "vgnusedcar", "marinadoor2_256", 0x00000000);
	SetDynamicObjectMaterialText(tmpobjid, 0, "LOTUS", 120, "Fixedsys", 90, 0, 0xFF990000, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 4559.259765, -4058.718017, 7.255465, 0.000000, 0.000000, 0.899999, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "BUS STATION", 120, "Arial", 63, 1, 0xFFFFFFFF, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 4559.283203, -4058.757812, 7.325468, 0.000000, 0.000000, 0.899999, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "BUS STATION", 120, "Arial", 63, 1, 0xFF000000, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(3499, 4578.750000, -3253.491455, 50.331230, 0.000000, 90.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 16640, "a51", "concreteyellow256 copy", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 14629, "ab_chande", "ab_goldpipe", 0x00000000);
	tmpobjid = CreateDynamicObject(4735, 5208.545898, -4163.996093, 7.545492, 0.000000, 0.000000, 90.599990, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 14652, "ab_trukstpa", "bbar_door1", 0x00000000);
	SetDynamicObjectMaterialText(tmpobjid, 0, "A.C.P.D.", 120, "Segoe Keycaps", 36, 1, 0xFF000099, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 5208.405273, -4163.985351, 6.845500, 0.000000, 0.000000, 90.599990, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 14652, "ab_trukstpa", "bbar_door1", 0x00000000);
	SetDynamicObjectMaterialText(tmpobjid, 0, "Albion City Police Department", 120, "Calibri", 12, 1, 0xFF000099, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(19545, 4724.244140, -2560.805419, 29.324409, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 19523, "sampicons", "reeedgrad32", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 19523, "sampicons", "reeedgrad32", 0x00000000);
	tmpobjid = CreateDynamicObject(4735, 4724.012207, -2531.236816, 29.345455, 0.699998, 89.999931, 90.100044, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "������������� �����", 120, "Arial", 30, 0, 0xFF000000, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 4724.008789, -2534.459960, 29.345443, 0.599999, 89.999931, 90.100044, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "������ ����� :", 120, "Arial", 25, 0, 0xFF000000, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 4724.186523, -2536.091552, 29.333562, 0.599999, 89.999931, 90.100044, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "MOF, �������, Shinichiro_Masato", 120, "Arial", 25, 0, 0xFF000000, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 4723.851562, -2537.052246, 29.337148, 0.599999, 89.999931, 90.100044, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "vk.com/mofex", 120, "Arial", 25, 0, 0xFF000000, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 4723.501953, -2566.917480, 29.351093, 0.599999, 89.999931, 90.100044, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "24. ����� : Rossy", 120, "Arial", 20, 1, 0xFF000000, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 4724.478515, -2539.562744, 29.330545, 0.599999, 89.999931, 90.100044, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "RUSSIA GAMING ( Ryo_Masato )", 120, "Arial", 20, 1, 0xFF000000, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 4724.198242, -2546.755859, 29.333562, 0.599999, 89.999931, 90.100044, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "��� ���������� ��������������", 120, "Arial", 20, 1, 0xFF000000, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 4724.192871, -2547.809570, 29.333562, 0.599999, 89.999931, 90.100044, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "��������� ������ �� ������ :", 120, "Arial", 20, 1, 0xFF000000, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 4724.198730, -2549.978759, 29.333562, 0.599999, 89.999931, 90.100044, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "1. ����� : Rodenstark", 120, "Arial", 20, 1, 0xFF000000, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 4724.090820, -2550.829589, 29.334716, 0.599999, 89.999931, 90.100044, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "2. Nursultan_Adylovich", 120, "Arial", 20, 1, 0xFF000000, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 4723.973632, -2551.620361, 29.335975, 0.599999, 89.999931, 90.100044, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "3. Dominic_Hernandez", 120, "Arial", 20, 1, 0xFF000000, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 4723.108398, -2552.391845, 29.345090, 0.599999, 89.999931, 90.100044, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "4. Castro_Adelfio", 120, "Arial", 20, 1, 0xFF000000, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 4722.285644, -2553.112548, 29.353797, 0.599999, 89.999931, 90.100044, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "5. Lazy Man", 120, "Arial", 20, 1, 0xFF000000, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 4723.542480, -2553.812011, 29.340593, 0.599999, 89.999931, 90.100044, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "6. Diego_Rodriguez", 120, "Arial", 20, 1, 0xFF000000, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 4722.426757, -2554.552734, 29.352338, 0.599999, 89.999931, 90.100044, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "7. Jek_Redik", 120, "Arial", 20, 1, 0xFF000000, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 4723.116210, -2555.313476, 29.345100, 0.599999, 89.999931, 90.100044, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "8. Egor_Attwood", 120, "Arial", 20, 1, 0xFF000000, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 4722.871582, -2556.044189, 29.347723, 0.599999, 89.999931, 90.100044, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "9. Jake_Vegazz", 120, "Arial", 20, 1, 0xFF000000, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 4723.228515, -2556.814941, 29.343946, 0.599999, 89.999931, 90.100044, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "10. Jimmy_Coldaize", 120, "Arial", 20, 1, 0xFF000000, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 4723.032714, -2557.555664, 29.346044, 0.599999, 89.999931, 90.100044, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "11. Kevin_Richard", 120, "Arial", 20, 1, 0xFF000000, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 4723.140625, -2558.256347, 29.344890, 0.599999, 89.999931, 90.100044, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "12. Storm_Extazzy", 120, "Arial", 20, 1, 0xFF000000, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 4722.687500, -2558.957031, 29.349716, 0.599999, 89.999931, 90.100044, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "13. Axie_Vegazz", 120, "Arial", 20, 1, 0xFF000000, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 4723.460449, -2559.677734, 29.341533, 0.599999, 89.999931, 90.100044, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "14. Taer_Richardson", 120, "Arial", 20, 1, 0xFF000000, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 4723.274902, -2560.488525, 29.343526, 0.599999, 89.999931, 90.100044, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "15. Robert_Choppa", 120, "Arial", 20, 1, 0xFF000000, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 4722.941894, -2561.249267, 29.347093, 0.599999, 89.999931, 90.100044, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "16. Kelvin_Hustle", 120, "Arial", 20, 1, 0xFF000000, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 4724.639160, -2561.969726, 29.339162, 0.599999, 89.999931, 90.100044, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "17. ����� : Walter_Dently", 120, "Arial", 20, 1, 0xFF000000, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 4723.060546, -2562.743408, 29.355707, 0.599999, 89.999931, 90.100044, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "18. Andrew_Nevill", 120, "Arial", 20, 1, 0xFF000000, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 4723.995117, -2563.434082, 29.345848, 0.599999, 89.999931, 90.100044, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "19. Parlament_Coldaize", 120, "Arial", 20, 1, 0xFF000000, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 4723.887695, -2564.144775, 29.347002, 0.599999, 89.999931, 90.100044, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "20. Patrick_Hernandez", 120, "Arial", 20, 1, 0xFF000000, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 4723.153808, -2564.825439, 29.354764, 0.599999, 89.999931, 90.100044, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "21. Luka_Coldaize", 120, "Arial", 20, 1, 0xFF000000, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 4722.689453, -2565.496093, 29.359695, 0.599999, 89.999931, 90.100044, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "22. Amos_King", 120, "Arial", 20, 1, 0xFF000000, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 4724.480468, -2538.751953, 29.350542, 0.599999, 89.999931, 90.100044, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall01", 0x00000000);
	SetDynamicObjectMaterialText(tmpobjid, 0, "���� (����������) :", 120, "Arial", 20, 1, 0xFF000000, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 4723.335449, -2566.166748, 29.352876, 0.599999, 89.999931, 90.100044, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "23. Foster_Bonsak", 120, "Arial", 20, 1, 0xFF000000, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 4724.806152, -2567.647949, 29.337352, 0.599999, 89.999931, 90.100044, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 18835, "mickytextures", "whiteforletters", 0x00000000);
	SetDynamicObjectMaterialText(tmpobjid, 0, "25. ����� : Yra_Andrysak", 120, "Arial", 20, 1, 0xFF000000, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 4563.456542, -4059.024658, 23.615446, 0.000000, 0.000000, 0.899999, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "n", 120, "Webdings", 90, 1, 0xFFFFFFFF, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 4563.425292, -4059.024414, 23.615446, 0.000000, 0.000000, 0.899999, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "n", 120, "Webdings", 86, 1, 0xFF000000, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 4563.415039, -4059.024902, 23.615446, 0.000000, 0.000000, 0.899999, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "v", 120, "Webdings", 80, 1, 0xFFFFFFFF, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(2754, 4559.083007, -4050.319824, 2.385499, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 19627, "wrench1", "wrench1", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 19627, "wrench1", "wrench1", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 19058, "xmasboxes", "wrappingpaper28", 0x00000000);
	tmpobjid = CreateDynamicObject(2754, 4664.458984, -3994.844970, 2.385499, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 19627, "wrench1", "wrench1", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 19627, "wrench1", "wrench1", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 2, 19058, "xmasboxes", "wrappingpaper16", 0x00000000);
	tmpobjid = CreateDynamicObject(2754, 4618.409179, -4143.518066, 2.365498, 0.000000, 0.000000, -180.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 2, 19058, "xmasboxes", "wrappingpaper1", 0x00000000);
	tmpobjid = CreateDynamicObject(2754, 4524.789062, -4508.297363, 2.506227, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 2, 19058, "xmasboxes", "wrappingpaper4-2", 0x00000000);
	tmpobjid = CreateDynamicObject(4735, 4968.453125, -4275.644042, 14.983675, 0.000000, 0.000000, 91.799964, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "DIMOON", 120, "Comic Sans MS", 140, 1, 0xFFFFFF33, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 4972.825195, -4275.455566, 11.021075, 73.099975, 0.000000, 91.799964, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, ")", 120, "Comic Sans MS", 140, 1, 0xFF000000, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 4984.187500, -4275.206054, 12.173662, 0.000000, 0.000000, 91.799964, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "CLUB", 120, "Comic Sans MS", 140, 1, 0xFF000000, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 4984.148925, -4275.464843, 12.273664, 0.000000, 0.000000, 91.799964, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "CLUB", 120, "Comic Sans MS", 140, 1, 0xFFFFFF33, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 4968.534667, -4275.512695, 14.883671, 0.000000, 0.000000, 91.799964, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "DIMOON", 120, "Comic Sans MS", 140, 1, 0xFF000000, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 4972.586914, -4275.471679, 14.598745, 73.099975, 0.000000, 91.799964, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "n", 120, "Webdings", 23, 1, 0xFFFFFFFF, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 4972.460937, -4275.477050, 14.560956, 73.099975, 0.000000, 91.799964, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "n", 120, "Webdings", 10, 1, 0xFF000000, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 4972.584472, -4275.464843, 14.598745, 73.099975, 0.000000, 91.799964, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "n", 120, "Webdings", 26, 1, 0xFF000000, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 4972.750000, -4275.740722, 11.080180, 73.099975, 0.000000, 91.799964, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, ")", 120, "Comic Sans MS", 140, 1, 0xFFFFFF33, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 4969.246093, -4275.508300, 14.599508, 73.099975, 0.000000, 91.799964, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "n", 120, "Webdings", 26, 1, 0xFF000000, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 4969.251953, -4275.522949, 14.599508, 73.099975, 0.000000, 91.799964, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "n", 120, "Webdings", 23, 1, 0xFFFFFFFF, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 4969.085937, -4275.531250, 14.550091, 73.099975, 0.000000, 91.799964, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "n", 120, "Webdings", 10, 1, 0xFF000000, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(2754, 4921.880371, -4305.003417, 2.393697, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 2, 19058, "xmasboxes", "wrappingpaper28", 0x00000000);
	tmpobjid = CreateDynamicObject(2754, 5087.639648, -4402.597167, 2.405498, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 2, 19058, "xmasboxes", "wrappingpaper20", 0x00000000);
	tmpobjid = CreateDynamicObject(2754, 5212.626464, -4060.282958, 2.765499, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 2, 19063, "xmasorbs", "foil1-128x128", 0x00000000);
	tmpobjid = CreateDynamicObject(2754, 5315.369628, -3902.355712, 2.415498, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 2, 19063, "xmasorbs", "foil2-128x128", 0x00000000);
	tmpobjid = CreateDynamicObject(2754, 5128.910156, -3841.539794, 2.435497, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 2, 19058, "xmasboxes", "wrappingpaper1", 0x00000000);
	tmpobjid = CreateDynamicObject(2754, 4894.854980, -3887.283447, 2.405498, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 2, 19058, "xmasboxes", "silk9-128x128", 0x00000000);
	tmpobjid = CreateDynamicObject(2754, 5077.551757, -4047.860595, 2.645119, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 2, 19058, "xmasboxes", "wrappingpaper28", 0x00000000);
	tmpobjid = CreateDynamicObject(2754, 4726.829589, -3159.761474, 2.396822, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 2, 19058, "xmasboxes", "wrappingpaper20", 0x00000000);
	tmpobjid = CreateDynamicObject(2754, 4896.879394, -3044.526855, 2.609061, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 2, 19058, "xmasboxes", "wrappingpaper16", 0x00000000);
	tmpobjid = CreateDynamicObject(2754, 5137.544433, -3286.448242, 2.406822, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 2, 19063, "xmasorbs", "foil1-128x128", 0x00000000);
	tmpobjid = CreateDynamicObject(2754, 5079.957519, -3493.255126, 2.405498, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 2, 19058, "xmasboxes", "wrappingpaper28", 0x00000000);
	tmpobjid = CreateDynamicObject(2754, 4943.124023, -3499.419921, 2.425498, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 2, 19058, "xmasboxes", "wrappingpaper16", 0x00000000);
	tmpobjid = CreateDynamicObject(4735, 4792.589355, -4082.019775, 6.203687, 0.000000, 0.000000, 90.599899, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "THE NATION BANK OF ALBION CITY", 120, "Arial", 20, 1, 0xFF000000, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 4792.563476, -4082.039794, 6.253687, 0.000000, 0.000000, 90.599899, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "THE NATION BANK OF ALBION CITY", 120, "Arial", 20, 1, 0xFFFFFFFF, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(2754, 3648.666748, -5856.659667, 6.367706, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterial(tmpobjid, 2, 19058, "xmasboxes", "wrappingpaper28", 0x00000000);
	tmpobjid = CreateDynamicObject(4735, 4969.715820, -4275.491210, 17.927684, 73.099975, 0.000000, 91.799964, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "\\", 120, "Comic Sans MS", 70, 1, 0xFF000000, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 4969.670410, -4275.600585, 17.954326, 73.099975, 0.000000, 91.799964, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "\\", 120, "Comic Sans MS", 70, 1, 0xFFFFFF33, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 4972.679199, -4275.426269, 18.313516, 97.899971, 0.000000, 91.799964, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "/", 120, "Comic Sans MS", 70, 1, 0xFF000000, 0x00000000, 1);
	tmpobjid = CreateDynamicObject(4735, 4972.668457, -4275.614746, 18.326171, 97.899971, 0.000000, 91.799964, 0, 0, -1, 1000.00, 1000.00);
	SetDynamicObjectMaterialText(tmpobjid, 0, "/", 120, "Comic Sans MS", 70, 1, 0xFFFFFF33, 0x00000000, 1);
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	tmpobjid = CreateDynamicObject(3331, 819.283386, -2012.023559, 21.543800, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 837.094726, -2012.023559, 21.506900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(11696, 4123.685546, -3330.895751, -3.454710, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(11695, 3998.305175, -3555.338623, -3.218600, 0.000000, 0.000000, -52.380050, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(11694, 3631.589843, -3577.345703, 4.899580, 0.000000, 0.000000, -6.599998, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(11695, 3409.499023, -3303.359375, -3.218600, 0.000000, 0.000000, 11.880000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(11694, 3157.501953, -3228.146484, 4.899580, 0.000000, 0.000000, 7.259990, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19536, 4578.979492, -3186.312500, 1.519798, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19536, 4470.229492, -3155.062988, 1.519798, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19536, 4578.979492, -3108.812988, 1.519798, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(11695, 4065.541503, -2819.889648, -3.218600, 0.000000, 0.000000, -1.200000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(11694, 4335.272949, -2570.381103, 4.899580, 0.000000, 0.000000, -3.480010, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(11695, 4732.722656, -2554.480712, -3.218600, 0.000000, 0.000000, 88.079948, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19536, 4470.229492, -3000.063232, 1.519798, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19536, 4470.229492, -2860.063232, 1.519798, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19536, 4547.728515, -2860.063232, 1.519798, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19536, 4625.228515, -2860.063232, 1.519798, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19543, 4470.229492, -3085.063476, 1.519798, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19536, 4858.979003, -2953.813476, 1.519798, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19536, 4998.978027, -2953.813476, 1.519798, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19543, 4967.728515, -3210.062500, 1.523800, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19543, 4967.728515, -3195.062988, 1.523800, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19543, 4967.728515, -3180.063476, 1.523800, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19543, 4967.728515, -3165.102783, 1.519798, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19543, 4967.728515, -3162.562011, 1.523800, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19543, 4967.728515, -3132.567626, 1.523800, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19543, 4967.728515, -3117.570556, 1.523800, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19543, 4967.728515, -3102.574951, 1.523800, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19543, 4967.728515, -3087.577880, 1.483800, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19543, 4967.728515, -3085.062744, 1.523800, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19543, 4967.728515, -3055.069335, 1.523800, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19543, 4967.728515, -3040.071289, 1.523800, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19543, 4967.728515, -3025.074951, 1.523800, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19543, 4967.728515, -3010.078613, 1.523800, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19543, 4967.728515, -3007.516357, 1.519798, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19536, 5076.478027, -3186.312500, 1.515498, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19536, 5076.478027, -3108.813232, 1.515498, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19536, 5076.478027, -3031.313232, 1.523800, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19536, 5076.478027, -2953.813476, 1.523800, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19536, 5185.227050, -3062.563476, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19536, 5185.227050, -3187.562988, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19547, 5278.976562, -3062.563476, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19547, 5278.976562, -3187.562988, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(11693, 5466.476074, -3250.062255, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19536, 5185.227050, -3312.562500, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19547, 5278.976562, -3312.562500, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19536, 5216.477050, -3403.821777, 1.331500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19543, 5325.225585, -3442.562500, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19546, 5356.474609, -3375.056884, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19540, 5356.474609, -3450.062500, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 5356.472656, -3442.562988, 1.325500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19539, 5325.225585, -3450.062500, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19542, 5481.473632, -3375.056884, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19540, 5591.470214, -3375.056884, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19539, 5560.225097, -3375.056884, 1.327499, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19542, 5591.470214, -3312.557861, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19542, 5591.470214, -3187.557861, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19540, 5591.470214, -3125.063720, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19542, 5528.971679, -3125.065673, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19542, 5403.972656, -3125.065673, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19546, 5341.454589, -3125.063720, 1.327499, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19539, 5341.454589, -3031.313964, 1.327499, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19540, 5341.454589, -3000.071289, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19546, 5153.977050, -3450.062500, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19539, 5247.727050, -3450.062500, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 5286.477050, -3450.062500, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19546, 5153.977050, -3590.062500, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 5153.977050, -3520.062500, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(7537, 5621.387695, -3620.971679, 1.322600, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19542, 5216.477050, -3605.061523, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19539, 5107.727539, -3605.061523, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 5146.477539, -3605.061523, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 5068.978027, -3605.061523, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19546, 4936.479003, -3605.061523, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19539, 5030.228515, -3605.061523, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19540, 4936.479003, -3682.560546, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 4936.479003, -3675.061523, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19542, 4858.979003, -3682.560546, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 4928.978515, -3682.560546, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 4788.979003, -3682.560546, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19546, 4781.478515, -3605.061523, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 4781.478515, -3675.061523, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19540, 4781.478515, -3682.560546, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19539, 4687.729003, -3605.061523, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 4648.979492, -3605.061523, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19540, 5278.976562, -3605.061523, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 5278.976562, -3597.562011, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19540, 5278.976562, -3590.062500, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19539, 5247.727050, -3590.062500, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(7536, 5713.113281, -3646.822998, 0.572498, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19546, 5593.978027, -3605.061523, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19539, 5500.229003, -3605.061523, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19540, 5468.979980, -3605.061523, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 5468.979980, -3597.562011, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19540, 5468.979980, -3590.062011, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19539, 5500.229003, -3590.062011, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19546, 5593.978027, -3590.062011, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19540, 5593.978027, -3527.562988, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 5601.478515, -3527.562988, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19542, 5671.478027, -3527.562988, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 5741.447753, -3527.562988, 1.325500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19540, 5768.974121, -3527.562988, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 5761.501953, -3527.562988, 1.325500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 5751.174316, -3527.562988, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19542, 5768.974121, -3590.062255, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19539, 5768.974121, -3683.813232, 1.327499, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 5768.974121, -3722.562500, 1.327499, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 5768.974121, -3737.563476, 1.329499, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19540, 5768.974121, -3745.058837, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19539, 5593.978027, -3698.811767, 1.327499, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19542, 5706.477050, -3745.058837, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19542, 5671.478027, -3745.058837, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19540, 5593.978027, -3745.058837, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 5601.478515, -3745.058837, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 5593.978027, -3737.560058, 1.327499, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19543, 5625.228027, -3737.560058, 1.323698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19543, 5161.477050, -2953.813476, 1.523800, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19543, 5176.476074, -2953.813476, 1.523800, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19543, 5191.476074, -2953.813476, 1.523800, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19543, 5206.475585, -2953.813476, 1.523800, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19543, 5208.979003, -2953.813476, 1.523800, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19543, 5161.477050, -2876.313476, 1.523800, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19543, 5176.476074, -2876.313476, 1.523800, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19543, 5191.476074, -2876.313476, 1.523800, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19543, 5208.979003, -2876.313476, 1.523800, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19543, 5206.475585, -2876.313476, 1.523800, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19543, 5131.478027, -2876.313476, 1.523800, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19543, 5116.478515, -2876.313476, 1.523800, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19543, 5101.479003, -2876.313476, 1.523800, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19543, 5086.479492, -2876.313476, 1.523800, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19543, 5083.977539, -2876.313476, 1.523800, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3501, 5697.815917, -3558.435546, 4.509799, 0.000000, 0.000000, -75.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3501, 5641.567382, -3573.512451, 4.503798, 0.000000, 0.000000, -75.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3501, 5697.819824, -3634.870849, 4.509799, 0.000000, 0.000000, -105.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3501, 5641.588378, -3619.788574, 4.509799, 0.000000, 0.000000, -105.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(7535, 5748.723632, -3597.761718, 4.506898, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(7533, 5636.568359, -3669.313964, 4.503499, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(7538, 5734.508789, -3690.001708, 3.457900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19543, 5640.226074, -3722.560791, 1.325700, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19543, 5663.518554, -3714.102294, 1.321699, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19546, 4516.479003, -3605.061523, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19539, 4610.229003, -3605.061523, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 4516.479003, -3675.061523, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19539, 4516.479003, -3713.811279, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 4516.479003, -3752.561279, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19540, 4516.479003, -3760.061279, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 4508.979003, -3760.061279, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19542, 4438.980468, -3760.061279, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 4368.980957, -3760.061279, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19542, 4298.980957, -3760.061279, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 4228.980957, -3760.061279, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19540, 4221.482421, -3760.061279, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 4221.482421, -3752.561279, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19539, 4221.482421, -3713.811279, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 4221.482421, -3675.061523, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19540, 4221.482421, -3667.564453, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19536, 4438.980468, -3636.311767, 1.523800, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19536, 4438.980468, -3713.811279, 1.523800, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19536, 4298.980957, -3713.811279, 1.523800, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 4228.981445, -3667.564453, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19546, 4361.481445, -3667.564453, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19539, 4267.731445, -3667.564453, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 4361.481445, -3597.562011, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 4361.481445, -3582.562011, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19540, 4361.481445, -3575.062255, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 4368.980957, -3575.062255, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19546, 4501.479003, -3575.061523, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19539, 4407.729980, -3575.062255, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19539, 4501.479003, -3481.311767, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 4501.479003, -3442.562011, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 4423.979980, -3147.562744, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19539, 4423.979980, -3108.812988, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 4423.979980, -3070.063232, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19542, 4423.979980, -3000.063232, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 4423.979980, -2930.063232, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19542, 4423.979980, -2860.063232, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 4423.979980, -2790.063476, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19540, 4423.979980, -2782.563964, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 4431.479492, -2782.563964, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19539, 4470.229492, -2782.563964, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 4508.979003, -2782.563964, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19539, 4547.728515, -2782.563964, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 4586.478515, -2782.563964, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19539, 4625.228515, -2782.563964, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 4663.978515, -2782.563964, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19540, 4671.478027, -2782.563964, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 4671.478027, -2790.063476, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19542, 4671.478027, -2860.063232, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 4671.478027, -2930.063232, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19540, 4671.478027, -2937.562988, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 4663.978515, -2937.562988, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19539, 4625.228515, -2937.562988, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 4586.478515, -2937.562988, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19546, 4516.479492, -2937.562988, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19546, 4516.479492, -3062.563476, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19539, 4610.229980, -3062.563476, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 4648.979980, -3062.563476, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19546, 4781.479492, -3062.563476, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19539, 4687.729492, -3062.563476, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 4781.479492, -2992.563476, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19539, 4781.479492, -2953.813476, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 4781.479492, -2915.063476, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19540, 4781.479492, -2907.563476, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 4788.979003, -2907.563476, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19546, 5061.478027, -2907.563476, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 5061.478027, -2837.563720, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19540, 5061.478027, -2830.063720, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 5068.978027, -2830.063720, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19539, 5107.728027, -2830.063720, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 5146.477539, -2830.063720, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19539, 5185.227050, -2830.063720, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 5223.977050, -2830.063720, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19540, 5231.475097, -2830.063720, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 5231.475097, -2837.563720, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19539, 5231.475097, -2876.313476, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 5231.475097, -2915.063476, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19546, 5231.475097, -3000.063476, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 5231.475097, -2930.063232, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19539, 5325.098144, -3000.071289, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19536, 5402.727050, -4167.558105, 1.515498, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19536, 5402.727050, -4307.557617, 1.515498, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19536, 5402.727050, -4447.556640, 1.515498, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19546, 5153.977539, -4245.058105, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19546, 5278.977050, -4245.058105, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19536, 5216.477050, -4556.306640, 1.515498, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19546, 5278.977050, -4510.057617, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19546, 5153.977539, -4510.057617, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19539, 5278.977050, -4338.808105, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 5278.977050, -4377.557128, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19539, 5278.977050, -4416.307617, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19539, 5153.977539, -4416.307617, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 5153.977539, -4377.557128, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19539, 5153.977539, -4338.808105, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19536, 5076.479003, -4556.306640, 1.515498, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19543, 5301.475585, -4556.306640, 1.523800, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19543, 5316.474609, -4556.306640, 1.523800, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19543, 5331.473144, -4556.306640, 1.523800, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19543, 5346.448242, -4556.306640, 1.517799, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19543, 5348.980468, -4556.306640, 1.523800, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19543, 5378.975585, -4556.306640, 1.523800, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19543, 5393.973632, -4556.306640, 1.523800, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19543, 5408.972656, -4556.306640, 1.523800, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19543, 5423.970703, -4556.306640, 1.519798, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19543, 5426.477050, -4556.306640, 1.523800, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19546, 4501.480468, -4167.557617, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 4501.480468, -4097.558593, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19539, 4501.480468, -4058.809082, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 4501.480468, -4020.059082, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 4501.480468, -3942.559082, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19539, 4501.480468, -3981.309082, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19540, 4501.480468, -3935.059570, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 4508.980468, -3935.059570, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19546, 4641.479980, -3935.059570, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19539, 4547.729980, -3935.059570, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 4641.479980, -3802.559326, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19539, 4641.479980, -3841.309570, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19540, 4641.479980, -3795.059326, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 4648.979980, -3795.059326, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19539, 4687.729980, -3795.059326, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 4726.479492, -3795.059326, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19542, 4796.479492, -3795.059326, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 4866.479492, -3795.059326, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19542, 4936.479003, -3795.059326, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 5006.479003, -3795.059326, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19542, 5076.479003, -3795.059326, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 5146.477539, -3795.059326, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19542, 5216.477050, -3795.059326, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 5286.477050, -3795.059326, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19546, 5293.976562, -4090.059082, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 5363.976562, -4090.059082, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19539, 5402.727050, -4090.059082, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 5441.477050, -4090.059082, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19540, 5448.977050, -4090.059082, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 5448.977050, -4097.558593, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19542, 5448.977050, -4167.558105, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 5448.977050, -4237.558105, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19542, 5448.977050, -4307.557617, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 5448.977050, -4377.557128, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19542, 5448.977050, -4447.556640, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 5448.977050, -4517.556640, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19539, 5448.977050, -4556.306640, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 5448.977050, -4595.056640, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19540, 5448.977050, -4602.556640, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 5441.477050, -4602.556640, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19539, 5402.727050, -4602.556640, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 5363.976562, -4602.556640, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19539, 5325.226562, -4602.556640, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 5286.477050, -4602.556640, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19542, 5216.477050, -4602.556640, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 5146.477539, -4602.556640, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19542, 5076.479003, -4602.556640, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 5006.479003, -4602.556640, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19540, 4998.979492, -4602.556640, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 4998.979492, -4595.056640, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19539, 4998.979492, -4556.306640, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 4998.979492, -4517.556640, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19542, 4998.979492, -4447.556640, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19546, 4998.979492, -4322.557128, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19539, 4905.229980, -4322.557128, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 4866.479492, -4322.557128, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19539, 4827.728515, -4322.557128, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 4788.978515, -4322.557128, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19546, 4656.479980, -4322.557128, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19539, 4750.229492, -4322.557128, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 4656.479980, -4392.557617, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19542, 4656.479980, -4462.557617, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 4656.479980, -4532.557128, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19540, 4656.479980, -4540.056640, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 4648.979980, -4540.056640, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19542, 4578.979980, -4540.056640, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 4508.980468, -4540.056640, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 4423.981445, -4315.058105, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19542, 4423.981445, -4462.557617, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 4423.981445, -4392.557617, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19539, 4423.981445, -4353.808105, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 4423.981445, -4532.557128, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 4431.481445, -4167.557617, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19542, 4423.981445, -4602.557128, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19540, 4423.981445, -4665.057128, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 4431.481445, -4665.057128, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19540, 4438.980957, -4665.057128, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19546, 4438.980957, -4540.056640, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19539, 4438.980957, -4633.807617, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(17020, 3833.827880, -5854.672851, 9.448100, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(9587, 3696.772216, -5878.416992, 12.690238, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(10231, 3800.809570, -5881.294921, 7.817510, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(9241, 3651.706542, -5794.127929, 7.142600, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(9241, 3690.118652, -5793.943359, 7.142600, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(9587, 3806.938964, -5798.927734, 12.690238, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(1378, 3729.923583, -5794.334960, 29.765199, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(18248, 3772.683593, -5855.114746, 12.713998, 0.000000, 0.000000, -80.340026, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 819.283386, -2162.022216, 21.543800, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 837.094726, -2162.022216, 21.506900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 819.283386, -2312.021484, 21.543800, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 837.094726, -2312.021484, 21.506900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 819.283386, -2462.020019, 21.543800, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 837.094726, -2462.020019, 21.506900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 819.283386, -2612.019775, 21.543800, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 837.094726, -2612.019775, 21.506900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 819.283386, -2762.019287, 21.543800, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 819.283386, -2912.018310, 21.543800, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 1004.334594, -3097.169189, 21.543800, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 1154.334472, -3097.169189, 21.543800, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 1304.334472, -3097.169189, 21.543800, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 1454.334960, -3097.169189, 21.543800, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 1604.334716, -3097.169189, 21.543800, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 1754.334472, -3097.169189, 21.543800, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 1904.334594, -3097.169189, 21.543800, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 2054.333984, -3097.169189, 21.543800, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 2204.333496, -3097.169189, 21.543800, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 2354.332519, -3097.169189, 21.543800, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 2504.332031, -3097.169189, 21.543800, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 2654.332275, -3097.169189, 21.543800, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 2804.331787, -3097.169189, 21.543800, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 2954.330322, -3097.169189, 21.543800, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 3104.330078, -3097.169189, 21.543800, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 3104.330078, -2947.120117, 21.543800, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 2954.330322, -2947.120117, 21.543800, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 2804.331787, -2947.120117, 21.543800, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 2654.332275, -2947.120117, 21.543800, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 2504.332031, -2947.120117, 21.543800, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 2354.332519, -2947.120117, 21.543800, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 2204.333496, -2947.120117, 21.543800, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 2054.333984, -2947.120117, 21.543800, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 1904.334594, -2947.120117, 21.543800, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 1754.334472, -2947.120117, 21.543800, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 1604.334716, -2947.120117, 21.543800, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 1454.334960, -2947.120117, 21.543800, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 1304.334472, -2947.120117, 21.543800, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 1154.334472, -2947.120117, 21.543800, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 1004.334594, -2947.120117, 21.543800, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 3272.276611, -2947.120117, 21.543800, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 3422.276367, -2947.120117, 21.543800, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 3572.275878, -2947.120117, 21.543800, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 3722.275634, -2947.120117, 21.543800, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 3872.274902, -2947.120117, 21.543800, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 4022.274414, -2947.120117, 21.543800, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 4190.858398, -2762.023193, 21.543800, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 4190.858398, -2612.023437, 21.543800, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 4375.992187, -2443.464111, 21.543800, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 4525.992187, -2443.464111, 21.543800, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 4675.991210, -2443.464111, 21.543800, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 4844.599609, -2612.025390, 21.543800, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 4844.599609, -2762.025390, 21.543800, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 4844.599609, -2912.025390, 21.543800, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 4844.599609, -3061.849853, 18.160400, 2.500000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 4844.575683, -3200.055419, 15.304100, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 3272.943359, -3265.735595, 21.543800, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 3458.039794, -3450.872070, 21.543800, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 3607.983154, -3450.872070, 24.593900, -2.500000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 3757.839111, -3450.872070, 31.178789, -2.500000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 3907.695312, -3450.872070, 37.872539, -2.500000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 4097.090820, -3450.872070, 37.872501, 2.500000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 4246.947753, -3450.872070, 31.181379, 2.500000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 4396.804687, -3450.872070, 24.751920, 2.500000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 4546.660644, -3450.872070, 18.227830, 2.500000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 829.678588, -2086.905029, -1.313879, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 843.072204, -2087.104492, -1.313879, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 843.083374, -2237.044189, -1.313879, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 829.758056, -2236.947021, -1.313879, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 843.232543, -2387.031250, -1.313879, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 829.806518, -2386.941406, -1.313879, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 829.718750, -2536.953369, -1.313879, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 829.696533, -2686.922851, -1.313879, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 843.262329, -2687.074218, -1.313879, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 843.260192, -2836.980712, -1.313879, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 829.629089, -2836.965820, -1.313879, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 827.571716, -2987.028808, -1.313879, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 929.433471, -3088.834960, -1.313899, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 1079.401977, -3089.087890, -1.313899, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 1229.298461, -3089.201171, -1.313899, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 1379.342285, -3088.958984, -1.313899, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 1529.366699, -3088.715576, -1.313899, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 1679.259033, -3088.694335, -1.313899, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 1829.341796, -3089.116210, -1.313899, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 1979.352905, -3089.002685, -1.313899, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 2129.344970, -3088.824462, -1.313899, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 2279.353759, -3089.107666, -1.313899, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 2429.384521, -3088.770507, -1.313899, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 2579.276611, -3089.168457, -1.313899, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 2729.334228, -3088.894775, -1.313899, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 2879.346923, -3088.915527, -1.313899, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 3029.337646, -3089.087890, -1.313899, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 3179.504638, -3089.049316, -1.313899, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 3280.842285, -3190.734130, -1.313899, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 3281.062011, -3340.689697, -1.313899, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 3382.961914, -3442.192626, -1.313899, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 3533.147460, -3442.833984, -1.200888, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 3683.002685, -3442.833740, 5.133850, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 3832.895507, -3442.416503, 11.785690, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 4002.858154, -3442.771972, 19.612030, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 4171.834472, -3442.633544, 11.784198, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 4321.666992, -3442.648437, 5.280038, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 4471.534667, -3442.490966, -1.353639, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 947.310302, -2938.968750, -1.287189, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 1079.401977, -2938.881103, -1.313899, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 1229.298461, -2938.881103, -1.313899, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 1379.342285, -2938.881103, -1.313899, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 1529.366699, -2938.881103, -1.313899, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 1679.259033, -2938.881103, -1.313899, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 1829.341796, -2938.881103, -1.313899, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 1979.352905, -2938.881103, -1.313899, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 2129.344970, -2938.881103, -1.313899, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 2279.353759, -2938.881103, -1.313899, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 2429.384521, -2938.881103, -1.313899, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 2579.276611, -2938.881103, -1.313899, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 2729.334228, -2938.881103, -1.313899, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 2879.346923, -2938.881103, -1.313899, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 3029.337646, -2938.881103, -1.313899, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 3179.504638, -2938.881103, -1.313899, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 3347.211181, -2938.881103, -1.313899, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 3497.425292, -2938.881103, -1.313899, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 3647.293212, -2938.881103, -1.313899, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 3797.274414, -2938.881103, -1.313899, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 3947.330810, -2938.881103, -1.313899, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 4199.001464, -2836.991943, -1.313899, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 4198.882812, -2687.092285, -1.313899, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 4199.238769, -2536.979248, -1.313899, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 4300.987792, -2435.341064, -1.313899, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 4450.968750, -2435.106445, -1.313899, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 4601.037109, -2434.983886, -1.313899, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 4751.015136, -2435.193847, -1.313899, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 4852.771972, -2687.059570, -1.313899, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 4852.610351, -2837.051025, -1.313899, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 4852.434570, -2983.311279, -1.355190, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 4431.423828, -4835.219726, -7.556879, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 4431.266113, -4985.086425, -7.556879, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 4423.234863, -4760.054199, 15.045100, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 4423.234863, -4910.052734, 15.045100, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 4423.234863, -5060.052246, 15.045100, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 4423.234863, -5210.051757, 15.045100, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 4423.234863, -5360.051757, 15.045100, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 4423.234863, -5510.052246, 15.045100, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 4423.234863, -5660.051269, 15.045100, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 4254.625488, -5845.150878, 15.045100, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 4104.625488, -5845.150878, 15.045100, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3331, 3954.625732, -5845.150878, 15.045100, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 4431.317871, -5134.944335, -7.556879, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 4431.231933, -5285.290039, -7.556879, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 4431.243164, -5435.102539, -7.556879, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 4431.366699, -5585.128906, -7.556879, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 4431.402343, -5735.014160, -7.556879, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 4329.579101, -5836.727539, -7.556900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 4179.484375, -5836.979492, -7.556900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3330, 4029.510498, -5836.857910, -7.556900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19542, 4361.481445, -4167.557617, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19540, 4298.982421, -4167.557617, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 4298.982421, -4175.058105, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19540, 4298.982421, -4182.557617, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19546, 4423.981445, -4182.557617, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19539, 4330.231445, -4182.557617, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19539, 4423.981445, -4276.307128, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19540, 4108.979980, -4182.558105, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 4108.979980, -4175.058105, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19540, 4108.979980, -4167.558105, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19546, 3983.982421, -4182.558105, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19539, 4077.730468, -4182.558105, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19539, 3983.982421, -4276.307617, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 3983.982421, -4315.058105, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19540, 3983.982421, -4322.557128, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 3976.482910, -4322.557128, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19542, 3906.483154, -4322.557128, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 3836.483398, -4322.557128, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19540, 3828.984619, -4322.557128, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 3828.984619, -4315.058105, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19542, 3828.984619, -4245.058105, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 3828.984619, -4175.058105, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19539, 3828.984619, -4136.308105, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 3828.984619, -4097.558105, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19540, 3828.984619, -4090.059570, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 3836.483398, -4090.059570, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19542, 3906.483154, -4090.059570, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 3976.482910, -4090.059570, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19540, 3983.981201, -4090.059570, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 3983.981201, -4097.558105, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19546, 3983.981201, -4167.558105, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19539, 4077.730468, -4167.558105, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(9054, 3877.480957, -4268.952636, 11.027098, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(7885, 3866.833007, -4196.839355, 1.321099, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(9054, 3887.731201, -4134.044433, 11.057100, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(8535, 3932.245361, -4287.337890, 7.592588, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3749, 3966.886474, -4175.071289, 7.057199, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(9241, 3950.304687, -4122.417968, 2.967060, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(9241, 5621.111328, -3703.192138, 2.964620, 0.000000, 0.000000, -89.699951, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(8131, 3849.760742, -4114.815917, 11.738570, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3306, 4248.310058, -3695.989746, 2.986000, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3307, 4273.313964, -3695.989746, 2.986000, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3308, 4299.675781, -3695.989746, 2.986000, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3309, 4324.673339, -3695.989746, 2.986000, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3306, 4348.312988, -3695.989746, 2.986000, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3309, 4248.288085, -3731.633544, 2.986000, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3308, 4273.313964, -3731.655029, 2.986000, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3307, 4299.675781, -3731.655029, 2.986000, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3306, 4324.673339, -3731.655029, 2.986000, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3308, 4348.312988, -3731.655029, 2.986000, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3307, 4488.312500, -3695.989746, 2.986000, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3308, 4464.675292, -3695.989746, 2.986000, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3309, 4439.673339, -3695.989746, 2.986000, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3306, 4413.311523, -3695.989746, 2.986000, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3306, 4388.312011, -3695.989746, 2.986000, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3307, 4389.651367, -3731.635742, 2.986000, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3308, 4413.289062, -3731.635742, 2.986000, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3309, 4438.289550, -3731.635742, 2.986000, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3306, 4464.650878, -3731.635742, 2.986000, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3306, 4489.648437, -3731.635742, 2.986000, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3309, 4489.674804, -3618.488281, 2.986000, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3309, 4464.675781, -3618.488281, 2.986000, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3308, 4439.679199, -3618.488281, 2.986000, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3307, 4413.317871, -3618.488281, 2.986000, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3306, 4388.317871, -3618.488281, 2.986000, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3306, 4489.648925, -3654.135253, 2.986000, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3307, 4464.647460, -3654.135253, 2.986000, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3308, 4438.287597, -3654.135253, 2.986000, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3309, 4413.292968, -3654.135253, 2.986000, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3306, 4389.655761, -3654.135253, 2.986000, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3309, 5095.788574, -3049.135986, 2.986000, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3309, 5045.790527, -3049.135986, 2.986000, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3308, 5125.548828, -3013.263916, 2.986000, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3307, 5125.549804, -3049.390380, 2.986000, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3306, 5095.809570, -3013.492431, 2.986000, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3317, 5166.468261, -2888.833496, 4.861498, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3316, 5197.749023, -2895.072265, 4.861498, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3315, 5173.137207, -2861.605957, 2.516900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3314, 5208.057128, -2864.223876, 2.516900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3316, 5203.986816, -2941.293945, 4.861498, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3314, 5173.137207, -2931.012939, 2.516900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3315, 5170.520996, -2965.902343, 2.516900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3316, 5197.746582, -2972.575195, 4.861498, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3316, 5120.245605, -2857.569580, 4.861498, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3315, 5084.932617, -2864.224365, 2.516900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3314, 5095.638671, -2891.015625, 2.516900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3317, 5126.470703, -2888.829833, 4.861498, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3464, 4949.805175, -2937.597412, 3.816900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3466, 4976.454101, -2937.559570, 4.048200, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3464, 5003.120605, -2937.590820, 3.820899, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3444, 5030.012695, -2937.590576, 4.048200, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3444, 5057.068359, -2937.589599, 4.048200, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3466, 5110.622070, -2937.558349, 4.048200, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3464, 5083.958007, -2937.590332, 3.820899, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3444, 4976.708496, -2970.036132, 4.048200, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3466, 4949.816894, -2970.065185, 4.044198, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3464, 5003.599121, -2970.035888, 3.820899, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3464, 5030.265625, -2970.035644, 3.820899, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3444, 5057.157226, -2970.035400, 4.048200, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3444, 5110.939941, -2970.035156, 4.048200, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3466, 5084.050781, -2970.068603, 4.048200, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3310, 4908.972167, -2972.568359, 3.564399, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3311, 4883.994628, -2972.610351, 4.536200, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3312, 4833.971191, -2972.568847, 4.464300, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3313, 4808.972656, -2972.567382, 4.377998, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3313, 4808.985351, -2935.056884, 4.377998, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3310, 4833.984863, -2935.057861, 3.564399, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3312, 4858.983398, -2935.056396, 4.464300, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3311, 4881.757812, -2935.032470, 4.536200, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3312, 4908.986816, -2935.058837, 4.464300, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3308, 5070.787597, -3049.135986, 2.986000, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3307, 5066.593261, -3014.430175, 2.986000, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3306, 5027.407226, -3013.231689, 2.986000, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3315, 4990.522949, -3043.408447, 2.516900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3316, 4955.208007, -3050.062744, 4.861498, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3316, 4948.983398, -3018.794189, 4.861498, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3314, 4979.817871, -3016.611816, 2.516900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3485, 4639.364257, -2812.705810, 8.477100, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3484, 4639.222656, -2842.994384, 8.147198, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3485, 4639.365234, -2873.274169, 8.477100, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3488, 4645.988769, -2905.449462, 8.007800, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3487, 4625.013671, -2905.449218, 8.148400, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3488, 4604.463378, -2905.449462, 8.007800, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3488, 4604.466796, -2814.676025, 8.007800, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3446, 4603.232421, -2873.861816, 4.952798, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3445, 4603.230957, -2844.919921, 4.541298, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3488, 4568.494628, -2814.678466, 8.007800, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3488, 4547.517089, -2814.678710, 8.007800, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3487, 4526.968261, -2814.677001, 8.148400, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3484, 4561.723144, -2846.946044, 8.147198, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3485, 4561.866210, -2877.225097, 8.477100, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3486, 4561.863769, -2907.444335, 8.477398, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3487, 4526.963378, -2905.449951, 8.148400, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3445, 4525.729003, -2873.862304, 4.541298, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3446, 4525.731445, -2845.506103, 4.952798, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3483, 4456.093750, -2907.414794, 8.475700, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3486, 4456.092285, -2877.114013, 8.477398, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3483, 4456.093261, -2846.847412, 8.475700, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3485, 4454.120605, -2814.676513, 8.477100, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3483, 4484.364746, -2812.711914, 8.475700, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3488, 4490.989257, -2905.448974, 8.007800, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3446, 4487.014160, -2837.105957, 4.952798, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3445, 4487.013671, -2855.618408, 4.541298, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3446, 4487.013671, -2874.130371, 4.952798, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3488, 4449.469726, -2954.677001, 8.007800, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3487, 4470.444335, -2954.677490, 8.148400, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3487, 4490.993164, -2954.676025, 8.148400, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3488, 4449.465332, -3045.449951, 8.007800, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3487, 4470.437500, -3045.448974, 8.148400, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3488, 4490.989746, -3045.449462, 8.007800, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3483, 4484.364746, -3013.193603, 8.475700, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3488, 4484.365722, -2987.559814, 8.007800, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3446, 4448.233398, -3013.863281, 4.952798, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3445, 4448.229980, -2985.125732, 4.541298, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3485, 4486.338867, -3200.448242, 8.477100, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3483, 4456.092773, -3202.448974, 8.475700, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3483, 4456.092773, -3172.164794, 8.475700, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3483, 4456.092773, -3141.880371, 8.475700, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3483, 4456.092773, -3111.596679, 8.475700, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3488, 4456.104980, -3088.046142, 8.007800, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3487, 4490.994628, -3094.677734, 8.148400, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3446, 4487.014160, -3121.057373, 4.952798, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3445, 4487.014160, -3139.566894, 4.541298, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3445, 4487.013183, -3157.010009, 4.541298, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3446, 4487.011718, -3174.355468, 4.952798, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3474, 3815.027832, -5886.913085, 12.353778, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3316, 4986.485351, -3096.292480, 4.861498, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3316, 4955.208984, -3090.055175, 4.861498, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3314, 4944.929199, -3120.906982, 2.516900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3315, 4979.818359, -3123.525878, 2.516900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3316, 4986.486816, -3173.793212, 4.861498, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3314, 4979.817871, -3209.109375, 2.516900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3315, 4953.022949, -3198.402343, 2.516900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3316, 4955.209472, -3167.555175, 4.861498, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3307, 4578.310058, -3090.991699, 2.986000, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3308, 4529.673828, -3090.992675, 2.986000, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3309, 4554.671386, -3090.991699, 2.986000, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3306, 4628.306152, -3090.991943, 2.986000, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3309, 4604.668457, -3090.993164, 2.986000, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3306, 4529.649414, -3126.633544, 2.986000, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3306, 4629.641113, -3126.632812, 2.986000, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3307, 4579.642089, -3126.632568, 2.986000, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3308, 4553.283203, -3126.633544, 2.986000, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3309, 4603.280761, -3126.632568, 2.986000, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3309, 4528.294433, -3204.133056, 2.986000, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3307, 4554.651855, -3204.132812, 2.986000, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3308, 4578.289062, -3204.133056, 2.986000, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3306, 4604.650390, -3204.132324, 2.986000, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3306, 4629.649414, -3204.131591, 2.986000, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3309, 4629.673828, -3168.490478, 2.986000, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3306, 4603.312500, -3168.491455, 2.986000, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3309, 4579.674316, -3168.490722, 2.986000, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3307, 4553.315917, -3168.491699, 2.986000, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3309, 4529.675781, -3168.491699, 2.986000, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(10945, 4931.845703, -4179.770996, 88.769676, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(4572, 4747.685546, -3339.547363, 31.628498, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(4585, 4901.469238, -3333.530761, 91.238403, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(4681, 4824.730957, -3351.601806, 11.473718, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(4586, 4736.430175, -3484.856933, 63.467800, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(10606, 4821.800292, -3020.229003, 10.285900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(7971, 4896.452636, -3016.346923, 6.295000, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(7520, 4905.864257, -3091.876464, 1.825000, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(7419, 4705.573242, -3387.400634, -4.747398, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3314, 5414.815429, -4541.605957, 2.516900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3315, 5425.521484, -4568.395996, 2.516900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3316, 5390.206542, -4575.050781, 4.861498, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3316, 5383.984375, -4543.787597, 4.861498, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3316, 5343.969726, -4568.824707, 4.861498, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3314, 5313.138183, -4571.008300, 2.516900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3315, 5302.431152, -4544.218261, 2.516900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3316, 5337.746093, -4537.562500, 4.861498, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3445, 5385.945312, -4452.000000, 4.533298, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3446, 5385.943847, -4470.513183, 4.948800, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3485, 5416.860839, -4430.483886, 8.471098, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3483, 5416.861816, -4400.206542, 8.471698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3487, 5381.966308, -4402.171875, 8.144398, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3486, 5416.861816, -4460.792968, 8.471400, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3483, 5418.827636, -4492.941406, 8.471698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3485, 5388.592773, -4494.915039, 8.471098, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3446, 5385.944335, -4433.487304, 4.948800, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3486, 5416.862304, -4260.224609, 8.471400, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3485, 5416.861816, -4290.484375, 8.471098, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3483, 5416.861328, -4320.774902, 8.471698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3486, 5418.806152, -4352.942382, 8.471400, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3485, 5386.619628, -4352.940429, 8.471098, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3488, 5381.968750, -4262.173828, 8.003800, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3446, 5385.944335, -4289.534179, 4.948800, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3445, 5385.944824, -4326.560058, 4.533298, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3445, 5385.945312, -4308.047363, 4.533298, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3485, 5416.859863, -4120.201660, 8.471098, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3483, 5416.861328, -4150.492675, 8.471698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3486, 5416.862304, -4180.794433, 8.471400, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3483, 5418.827148, -4212.942382, 8.471698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3485, 5386.619140, -4212.942382, 8.471098, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3487, 5381.968261, -4122.175292, 8.144398, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3446, 5385.944824, -4186.561035, 4.948800, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3446, 5385.943847, -4168.047363, 4.948800, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3446, 5385.945312, -4149.538085, 4.948800, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3485, 5263.833984, -4570.439941, 8.471098, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3483, 5233.542968, -4570.440429, 8.471698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3486, 5171.092773, -4572.390136, 8.471400, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3485, 5203.265136, -4570.442382, 8.471098, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3486, 5171.091796, -4540.175292, 8.471400, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3487, 5261.861816, -4535.548339, 8.144398, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3445, 5234.500488, -4539.525390, 4.533298, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3446, 5197.472167, -4539.524414, 4.948800, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3445, 5215.986328, -4539.523925, 4.533298, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3485, 5031.095703, -4572.413574, 8.471098, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3485, 5031.094238, -4540.199707, 8.471098, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3486, 5063.332519, -4570.444335, 8.471400, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3483, 5123.828613, -4570.441894, 8.471698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3485, 5093.551757, -4570.441406, 8.471098, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3488, 5121.861816, -4535.546386, 8.003800, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3446, 5057.473632, -4539.522949, 4.948800, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3445, 5075.986328, -4539.523925, 4.533298, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3446, 5094.499511, -4539.523925, 4.948800, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(7491, 5098.972167, -3382.805908, 3.962198, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(8260, 4900.805664, -3141.044921, 5.236198, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(8060, 4537.186523, -4446.790527, 6.491600, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(8255, 4464.644042, -4449.349121, 6.068099, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(8063, 4614.261718, -4508.826171, 5.225968, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(8059, 4582.810058, -4435.373046, 4.895898, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(8433, 4659.493164, -4269.045410, 6.033360, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(8841, 4618.705566, -4269.050781, 4.776350, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(8841, 4699.326660, -4269.050781, 4.776400, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(7696, 4890.990722, -3219.414062, 6.927598, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(4718, 4943.569824, -4069.964355, 22.064899, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(4593, 5265.346191, -3877.160888, 1.405900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(10763, 4822.691406, -3264.723144, 34.236999, 0.000000, 0.000000, -45.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(8038, 5036.119140, -3504.172119, 21.609319, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(12847, 4623.136718, -4431.339843, 5.816298, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(13562, 4616.535644, -4434.127929, 14.750780, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(18474, 4641.437988, -4471.659179, 4.201098, 0.000000, 0.000000, -52.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(18365, 4455.720703, -4253.660644, 10.335800, 0.000000, 0.000000, -45.500000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(18251, 4470.038085, -4473.374511, 9.215660, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(10830, 4611.704589, -4354.754882, 6.432600, 0.000000, 0.000000, -45.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(10775, 4481.317382, -4253.481933, 22.959199, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(10776, 4485.697265, -4352.744628, 12.339590, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(10811, 4523.706542, -4348.317382, 13.391960, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(10814, 4463.037597, -4404.109375, 5.524350, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(10814, 4609.077148, -4352.016113, 5.524350, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(10814, 4614.169433, -4355.865722, 5.524300, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(18245, 4457.027343, -4348.025878, 12.310359, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(10810, 4574.098144, -4510.561523, 6.214900, 0.000000, 0.000000, 110.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(10966, 4947.214355, -3869.395507, 15.123200, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(10965, 5039.239746, -3868.938476, 13.927900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(1682, 5037.291015, -3533.314941, 47.270061, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3873, 5036.216308, -3415.602050, 18.832130, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3873, 5036.216308, -3372.895751, 18.832099, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3873, 5036.216308, -3329.587158, 18.832099, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(9900, 4828.232421, -4216.791503, 137.593902, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(10165, 4828.164062, -4216.795410, 12.735198, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(10235, 4828.232421, -4216.791503, 12.736000, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(10166, 5654.016113, -3266.619384, -8.428198, 0.000000, 0.000000, -34.019981, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(9901, 4758.503417, -4148.424316, 27.057739, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(9950, 4792.779296, -4069.266113, 13.494898, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(10368, 5198.897460, -3851.613037, 22.001600, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(9582, 4559.442871, -4142.158203, 10.239700, 0.000000, 0.000000, -15.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(10398, 5104.203125, -4140.730957, 29.842399, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(9907, 4829.103027, -3982.349365, 91.414627, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(5409, 4608.582519, -4140.461425, 5.912878, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(9171, 5239.197265, -4069.798095, 4.598400, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(6873, 5052.569335, -4486.925781, 1.329200, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(6971, 5053.217285, -4441.065917, 1.591199, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3448, 5038.404296, -4457.746093, 1.710299, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3448, 5038.404296, -4457.746093, 6.009300, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3448, 5038.404296, -4457.746093, 10.309900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3448, 5038.404296, -4457.746093, 14.609700, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3448, 5038.404296, -4457.746093, 18.909200, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3448, 5038.404296, -4457.746093, 23.209199, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3448, 5038.404296, -4457.746093, 27.510400, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3448, 5038.404296, -4457.746093, 31.810600, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3448, 5038.404296, -4457.746093, 36.110500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3448, 5038.404296, -4457.746093, 40.410499, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(4007, 4965.483886, -3985.745849, 31.148199, 0.000000, 0.000000, 12.500000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(4602, 4891.755859, -3405.454101, 72.588127, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(10973, 5236.360839, -3996.070556, 9.400098, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(10974, 5236.360839, -4008.389892, 20.428649, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(10948, 4793.613281, -3874.715576, 63.707000, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(7973, 5103.068847, -4292.863281, 2.524899, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(7540, 5106.106445, -4292.405273, 1.621580, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(7943, 5133.726074, -4284.884277, 5.298590, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(6973, 5059.336914, -4442.066894, 60.240299, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(6976, 5015.400390, -4460.785156, 42.763980, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(4564, 4963.761718, -3393.525634, 110.763687, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(6871, 4922.921386, -3876.464599, 31.177900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19457, 4952.086914, -3920.328369, 15.881348, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19457, 4952.086914, -3910.694580, 15.881299, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19457, 4952.086914, -3901.060546, 15.881299, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19457, 4952.086914, -3891.426757, 15.881299, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19457, 4952.086914, -3881.793457, 15.881299, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(4006, 4970.919433, -3540.174804, 21.097520, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(8401, 5108.218750, -3559.990722, 4.169188, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(10982, 5080.416992, -3282.260986, 7.454988, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(6977, 4678.959472, -3349.074707, 1.471279, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(10982, 5034.837402, -3282.274658, 7.454988, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(10393, 4963.290039, -3333.046630, 10.529330, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(10995, 4951.542968, -3277.378906, 8.927788, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(10982, 4989.813476, -3282.275146, 7.454988, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(10952, 4819.703125, -3192.480468, 13.657698, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(10952, 4819.978515, -3097.347412, 13.657698, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(8068, 5039.932128, -4278.799804, 8.366100, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(9918, 4777.715332, -3983.254638, 21.635160, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(8034, 4687.774902, -3917.243896, 6.187170, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(8034, 4687.819335, -3827.723632, 6.187200, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(8841, 4687.930664, -3872.378906, 4.776400, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(8411, 5096.541503, -3472.863281, 4.175098, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(8516, 4548.493652, -3542.403076, 5.480480, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(8432, 4608.463867, -3543.091308, 5.480500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(8432, 4688.333007, -3542.288574, 5.480500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(7971, 4765.203613, -3550.041992, 6.327700, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(8432, 4549.198242, -3487.079345, 5.480500, 0.000000, 0.000000, 178.740066, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(8437, 4537.351562, -3285.235107, 7.509200, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(8300, 4623.142089, -3413.469238, 4.569550, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(4193, 4825.916503, -3412.537841, 15.721529, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(7985, 4736.327636, -3264.022216, 5.808128, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(8131, 4558.285156, -3280.093261, 11.973978, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(8034, 4674.961425, -3263.940673, 6.197770, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(7315, 4661.328613, -4058.547607, 21.465900, 0.800000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(7288, 4686.052246, -4058.519531, 1.526298, 0.000000, 90.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(4594, 4897.324218, -4296.855957, 1.486600, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(4028, 5040.111328, -4069.046386, 14.979200, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3988, 4763.777832, -4228.157226, 9.987488, 0.000000, 0.000000, 179.700012, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(10988, 4828.062500, -4280.434082, 9.371688, 0.000000, 0.000000, 90.299942, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(7491, 4589.224121, -3350.065673, 3.977600, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(10991, 4671.621093, -3480.563476, 9.745808, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(4048, 4966.090332, -3246.557373, 13.450400, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(10992, 5023.533203, -3236.811523, 7.459619, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(10992, 5057.931640, -3236.811523, 7.459599, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(4048, 5098.070312, -3243.434326, 13.450400, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(7658, 4538.465332, -3419.294677, 1.477120, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(7508, 4582.322753, -3408.640869, 5.124898, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(7708, 4587.705078, -3414.219726, 3.338200, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(8435, 4618.630371, -3485.616943, 5.423200, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(4570, 4689.105468, -3982.684570, 47.975631, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(6100, 4721.407226, -4203.782226, 25.693679, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(6157, 4906.720703, -3967.040039, 12.080200, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(6157, 4906.906738, -3995.562500, 12.080200, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(9950, 4579.635742, -4203.807617, 13.494898, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(6371, 4696.271484, -3186.174072, 32.787479, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(10995, 4745.028320, -3200.627929, 8.927800, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(10982, 4758.835449, -3163.158691, 7.450600, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(10982, 4774.286132, -3192.078369, 7.450600, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(6104, 4718.676269, -3092.566894, 5.491108, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(4113, 4967.829589, -4124.087402, 37.431331, 0.000000, 0.000000, 192.639831, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(5476, 4737.553222, -3113.496826, 9.052538, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(4048, 4669.801757, -3109.000976, 13.440299, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3312, 5026.484375, -3090.056884, 4.456799, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3311, 5076.473144, -3090.054199, 4.454400, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3313, 5051.483398, -3090.060058, 4.372798, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3310, 5101.479980, -3090.061767, 3.557698, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3313, 5126.483886, -3090.059326, 4.372798, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3312, 5126.469726, -3127.566650, 4.456799, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3313, 5101.474121, -3127.566406, 4.372798, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3310, 5051.472656, -3127.564453, 3.557698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3311, 5076.480468, -3127.572021, 4.454400, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3311, 5026.479492, -3127.573486, 4.454400, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3312, 5126.470214, -3205.065917, 4.456799, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3313, 5101.474121, -3205.065917, 4.372798, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3311, 5076.480468, -3205.065917, 4.454400, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3310, 5051.472656, -3205.065917, 3.557698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3311, 5026.479492, -3205.065917, 4.454400, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3313, 5126.484375, -3167.560058, 4.372798, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3310, 5101.479980, -3167.560058, 3.557698, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3311, 5076.473144, -3167.560058, 4.454400, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3313, 5051.483398, -3167.560058, 4.372798, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3312, 5026.484375, -3167.560058, 4.456799, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(10982, 5103.404296, -3319.121337, 7.454998, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(10982, 4525.178222, -3342.863037, 7.454998, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(8435, 4676.569824, -4206.704589, 5.423200, 0.000000, 0.000000, 90.240013, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(5732, 5326.481933, -4128.562988, 9.101698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(6151, 5314.197265, -4149.415527, 8.102700, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(17517, 5166.466796, -3915.294677, 4.591269, 0.000000, 0.000000, 179.519683, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(6159, 4820.072265, -4039.753906, 8.810680, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(6158, 4537.681640, -4276.106933, 6.844398, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(5168, 4535.052246, -4500.877441, 7.532198, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(6158, 5334.731933, -4196.887207, 6.837759, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(8675, 5303.538574, -4210.832031, 10.531608, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(6041, 5322.981933, -4337.196777, 9.434900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(6041, 5325.481445, -4274.829101, 9.436900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(6047, 5325.441406, -4404.964355, 9.663518, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(6047, 5326.119628, -4446.771972, 9.663518, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(6047, 5324.630371, -4488.460937, 9.663518, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19546, 5293.976562, -3950.058105, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 5293.976562, -4020.058837, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 5363.976562, -3950.058105, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19542, 5433.977050, -3950.058105, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19540, 5496.475097, -3950.058105, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19542, 5496.475097, -3872.559082, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 5496.475097, -3942.559082, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 5496.475097, -3802.559326, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19540, 5496.447265, -3795.093994, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19542, 5433.977050, -3795.059326, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 5363.976562, -3795.059326, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19539, 5325.226562, -3795.059326, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(6157, 5676.838378, -3711.912353, 11.934000, 0.000000, 0.000000, -135.600006, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(17533, 5330.366699, -3907.348144, 29.088499, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3432, 5096.922851, -3490.759277, 6.188468, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(11271, 4492.348632, -4396.581054, 8.008520, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3637, 4449.145507, -4477.989257, 9.378330, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3643, 4467.979003, -4298.452636, 15.697710, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3673, 4484.075683, -4361.118164, 29.238969, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3673, 4484.589355, -4347.082031, 29.238969, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3620, 4583.993652, -4459.946777, 14.452798, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19546, 4936.478515, -2907.563476, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19546, 4921.479003, -2907.563476, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19539, 4827.729003, -2907.563476, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19550, 4998.978027, -2580.064697, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19537, 4998.978027, -2688.812988, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19546, 4936.478515, -2720.063720, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19539, 4936.478515, -2813.813720, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19539, 5030.228515, -2720.063720, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19543, 4928.978515, -2611.312988, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19543, 4928.978515, -2548.812988, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19540, 5061.478027, -2720.063720, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19539, 5061.478027, -2688.812988, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 5061.478027, -2650.063720, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19542, 5061.478027, -2580.064697, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19540, 5061.478027, -2517.564453, 1.323500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19542, 4998.978027, -2517.564453, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 4928.978515, -2517.564453, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19540, 4921.479003, -2517.564453, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19542, 4921.479003, -2580.064697, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19542, 4921.479003, -2720.063720, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 4921.479003, -2650.063720, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19539, 4921.479003, -2813.813720, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(10831, 5045.035644, -2703.431884, 5.866700, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(10831, 5045.071777, -2673.493652, 5.866700, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(8059, 4952.727539, -2700.065673, 4.697948, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(8063, 4998.490722, -2703.159179, 5.018390, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(10810, 5076.055664, -2651.416015, 5.564660, 0.000000, 0.000000, -160.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(18248, 5052.328613, -2615.320312, 9.337988, 0.000000, 0.000000, -151.980010, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(5704, 4596.629394, -4058.495361, 13.748700, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(5299, 4914.755859, -2650.795898, 0.806729, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(5299, 4523.499511, -4410.770507, 0.930930, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3586, 4978.899414, -4002.246826, 4.980518, 0.000000, 0.000000, -107.500000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(9193, 4639.863769, -4166.904785, 6.299600, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(9193, 4639.827636, -4105.751464, 6.299600, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(7526, 5104.534667, -4039.439697, 3.793498, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(9193, 5277.876464, -4088.367187, 6.367578, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(9193, 5200.265136, -4086.040527, 6.367578, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19546, 4423.979980, -3217.562255, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 4353.979980, -3217.562255, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 4346.479980, -3225.062011, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19540, 4346.479980, -3217.562255, 1.323500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19539, 4346.479980, -3263.812500, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 4346.479980, -3302.562500, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19540, 4346.479980, -3310.061035, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 4353.979980, -3310.061035, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19546, 4501.479003, -3310.061035, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19539, 4392.729980, -3310.061035, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19541, 4431.479492, -3310.061035, 1.323500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(19539, 4501.479003, -3403.811279, 1.323500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(6099, 4464.782714, -3249.711181, 18.240299, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3626, 3652.373046, -5858.751464, 6.921400, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3627, 3641.478271, -5839.028320, 9.157910, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3626, 5028.458496, -2664.285156, 2.785000, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(966, 825.628417, -1847.999633, 11.803000, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(966, 847.570678, -1848.058959, 11.803000, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(968, 847.560485, -1848.051757, 12.520098, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(968, 825.598327, -1847.997924, 12.520098, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(1424, 823.970825, -1848.098022, 12.347318, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3627, 5303.742675, -3850.322998, 5.287020, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3627, 5325.077636, -3819.089843, 5.287000, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(3627, 5346.960937, -3850.322998, 5.287000, 0.000000, 0.000000, 180.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(966, 5356.201171, -3884.049316, 1.505699, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(1424, 5356.170898, -3875.576171, 2.048908, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(1424, 5353.355957, -3886.959960, 2.032560, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(968, 5356.207519, -3884.057373, 2.214798, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(11245, 4880.334472, -3526.016601, 9.277462, 0.000000, -29.400011, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(11245, 4880.334472, -3535.246826, 9.277462, 0.000000, -29.400011, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(11245, 4880.334472, -3544.526123, 9.277462, 0.000000, -29.400011, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(11245, 4880.334472, -3553.836914, 9.277462, 0.000000, -29.400011, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(11245, 4880.334472, -3563.086181, 9.277462, 0.000000, -29.400011, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(11245, 4880.334472, -3570.157226, 9.277462, 0.000000, -29.400011, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(11245, 4880.334472, -3498.240722, 9.277462, 0.000000, -29.400011, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(11245, 4880.334472, -3488.980224, 9.277462, 0.000000, -29.400011, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(11245, 4880.334472, -3479.771240, 9.277462, 0.000000, -29.400011, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(11245, 4880.334472, -3470.420166, 9.277462, 0.000000, -29.400011, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(11245, 4880.334472, -3461.139160, 9.277462, 0.000000, -29.400011, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(11245, 4880.334472, -3455.329589, 9.277462, 0.000000, -29.400011, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(1522, 4522.412109, -4507.770996, 1.624271, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(1522, 4520.904785, -4507.770996, 1.624271, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(1532, 5349.893554, -4108.340332, 1.492182, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(1569, 5207.693847, -4162.321777, 1.513136, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(1501, 4590.840332, -4147.407714, 1.450306, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(1522, 5116.260742, -4295.344726, 1.724455, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(1532, 4519.336425, -3416.091552, 1.486824, 0.000000, 0.000000, -90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(1522, 4817.299316, -3014.122558, 1.797150, 0.000000, 0.000000, -90.300086, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(1538, 5137.516601, -3270.802734, 1.506824, 0.000000, 0.000000, 90.000000, 0, 0, -1, 1000.00, 1000.00);
	tmpobjid = CreateDynamicObject(1538, 5041.316406, -3579.307128, 1.533543, 0.000000, 0.000000, 0.000000, 0, 0, -1, 1000.00, 1000.00);
	// LITTLE
	tmpobjid = CreateDynamicObject(982, 5384.451660, -3795.105712, 1.989050, 0.000000, 180.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(967, 5372.814941, -3886.665039, 1.296759, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 14668, "711c", "CJ_CHIP_M2", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 14668, "711c", "CJ_CHIP_M2", 0x00000000);
	tmpobjid = CreateDynamicObject(8650, 5138.569824, -3825.319335, 2.624598, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	tmpobjid = CreateDynamicObject(8650, 5122.925781, -3810.465087, 2.624598, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	tmpobjid = CreateDynamicObject(8650, 5092.425292, -3810.465087, 2.624598, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	tmpobjid = CreateDynamicObject(8650, 5356.063964, -3825.324707, 2.624598, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	tmpobjid = CreateDynamicObject(8650, 5356.067871, -3855.816894, 2.624598, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	tmpobjid = CreateDynamicObject(8650, 5339.191894, -3810.468017, 2.624598, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	tmpobjid = CreateDynamicObject(8650, 5309.240234, -3810.465332, 2.624598, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	tmpobjid = CreateDynamicObject(7922, 5355.449707, -3811.232910, 2.335400, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	tmpobjid = CreateDynamicObject(7922, 5295.146972, -3811.085693, 2.335400, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	tmpobjid = CreateDynamicObject(8650, 5294.374023, -3827.354248, 2.624598, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	tmpobjid = CreateDynamicObject(8650, 5294.374023, -3857.854003, 2.624598, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	tmpobjid = CreateDynamicObject(967, 5294.735839, -3886.946289, 1.509400, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 14668, "711c", "CJ_CHIP_M2", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 14668, "711c", "CJ_CHIP_M2", 0x00000000);
	tmpobjid = CreateDynamicObject(8657, 3879.056396, -5858.473632, 6.653698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall01", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall01", 0x00000000);
	tmpobjid = CreateDynamicObject(8657, 3879.051513, -5883.933105, 6.653698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall01", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall01", 0x00000000);
	tmpobjid = CreateDynamicObject(8657, 3862.935791, -5898.808105, 6.653698, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall01", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall01", 0x00000000);
	tmpobjid = CreateDynamicObject(8657, 3831.929443, -5898.808105, 6.653698, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall01", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall01", 0x00000000);
	tmpobjid = CreateDynamicObject(8657, 3800.925292, -5898.808105, 6.653698, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall01", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall01", 0x00000000);
	tmpobjid = CreateDynamicObject(8657, 3769.918945, -5898.808105, 6.653698, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall01", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall01", 0x00000000);
	tmpobjid = CreateDynamicObject(8657, 3738.914550, -5898.808105, 6.653698, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall01", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall01", 0x00000000);
	tmpobjid = CreateDynamicObject(8657, 3707.908691, -5898.808105, 6.653698, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall01", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall01", 0x00000000);
	tmpobjid = CreateDynamicObject(8657, 3676.903320, -5898.808105, 6.653698, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall01", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall01", 0x00000000);
	tmpobjid = CreateDynamicObject(8657, 3645.901123, -5898.808105, 6.653698, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall01", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall01", 0x00000000);
	tmpobjid = CreateDynamicObject(8657, 3630.202636, -5883.935058, 6.653698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall01", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall01", 0x00000000);
	tmpobjid = CreateDynamicObject(8657, 3630.202636, -5852.929199, 6.653698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall01", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall01", 0x00000000);
	tmpobjid = CreateDynamicObject(8657, 3630.202636, -5821.925781, 6.653698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall01", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall01", 0x00000000);
	tmpobjid = CreateDynamicObject(8657, 3630.202636, -5790.918457, 6.653698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall01", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall01", 0x00000000);
	tmpobjid = CreateDynamicObject(8657, 3645.092285, -5774.991210, 6.653698, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall01", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall01", 0x00000000);
	tmpobjid = CreateDynamicObject(8657, 3676.098876, -5774.991210, 6.653698, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall01", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall01", 0x00000000);
	tmpobjid = CreateDynamicObject(8657, 3707.105957, -5774.991210, 6.653698, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall01", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall01", 0x00000000);
	tmpobjid = CreateDynamicObject(8657, 3738.112304, -5774.991210, 6.653698, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall01", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall01", 0x00000000);
	tmpobjid = CreateDynamicObject(8657, 3769.118164, -5774.991210, 6.653698, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall01", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall01", 0x00000000);
	tmpobjid = CreateDynamicObject(8657, 3800.124267, -5774.991210, 6.653698, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall01", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall01", 0x00000000);
	tmpobjid = CreateDynamicObject(8657, 3831.127929, -5774.991210, 6.653698, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall01", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall01", 0x00000000);
	tmpobjid = CreateDynamicObject(8657, 3864.023437, -5774.991210, 6.653698, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall01", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall01", 0x00000000);
	tmpobjid = CreateDynamicObject(8657, 3879.056396, -5815.466796, 6.653698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall01", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall01", 0x00000000);
	tmpobjid = CreateDynamicObject(8657, 3879.042480, -5790.014160, 6.653698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall01", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall01", 0x00000000);
	tmpobjid = CreateDynamicObject(18765, 4898.876953, -3512.418945, 0.670260, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(18763, 4898.876953, -3512.418945, 3.309000, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(7922, 4517.656250, -3951.088623, 2.488698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	tmpobjid = CreateDynamicObject(7922, 4517.512207, -4011.384765, 2.488698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	tmpobjid = CreateDynamicObject(8650, 4516.884765, -3965.379150, 2.628900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	tmpobjid = CreateDynamicObject(8650, 4516.882812, -3994.958007, 2.628900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	tmpobjid = CreateDynamicObject(8650, 4534.083007, -3950.462890, 2.628900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	tmpobjid = CreateDynamicObject(8650, 4564.583984, -3950.462890, 2.628900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	tmpobjid = CreateDynamicObject(8650, 4595.084472, -3950.462890, 2.628900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	tmpobjid = CreateDynamicObject(8650, 4625.534179, -3950.462890, 2.628900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	tmpobjid = CreateDynamicObject(7922, 4640.451171, -3951.224365, 2.488698, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	tmpobjid = CreateDynamicObject(8650, 4641.068847, -3965.389648, 2.628900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	tmpobjid = CreateDynamicObject(8650, 4533.770019, -4012.146728, 2.628900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	tmpobjid = CreateDynamicObject(8650, 4623.870117, -4012.144287, 2.628900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	tmpobjid = CreateDynamicObject(8650, 4641.068847, -3995.890625, 2.628900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	tmpobjid = CreateDynamicObject(7922, 4640.304199, -4011.531005, 2.488698, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	tmpobjid = CreateDynamicObject(14467, 5666.634765, -3597.181152, 3.880300, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	tmpobjid = CreateDynamicObject(18762, 5278.477539, -3377.982666, 1.952100, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	tmpobjid = CreateDynamicObject(18762, 5174.480957, -3000.562744, 1.952100, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	tmpobjid = CreateDynamicObject(18762, 5185.674804, -3000.572509, 1.942100, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	tmpobjid = CreateDynamicObject(18762, 5231.974609, -2830.562988, 1.942100, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	tmpobjid = CreateDynamicObject(8040, 5238.949218, -4211.448242, 2.252099, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	tmpobjid = CreateDynamicObject(8650, 5154.377929, -4212.459472, 2.624598, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	tmpobjid = CreateDynamicObject(8650, 5171.265136, -4229.652832, 2.624598, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	tmpobjid = CreateDynamicObject(8650, 5154.377929, -4181.958496, 2.624598, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	tmpobjid = CreateDynamicObject(8650, 5154.377929, -4151.459472, 2.624598, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	tmpobjid = CreateDynamicObject(8650, 5154.377929, -4120.960449, 2.624598, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	tmpobjid = CreateDynamicObject(7922, 5155.006347, -4228.884277, 2.335400, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	tmpobjid = CreateDynamicObject(7922, 5155.149414, -4106.080078, 2.335400, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	tmpobjid = CreateDynamicObject(8650, 5171.574707, -4105.455078, 2.624598, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	tmpobjid = CreateDynamicObject(8650, 5202.075195, -4105.455078, 2.624598, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	tmpobjid = CreateDynamicObject(8650, 5232.574218, -4105.455078, 2.624598, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	tmpobjid = CreateDynamicObject(8650, 5263.073242, -4105.455078, 2.624598, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	tmpobjid = CreateDynamicObject(7922, 5277.951171, -4106.227539, 2.335400, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	tmpobjid = CreateDynamicObject(8650, 5278.568359, -4122.659179, 2.624598, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	tmpobjid = CreateDynamicObject(8650, 5278.568359, -4153.159179, 2.624598, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	tmpobjid = CreateDynamicObject(8650, 5278.571777, -4167.983398, 2.622600, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	tmpobjid = CreateDynamicObject(968, 5278.655761, -4185.339355, 2.095798, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	tmpobjid = CreateDynamicObject(19545, 5204.013183, -3403.836181, 1.363499, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10385, "baseballground_sfs", "ws_football_lines2", 0x00000000);
	tmpobjid = CreateDynamicObject(19545, 5189.015136, -3355.518310, 1.363499, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10385, "baseballground_sfs", "ws_football_lines2", 0x00000000);
	tmpobjid = CreateDynamicObject(19545, 5183.732421, -3049.675537, 1.363499, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10385, "baseballground_sfs", "ws_football_lines2", 0x00000000);
	tmpobjid = CreateDynamicObject(19545, 5189.015136, -3293.018798, 1.363499, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10385, "baseballground_sfs", "ws_football_lines2", 0x00000000);
	tmpobjid = CreateDynamicObject(19545, 5189.015136, -3230.520019, 1.363499, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10385, "baseballground_sfs", "ws_football_lines2", 0x00000000);
	tmpobjid = CreateDynamicObject(19545, 5189.015136, -3168.021728, 1.363499, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10385, "baseballground_sfs", "ws_football_lines2", 0x00000000);
	tmpobjid = CreateDynamicObject(19545, 5189.015136, -3105.522705, 1.363499, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10385, "baseballground_sfs", "ws_football_lines2", 0x00000000);
	tmpobjid = CreateDynamicObject(19545, 5189.015136, -3088.423828, 1.359500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10385, "baseballground_sfs", "ws_football_lines2", 0x00000000);
	tmpobjid = CreateDynamicObject(8650, 3968.580810, -4200.106933, 2.421798, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	tmpobjid = CreateDynamicObject(8650, 3968.580810, -4230.606445, 2.421798, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	tmpobjid = CreateDynamicObject(8650, 3968.580810, -4261.106933, 2.421798, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	tmpobjid = CreateDynamicObject(8650, 3968.580810, -4291.607421, 2.421798, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	tmpobjid = CreateDynamicObject(7922, 3967.816650, -4306.533691, 2.135200, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	tmpobjid = CreateDynamicObject(8650, 3951.381347, -4307.147949, 2.421798, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	tmpobjid = CreateDynamicObject(8650, 3920.881591, -4307.147949, 2.421798, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	tmpobjid = CreateDynamicObject(8650, 3890.381835, -4307.147949, 2.421798, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	tmpobjid = CreateDynamicObject(8650, 3859.881835, -4307.147949, 2.421798, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	tmpobjid = CreateDynamicObject(7922, 3845.008789, -4306.389160, 2.135200, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	tmpobjid = CreateDynamicObject(8650, 3844.381591, -4289.961914, 2.421798, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	tmpobjid = CreateDynamicObject(8650, 3844.381591, -4259.462890, 2.421798, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	tmpobjid = CreateDynamicObject(8650, 3968.580810, -4150.031738, 2.421798, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	tmpobjid = CreateDynamicObject(8650, 3968.575195, -4120.389160, 2.419800, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	tmpobjid = CreateDynamicObject(7922, 3967.956298, -4106.227539, 2.135200, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	tmpobjid = CreateDynamicObject(8650, 3951.689208, -4105.454589, 2.419800, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	tmpobjid = CreateDynamicObject(8650, 3921.189941, -4105.454589, 2.419800, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	tmpobjid = CreateDynamicObject(8650, 3890.690673, -4105.454589, 2.419800, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	tmpobjid = CreateDynamicObject(8650, 3860.191650, -4105.454589, 2.419800, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	tmpobjid = CreateDynamicObject(7922, 3845.124511, -4106.072265, 2.135200, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	tmpobjid = CreateDynamicObject(8650, 3844.351318, -4122.337890, 2.419800, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	SetDynamicObjectMaterial(tmpobjid, 1, 10101, "2notherbuildsfe", "sl_vicwall02", 0x00000000);
	tmpobjid = CreateDynamicObject(18766, 3942.648681, -4250.468261, -0.556909, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(18766, 3942.648681, -4240.468750, -0.556900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(18766, 3942.648681, -4230.469726, -0.556900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(18766, 3942.648681, -4220.471191, -0.556900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(18766, 3942.648681, -4210.472167, -0.556900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(18766, 3942.648681, -4200.474121, -0.556900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(18766, 3942.646972, -4197.967773, -0.552900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(18766, 3938.146484, -4192.467773, -0.556900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(18766, 3928.147705, -4192.467773, -0.556900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(18766, 3918.148681, -4192.467773, -0.556900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(18766, 3912.648681, -4196.967285, -0.556900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(18766, 3912.648681, -4206.966308, -0.556900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(18766, 3912.648681, -4216.964355, -0.556900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(18766, 3912.648681, -4226.963867, -0.556900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(18766, 3912.648681, -4236.962890, -0.556900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(18766, 3912.648681, -4246.962402, -0.556900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(18766, 3912.650634, -4250.469726, -0.552900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(18766, 3917.149902, -4255.968261, -0.556900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(18766, 3927.150146, -4255.968261, -0.556900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(18766, 3937.150390, -4255.968261, -0.556900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(18766, 3938.147216, -4255.965820, -0.552900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 9514, "711_sfw", "ws_carpark2", 0x00000000);
	tmpobjid = CreateDynamicObject(19463, 4661.435546, -4088.136962, 2.990900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 1613, "alleyprop", "stuffdirtcol", 0x00000000);
	tmpobjid = CreateDynamicObject(19463, 4661.435546, -4088.136962, 6.501440, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 1613, "alleyprop", "stuffdirtcol", 0x00000000);
	tmpobjid = CreateDynamicObject(19463, 4661.435546, -4088.136962, 9.953680, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 1613, "alleyprop", "stuffdirtcol", 0x00000000);
	tmpobjid = CreateDynamicObject(19463, 4661.435546, -4086.823242, 3.006020, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 1613, "alleyprop", "stuffdirtcol", 0x00000000);
	tmpobjid = CreateDynamicObject(19463, 4661.435546, -4086.823242, 6.498178, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 1613, "alleyprop", "stuffdirtcol", 0x00000000);
	tmpobjid = CreateDynamicObject(19463, 4661.435546, -4086.823242, 9.975238, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 1613, "alleyprop", "stuffdirtcol", 0x00000000);
	tmpobjid = CreateDynamicObject(19463, 4660.932617, -4084.223876, 1.884050, 0.000000, 66.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 1613, "alleyprop", "stuffdirtcol", 0x00000000);
	tmpobjid = CreateDynamicObject(19463, 4660.943847, -4080.911376, 3.253400, 0.000000, 70.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 1613, "alleyprop", "stuffdirtcol", 0x00000000);
	tmpobjid = CreateDynamicObject(19463, 4660.936035, -4077.554199, 4.152598, 0.000000, 80.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 1613, "alleyprop", "stuffdirtcol", 0x00000000);
	tmpobjid = CreateDynamicObject(19463, 4660.923339, -4074.091308, 4.621900, 0.000000, 85.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 1613, "alleyprop", "stuffdirtcol", 0x00000000);
	tmpobjid = CreateDynamicObject(19463, 4660.953613, -4070.569335, 4.933198, 0.000000, 85.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 1613, "alleyprop", "stuffdirtcol", 0x00000000);
	tmpobjid = CreateDynamicObject(19463, 4660.944824, -4067.086425, 5.032898, 0.000000, 94.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 1613, "alleyprop", "stuffdirtcol", 0x00000000);
	tmpobjid = CreateDynamicObject(19463, 4660.946289, -4063.602783, 4.722660, 0.000000, 95.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 1613, "alleyprop", "stuffdirtcol", 0x00000000);
	tmpobjid = CreateDynamicObject(19463, 4660.913085, -4060.158447, 4.294898, 0.000000, 100.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 1613, "alleyprop", "stuffdirtcol", 0x00000000);
	tmpobjid = CreateDynamicObject(19463, 4660.880859, -4056.745605, 3.689218, 0.000000, 100.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 1613, "alleyprop", "stuffdirtcol", 0x00000000);
	tmpobjid = CreateDynamicObject(19463, 4660.841796, -4053.311279, 3.097538, 0.000000, 100.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 1613, "alleyprop", "stuffdirtcol", 0x00000000);
	tmpobjid = CreateDynamicObject(19463, 4665.330566, -4046.725341, 6.710790, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 1613, "alleyprop", "stuffdirtcol", 0x00000000);
	tmpobjid = CreateDynamicObject(19463, 4665.330566, -4046.725341, 3.277400, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 1613, "alleyprop", "stuffdirtcol", 0x00000000);
	tmpobjid = CreateDynamicObject(19463, 4665.345214, -4037.125732, 3.277400, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 1613, "alleyprop", "stuffdirtcol", 0x00000000);
	tmpobjid = CreateDynamicObject(19463, 4665.345214, -4037.125732, 6.708250, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 1613, "alleyprop", "stuffdirtcol", 0x00000000);
	tmpobjid = CreateDynamicObject(19463, 4665.382812, -4032.768310, 3.277400, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 16644, "a51_detailstuff", "roucghstonebrtb", 0x00000000);
	tmpobjid = CreateDynamicObject(19463, 4665.382812, -4032.768310, 6.708300, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 16644, "a51_detailstuff", "roucghstonebrtb", 0x00000000);
	tmpobjid = CreateDynamicObject(19463, 4661.217773, -4027.979492, 3.277400, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 16644, "a51_detailstuff", "roucghstonebrtb", 0x00000000);
	tmpobjid = CreateDynamicObject(19463, 4661.217773, -4027.979492, 6.708300, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 16644, "a51_detailstuff", "roucghstonebrtb", 0x00000000);
	tmpobjid = CreateDynamicObject(19463, 4657.312011, -4032.645019, 3.277400, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 16644, "a51_detailstuff", "roucghstonebrtb", 0x00000000);
	tmpobjid = CreateDynamicObject(19463, 4657.312011, -4032.645019, 6.708300, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 16644, "a51_detailstuff", "roucghstonebrtb", 0x00000000);
	tmpobjid = CreateDynamicObject(19463, 4657.310546, -4042.262207, 3.277400, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 1613, "alleyprop", "stuffdirtcol", 0x00000000);
	tmpobjid = CreateDynamicObject(19463, 4657.310546, -4042.262207, 6.708300, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 1613, "alleyprop", "stuffdirtcol", 0x00000000);
	tmpobjid = CreateDynamicObject(19463, 4657.232421, -4047.105468, 3.277400, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 1613, "alleyprop", "stuffdirtcol", 0x00000000);
	tmpobjid = CreateDynamicObject(19463, 4657.232421, -4047.105468, 6.708300, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 1613, "alleyprop", "stuffdirtcol", 0x00000000);
	tmpobjid = CreateDynamicObject(19463, 4657.181152, -4056.724609, 5.511929, -10.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 1613, "alleyprop", "stuffdirtcol", 0x00000000);
	tmpobjid = CreateDynamicObject(19463, 4665.442871, -4056.724609, 8.843798, -10.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 1613, "alleyprop", "stuffdirtcol", 0x00000000);
	tmpobjid = CreateDynamicObject(19463, 4656.927734, -4066.359375, 6.989270, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 1613, "alleyprop", "stuffdirtcol", 0x00000000);
	tmpobjid = CreateDynamicObject(19463, 4656.927734, -4066.359375, 9.890258, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 1613, "alleyprop", "stuffdirtcol", 0x00000000);
	tmpobjid = CreateDynamicObject(19463, 4657.031250, -4075.882812, 6.249410, 10.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 1613, "alleyprop", "stuffdirtcol", 0x00000000);
	tmpobjid = CreateDynamicObject(19463, 4657.031250, -4075.882812, 9.668918, 10.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 1613, "alleyprop", "stuffdirtcol", 0x00000000);
	tmpobjid = CreateDynamicObject(19463, 4656.233886, -4083.401367, 4.614058, 20.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 1613, "alleyprop", "stuffdirtcol", 0x00000000);
	tmpobjid = CreateDynamicObject(19463, 4656.233886, -4083.401367, 8.212598, 20.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 1613, "alleyprop", "stuffdirtcol", 0x00000000);
	tmpobjid = CreateDynamicObject(19463, 4665.442871, -4055.884765, 5.511929, -10.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 1613, "alleyprop", "stuffdirtcol", 0x00000000);
	tmpobjid = CreateDynamicObject(19463, 4657.181152, -4056.724609, 8.843798, -10.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 1613, "alleyprop", "stuffdirtcol", 0x00000000);
	tmpobjid = CreateDynamicObject(19463, 4665.442871, -4066.359375, 6.989298, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 1613, "alleyprop", "stuffdirtcol", 0x00000000);
	tmpobjid = CreateDynamicObject(19463, 4665.442871, -4066.359375, 9.890298, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 1613, "alleyprop", "stuffdirtcol", 0x00000000);
	tmpobjid = CreateDynamicObject(19463, 4665.442871, -4075.882812, 9.668898, 10.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 1613, "alleyprop", "stuffdirtcol", 0x00000000);
	tmpobjid = CreateDynamicObject(19463, 4665.442871, -4075.882812, 6.249400, 10.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 1613, "alleyprop", "stuffdirtcol", 0x00000000);
	tmpobjid = CreateDynamicObject(19463, 4665.442871, -4083.401367, 4.614099, 20.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 1613, "alleyprop", "stuffdirtcol", 0x00000000);
	tmpobjid = CreateDynamicObject(19463, 4665.442871, -4083.401367, 8.212598, 20.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 1613, "alleyprop", "stuffdirtcol", 0x00000000);
	tmpobjid = CreateDynamicObject(19463, 4660.932617, -4084.223876, 9.746470, 0.000000, 66.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 1613, "alleyprop", "stuffdirtcol", 0x00000000);
	tmpobjid = CreateDynamicObject(19463, 4660.943847, -4080.911376, 11.037388, 0.000000, 70.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 1613, "alleyprop", "stuffdirtcol", 0x00000000);
	tmpobjid = CreateDynamicObject(19463, 4660.936035, -4077.554199, 11.752128, 0.000000, 80.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 1613, "alleyprop", "stuffdirtcol", 0x00000000);
	tmpobjid = CreateDynamicObject(19463, 4660.923339, -4074.091308, 11.900178, 0.000000, 85.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 1613, "alleyprop", "stuffdirtcol", 0x00000000);
	tmpobjid = CreateDynamicObject(19463, 4660.953613, -4070.569335, 12.058910, 0.000000, 85.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 1613, "alleyprop", "stuffdirtcol", 0x00000000);
	tmpobjid = CreateDynamicObject(19463, 4660.944824, -4067.086425, 11.971328, 0.000000, 94.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 16644, "a51_detailstuff", "roucghstonebrtb", 0x00000000);
	tmpobjid = CreateDynamicObject(19463, 4660.946289, -4063.602783, 11.797328, 0.000000, 95.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 16644, "a51_detailstuff", "roucghstonebrtb", 0x00000000);
	tmpobjid = CreateDynamicObject(19463, 4660.913085, -4060.158447, 11.394908, 0.000000, 100.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 16644, "a51_detailstuff", "roucghstonebrtb", 0x00000000);
	tmpobjid = CreateDynamicObject(19463, 4660.880859, -4056.745605, 10.787590, 0.000000, 100.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 16644, "a51_detailstuff", "roucghstonebrtb", 0x00000000);
	tmpobjid = CreateDynamicObject(19463, 4660.841796, -4053.311279, 10.056710, 0.000000, 100.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 16644, "a51_detailstuff", "roucghstonebrtb", 0x00000000);
	tmpobjid = CreateDynamicObject(19463, 4661.136230, -4049.978759, 8.657230, 0.000000, 90.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 16644, "a51_detailstuff", "roucghstonebrtb", 0x00000000);
	tmpobjid = CreateDynamicObject(19463, 4661.109863, -4046.510009, 8.657230, 0.000000, 90.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 16644, "a51_detailstuff", "roucghstonebrtb", 0x00000000);
	tmpobjid = CreateDynamicObject(19463, 4661.080078, -4042.967041, 8.657230, 0.000000, 90.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 16644, "a51_detailstuff", "roucghstonebrtb", 0x00000000);
	tmpobjid = CreateDynamicObject(19463, 4661.064941, -4039.495605, 8.657230, 0.000000, 90.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 16644, "a51_detailstuff", "roucghstonebrtb", 0x00000000);
	tmpobjid = CreateDynamicObject(19463, 4661.171386, -4035.980468, 8.657230, 0.000000, 90.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 16644, "a51_detailstuff", "roucghstonebrtb", 0x00000000);
	tmpobjid = CreateDynamicObject(19463, 4661.193847, -4032.573730, 8.657230, 0.000000, 90.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 16644, "a51_detailstuff", "roucghstonebrtb", 0x00000000);
	tmpobjid = CreateDynamicObject(19463, 4661.211914, -4029.549316, 8.657230, 0.000000, 90.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 16644, "a51_detailstuff", "roucghstonebrtb", 0x00000000);
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	tmpobjid = CreateDynamicObject(982, 5410.105468, -3795.101318, 1.989099, 0.000000, 180.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(982, 5435.746093, -3795.092529, 1.989099, 0.000000, 180.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(982, 5461.383789, -3795.098388, 1.989099, 0.000000, 180.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(982, 5483.744140, -3795.091552, 1.989099, 0.000000, 180.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(982, 5496.443359, -3808.015136, 1.989099, 0.000000, 180.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(982, 5496.443359, -3833.689453, 1.989099, 0.000000, 180.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(982, 5496.433593, -3859.504150, 1.989099, 0.000000, 180.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(982, 5496.430175, -3885.436523, 1.989099, 0.000000, 180.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(982, 5496.418457, -3911.347412, 1.989099, 0.000000, 180.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(982, 5496.416992, -3937.178710, 1.989099, 0.000000, 180.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(982, 5483.579101, -3950.024414, 1.989099, 0.000000, 180.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(982, 5461.203613, -3950.024414, 1.989099, 0.000000, 180.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(982, 5435.582519, -3950.024414, 1.989099, 0.000000, 180.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(982, 5409.961425, -3950.024414, 1.989099, 0.000000, 180.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(982, 5384.334472, -3950.024414, 1.989099, 0.000000, 180.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(982, 5371.648437, -3937.193115, 1.989099, 0.000000, 180.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(982, 5371.668945, -3911.578125, 1.989099, 0.000000, 180.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(982, 5371.648437, -3807.906005, 1.989099, 0.000000, 180.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(982, 5371.648437, -3833.544677, 1.989099, 0.000000, 180.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(982, 5371.648437, -3859.202392, 1.989099, 0.000000, 180.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(984, 5371.671386, -3892.345703, 2.033900, 0.000000, 180.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(983, 5371.648437, -3875.219482, 1.989099, 0.000000, 180.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(966, 5371.967285, -3885.481933, 1.308529, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(968, 5371.960449, -3885.537353, 1.935570, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(11099, 5415.979003, -3877.253662, 1.327749, 0.000000, 0.000000, -19.320030, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5380.681640, -3889.916503, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5380.661132, -3894.454589, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5380.992187, -3902.920166, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5380.554199, -3898.560302, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5382.241210, -3906.657714, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5385.062011, -3909.483398, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5388.924316, -3911.270507, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5393.833007, -3911.632080, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5396.645507, -3914.784912, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5386.833984, -3889.861328, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5386.857421, -3894.271240, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5387.041503, -3898.446777, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5388.375976, -3902.623779, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5391.451171, -3904.769531, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5395.560546, -3905.891845, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5399.345703, -3907.303466, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5401.708496, -3909.585693, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5398.147460, -3918.077880, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5396.878417, -3921.818603, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5394.376953, -3924.503906, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5403.670410, -3913.663085, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5403.931152, -3918.251220, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5402.837402, -3922.506103, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5400.476562, -3926.548095, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5397.865234, -3929.745849, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5391.519042, -3926.855224, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5390.047363, -3930.105224, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5389.622070, -3933.366943, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5389.627441, -3936.996093, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5390.875976, -3940.963623, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5394.031250, -3944.424316, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5396.783691, -3932.167236, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5397.169921, -3935.514160, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5399.111328, -3938.523437, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5398.223144, -3946.367919, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5403.175292, -3947.296630, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5403.186035, -3940.190917, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5403.186035, -3940.190917, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(19970, 5379.386230, -3888.773437, 1.233150, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(19983, 5370.690917, -3878.554931, 1.314399, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(19967, 5404.640136, -3939.679931, 1.215700, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5421.627929, -3947.151611, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5421.650878, -3939.910156, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5427.416503, -3947.162597, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5432.823242, -3947.165527, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5438.333007, -3947.173583, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5443.458007, -3947.291748, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5449.617187, -3947.569091, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5460.640136, -3947.617919, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5456.020996, -3947.622314, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5449.708984, -3940.193359, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5444.706054, -3939.906494, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5427.437011, -3940.203369, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5432.586914, -3939.947753, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(19967, 5404.535156, -3947.783447, 1.215700, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5466.503906, -3947.481445, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5472.343750, -3947.383056, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5472.294433, -3939.486816, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5466.358886, -3939.510742, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5461.062011, -3939.654785, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5461.017578, -3936.526123, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5460.960937, -3932.814453, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5456.122558, -3932.694580, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5450.124511, -3932.662353, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5444.523925, -3932.576416, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5438.952148, -3939.650878, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5444.650878, -3936.313964, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5453.242675, -3939.901611, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(19967, 5473.491699, -3947.169189, 1.215700, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(19967, 5473.526367, -3939.329101, 1.215700, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5481.088378, -3914.203857, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5491.579589, -3924.646972, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5481.143554, -3924.607666, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5490.868164, -3914.198974, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5490.595214, -3903.852783, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5481.372558, -3903.800292, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5489.719238, -3893.390869, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5481.941406, -3893.349121, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5489.721679, -3883.029785, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5481.973632, -3882.936279, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5482.094238, -3872.531494, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5489.793457, -3872.529296, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5489.866210, -3862.159912, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5482.215332, -3862.142333, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5482.428222, -3851.791015, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5489.878906, -3851.678466, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5489.798828, -3841.201171, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5482.402832, -3841.314697, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5489.562500, -3830.913085, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5482.458496, -3830.851074, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(19425, 5485.930664, -3830.657470, 1.313598, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(19425, 5485.934082, -3830.451904, 1.373600, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(19425, 5485.940917, -3830.259277, 1.313598, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5489.588867, -3823.719726, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5482.393066, -3823.741210, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5482.270019, -3817.433593, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5489.579589, -3817.346679, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5489.640136, -3811.831298, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5489.653320, -3806.117187, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5482.285156, -3796.948242, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5482.263183, -3811.958740, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5482.140136, -3806.012207, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5489.827148, -3801.271972, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5489.968750, -3797.526123, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5485.971679, -3797.030761, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5477.916503, -3796.897460, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5472.553710, -3796.788818, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5477.971679, -3805.647216, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5472.674804, -3805.782714, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(19967, 5471.762695, -3796.934326, 1.215700, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(19967, 5471.666992, -3805.644042, 1.215700, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5427.229980, -3808.462402, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5427.472656, -3801.668701, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5419.250976, -3801.563476, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5419.049316, -3808.187255, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5406.944335, -3808.035400, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5412.046875, -3808.255371, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5412.500000, -3801.491699, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5407.218750, -3801.437255, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5401.858398, -3807.982910, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5401.992675, -3801.310546, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5395.819335, -3801.008789, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5389.929687, -3800.921875, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5384.379882, -3800.763427, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5378.547851, -3803.448730, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5376.619628, -3809.212890, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5379.141601, -3813.778808, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5396.354492, -3808.089355, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5390.425292, -3807.698242, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5386.321289, -3807.807128, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5385.546875, -3815.155761, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5391.775878, -3815.387207, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5398.321289, -3815.428955, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5405.296386, -3815.621337, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5411.770019, -3815.405273, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5419.232910, -3815.154296, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5426.973632, -3815.125732, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5434.294433, -3813.968261, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(19967, 5434.638183, -3813.400390, 1.215700, 0.000000, 0.000000, -226.859603, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5444.376953, -3830.956542, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5451.277832, -3831.165039, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5451.277832, -3831.165039, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5444.418945, -3837.379882, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5451.205078, -3837.252441, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(19817, 5447.716796, -3843.288085, 0.788730, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(19817, 5447.700683, -3852.932617, 0.788698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5451.467285, -3843.615234, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5444.152343, -3842.882324, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5444.321289, -3855.269287, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5450.504394, -3855.408203, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5450.583984, -3860.941406, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5444.411132, -3860.908203, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5444.337890, -3865.160888, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5450.623535, -3865.290527, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5450.645019, -3867.815673, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5450.665527, -3870.155029, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5447.352050, -3870.438720, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5444.476562, -3870.453613, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(19967, 5443.897949, -3871.057861, 1.215700, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(19967, 5443.704589, -3865.140136, 1.215700, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(19817, 5423.227539, -3862.057861, 1.248370, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(19872, 5415.810058, -3862.065185, 1.248399, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(19872, 5410.577636, -3862.066650, 1.248399, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(19872, 5405.347167, -3862.065673, 1.248399, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(19817, 5397.919433, -3862.063232, 1.248399, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5428.500488, -3864.247802, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5428.465332, -3859.541992, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5431.782714, -3859.394287, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5432.125488, -3864.194824, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5395.562988, -3865.134765, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5395.780273, -3859.118408, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5392.348144, -3859.104248, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5392.310546, -3864.950927, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5388.868652, -3858.929443, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1238, 5388.735839, -3864.836669, 1.636389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(19967, 5388.000000, -3865.242675, 1.215700, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(19967, 5387.839843, -3858.982666, 1.215700, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(19970, 5420.863281, -3946.968750, 1.233199, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(19970, 5491.496093, -3925.725097, 1.233199, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(9682, 5070.565917, -3852.257568, -11.987600, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(982, 5371.648437, -3807.906005, 3.341500, 0.000000, 180.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(982, 5371.648437, -3833.544677, 3.341500, 0.000000, 180.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(982, 5371.648437, -3859.202392, 3.341500, 0.000000, 180.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(983, 5371.648437, -3875.219482, 3.341500, 0.000000, 180.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(984, 5371.671386, -3892.345703, 3.341500, 0.000000, 180.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(982, 5371.668945, -3911.578125, 3.341500, 0.000000, 180.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(982, 5371.648437, -3937.193115, 3.341500, 0.000000, 180.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(982, 5384.334472, -3950.024414, 3.341500, 0.000000, 180.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(982, 5409.961425, -3950.024414, 3.341500, 0.000000, 180.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(982, 5435.582519, -3950.024414, 3.341500, 0.000000, 180.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(982, 5461.203613, -3950.024414, 3.341500, 0.000000, 180.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(982, 5483.579101, -3950.024414, 3.341500, 0.000000, 180.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(982, 5496.416992, -3937.178710, 3.341500, 0.000000, 180.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(982, 5496.418457, -3911.347412, 3.341500, 0.000000, 180.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(982, 5496.430175, -3885.436523, 3.341500, 0.000000, 180.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(982, 5496.433593, -3859.504150, 3.341500, 0.000000, 180.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(982, 5496.443359, -3833.689453, 3.341500, 0.000000, 180.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(982, 5496.443359, -3808.015136, 3.341500, 0.000000, 180.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(982, 5483.744140, -3795.091552, 3.341500, 0.000000, 180.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(982, 5461.383789, -3795.098388, 3.341500, 0.000000, 180.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(982, 5435.746093, -3795.092529, 3.341500, 0.000000, 180.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(982, 5410.105468, -3795.101318, 3.341500, 0.000000, 180.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(982, 5384.451660, -3795.105712, 3.341500, 0.000000, 180.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1424, 5356.171386, -3872.732666, 2.034310, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(966, 5294.385742, -3885.812988, 1.505699, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1424, 5294.400878, -3874.673339, 2.030179, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1424, 5294.414550, -3877.400390, 2.049798, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1424, 5297.510742, -3886.582031, 2.027338, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(19876, 3850.520507, -5891.202148, 7.429900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3630, 3743.854248, -5801.569335, 6.953299, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3630, 3743.865478, -5811.311523, 6.953299, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(5259, 3722.146972, -5797.037109, 7.192278, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3630, 3759.489501, -5794.184570, 31.506099, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(5259, 3722.845947, -5857.346679, 7.189098, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(5259, 3701.478027, -5857.281250, 7.189098, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3576, 3772.498535, -5858.605468, 15.274900, 0.000000, 0.000000, -30.120000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3633, 3753.091064, -5860.580078, 5.960790, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3633, 3751.616210, -5860.625000, 5.960790, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3633, 3750.193115, -5860.582031, 5.960790, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3633, 3748.751708, -5860.545898, 5.960790, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3886, 3849.016845, -5772.112792, 4.394299, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3465, 3855.007812, -5880.141113, 6.891499, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3465, 3846.113769, -5880.143554, 6.891499, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3465, 3856.715087, -5880.163574, 6.891499, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3465, 3844.393066, -5880.236816, 6.891499, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3043, 3792.383789, -5881.831542, 6.933198, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3062, 3788.866943, -5883.327148, 6.872900, 0.000000, 0.000000, 173.580017, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3062, 3788.860351, -5880.285644, 6.872900, 0.000000, 0.000000, 264.420013, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3576, 3793.178710, -5881.931640, 6.884088, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3043, 3728.531250, -5891.893066, 6.933198, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3062, 3726.942382, -5888.369628, 6.868730, 0.000000, 0.000000, 88.920097, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3062, 3730.077636, -5888.340332, 6.876870, 0.000000, 0.000000, 170.700485, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3576, 3727.924560, -5893.844238, 6.880208, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3043, 3666.587402, -5859.591308, 6.933198, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3576, 3667.290771, -5859.604980, 6.880208, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3062, 3671.684326, -5861.088867, 6.876870, 0.000000, 0.000000, 180.720214, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3062, 3670.131835, -5859.573730, 6.876870, 0.000000, 0.000000, 90.840377, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1676, 5241.222167, -4067.733398, 3.166680, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1676, 5230.386718, -4067.660156, 3.166680, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1676, 4631.369140, -4133.413574, 3.065520, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1676, 4631.317871, -4140.687988, 3.065520, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1676, 4770.751464, -3556.517089, 3.242799, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1676, 4759.896972, -3556.424072, 3.242799, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1676, 4902.684570, -3010.867431, 3.185260, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1676, 4902.775390, -3021.675537, 3.185260, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(12978, 5058.951171, -4292.971191, 1.881000, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(13027, 5058.951171, -4292.971191, 4.709798, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(13027, 5345.584472, -4161.914062, 4.708700, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(12978, 5345.584472, -4161.914062, 1.879199, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(12978, 4590.757324, -4120.145507, 1.878499, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(13027, 4590.757324, -4120.145507, 4.708700, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(13027, 4527.004882, -3315.432373, 4.709400, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(12978, 4527.004882, -3315.432373, 1.881000, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(12978, 4765.689453, -3380.866210, 1.879299, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(10995, 4765.473632, -3415.729492, 8.927800, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(13027, 4765.689453, -3380.866210, 4.709700, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(12978, 4872.238281, -3014.757812, 1.873800, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(13027, 4872.238281, -3014.757812, 4.703700, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(9915, 4888.857421, -3511.628906, 3.329200, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3471, 3885.032470, -4202.536132, 2.601099, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3471, 3885.032470, -4191.172363, 2.601058, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7917, 3866.833007, -4196.839355, 1.297798, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3471, 4300.129882, -4181.786132, 2.814280, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3471, 4300.129882, -4168.314941, 2.814300, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(19972, 4326.620117, -4166.387695, 1.249660, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3462, 5278.279296, -3590.853759, 2.948899, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3462, 5278.279296, -3604.311035, 2.948899, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(19972, 5235.957519, -3606.688964, 1.333500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(18229, 5453.656250, -3419.718017, -8.951628, 0.000000, 0.000000, -87.600090, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1424, 833.966613, -1848.098022, 12.323598, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1424, 849.239318, -1848.098022, 12.323698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1424, 839.044128, -1848.098022, 12.340998, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(19970, 824.006591, -1848.607177, 11.685600, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(19966, 839.078674, -1848.569458, 11.860400, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(19966, 849.247802, -1848.492675, 11.860400, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(19966, 4642.259765, -3435.965332, 1.515100, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(19966, 4642.190917, -3449.241699, 1.515100, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(19970, 4860.504394, -3295.745117, 1.519950, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(9697, 4915.267578, -3512.203369, 1.516800, -0.270000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4515.809570, -2797.157226, 1.444859, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4501.818847, -2796.777587, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4593.277343, -2797.114501, 1.444859, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4579.419921, -2796.805419, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4579.746093, -2923.077880, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4579.726074, -2936.852050, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4593.320800, -2923.257324, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4502.034179, -2936.856933, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4515.837402, -2923.323730, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4515.762695, -2936.979248, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4502.291503, -2923.173095, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4438.342285, -2923.251464, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4424.760742, -2923.153564, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4438.193847, -2936.937744, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4424.776367, -3063.047119, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4438.312011, -3077.040527, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4438.405761, -3063.254150, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4515.958984, -3063.316650, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4515.730957, -3076.937744, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4502.065429, -3063.215820, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4502.091308, -3076.699707, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4655.566894, -3063.225097, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4655.718750, -3076.979492, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4641.995117, -3076.857177, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4642.009277, -3154.368896, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4656.039062, -3140.792968, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4655.756835, -3154.468505, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4642.235351, -3140.678710, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4502.243164, -3132.375000, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4515.671386, -3154.479248, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4515.776855, -3140.859375, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4438.367675, -3218.351562, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4424.239257, -3231.707275, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4424.747070, -3218.146728, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4502.179687, -3218.121337, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4515.701171, -3231.890136, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4502.033203, -3231.750244, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4515.820312, -3218.429199, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4655.727050, -3232.081298, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4642.146972, -3218.228759, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4656.002441, -3218.334960, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4642.063964, -3231.813476, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4782.106933, -3076.864746, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4795.712890, -3078.562988, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4782.165039, -3063.120605, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4782.186035, -2985.748291, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4795.745605, -2999.437988, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4795.915527, -2985.849365, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4935.708496, -2999.543457, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4922.165039, -2985.677734, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4935.888183, -2985.825927, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4922.075195, -2999.398437, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4922.290039, -2908.182128, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4935.645507, -2921.924804, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4935.833496, -2908.400878, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4922.091308, -2921.889404, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5075.821289, -2908.332275, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5061.655273, -2921.667724, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5062.280273, -2908.190917, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5139.651367, -2844.250976, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5153.062988, -2830.740478, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5153.263671, -2844.466308, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5217.042480, -2921.811767, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5230.728027, -2921.491455, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5217.258300, -2908.129150, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5139.683105, -2921.880615, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5153.392089, -2908.335449, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5153.262695, -2922.033691, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5139.810546, -2908.078857, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5153.160644, -2999.450439, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5139.687011, -2985.718505, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5139.571289, -2999.235351, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5153.315429, -2985.993164, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5153.250488, -3077.472412, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5139.757324, -3063.173339, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5139.635742, -3076.776367, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5139.517089, -3154.360595, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5153.286132, -3154.499023, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5139.641113, -3140.589843, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5139.624023, -3231.835449, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5139.666503, -3218.062988, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5153.214355, -3231.603027, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5153.240722, -3309.137451, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5139.579589, -3309.361572, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5139.744628, -3295.711425, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5139.694335, -3435.712158, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5153.284179, -3449.450927, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5153.296386, -3435.882812, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5139.620605, -3449.325439, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4999.764160, -3435.766113, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5013.156250, -3449.400146, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5013.244140, -3435.928955, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4999.475097, -3449.286865, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4922.233398, -3435.637451, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4935.617675, -3449.395263, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4935.818847, -3435.791748, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4922.096679, -3449.356933, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4935.861816, -3295.773681, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4922.079589, -3309.261474, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4935.757812, -3309.527587, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4922.265136, -3295.611328, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5013.593261, -3295.830810, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5013.250488, -3309.523193, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4999.560546, -3309.278076, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4922.118164, -3218.359375, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4935.718750, -3231.986083, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4935.888671, -3218.339843, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5013.328613, -3218.319824, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4999.458984, -3231.744628, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4999.766113, -3218.166259, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4999.753906, -3140.689453, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5013.260253, -3154.394775, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5013.356933, -3140.765869, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4999.620605, -3154.255615, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4935.853515, -3140.754150, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4935.728027, -3154.435791, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4922.207031, -3140.659423, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4999.847167, -3063.191894, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5013.147460, -3076.983398, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5013.303710, -3063.291259, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4999.556152, -3076.884033, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5015.760253, -2985.867919, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4999.622558, -2999.360839, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5013.179687, -2999.499023, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4935.740722, -3076.845703, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4922.239746, -3062.993408, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4935.922851, -3063.304931, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4844.679199, -3295.504638, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4861.671875, -3295.662109, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4844.328125, -3309.240966, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4782.221679, -3295.698974, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4795.719726, -3309.564208, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4795.777343, -3295.859863, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4782.000488, -3309.314697, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4782.235839, -3218.169189, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4795.738281, -3232.009033, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4782.187988, -3231.719238, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4782.055664, -3154.356933, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4795.655761, -3155.810058, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4782.223632, -3140.635498, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4642.195800, -3295.588134, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4655.649902, -3309.381835, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4655.827636, -3295.710937, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4642.039062, -3309.276855, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4502.223632, -3295.746582, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(982, 4488.634765, -3295.018798, 2.191998, 0.000000, 180.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(982, 4463.019042, -3295.018798, 2.191998, 0.000000, 180.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(982, 4437.393554, -3295.018798, 2.191998, 0.000000, 180.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(982, 4411.775878, -3295.018798, 2.191998, 0.000000, 180.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(982, 4386.153808, -3295.018798, 2.191998, 0.000000, 180.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(984, 4368.583984, -3295.014892, 2.237798, 0.000000, 180.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(982, 4362.182128, -3282.196044, 2.191998, 0.000000, 180.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(982, 4362.188476, -3256.591796, 2.191998, 0.000000, 180.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(984, 4362.210449, -3239.020507, 2.237798, 0.000000, 180.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(984, 4368.583984, -3232.618652, 2.237798, 0.000000, 180.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(982, 4386.153808, -3232.618652, 2.191998, 0.000000, 180.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(982, 4411.775878, -3232.618652, 2.191998, 0.000000, 180.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(982, 4437.393554, -3232.618652, 2.191998, 0.000000, 180.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(982, 4463.019042, -3232.618652, 2.191998, 0.000000, 180.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(982, 4488.634765, -3232.618652, 2.191998, 0.000000, 180.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(982, 4501.430664, -3245.423583, 2.191998, 0.000000, 180.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(984, 4501.437500, -3288.605224, 2.237798, 0.000000, 180.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(984, 4501.437500, -3264.624023, 2.237798, 0.000000, 180.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(967, 4500.723144, -3272.421142, 1.506350, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(966, 4501.185546, -3274.054687, 1.506999, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(968, 4501.176757, -3274.085205, 2.173578, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4515.760742, -3309.463378, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4515.945800, -3295.799804, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4502.176757, -3309.289794, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4502.166015, -3575.636962, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1284, 4501.988281, -3596.881103, 4.650410, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1284, 4515.940917, -3583.310302, 4.650400, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4515.739746, -3604.520751, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4515.735839, -3681.502929, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4502.293457, -3668.123291, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4502.133300, -3681.749755, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4362.109863, -3681.739257, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4375.815429, -3668.363037, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4375.796386, -3682.014160, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4362.250488, -3668.210449, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4362.089843, -3759.389648, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4376.035156, -3745.797119, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4362.229980, -3745.640869, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1284, 4640.405273, -3596.811279, 4.650410, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1284, 4656.060058, -3583.309570, 4.650400, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4642.248535, -3575.712890, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4655.578125, -3604.425781, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1284, 4782.006835, -3596.840576, 4.650410, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1284, 4795.896484, -3583.268066, 4.650400, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4782.269042, -3575.663330, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4795.700683, -3604.503417, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1284, 4921.968261, -3596.807617, 4.650410, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1284, 4935.961914, -3583.230224, 4.650400, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4922.173339, -3575.708007, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4935.730468, -3604.431152, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5062.147460, -3590.672363, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5061.958007, -3604.370117, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5075.836914, -3590.883300, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5153.439453, -3590.897460, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5137.867675, -3604.380859, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5154.777832, -3604.628906, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5139.710449, -3590.732177, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5139.704589, -3513.067138, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5153.385253, -3526.159667, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5139.520507, -3526.800781, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4782.098144, -3449.252441, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4795.909667, -3435.837402, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4782.179687, -3435.583251, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4795.774414, -3449.382812, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4655.704589, -3449.493164, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4642.228027, -3433.953613, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4655.920410, -3435.845947, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4642.030761, -3450.851318, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4733.214843, -3809.480224, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4733.647949, -3795.808837, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4719.671386, -3809.172607, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4655.658691, -3809.516845, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4642.240234, -3795.567138, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4655.916992, -3795.829589, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4642.136230, -3935.700683, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4655.629882, -3949.413085, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4655.855468, -3935.861572, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4642.006347, -3949.333984, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4642.063476, -4026.733642, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4655.866210, -4013.343994, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4655.596191, -4027.035888, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4642.219238, -4013.158447, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4502.295410, -4013.157226, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4515.728515, -4026.921142, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4515.839843, -4013.256591, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4515.670410, -4104.541992, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4515.837402, -4090.827636, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4502.374511, -4091.196044, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4502.145019, -4168.179199, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4515.906250, -4168.297851, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4502.047851, -4181.824218, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4515.780761, -4181.986816, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4424.561035, -4181.751464, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4438.112304, -4181.965332, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4438.585449, -4168.441406, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4719.433593, -3949.473144, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4733.386230, -3935.802734, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4733.185058, -3949.482910, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4719.686035, -3935.699462, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4733.220214, -4026.974609, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4719.664062, -4013.219482, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4733.289550, -4013.340087, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4719.560546, -4026.801269, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4718.388671, -4104.228027, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4733.323730, -4090.742919, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4719.744628, -4090.609130, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4642.143066, -4090.737548, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4655.711914, -4104.365234, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4655.848144, -4090.841064, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4642.020019, -4104.249511, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4642.083496, -4181.854980, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4655.738281, -4168.268554, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4655.751464, -4181.954101, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4642.183105, -4168.072753, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3458, 4676.773925, -4305.251953, 3.021790, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3458, 4622.862304, -4305.105468, 3.021790, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4642.023437, -4321.787597, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4655.678222, -4321.855957, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4655.210937, -4308.587402, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4642.125976, -4399.342285, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4655.761230, -4399.375000, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4642.270019, -4385.423339, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4502.249023, -4385.542480, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4515.738769, -4399.475585, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4515.824707, -4385.748535, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4515.849609, -4308.267089, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4515.729980, -4321.944824, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4502.232421, -4308.149902, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4502.100097, -4525.621582, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4515.890136, -4525.841308, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4502.075195, -4539.305175, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4438.433593, -4525.811523, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4438.314453, -4539.400878, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4424.544433, -4525.712890, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4782.184570, -4308.130859, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4795.855957, -4308.285156, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4781.891601, -4321.805664, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4795.138671, -4168.254394, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4782.079101, -4181.683105, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4795.705078, -4181.828613, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4873.188964, -4181.855468, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4859.546386, -4181.863281, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4859.593261, -4168.215332, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4859.782714, -4308.161621, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4873.381347, -4308.311035, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4859.581542, -4321.749511, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4859.719238, -4090.625244, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4873.210937, -4104.499023, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4873.326660, -4090.833251, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4859.565917, -4104.257324, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4859.875000, -4013.210449, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4873.397460, -4027.023681, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4859.606445, -4026.772216, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4873.559570, -4013.406250, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4859.833496, -3935.554199, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4873.300292, -3949.422607, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4873.392089, -3935.938964, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4859.619140, -3949.342041, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4873.517089, -3795.787109, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4859.526367, -3809.241210, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4873.162109, -3809.406005, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5013.236328, -3809.490478, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5013.502929, -3795.905029, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4999.644042, -3809.324951, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4999.616210, -3949.308105, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5013.497070, -3935.851318, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5013.194335, -3949.415527, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4999.715332, -3935.568359, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4999.517089, -4026.828369, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5013.357421, -4013.399902, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5013.180664, -4026.967285, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4999.729492, -4013.064453, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4999.659667, -4104.369628, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5013.176757, -4104.586914, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4999.762207, -4090.719726, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5013.263671, -4244.284667, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4999.771484, -4230.545898, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5013.250000, -4230.810546, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5013.340820, -4322.104003, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4999.778320, -4308.233886, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5013.319824, -4308.412597, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4999.649414, -4321.819335, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5139.728515, -3795.630859, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5153.268554, -3809.617431, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5139.564453, -3809.335693, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5153.330078, -3795.735107, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5139.725585, -3935.659423, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5153.156250, -3949.460693, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5153.309570, -3935.880615, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5139.420410, -3949.339843, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5139.506835, -4026.794677, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5139.642578, -4013.240234, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5153.121093, -4027.052246, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5153.105468, -4104.299804, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5153.363769, -4090.743896, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5139.759277, -4090.605712, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5153.196289, -4244.415039, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5139.684082, -4230.761718, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5153.264648, -4230.854492, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5139.607421, -4244.259277, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5139.517089, -4321.867675, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5139.769042, -4308.255859, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5153.183105, -4322.095703, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5139.525390, -4524.251464, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5153.332519, -4510.839355, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5153.200683, -4524.373046, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5139.718750, -4510.747070, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5139.723632, -4588.205566, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5153.237304, -4588.228027, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5139.466308, -4601.663574, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5013.345703, -4510.809082, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5013.255371, -4524.404296, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4999.718261, -4510.495605, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5293.170410, -4524.501953, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5279.741699, -4510.694335, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5293.374511, -4510.787109, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5279.593750, -4524.383300, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5279.728027, -4588.145019, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5293.269042, -4588.349609, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5278.281738, -4601.718750, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5370.855957, -4588.369628, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5357.008789, -4601.776367, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5357.209960, -4588.179199, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5434.566406, -4524.250976, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5448.199707, -4523.972656, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5434.761718, -4510.696777, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5357.244140, -4510.645996, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5370.688964, -4524.425781, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5357.045898, -4524.260253, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5370.754882, -4510.681152, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5370.860839, -4370.851074, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5356.978027, -4384.340820, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5370.821289, -4384.332519, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5357.191894, -4370.599609, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5279.718750, -4370.762695, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5293.236328, -4384.375976, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5293.387695, -4370.749511, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5293.410644, -4230.813964, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5279.568847, -4244.411621, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5293.259765, -4244.454589, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5279.738281, -4230.477050, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5279.765625, -4090.650146, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5293.270507, -4104.372558, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5293.380859, -4090.805664, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5279.609375, -4104.337890, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5293.212402, -3949.364990, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5279.794921, -3935.728515, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5293.296875, -3935.906250, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5279.620117, -3949.306640, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5292.067871, -3795.721435, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5279.600097, -3809.178222, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5293.195312, -3809.499023, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5488.777832, -3811.790771, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5370.781250, -4090.860351, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5357.094238, -4104.346679, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5370.676269, -4104.539062, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5370.759765, -4244.397460, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5357.313476, -4230.670898, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5370.877929, -4230.647949, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5357.025390, -4244.173828, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5448.295410, -4384.515625, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5434.500976, -4384.394531, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5434.795410, -4370.725585, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5434.796386, -4230.715332, 1.444900, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5448.414550, -4244.555175, 1.444900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 5434.539550, -4244.242187, 1.444900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7953, 4720.146972, -3590.058349, 2.153500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7953, 4579.813964, -3590.058349, 2.153500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7953, 4438.859863, -3590.058349, 2.153500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7953, 4859.094726, -3590.058349, 2.153500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7953, 4920.616699, -3512.644775, 2.153500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1368, 4894.090820, -3617.569335, 2.204699, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1368, 4894.090820, -3609.374267, 2.204699, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1368, 4894.090820, -3655.175292, 2.204699, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1368, 4894.090820, -3663.208740, 2.204699, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1368, 4887.325683, -3622.245605, 2.204699, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1368, 4874.458007, -3622.245605, 2.204699, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1368, 4874.458007, -3650.240478, 2.204699, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1368, 4887.325683, -3650.240478, 2.204699, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1368, 4867.709960, -3663.208740, 2.204699, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1368, 4867.709960, -3655.175292, 2.204699, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1368, 4867.709960, -3617.569335, 2.204699, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1368, 4867.709960, -3609.374267, 2.204699, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1368, 4850.253417, -3609.374267, 2.204699, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1368, 4850.253417, -3617.569335, 2.204699, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1368, 4829.592285, -3650.240478, 2.204699, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1368, 4844.053222, -3650.240478, 2.204699, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1368, 4844.053222, -3622.245605, 2.204699, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1368, 4829.592285, -3622.245605, 2.204699, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1368, 4850.253417, -3655.175292, 2.204699, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1368, 4850.253417, -3663.208740, 2.204699, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1368, 4823.880859, -3663.208740, 2.204699, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1368, 4823.880859, -3655.175292, 2.204699, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1368, 4823.880859, -3617.569335, 2.204699, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1368, 4823.880859, -3609.374267, 2.204699, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7952, 4879.783203, -3513.687011, 2.192589, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(16362, 4480.914062, -3289.524658, 4.508968, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(16362, 4440.255371, -3289.524658, 4.508998, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(16362, 4399.644531, -3289.524658, 4.508998, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(16362, 4368.104003, -3264.158935, 4.508998, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(16362, 4399.644531, -3239.193359, 4.508998, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(16362, 4523.353515, -3971.784179, 4.593200, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(16362, 4538.247558, -4004.175048, 4.593200, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(16362, 4619.138183, -4004.144531, 4.593200, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(16362, 4634.303710, -3971.782470, 4.593200, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(16362, 4605.197265, -3957.054443, 4.593200, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(16362, 4553.722167, -3957.214355, 4.593210, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7952, 5099.225097, -3511.735107, 2.192600, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7953, 4577.978515, -4028.394775, 2.168169, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7953, 4577.978515, -4089.222656, 2.168200, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7953, 5154.789550, -4019.880371, 2.169348, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7952, 5138.133300, -4363.370605, 2.229578, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(640, 4898.876953, -3515.632080, 3.520600, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(640, 4898.876953, -3509.276855, 3.520600, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(640, 4902.016113, -3512.418945, 3.520600, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(640, 4895.859863, -3512.418945, 3.520600, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1256, 4879.972167, -3534.401123, 2.173799, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1256, 4880.137207, -3559.990722, 2.173799, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1256, 4880.089843, -3490.821533, 2.173799, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1256, 4880.102539, -3466.778076, 2.173799, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1256, 4898.876953, -3506.491210, 2.173799, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1256, 4898.876953, -3518.250732, 2.173799, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1256, 4904.623535, -3512.418945, 2.173799, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1256, 4892.990722, -3512.418945, 2.173799, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1256, 5063.588378, -3493.855224, 2.174598, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1256, 5074.048828, -3493.855224, 2.174598, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1256, 5118.068847, -3493.855224, 2.174598, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1256, 5128.974121, -3493.855224, 2.174598, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(12978, 5132.800781, -3320.932861, 1.879500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(13027, 5132.800781, -3320.932861, 4.709898, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1256, 4992.774902, -3478.376464, 2.145410, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1256, 4992.608398, -3467.220214, 2.145410, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1256, 4982.912597, -3455.296875, 2.145400, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1256, 4972.729003, -3455.296875, 2.145400, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1256, 4601.987792, -3272.129882, 2.169698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1256, 4611.012695, -3272.069091, 2.169698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1256, 4464.486816, -3264.229248, 2.137500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3660, 4749.003417, -3983.479492, 3.966099, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1257, 4562.541992, -4402.102539, 2.768300, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1257, 3804.768554, -5817.302246, 6.724699, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1257, 5298.630859, -4202.136718, 2.783499, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(9697, 5159.568359, -4169.634765, 1.518000, -0.300000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1257, 5056.436523, -4034.412109, 2.762870, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7953, 5014.794433, -4167.485351, 2.169399, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(9697, 5020.092285, -4170.364746, 1.518000, -0.300000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1257, 5134.648437, -4440.807617, 2.733999, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1257, 5302.078613, -3930.699951, 2.725698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(12978, 5257.584960, -3818.013183, 1.879500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(13027, 5257.584960, -3818.013183, 4.710299, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1256, 5334.815429, -3913.020996, 2.142298, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1256, 5315.788574, -3913.020996, 2.142298, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(869, 5321.621582, -3900.766113, 1.986600, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(869, 5325.305664, -3900.685302, 1.986600, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(869, 5329.528808, -3900.649902, 1.986600, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(869, 5332.091796, -3900.548095, 1.986600, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7953, 5076.306152, -3794.068359, 1.992249, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7953, 4953.869628, -3794.068359, 1.992200, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7953, 4835.897460, -3794.068359, 1.992200, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7953, 4718.180664, -3794.068359, 1.992200, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7953, 5215.722167, -3794.068359, 1.992200, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7953, 5312.715332, -3794.044189, 1.988198, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7953, 4640.152343, -3869.342529, 1.992200, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7953, 4570.035644, -3933.724365, 1.992200, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7953, 4500.151367, -3995.704345, 1.988198, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7953, 4500.205078, -4098.536621, 1.992200, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7953, 5295.273925, -4019.062011, 1.988198, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7953, 5365.024414, -4088.870605, 1.988198, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7953, 5450.394042, -4148.786621, 1.988198, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7953, 5450.394042, -4275.854492, 1.988198, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7953, 5450.394042, -4404.028808, 1.988198, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7953, 5450.394042, -4535.102050, 1.988198, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7953, 5390.499511, -4603.531738, 1.988198, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7953, 5261.849609, -4603.531738, 1.988198, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7953, 5143.497558, -4603.531738, 1.988198, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7952, 5040.585937, -4603.520019, 2.039410, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7953, 4997.901855, -4397.100585, 1.988198, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7953, 4997.901855, -4531.375488, 1.988198, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7953, 4940.103515, -4323.769042, 1.988198, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7953, 4715.499511, -4323.769042, 1.988198, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7952, 4826.677246, -4323.769042, 2.033710, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7953, 4719.713378, -3606.343017, 1.996899, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7953, 4866.369628, -3683.998779, 1.996899, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7953, 4995.219726, -3606.083251, 1.996899, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7952, 5095.722167, -3606.132568, 2.192600, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7952, 5213.910156, -3606.158935, 2.192600, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7952, 5213.378417, -3589.021484, 2.192600, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7953, 5155.070800, -3521.236328, 1.996899, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7953, 5221.979492, -3451.406494, 1.996899, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7665, 5255.820800, -3406.763427, 2.884000, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7505, 5154.472656, -3337.891601, 2.869998, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7423, 5203.972167, -3425.053955, 1.315999, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7423, 5163.984375, -3050.059082, 1.315999, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7505, 5154.472656, -3180.730712, 2.869998, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7665, 5209.322753, -2972.780029, 2.875998, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7505, 5231.984375, -2907.996582, 2.874000, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(970, 5296.083496, -3435.042724, 1.859760, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(970, 5300.260253, -3435.042724, 1.859799, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(970, 5304.437500, -3435.042724, 1.859799, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(970, 5308.614257, -3435.042724, 1.859799, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(970, 5312.791503, -3435.042724, 1.859799, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(970, 5316.968261, -3435.042724, 1.859799, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(970, 5321.144531, -3435.042724, 1.859799, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(970, 5325.312011, -3435.042724, 1.859799, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(970, 5329.489746, -3435.042724, 1.859799, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(970, 5333.657714, -3435.042724, 1.859799, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(970, 5337.822753, -3435.042724, 1.859799, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(970, 5341.996093, -3435.042724, 1.859799, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(970, 5346.168945, -3435.042724, 1.859799, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(970, 5350.245605, -3435.042724, 1.859799, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(970, 5354.353027, -3435.042724, 1.859799, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(970, 5356.441894, -3432.952148, 1.859799, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(970, 5356.441894, -3428.775878, 1.859799, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(970, 5356.441894, -3424.600097, 1.859799, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(970, 5356.441894, -3420.423583, 1.859799, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(970, 5356.441894, -3416.260742, 1.859799, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(970, 5356.441894, -3412.114257, 1.859799, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(970, 5356.441894, -3407.937500, 1.859799, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(970, 5356.441894, -3403.765380, 1.859799, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(970, 5356.441894, -3399.596435, 1.859799, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(970, 5356.441894, -3395.420654, 1.859799, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(970, 5354.352539, -3375.096191, 1.859799, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(970, 5350.245605, -3375.096191, 1.859799, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(970, 5346.168945, -3375.096191, 1.859799, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(970, 5341.996093, -3375.096191, 1.859799, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(970, 5337.822753, -3375.096191, 1.859799, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(970, 5333.657714, -3375.096191, 1.859799, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(970, 5329.489746, -3375.096191, 1.859799, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(970, 5325.312011, -3375.096191, 1.859799, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(970, 5321.144531, -3375.096191, 1.859799, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(970, 5316.968261, -3375.096191, 1.859799, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(970, 5312.791503, -3375.096191, 1.859799, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(970, 5308.614257, -3375.096191, 1.859799, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(970, 5304.437500, -3375.096191, 1.859799, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(970, 5300.260253, -3375.096191, 1.859799, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(970, 5296.083496, -3375.096191, 1.859799, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(9682, 5359.801269, -3390.224609, -12.178198, 0.000000, 0.000000, 180.300003, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(970, 5356.441894, -3391.251464, 1.859799, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(970, 5356.441894, -3387.074951, 1.859799, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(970, 5356.441894, -3382.897216, 1.859799, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(970, 5356.441894, -3377.182617, 1.859799, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3458, 5325.738281, -3430.064697, 2.821710, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3458, 5352.293945, -3403.820068, 2.821700, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3458, 5329.469238, -3378.566894, 2.821700, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3660, 5322.733886, -3405.069091, 3.783849, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1368, 5316.694335, -3406.946533, 2.009500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1368, 5328.281250, -3406.946533, 2.009500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1368, 5328.281250, -3403.667968, 2.009500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1368, 5316.694335, -3403.667968, 2.009500, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3499, 4578.750000, -3253.491455, 51.231201, 0.000000, 90.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(982, 5173.693359, -4230.014648, 4.391499, 0.000000, 180.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(983, 5157.682617, -4230.017578, 4.423998, 0.000000, 180.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(982, 5154.495605, -4217.199707, 4.391499, 0.000000, 180.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(982, 5154.495605, -4191.585937, 4.391499, 0.000000, 180.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(982, 5154.495605, -4165.982421, 4.391499, 0.000000, 180.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(982, 5154.495605, -4140.370605, 4.391499, 0.000000, 180.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(982, 5154.491699, -4117.976562, 4.391499, 0.000000, 180.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(982, 5167.224121, -4105.152832, 4.391499, 0.000000, 180.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(982, 5192.759277, -4105.154785, 4.391499, 0.000000, 180.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(982, 5218.291503, -4105.152832, 4.391499, 0.000000, 180.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(982, 5243.803710, -4105.152832, 4.391499, 0.000000, 180.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(982, 5266.125488, -4105.156738, 4.391499, 0.000000, 180.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(982, 5278.933593, -4117.945312, 4.391499, 0.000000, 180.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(982, 5278.933593, -4143.564941, 4.391499, 0.000000, 180.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(967, 5277.653320, -4184.238769, 1.502099, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(982, 5265.437011, -4193.494628, 3.680918, 0.000000, 180.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(982, 5239.824707, -4193.495605, 3.680900, 0.000000, 180.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(982, 5214.208984, -4193.493164, 3.680900, 0.000000, 180.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(983, 5199.643554, -4197.497070, 3.711400, 0.000000, 180.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(983, 5203.042968, -4193.492675, 3.693398, 0.000000, 180.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(966, 5278.663085, -4185.338867, 1.510599, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(982, 5278.932128, -4169.180175, 4.391499, 0.000000, 180.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(982, 5232.058105, -4211.510253, 2.338920, 0.000000, 180.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(984, 5251.270507, -4211.506835, 2.392400, 0.000000, 180.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(967, 5199.598632, -4218.462402, 1.502099, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(966, 5199.079101, -4217.086914, 1.510599, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(968, 5199.100585, -4217.134765, 2.095798, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(973, 5199.274902, -4205.294921, 2.477849, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(967, 5195.283691, -4229.289062, 1.502099, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1424, 5197.492187, -4229.769531, 2.039098, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(966, 5194.099609, -4229.803222, 1.510599, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(968, 5194.098144, -4229.787597, 2.095798, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7953, 5215.958496, -4246.279785, 1.988198, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7953, 5155.058593, -4307.549316, 1.988198, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7953, 5155.058593, -4440.377441, 1.988198, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7953, 5216.320312, -4508.831542, 1.988198, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7953, 5277.861816, -4440.377441, 1.988198, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7953, 5277.861816, -4307.549316, 1.988198, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3660, 5246.481445, -4164.549316, 3.924278, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3660, 5226.747558, -4164.549316, 3.924299, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3660, 5189.659179, -4164.549316, 3.924299, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(9697, 5159.668457, -4020.464843, 1.518000, -0.300000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1256, 5184.402832, -4166.491699, 2.136498, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3660, 5211.468750, -4191.475585, 3.924299, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3660, 5232.536132, -4191.475585, 3.924299, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3660, 5253.614257, -4191.475585, 3.924299, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1256, 5189.841308, -4166.491699, 2.136498, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1256, 5195.006347, -4166.491699, 2.136498, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1256, 5222.491699, -4166.491699, 2.136498, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1256, 5231.445800, -4166.491699, 2.136498, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1256, 5242.272949, -4166.491699, 2.136498, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1256, 5250.636230, -4166.491699, 2.136498, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1367, 5203.689941, -4163.888671, 2.122100, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1367, 5213.166503, -4163.937011, 2.122100, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1365, 5275.936523, -4113.511230, 2.602200, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(10716, 5198.897460, -3851.613037, 21.801900, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1359, 5318.726074, -3917.200195, 2.172188, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1359, 5331.992675, -3917.113281, 2.172188, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1372, 5316.755859, -3920.762207, 1.639490, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1372, 5314.503906, -3920.781250, 1.639490, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1364, 5093.136718, -3840.169189, 2.292299, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1364, 5126.236328, -3840.169189, 2.292299, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1367, 5098.778320, -3840.511962, 2.117300, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1367, 5120.541015, -3840.642822, 2.117300, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(9697, 5064.038574, -3868.969970, 1.518000, -0.300000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(10946, 5077.065917, -3984.091064, 2.985599, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(5463, 5043.349121, -3983.825195, 27.983900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(5463, 5110.541015, -3985.446289, 27.983900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(5644, 5110.541015, -3985.446289, 28.492200, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(5644, 5043.349121, -3983.825195, 28.492200, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3867, 5115.275878, -3967.926269, 16.199649, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3867, 5048.375976, -3966.597900, 16.199649, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1378, 5075.727539, -3982.500000, 25.858409, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(18248, 5092.762207, -3969.064697, 9.497360, 0.000000, 0.000000, 52.380001, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(4205, 4975.558593, -3979.450195, 4.237030, 0.000000, 0.000000, 12.500000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1257, 5132.759277, -3852.592041, 2.713530, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7953, 4578.605468, -3606.336425, 1.996899, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7953, 4429.657226, -3574.031005, 2.002500, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7952, 4360.473632, -3622.307373, 2.054698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7953, 4287.231933, -3666.533691, 1.993499, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7952, 4220.280761, -3713.306396, 2.054698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7953, 4280.406738, -3761.018066, 1.993499, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7953, 4438.012207, -3760.992187, 1.993499, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7953, 4517.513183, -3691.993408, 1.996899, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7953, 4422.909667, -3158.724121, 2.153500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7953, 4423.033691, -3031.835937, 2.153500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7953, 4423.008789, -2852.314208, 2.153500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7953, 4489.136718, -2781.649658, 2.153500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7953, 4612.683105, -2781.629638, 2.153500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7953, 4672.439453, -2861.514648, 2.153500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7953, 4590.363769, -2938.496826, 2.153500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7953, 4517.394531, -3000.014648, 2.153500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7953, 4585.633300, -3061.564208, 2.153500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7953, 4711.346679, -3061.682617, 2.153500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7953, 4780.554687, -2985.724121, 2.153500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7953, 4849.711425, -2906.545898, 2.153500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7953, 4996.438476, -2906.628417, 2.153500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7953, 5130.103515, -2829.192871, 2.153500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 827.460815, -1967.579223, 16.872739, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 827.425720, -2117.547119, 16.872739, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 827.459838, -2267.447753, 16.872739, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 827.481628, -2417.763427, 16.872739, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 827.460693, -2567.500244, 16.872739, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 827.447265, -2717.443359, 16.872739, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 827.451477, -2867.617919, 16.872739, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 827.435302, -2987.057128, 16.872739, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 959.301025, -3088.908447, 16.872699, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 1112.609497, -3088.920166, 16.872699, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 1263.474731, -3088.872070, 16.872699, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 1409.396850, -3088.908935, 16.872699, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 1561.930664, -3088.916748, 16.872699, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 1711.513305, -3088.873046, 16.872699, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 1862.122924, -3088.888427, 16.872699, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 2011.712036, -3088.935302, 16.872699, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 2163.647705, -3088.877441, 16.872699, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 2313.177490, -3088.873291, 16.872699, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 2464.342041, -3088.888427, 16.872699, 0.000000, 0.000000, 90.239990, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 2612.336425, -3088.927490, 16.872699, 0.000000, 0.000000, 90.239990, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 2763.313232, -3088.905273, 16.872699, 0.000000, 0.000000, 90.239990, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 2912.214355, -3088.889892, 16.872699, 0.000000, 0.000000, 90.239990, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 3062.847167, -3088.882080, 16.872699, 0.000000, 0.000000, 90.239990, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 3179.483398, -3088.953125, 16.872699, 0.000000, 0.000000, 90.239990, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 3281.167236, -3222.464355, 16.872699, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 3281.198730, -3340.808593, 16.872699, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 3417.107910, -3442.617675, 16.872699, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 3567.659179, -3442.572021, 18.372190, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 3716.749023, -3442.606445, 24.911369, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 3866.905761, -3442.626464, 31.491188, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 4054.696533, -3442.587402, 35.130371, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 4204.614746, -3442.577148, 28.552299, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 4350.790039, -3442.539794, 22.153030, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 4503.953125, -3442.560546, 15.554658, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 4606.754394, -3442.625000, 11.715250, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 845.435302, -1967.579223, 16.872699, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 845.435302, -2117.547119, 16.872699, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 845.435302, -2267.447753, 16.872699, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 845.435302, -2417.763427, 16.872699, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 845.435302, -2567.500244, 16.872699, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 845.435302, -2717.443359, 16.872699, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 845.383544, -2836.948242, 16.872739, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 959.301025, -2938.888427, 16.872699, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 1112.609497, -2938.888427, 16.872699, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 1263.474731, -2938.888427, 16.872699, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 1409.396850, -2938.888427, 16.872699, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 1561.930664, -2938.888427, 16.872699, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 1711.513305, -2938.888427, 16.872699, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 1862.122924, -2938.888427, 16.872699, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 2011.712036, -2938.888427, 16.872699, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 2163.647705, -2938.888427, 16.872699, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 2313.177490, -2938.888427, 16.872699, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 2464.342041, -2938.888427, 16.872699, 0.000000, 0.000000, 90.239997, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 2612.336425, -2938.888427, 16.872699, 0.000000, 0.000000, 90.239997, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 2763.313232, -2938.888427, 16.872699, 0.000000, 0.000000, 90.239997, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 2912.214355, -2938.888427, 16.872699, 0.000000, 0.000000, 90.239997, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 3062.847167, -2938.888427, 16.872699, 0.000000, 0.000000, 90.239997, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 3231.174316, -2938.853027, 16.872699, 0.000000, 0.000000, 90.239997, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 3381.328125, -2938.855224, 16.872699, 0.000000, 0.000000, 90.239997, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 3529.760009, -2938.860107, 16.872699, 0.000000, 0.000000, 90.239997, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 3680.602050, -2938.873779, 16.872699, 0.000000, 0.000000, 90.239997, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 3830.830810, -2938.857910, 16.872699, 0.000000, 0.000000, 90.239997, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 3980.725097, -2938.869873, 16.872699, 0.000000, 0.000000, 90.239997, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 4111.265625, -2937.898925, 16.872699, 0.000000, 0.000000, 101.279930, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 4199.072753, -2803.249755, 16.872699, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 4199.061035, -2651.857421, 16.872699, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 4202.514648, -2510.943359, 16.872699, 0.000000, 0.000000, -16.020050, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 4335.717773, -2435.197021, 16.872699, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 4486.285156, -2435.134765, 16.872699, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 4634.381835, -2435.130371, 16.872699, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 4756.962890, -2435.649902, 16.872699, 0.000000, 0.000000, 85.320091, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 4852.854980, -2570.017822, 16.872699, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 4852.864257, -2723.308837, 16.872699, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 4852.808105, -2873.199951, 16.872699, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 4852.867675, -3020.592041, 15.400320, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 4852.852539, -3158.912841, 10.838170, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 4852.835449, -3265.391845, 10.685070, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1226, 4669.870605, -2936.084228, 5.403398, 0.000000, 0.000000, -45.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1226, 4669.621582, -2861.744628, 5.403398, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1226, 4670.028320, -2784.187255, 5.403398, 0.000000, 0.000000, 45.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4593.365722, -2783.377685, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1226, 4425.749511, -2784.022949, 5.403398, 0.000000, 0.000000, 135.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1226, 4425.694335, -2852.742187, 5.403398, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1226, 4514.706054, -3003.245605, 5.403398, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1226, 4425.857421, -3004.792236, 5.403398, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1226, 4425.894531, -3133.830566, 5.403398, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1226, 4592.625488, -3064.388671, 5.403398, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1226, 4348.307128, -3219.087158, 5.403398, 0.000000, 0.000000, 135.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1226, 4348.124511, -3308.554931, 5.403398, 0.000000, 0.000000, 215.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1350, 4515.759765, -2783.378417, 1.444900, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1226, 4431.428710, -3308.312255, 5.403398, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1226, 4503.250000, -3379.073242, 5.403398, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1226, 4503.212402, -3502.755859, 5.403398, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1226, 4363.232910, -3576.609863, 5.403398, 0.000000, 0.000000, 135.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1226, 4223.147460, -3668.985595, 5.403398, 0.000000, 0.000000, 135.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1226, 4222.988769, -3758.361328, 5.403398, 0.000000, 0.000000, 225.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1226, 4514.745117, -3758.567138, 5.403398, 0.000000, 0.000000, -45.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3472, 4698.109863, -3590.131103, 1.891100, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3472, 4743.111816, -3590.019287, 1.891100, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3472, 4602.677734, -3590.165283, 1.891100, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3472, 4557.969238, -3590.187988, 1.891100, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3472, 4836.820312, -3590.235107, 1.891100, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3472, 4882.262695, -3590.184814, 1.891100, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3472, 4519.447265, -3589.990478, 1.891100, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3472, 4640.099609, -3590.198730, 1.891100, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3472, 4659.500488, -3590.215332, 1.891100, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3472, 4780.223632, -3590.321289, 1.891100, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3472, 4799.653808, -3590.125244, 1.891100, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3472, 4920.146484, -3590.274658, 1.891100, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7662, 4986.287109, -3590.094726, 2.266999, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7662, 5004.827148, -3590.094726, 2.266999, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3472, 4961.388183, -3590.170898, 1.891100, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3472, 4995.418945, -3590.304931, 1.891100, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1359, 4837.047363, -3622.008544, 2.152920, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1359, 4837.047363, -3650.608886, 2.152899, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1359, 4881.029785, -3621.919677, 2.152920, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1359, 4881.029785, -3650.611572, 2.152899, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1568, 4868.415039, -3651.049804, 1.466300, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1568, 4893.500000, -3650.885742, 1.466300, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1568, 4893.401855, -3621.515869, 1.466300, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1568, 4868.392578, -3621.540527, 1.466300, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1568, 4849.602539, -3621.581542, 1.466300, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1568, 4824.686523, -3621.497802, 1.466300, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1568, 4824.623046, -3651.008300, 1.466300, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1568, 4849.604492, -3651.013916, 1.466300, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(713, 4881.225097, -3613.708496, 1.868430, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(713, 4836.210449, -3613.599365, 1.868430, 0.000000, 0.000000, -44.400009, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(713, 4881.231445, -3660.909179, 1.868430, 0.000000, 0.000000, 24.719989, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(713, 4835.889160, -3659.604980, 1.868430, 0.000000, 0.000000, 76.559982, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(737, 4806.850585, -3615.454345, 1.581230, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(737, 4806.908203, -3657.127685, 1.581230, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(737, 4832.655761, -3636.268554, 1.581230, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(737, 4885.037597, -3636.274902, 1.581230, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(737, 4911.037597, -3615.372558, 1.581230, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(737, 4911.051269, -3657.215332, 1.581230, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1226, 4783.193847, -2909.156005, 5.390398, 0.000000, 0.000000, 135.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1226, 4923.300292, -2833.013916, 5.390398, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1226, 4934.453613, -2751.019531, 5.390398, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1226, 4923.243164, -2644.258056, 5.390398, 0.000000, 0.000000, 135.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1226, 4987.090820, -2644.347656, 5.390398, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1226, 5058.694335, -2644.314453, 5.390398, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1226, 5063.256347, -2831.607421, 5.390398, 0.000000, 0.000000, 135.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1226, 5229.902343, -2831.838378, 5.390398, 0.000000, 0.000000, 45.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1226, 5229.761718, -2998.582519, 5.390398, 0.000000, 0.000000, -45.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1226, 5292.227050, -3448.566406, 5.390398, 0.000000, 0.000000, -45.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1231, 5312.139160, -3405.429687, 3.967700, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1231, 5332.994628, -3405.361328, 3.967700, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(16061, 5166.323730, -3397.115722, 1.427090, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(16061, 5165.505371, -3323.195312, 1.427098, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(16061, 5166.255859, -3255.840332, 1.427098, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(16061, 5164.177246, -3175.429199, 1.427098, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(16061, 5164.850097, -3109.387695, 1.427098, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(16061, 5183.853515, -3010.789794, 1.427098, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(16061, 5219.267578, -3100.670410, 1.427098, 0.000000, 0.000000, 186.479766, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(16061, 5220.958496, -3173.410644, 1.427098, 0.000000, 0.000000, -11.220000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(16061, 5212.645019, -3239.548583, 1.427098, 0.000000, 0.000000, 170.220016, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(16061, 5213.416503, -3312.476806, 1.427098, 0.000000, 0.000000, -6.059998, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(16061, 5238.483398, -3365.510009, 1.427098, 0.000000, 0.000000, 73.080146, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(16061, 5250.852050, -3427.317871, 1.427098, 0.000000, 0.000000, 85.320129, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(16061, 5270.621582, -3391.419677, 1.427098, 0.000000, 0.000000, 178.860137, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(713, 5236.407226, -3400.852294, 1.290899, 0.000000, 0.000000, -27.420000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(708, 5180.777343, -3424.442382, 1.413020, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(705, 5260.478027, -3307.209228, 10.082240, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(705, 5393.435546, -3255.479980, 25.202190, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(705, 5521.914550, -3207.396240, 12.324190, 0.000000, 0.000000, -109.920066, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(705, 5292.855957, -3069.302734, 11.306698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(16061, 5217.578613, -3047.016357, 1.427098, 0.000000, 0.000000, -2.099980, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(703, 5266.456054, -3151.565185, 5.802878, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(703, 5251.001464, -3211.990234, 5.780900, 0.000000, 0.000000, 58.500019, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(703, 5397.195800, -3190.023925, 24.192190, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(691, 5267.041503, -3268.532470, 5.461248, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(691, 5306.391601, -3203.909912, 6.297658, 0.000000, 0.000000, 125.219993, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(672, 5335.377441, -3123.640869, 1.937620, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(669, 5162.212890, -3031.909423, 1.287268, 0.000000, 0.000000, -50.099998, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(669, 5258.204101, -3109.815429, 3.764260, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(669, 5307.472167, -3280.742431, 6.385340, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(16061, 5298.814941, -3251.353515, 1.272629, 0.000000, 0.000000, 83.820137, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(705, 5440.517578, -3276.886230, 6.082290, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(830, 5211.614257, -3364.363037, 1.934918, 0.000000, 0.000000, 114.660003, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(830, 5207.918945, -3314.527343, 1.934918, 0.000000, 0.000000, 15.000008, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(830, 5162.339355, -3223.293945, 1.934918, 0.000000, 0.000000, -45.779998, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(830, 5208.229492, -3063.520019, 1.934918, 0.000000, 0.000000, -20.579990, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(830, 5161.420898, -3026.977539, 1.925958, 0.000000, 0.000000, 47.939998, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(830, 5174.657226, -3117.710205, 1.925958, 0.000000, 0.000000, 69.960006, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(830, 5203.606445, -3225.709228, 1.925958, 0.000000, 0.000000, -28.020000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(705, 5193.567871, -3391.489257, 1.318539, 0.000000, 0.000000, 12.899998, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(669, 5200.921875, -3368.761474, 1.381628, 0.000000, 0.000000, 24.959999, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1232, 5204.203125, -3379.522460, 3.967700, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1231, 5188.941894, -3379.390380, 3.967700, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1231, 5189.015136, -3355.518310, 3.967700, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1231, 5189.015136, -3293.018798, 3.967700, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1231, 5189.015136, -3230.520019, 3.967700, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1231, 5189.015136, -3168.021728, 3.967700, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1231, 5189.015136, -3105.522705, 3.967700, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1232, 5204.568359, -3049.742675, 3.967700, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1232, 5163.959472, -3060.552246, 5.658360, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1232, 5163.855468, -3039.493652, 5.658360, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1232, 5193.460449, -3425.036865, 5.668488, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1232, 5214.426269, -3425.085205, 5.668488, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1363, 5303.192382, -3377.190185, 2.153850, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1363, 5306.190429, -3377.275390, 2.153850, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1363, 5350.762695, -3906.092773, 2.153800, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1363, 5299.265625, -3906.676757, 2.153800, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1363, 5191.887695, -3976.701416, 2.153800, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1363, 5076.555664, -4041.106689, 2.577198, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1363, 5030.482910, -4266.751953, 2.353158, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1363, 5030.783203, -4290.187988, 2.353199, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1363, 5095.506347, -4398.670898, 2.353199, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1363, 4717.268554, -4269.193847, 2.592430, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1363, 4586.426757, -4413.749023, 2.353199, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1363, 3839.490234, -5884.844726, 6.301828, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(19877, 3844.544433, -5890.940429, 7.437038, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1363, 4558.090820, -4074.132568, 2.353538, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1363, 4558.122070, -4043.573974, 2.353538, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1367, 4558.779785, -4063.203125, 2.108400, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1367, 4558.573242, -4054.168457, 2.108400, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(737, 4527.097656, -4079.595947, 1.559900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(737, 4526.921386, -4069.259033, 1.559900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(737, 4526.937011, -4048.287109, 1.559900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(737, 4526.867187, -4037.913818, 1.559900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1257, 4521.552246, -4058.867675, 2.714230, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(737, 4899.966308, -3532.874023, 1.561789, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(737, 4900.004394, -3553.613769, 1.561789, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(737, 4899.980468, -3492.412353, 1.561789, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1226, 4934.677246, -3681.055419, 5.348090, 0.000000, 0.000000, -45.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1226, 4783.005371, -3680.886718, 5.348100, 0.000000, 0.000000, -135.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1226, 5063.293945, -3514.056884, 5.364698, 0.000000, 0.000000, 135.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1226, 5369.920898, -3796.759765, 5.364698, 0.000000, 0.000000, 45.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1278, 5495.550781, -3795.769531, 15.394680, 0.000000, 0.000000, -45.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1278, 5495.755859, -3949.208984, 15.394700, 0.000000, 0.000000, -135.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1278, 5372.613281, -3949.290771, 15.394700, 0.000000, 0.000000, 135.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1278, 5372.340820, -3796.114257, 15.394700, 0.000000, 0.000000, 35.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1226, 5369.791503, -3948.607177, 5.364698, 0.000000, 0.000000, -45.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1226, 5447.445800, -4091.735595, 5.364698, 0.000000, 0.000000, 45.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1226, 5447.304687, -4601.116210, 5.364698, 0.000000, 0.000000, -45.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1226, 5000.499023, -4600.939453, 5.364698, 0.000000, 0.000000, -135.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1226, 4654.756835, -4538.492187, 5.364698, 0.000000, 0.000000, -45.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1226, 4425.842285, -4370.993164, 5.364698, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 4431.518066, -4719.135253, 10.481780, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 4431.507812, -4868.911132, 10.481780, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 4431.501953, -5020.349609, 10.481780, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 4431.503417, -5169.246093, 10.481780, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 4431.472656, -5317.746582, 10.481780, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 4431.440917, -5469.472656, 10.481780, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 4431.490234, -5617.981933, 10.481780, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 4428.005859, -5761.276367, 10.481780, 0.000000, 0.000000, -15.659990, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 4296.243652, -5836.958496, 10.481800, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 4144.335937, -5836.953613, 10.481800, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1290, 3997.110107, -5836.930175, 10.481800, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1278, 3877.541015, -5897.252929, 19.588499, 0.000000, 0.000000, -135.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1278, 3877.810546, -5776.137207, 19.588499, 0.000000, 0.000000, -45.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1278, 3755.280273, -5864.294433, 19.588499, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1278, 3631.409912, -5897.555175, 19.588499, 0.000000, 0.000000, 135.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1278, 3631.624023, -5776.434082, 19.588499, 0.000000, 0.000000, 45.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1232, 3983.169677, -4168.291992, 4.091228, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1232, 3983.235839, -4181.862792, 4.091228, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1232, 3983.246582, -4090.798828, 4.091228, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1232, 3829.705078, -4090.817871, 4.091228, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1232, 3829.832519, -4321.531250, 4.091228, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1232, 3983.148437, -4321.872558, 4.091228, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(9697, 3964.073974, -4237.511718, 1.326900, -0.270000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7662, 4089.236083, -4166.491210, 2.064698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7662, 4029.560302, -4166.491210, 2.064698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7662, 4089.236083, -4183.556152, 2.064698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7662, 4029.560302, -4183.556152, 2.064698, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(19543, 3934.653808, -4224.217285, 1.764999, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(19543, 3919.655517, -4224.217285, 1.764979, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(9019, 3926.975341, -4205.351562, 3.401628, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(9019, 3926.984375, -4224.340332, 3.401628, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(9019, 3926.989257, -4243.226074, 3.401628, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3439, 3925.489257, -4275.625488, 5.419030, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3439, 3939.212890, -4275.547363, 5.419030, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3517, 3925.621337, -4224.445312, 12.551300, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3517, 3925.621337, -4205.302734, 12.551259, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3517, 3925.621337, -4243.677734, 12.551300, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(700, 3925.621337, -4215.061035, 1.849498, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(700, 3925.621337, -4234.417480, 1.849498, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7662, 3944.528076, -4242.625976, 2.064698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7662, 3910.968994, -4242.625976, 2.064698, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1256, 3911.633056, -4224.417968, 1.982398, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1256, 3911.633056, -4197.292480, 1.982398, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1256, 3911.633056, -4252.850097, 1.982398, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1256, 3943.825439, -4197.292480, 1.982398, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1256, 3943.825439, -4224.417968, 1.982398, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1256, 3943.825439, -4252.850097, 1.982398, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1232, 3942.459716, -4191.479492, 3.937108, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1232, 3912.573730, -4191.546386, 3.937108, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1232, 3912.629638, -4256.824707, 3.937108, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1232, 3942.591064, -4256.826171, 3.937108, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1232, 3924.061767, -4135.818847, 3.937108, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1232, 3904.325439, -4276.968261, 3.937108, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(874, 3931.981689, -4205.457519, 3.242460, 0.000000, 0.000000, -12.179988, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(874, 3931.372070, -4223.044921, 3.242460, 0.000000, 0.000000, -12.179988, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(874, 3932.296386, -4241.930175, 3.242460, 0.000000, 0.000000, -12.179988, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(874, 3922.517578, -4204.750000, 3.242460, 0.000000, 0.000000, -12.179988, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(874, 3921.280273, -4223.046386, 3.242460, 0.000000, 0.000000, -12.179988, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(874, 3921.533203, -4238.088378, 3.242460, 0.000000, 0.000000, -12.179988, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7952, 5531.975585, -3606.222412, 2.040400, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7952, 5531.975585, -3589.066650, 2.040400, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7662, 5592.931640, -3571.983154, 2.059798, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7662, 5593.011230, -3653.938720, 2.059798, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1232, 5609.305664, -3564.246337, 3.819070, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1232, 5609.525878, -3630.907714, 3.819098, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1232, 5669.811035, -3686.135986, 3.819098, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1232, 5666.061523, -3641.550537, 3.819098, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1232, 5732.221679, -3627.597656, 3.819098, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1232, 5732.272949, -3567.876708, 3.819098, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1232, 5670.126464, -3581.808349, 3.819098, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1232, 5670.038574, -3611.446533, 3.819098, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1232, 5620.593261, -3594.809570, 3.819098, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1232, 5620.704589, -3598.334472, 3.819098, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1232, 5594.782226, -3590.808349, 4.020060, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1232, 5594.667480, -3604.375732, 4.020060, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(16061, 5199.398437, -3088.100341, 1.427098, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(16061, 5198.774902, -3144.535644, 1.427098, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(16061, 5199.898925, -3213.458251, 1.427098, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(16061, 5199.230468, -3276.105468, 1.427098, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(16061, 5199.661621, -3338.729003, 1.427098, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(16061, 5176.914550, -3090.811767, 1.427098, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(16061, 5178.477539, -3160.462890, 1.427098, 0.000000, 0.000000, -1.200000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(16061, 5179.019531, -3218.527587, 1.427098, 0.000000, 0.000000, -178.679992, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(16061, 5178.706054, -3306.947021, 1.427098, 0.000000, 0.000000, 3.299849, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(691, 5173.810546, -3368.666015, 0.784039, 0.000000, 0.000000, 207.839965, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1364, 5182.280761, -3366.162841, 2.152100, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1364, 5195.722656, -3339.328125, 2.152100, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1364, 5182.301757, -3309.104980, 2.152100, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1364, 5195.624023, -3277.126220, 2.152100, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1364, 5182.272949, -3245.989257, 2.152100, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1364, 5195.735839, -3213.937255, 2.152100, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1364, 5182.335449, -3183.585205, 2.152100, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1364, 5195.704589, -3153.133789, 2.152100, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1364, 5182.277832, -3120.693115, 2.152100, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1364, 5195.718750, -3080.555664, 2.152100, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1364, 5214.195800, -3049.231445, 2.152100, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1360, 5182.085449, -3080.555664, 2.126300, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1360, 5182.184082, -3153.133789, 2.126300, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1360, 5195.891601, -3120.693115, 2.126300, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1360, 5195.885253, -3183.585205, 2.126300, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1360, 5182.128906, -3213.937255, 2.126300, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1360, 5195.838867, -3245.989257, 2.126300, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1360, 5182.149414, -3277.126220, 2.126300, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1360, 5195.919433, -3309.104980, 2.126300, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1360, 5182.118652, -3339.328125, 2.126300, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1360, 5195.940917, -3366.162841, 2.126300, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1360, 5187.670898, -3386.159423, 2.126300, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1364, 5210.729492, -3379.829589, 2.152100, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1367, 5213.988769, -3046.243896, 1.942198, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1367, 5195.441894, -3083.227294, 1.942198, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1367, 5182.509765, -3123.351806, 1.942198, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1367, 5195.686035, -3150.410400, 1.942198, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1367, 5182.503906, -3186.199462, 1.942198, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1367, 5195.887695, -3210.908935, 1.942198, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1367, 5182.367675, -3248.530273, 1.942198, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1367, 5195.510253, -3273.905273, 1.942198, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1367, 5182.312011, -3311.732177, 1.942198, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1367, 5195.770019, -3341.962890, 1.942198, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1367, 5182.292968, -3368.765869, 1.942198, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1367, 5210.750000, -3382.379150, 1.942198, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1281, 5365.532714, -3397.291503, 2.100028, 0.000000, 0.000000, 44.100009, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1281, 5373.832031, -3382.716552, 2.100028, 0.000000, 0.000000, -3.779989, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1281, 5404.378417, -3378.643798, 2.100028, 0.000000, 0.000000, -18.660030, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1281, 5403.609375, -3394.098632, 2.100028, 0.000000, 0.000000, 52.079978, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1281, 5420.518066, -3387.220214, 2.100028, 0.000000, 0.000000, -160.139968, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1281, 5444.028320, -3381.119384, 2.100028, 0.000000, 0.000000, 9.180020, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1281, 5480.782714, -3388.976806, 2.100028, 0.000000, 0.000000, 243.659683, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1281, 5514.762695, -3379.718750, 2.100028, 0.000000, 0.000000, 169.319656, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1281, 5549.564453, -3380.186035, 2.100028, 0.000000, 0.000000, 263.699432, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1281, 5569.913574, -3395.347412, 2.100028, 0.000000, 0.000000, 193.319442, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1281, 5590.734863, -3382.712402, 2.100028, 0.000000, 0.000000, 265.739105, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1255, 5375.998535, -3391.602539, 1.883419, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1255, 5385.306152, -3382.433105, 1.883419, 0.000000, 0.000000, -66.060012, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1255, 5396.794921, -3383.412841, 1.883419, 0.000000, 0.000000, -113.760063, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1255, 5408.270996, -3391.573974, 1.883419, 0.000000, 0.000000, -79.680053, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1255, 5422.041503, -3383.635253, 1.883419, 0.000000, 0.000000, -164.940032, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1255, 5434.688476, -3388.441162, 1.883419, 0.000000, 0.000000, -129.300094, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1255, 5458.880371, -3389.260986, 1.883419, 0.000000, 0.000000, -102.060096, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1255, 5456.383789, -3388.442626, 1.883419, 0.000000, 0.000000, -83.640106, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1255, 5475.722656, -3383.391357, 1.883419, 0.000000, 0.000000, -135.120071, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1255, 5482.908203, -3390.251220, 1.883419, 0.000000, 0.000000, -100.740051, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1255, 5510.963867, -3381.395996, 1.883419, 0.000000, 0.000000, -100.740051, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1255, 5524.493164, -3383.728271, 1.883419, 0.000000, 0.000000, -164.159973, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1255, 5516.992675, -3396.162109, 1.883419, 0.000000, 0.000000, -90.300102, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1255, 5515.100097, -3395.973388, 1.883419, 0.000000, 0.000000, -103.320121, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1255, 5553.797851, -3380.642333, 1.883419, 0.000000, 0.000000, -103.320121, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1255, 5573.281738, -3393.841552, 1.883419, 0.000000, 0.000000, -77.940116, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1255, 5602.452148, -3388.848388, 1.883419, 0.000000, 0.000000, -22.560100, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1281, 5373.596679, -3433.823974, 2.100028, 0.000000, 0.000000, -11.879988, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1281, 5359.385742, -3453.590087, 2.100028, 0.000000, 0.000000, -2.219980, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1281, 5334.613769, -3460.356445, 2.100028, 0.000000, 0.000000, 59.400009, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1281, 5314.117675, -3443.680175, 2.100028, 0.000000, 0.000000, 131.399978, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1255, 5360.829101, -3418.847900, 1.883419, 0.000000, 0.000000, -20.940000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1255, 5374.298828, -3438.631591, 1.883419, 0.000000, 0.000000, 53.099998, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1255, 5352.447265, -3439.315429, 1.883419, 0.000000, 0.000000, -33.119998, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1255, 5355.811523, -3452.820312, 1.883419, 0.000000, 0.000000, -102.060020, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1255, 5330.898437, -3456.965576, 1.883419, 0.000000, 0.000000, -102.060020, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1522, 4762.619628, -3333.531494, 1.511999, 0.000000, 0.000000, 130.860198, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1522, 4519.330078, -3417.630615, 1.512799, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1522, 4549.076660, -3428.321533, 7.110098, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1522, 4817.272949, -3014.096923, 1.812399, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1522, 5137.537597, -3270.814697, 1.506600, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1522, 5041.287597, -3579.260009, 1.519798, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1215, 4689.745605, -4029.105957, 16.145299, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1215, 4689.761718, -4040.544677, 16.145299, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1215, 4689.757324, -4076.249755, 16.145299, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1215, 4689.750488, -4087.687988, 16.145299, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(2773, 4689.206054, -4042.579589, 2.031800, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(2773, 4689.220703, -4044.911132, 2.031800, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(2773, 4689.175292, -4047.243652, 2.031800, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(2773, 4689.152343, -4049.605957, 2.031800, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(2773, 4689.167968, -4051.952392, 2.031800, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(2773, 4689.189941, -4074.233398, 2.031800, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(2773, 4689.187011, -4071.905029, 2.031800, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(8497, 4764.480957, -4064.730712, -1.369210, 0.000000, 0.000000, 179.280029, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(2773, 4689.197265, -4069.577880, 2.031800, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(2773, 4689.193359, -4067.248291, 2.031800, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(2773, 4689.196289, -4064.924804, 2.031800, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(2773, 4691.298828, -4053.360107, 2.031800, 0.000000, 0.000000, 89.040023, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(2773, 4693.875488, -4053.349121, 2.049839, -0.158000, 0.000000, 88.379989, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(2773, 4696.532226, -4053.329833, 2.049839, -0.158000, 0.000000, 88.559898, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(2773, 4691.021484, -4063.420410, 2.054348, 0.000000, 0.000000, 91.319976, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(2773, 4693.709472, -4063.438964, 2.049839, -0.158000, 0.000000, 91.079963, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(2773, 4696.505371, -4063.400878, 2.049839, -0.158000, 0.000000, 92.399932, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(9126, 4674.951660, -4079.185791, -2.089400, 90.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(9126, 4674.951660, -4059.153320, -2.089400, 90.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(9126, 4674.951660, -4038.289306, -2.089400, 90.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(9126, 4708.109863, -4046.906005, 6.090960, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(9126, 4708.423339, -4069.483886, 4.971280, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3437, 4699.264160, -4063.189453, 5.843860, 0.000000, 0.000000, -0.599990, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3437, 4699.260742, -4053.405517, 5.834468, 0.000000, 0.000000, -0.599990, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(8491, 4705.434082, -4058.472412, 20.746999, 0.000000, 0.000000, 131.160003, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(8491, 4702.039550, -4057.423095, 20.746999, 0.000000, 0.000000, -45.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3509, 5045.090820, -4115.356933, 1.465600, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3509, 5045.295410, -4146.843750, 1.474979, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3509, 5045.421875, -4177.892089, 1.477329, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3509, 5045.277343, -4209.333007, 1.478639, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1226, 5356.951171, -3899.515625, 5.364698, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1226, 5293.111816, -3900.693115, 5.364698, 0.000000, 0.000000, -90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3509, 4920.241210, -3512.970947, 1.501278, 0.000000, 0.000000, 40.560020, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3509, 4920.127441, -3573.197998, 1.501278, 0.000000, 0.000000, 40.560020, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3509, 4919.952636, -3451.781494, 1.501278, 0.000000, 0.000000, 40.560020, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3509, 4920.110351, -3491.143554, 1.501278, 0.000000, 0.000000, -16.739999, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3509, 4920.413574, -3535.979980, 1.501278, 0.000000, 0.000000, 103.920089, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1256, 4483.642578, -3264.297119, 2.137500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1256, 4445.863281, -3264.200683, 2.137500, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3509, 4632.627441, -3340.650146, 1.483898, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3509, 4586.150390, -3340.685058, 1.489349, 0.000000, 0.000000, -44.579990, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3509, 4579.606445, -3311.609863, 1.502529, 0.000000, 0.000000, 58.439998, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3509, 4798.917968, -3334.190917, 1.494379, 0.000000, 0.000000, 103.259986, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3509, 4798.408203, -3377.927001, 1.486320, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3509, 4798.903320, -3418.707031, 1.490280, 0.000000, 0.000000, -70.440002, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3509, 4859.090332, -3423.084472, 1.494480, 0.000000, 0.000000, 68.339988, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3509, 4859.028808, -3323.476074, 1.488620, 0.000000, 0.000000, 59.940010, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3509, 4858.943359, -3357.541015, 1.478919, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3509, 4858.990234, -3388.114501, 1.462110, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1256, 4858.615234, -3343.579833, 2.146898, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1256, 4858.670410, -3334.024658, 2.146898, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1256, 4858.581054, -3366.390869, 2.146898, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1256, 4858.630371, -3375.230468, 2.146898, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1256, 4858.593261, -3398.277587, 2.146898, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1256, 4858.625976, -3407.050048, 2.146898, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1359, 4858.872070, -3338.735839, 2.148950, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1359, 4858.718750, -3370.778320, 2.148950, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1359, 4858.655761, -3402.885742, 2.148950, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3509, 5137.062500, -3373.442626, 1.493149, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3509, 5108.515625, -3379.287841, 1.479779, 0.000000, 0.000000, 46.740028, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3509, 5107.911621, -3433.165771, 1.471459, 0.000000, 0.000000, -53.459999, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3509, 5353.115722, -3433.173828, 1.305528, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3509, 5354.335937, -3376.810302, 1.305809, 0.000000, 0.000000, -65.819976, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3509, 5296.068847, -3432.574218, 1.308400, 0.000000, 0.000000, 48.960018, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3509, 5297.017578, -3377.858642, 1.315358, 0.000000, 0.000000, 163.979949, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3509, 5119.755859, -3511.021972, 1.498118, 0.000000, 0.000000, -52.740001, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3509, 5097.178710, -3511.056884, 1.490890, 0.000000, 0.000000, 54.780010, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3509, 5075.989257, -3511.077148, 1.490890, 0.000000, 0.000000, 25.140010, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3509, 4993.913574, -3569.931884, 1.492140, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3509, 4942.795898, -3570.699707, 1.470209, 0.000000, 0.000000, 44.580009, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3509, 4970.660156, -3570.854248, 1.482419, 0.000000, 0.000000, 52.200008, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1257, 4799.573730, -3463.313232, 2.634948, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1363, 4719.041992, -3461.456054, 2.352988, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1363, 4719.010742, -3455.559814, 2.352988, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3509, 4774.785156, -3455.250000, 1.499130, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3509, 4727.479492, -3455.979736, 1.499130, 0.000000, 0.000000, 81.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(7662, 4910.056152, -3234.204345, 2.231640, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3509, 4909.827636, -3217.505859, 1.487030, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3509, 5018.916503, -4302.339843, 1.470620, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3509, 5019.546386, -4250.347167, 1.471150, 0.000000, 0.000000, 140.460021, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(736, 5097.652832, -4447.055175, 12.015548, 0.000000, 0.000000, -80.159988, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(736, 5129.852539, -4460.303222, 12.015548, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(736, 5113.048339, -4461.016113, 12.015548, 0.000000, 0.000000, 105.420013, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(736, 5115.612792, -4476.697753, 12.015548, 0.000000, 0.000000, 183.059814, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(736, 5115.612792, -4476.697753, 12.015548, 0.000000, 0.000000, 183.059814, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(736, 5093.682128, -4345.247558, 12.015548, 0.000000, 0.000000, -148.199905, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(736, 5076.571777, -4342.097167, 12.015548, 0.000000, 0.000000, -62.219951, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(736, 5026.846679, -4332.535156, 12.015548, 0.000000, 0.000000, -2.699939, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(12978, 4772.354003, -4290.353515, 1.880900, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(13027, 4772.354003, -4290.353515, 4.710700, 0.000000, 0.000000, 180.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3509, 4666.430664, -4120.831542, 1.280460, 0.000000, 0.000000, -1.440000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3509, 4666.635253, -4151.966796, 1.293699, 0.000000, 0.000000, 100.620018, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3509, 4879.048828, -4268.057617, 1.499930, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3509, 4879.146972, -4297.358398, 1.489789, 0.000000, 0.000000, 106.439987, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(700, 4885.552734, -3921.927734, 3.083300, 0.000000, 0.000000, -44.820011, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(700, 4885.430664, -3903.062255, 3.083300, 0.000000, 0.000000, 15.539999, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(700, 4885.782226, -3886.599853, 3.083300, 0.000000, 0.000000, -51.900009, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(700, 4885.525390, -3868.829101, 3.083300, 0.000000, 0.000000, -10.979998, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(700, 4885.673828, -3849.799804, 3.083300, 0.000000, 0.000000, -67.620002, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3509, 4771.305664, -4039.767578, 1.480090, 0.000000, 0.000000, -55.380001, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3509, 4746.719238, -4039.552001, 1.486490, 0.000000, 0.000000, 180.780029, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3509, 4848.978027, -4120.319824, 1.486490, 0.000000, 0.000000, 255.119918, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3509, 4848.971191, -4150.939453, 1.486490, 0.000000, 0.000000, 181.080047, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(737, 4900.047363, -3471.572753, 1.561789, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(737, 4848.024902, -3840.763671, 1.581230, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(737, 4828.273437, -3821.079101, 1.581230, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(737, 4765.354492, -3820.482910, 1.581230, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(737, 4754.598144, -3841.269531, 1.581230, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3509, 4744.608398, -3924.416015, 1.477460, 0.000000, 0.000000, -46.439998, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3509, 4847.691894, -3924.200683, 1.477460, 0.000000, 0.000000, -104.760032, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3509, 5174.898437, -3960.227539, 1.487848, 0.000000, 0.000000, -55.680019, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3509, 5174.609863, -4074.715332, 1.487848, 0.000000, 0.000000, -55.680019, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3509, 5174.917480, -4043.503173, 1.487848, 0.000000, 0.000000, -7.740028, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3509, 5174.904785, -3991.349365, 1.487848, 0.000000, 0.000000, -97.500000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1522, 5349.907226, -4108.362792, 1.512858, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3509, 4744.165039, -3872.303710, 1.477460, 0.000000, 0.000000, -124.740028, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(821, 4923.207519, -2621.912109, 2.951148, 0.000000, 0.000000, -12.180000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(821, 4949.031250, -2622.330810, 2.951148, 0.000000, 0.000000, 69.900009, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(821, 4975.542480, -2623.103759, 2.951148, 0.000000, 0.000000, -40.740001, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(821, 5002.776855, -2623.346923, 2.951148, 0.000000, 0.000000, 37.020000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(821, 5034.931640, -2623.983886, 2.951148, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(821, 5059.390625, -2596.374023, 2.951148, 0.000000, 0.000000, -76.259979, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(821, 5034.806152, -2596.988769, 2.951148, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(821, 5003.000488, -2597.360107, 2.951148, 0.000000, 0.000000, -37.020000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(821, 4976.087890, -2598.427978, 2.951148, 0.000000, 0.000000, -57.240001, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(821, 4950.448242, -2599.383544, 2.951148, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(821, 4924.470214, -2597.469726, 2.951148, 0.000000, 0.000000, 19.680000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(821, 4923.730468, -2570.557128, 2.951148, 0.000000, 0.000000, -43.020000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(821, 4950.419433, -2571.949707, 2.951148, 0.000000, 0.000000, 58.740001, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(821, 4974.123535, -2573.767578, 2.951148, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(821, 5002.904296, -2573.868896, 2.951148, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(821, 5034.164550, -2571.500488, 2.951148, 0.000000, 0.000000, 53.760009, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(821, 5061.921875, -2571.392822, 2.951148, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(821, 5061.791015, -2538.870117, 2.951148, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(821, 5034.669433, -2537.696044, 2.951148, 0.000000, 0.000000, 64.079986, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(821, 5003.438964, -2538.550048, 2.951148, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(821, 4975.409667, -2538.709960, 2.951148, 0.000000, 0.000000, -52.140018, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(821, 4949.999023, -2539.443847, 2.951148, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(821, 4924.232910, -2539.959228, 2.951148, 0.000000, 0.000000, 43.439998, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(821, 5062.346679, -2507.631591, 2.951148, 0.000000, 0.000000, 86.820022, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(821, 5034.954101, -2508.614746, 2.951148, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(821, 5003.846191, -2510.445800, 2.951148, 0.000000, 0.000000, 54.240001, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(821, 4975.773437, -2509.919677, 2.951148, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(821, 4952.563476, -2510.549072, 2.951148, 0.000000, 0.000000, -74.699996, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(821, 4925.401367, -2509.648437, 2.951148, 0.000000, 0.000000, -102.480010, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(740, 4960.715820, -2555.132324, 1.247390, 0.000000, 0.000000, -65.519989, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(740, 5066.936523, -2581.160156, 1.186758, 0.000000, 0.000000, -92.220001, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5016.953613, -2585.456298, 16.488630, 0.000000, 0.000000, 23.340000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4936.855468, -2615.243164, 16.488630, 0.000000, 0.000000, -174.419967, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4949.841796, -2521.979492, 16.488630, 0.000000, 0.000000, -318.479949, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(622, 5020.890136, -2523.462890, 0.899140, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4903.104980, -2590.265625, 16.627660, 0.000000, 0.000000, -174.419967, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4918.353515, -2679.059082, 16.627660, 0.000000, 0.000000, -242.519912, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3509, 4903.690429, -2842.731201, -1.863800, 0.000000, 0.000000, -126.479972, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4988.471679, -2724.676757, 15.274620, 0.000000, 0.000000, -314.219909, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(740, 5069.405273, -2709.007812, -5.554998, 0.000000, 0.000000, 6.300000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4938.489746, -2800.482177, 6.454380, 0.000000, 0.000000, -201.059753, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4948.117187, -2840.991943, 15.776248, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4898.780273, -2740.996337, 12.158670, 0.000000, 0.000000, -53.340000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(622, 4893.182128, -2689.189208, 0.196878, 0.000000, 0.000000, 76.739982, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(622, 4963.330078, -2780.702636, 0.080288, 0.000000, 0.000000, 622.080505, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(622, 5066.217285, -2804.254882, 0.080288, 0.000000, 0.000000, 675.180664, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(622, 5258.494628, -2880.844238, 0.080288, 0.000000, 0.000000, 674.280700, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(622, 5367.656250, -2994.974609, 0.082639, 0.000000, 0.000000, 674.280700, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(622, 5567.076660, -3097.790039, 0.082639, 0.000000, 0.000000, 767.040588, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(622, 5619.110839, -3223.738769, -0.163858, 0.000000, 0.000000, 595.380004, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(622, 5552.317382, -3401.903076, -3.527478, 0.000000, 0.000000, 573.959411, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(622, 5255.534667, -3475.975341, -3.527478, 0.000000, 0.000000, 529.379516, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(622, 5254.238281, -3563.363037, -3.527478, 0.000000, 0.000000, 409.919647, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(622, 5794.786621, -3568.380126, -3.527478, 0.000000, 0.000000, 686.098388, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(622, 5484.231445, -3560.696777, -3.527478, 0.000000, 0.000000, 558.838928, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(622, 5524.111328, -3923.806396, -3.527478, 0.000000, 0.000000, 805.438537, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(622, 5319.791503, -4046.979980, -3.527478, 0.000000, 0.000000, 963.598693, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(622, 5472.444335, -4215.145996, -3.527478, 0.000000, 0.000000, 965.638610, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(622, 5474.083496, -4374.349609, -3.527478, 0.000000, 0.000000, 1028.397949, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(622, 5308.130859, -4626.680175, -3.527478, 0.000000, 0.000000, 899.457153, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(622, 5046.909667, -4619.711914, -3.527478, 0.000000, 0.000000, 727.676696, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(622, 5167.689941, -4372.549316, -3.527478, 0.000000, 0.000000, 592.497009, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(622, 5171.144531, -4322.645507, -3.527478, 0.000000, 0.000000, 668.036682, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(622, 5254.031738, -4381.208496, -3.527478, 0.000000, 0.000000, 763.976745, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(622, 4711.281250, -4343.214843, -3.527478, 0.000000, 0.000000, 562.676635, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(622, 4678.725097, -4538.403320, -3.527478, 0.000000, 0.000000, 663.776123, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(622, 4463.209960, -4685.851562, -3.527478, 0.000000, 0.000000, 778.135864, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(622, 4400.076660, -4387.872070, -3.527478, 0.000000, 0.000000, 827.515686, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(622, 4401.812500, -4304.495605, -3.527478, 0.000000, 0.000000, 796.316223, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(622, 4481.285644, -4060.534179, -3.527478, 0.000000, 0.000000, 833.756286, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(622, 4491.810058, -3916.146972, -3.527478, 0.000000, 0.000000, 751.976562, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(622, 4756.895019, -3768.124511, -3.527478, 0.000000, 0.000000, 710.156555, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(622, 4766.983398, -3707.790283, -3.527478, 0.000000, 0.000000, 571.016113, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(622, 4929.085449, -3706.968750, -3.527478, 0.000000, 0.000000, 579.055541, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(622, 5047.248046, -3774.387695, -3.527478, 0.000000, 0.000000, 691.075683, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(622, 5241.170898, -3769.837890, -3.527478, 0.000000, 0.000000, 746.455261, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(622, 4417.224609, -3785.563476, -3.527478, 0.000000, 0.000000, 877.316284, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(622, 4272.931640, -3785.870605, -3.527478, 0.000000, 0.000000, 923.516174, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(622, 4200.277343, -3648.826416, -3.527478, 0.000000, 0.000000, 753.656188, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(622, 4477.634277, -3482.953857, -3.527478, 0.000000, 0.000000, 739.196533, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(622, 4403.842773, -3136.472167, -8.745900, 0.000000, 0.000000, 822.175720, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(622, 4395.960937, -2961.634765, -3.527478, 0.000000, 0.000000, 653.035827, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(622, 4403.256835, -2771.063720, -3.527478, 0.000000, 0.000000, 792.896118, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(622, 4502.760742, -2763.881347, -3.527478, 0.000000, 0.000000, 914.095397, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(622, 4692.275390, -2877.965820, -3.527478, 0.000000, 0.000000, 975.895507, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(622, 4758.879394, -2929.705566, -3.527478, 0.000000, 0.000000, 822.355041, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(622, 4598.622558, -3040.058349, -3.527478, 0.000000, 0.000000, 677.574951, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4997.814453, -2893.657958, 15.776248, 0.000000, 0.000000, -48.899990, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5045.020019, -2901.009033, 15.776248, 0.000000, 0.000000, 1.380020, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5058.624023, -2849.330810, 15.776248, 0.000000, 0.000000, 48.000038, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5097.055175, -2813.709228, 15.776248, 0.000000, 0.000000, -84.659973, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5146.714355, -2824.966796, 15.776248, 0.000000, 0.000000, -84.659973, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5221.220214, -2821.367919, 15.776248, 0.000000, 0.000000, 49.500038, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5255.578125, -2851.862060, 15.776248, 0.000000, 0.000000, 162.719970, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5236.375488, -2966.392333, 15.776248, 0.000000, 0.000000, 162.719970, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5290.405273, -3014.651611, 15.776248, 0.000000, 0.000000, 95.700057, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5320.093261, -2985.520507, 15.776248, 0.000000, 0.000000, 174.420059, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5357.410156, -3035.961181, 14.562140, 0.000000, 0.000000, 174.420059, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5330.095703, -3076.453857, 5.070300, 0.000000, 0.000000, 106.020187, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5399.816894, -3121.093750, 5.070300, 0.000000, 0.000000, 24.960180, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5452.402343, -3103.448730, 14.562140, 0.000000, 0.000000, 208.440109, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5527.104980, -3121.855224, 14.562140, 0.000000, 0.000000, 106.740150, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5597.152832, -3102.775878, 14.562140, 0.000000, 0.000000, 190.980133, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5584.462402, -3159.926757, 17.514329, 0.000000, 0.000000, 114.900177, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5597.875488, -3250.867919, 16.670019, 0.000000, 0.000000, 114.900177, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5600.753906, -3327.050292, 16.670019, 0.000000, 0.000000, 53.700180, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5576.607910, -3381.887207, 16.670019, 0.000000, 0.000000, 162.600189, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5506.228027, -3377.685058, 16.670019, 0.000000, 0.000000, 90.960189, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5493.733398, -3394.160888, 11.256508, 0.000000, 0.000000, 90.960189, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5424.406250, -3367.280273, 19.932989, 0.000000, 0.000000, 90.960189, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5368.141113, -3421.690429, 16.670019, 0.000000, 0.000000, 31.860210, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5348.420898, -3462.467041, 10.753930, 0.000000, 0.000000, -67.619789, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5299.857421, -3461.240722, 14.386520, 0.000000, 0.000000, -26.099790, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5221.563476, -3455.715820, 14.386520, 0.000000, 0.000000, 72.600189, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5160.200195, -3471.761474, 14.386520, 0.000000, 0.000000, -110.039802, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5171.846191, -3523.836181, 12.863510, 0.000000, 0.000000, -13.139800, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5159.583007, -3568.272216, 12.863510, 0.000000, 0.000000, 106.800209, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5221.017578, -3576.687500, 9.854290, 0.000000, 0.000000, 23.220209, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5282.965820, -3621.295166, 9.854290, 0.000000, 0.000000, -37.199798, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5207.389648, -3629.081787, 15.527778, 0.000000, 0.000000, -128.759811, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5090.677246, -3614.579345, 15.527778, 0.000000, 0.000000, -240.839752, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5025.627441, -3627.459716, 13.270408, 0.000000, 0.000000, -147.119720, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5001.461425, -3612.116455, 15.527778, 0.000000, 0.000000, -61.019729, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5025.627441, -3627.459716, 13.270408, 0.000000, 0.000000, -147.119720, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4948.820800, -3646.900146, 13.272000, 0.000000, 0.000000, 48.840259, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4942.909179, -3705.500000, 10.187178, 0.000000, 0.000000, 148.080261, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4892.615722, -3692.679199, 13.272000, 0.000000, 0.000000, 48.840259, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4820.851074, -3701.786132, 16.285469, 0.000000, 0.000000, -55.979740, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4768.130371, -3668.334228, 16.083759, 0.000000, 0.000000, -161.939743, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4772.953613, -3618.464111, 16.083759, 0.000000, 0.000000, -97.679733, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4720.745117, -3610.756347, 16.083759, 0.000000, 0.000000, -112.619728, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4660.441406, -3620.284423, 16.083759, 0.000000, 0.000000, -168.359786, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4637.496093, -3610.942382, 16.083759, 0.000000, 0.000000, -234.299774, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4574.840820, -3631.338867, 14.701700, 0.000000, 0.000000, -234.299774, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4523.988769, -3614.548339, 14.701700, 0.000000, 0.000000, -126.779869, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4537.315917, -3684.802246, 15.839368, 0.000000, 0.000000, -197.879821, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4525.597656, -3723.236328, 10.626580, 0.000000, 0.000000, -301.919769, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4494.575195, -3781.447265, 15.839368, 0.000000, 0.000000, -301.919769, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4434.183593, -3770.392578, 15.839368, 0.000000, 0.000000, -301.919769, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4365.975585, -3780.123535, 15.839368, 0.000000, 0.000000, -181.139816, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4308.808105, -3766.276611, 9.987508, 0.000000, 0.000000, -312.839782, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4220.987304, -3778.560791, 13.577798, 0.000000, 0.000000, -231.299728, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4205.752441, -3720.892822, 11.206978, 0.000000, 0.000000, -181.499725, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4223.387207, -3651.848388, 16.260629, 0.000000, 0.000000, -353.459747, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4295.765136, -3658.869384, 16.260629, 0.000000, 0.000000, -144.180023, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4352.426757, -3663.091308, 16.260629, 0.000000, 0.000000, -126.960067, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4334.172851, -3607.692871, 14.516868, 0.000000, 0.000000, -126.960067, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4367.903808, -3550.856689, 15.128438, 0.000000, 0.000000, -153.479965, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4426.180175, -3571.630126, 15.128438, 0.000000, 0.000000, -110.879997, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4461.949707, -3550.047363, 14.693208, 0.000000, 0.000000, -189.960037, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4494.311523, -3515.072509, 5.401998, 0.000000, 0.000000, -234.419982, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4485.947753, -3487.291503, 14.274160, 0.000000, 0.000000, -234.419982, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4489.935546, -3402.444335, 16.829860, 0.000000, 0.000000, -304.319946, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4473.806640, -3341.559082, 14.351220, 0.000000, 0.000000, -335.459899, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4498.330078, -3320.956542, 14.351220, 0.000000, 0.000000, -406.679687, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4423.519531, -3316.113525, 14.351220, 0.000000, 0.000000, -406.679687, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4355.663085, -3337.048583, 13.694190, 0.000000, 0.000000, -406.679687, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4329.232421, -3285.509033, 6.108530, 0.000000, 0.000000, -511.799743, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4336.029296, -3233.045654, 10.365900, 0.000000, 0.000000, -630.959594, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4323.911132, -3222.784179, 15.999340, 0.000000, 0.000000, -558.719360, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4381.479492, -3213.553710, 15.999340, 0.000000, 0.000000, -574.199584, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4402.481933, -3206.071044, 12.191068, 0.000000, 0.000000, -449.940551, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4411.426757, -3170.713867, 16.316740, 0.000000, 0.000000, -546.840270, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4418.627441, -3108.521240, 16.316740, 0.000000, 0.000000, -665.459899, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4400.410644, -3053.852539, 14.751210, 0.000000, 0.000000, -472.619964, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4410.875976, -3007.930175, 14.751210, 0.000000, 0.000000, -578.760131, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4394.597656, -2980.653808, 13.854688, 0.000000, 0.000000, -694.680114, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4419.908203, -2937.075683, 13.854688, 0.000000, 0.000000, -770.820007, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4419.752441, -2918.727539, 10.043580, 0.000000, 0.000000, -573.180541, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4401.172851, -2874.514648, 16.235250, 0.000000, 0.000000, -573.180541, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4415.870117, -2849.810546, 16.235250, 0.000000, 0.000000, -501.480834, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4410.337402, -2785.141357, 15.632180, 0.000000, 0.000000, -501.480834, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4409.143066, -2797.721191, 12.060178, 0.000000, 0.000000, -418.500885, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4443.348144, -2772.343261, 15.632180, 0.000000, 0.000000, -574.080627, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4475.553222, -2777.511230, 15.632180, 0.000000, 0.000000, -446.820617, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4541.449707, -2757.427001, 15.611268, 0.000000, 0.000000, -553.860473, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4572.863281, -2777.439208, 15.939290, 0.000000, 0.000000, -455.400695, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4619.011718, -2760.531250, 13.912618, 0.000000, 0.000000, -548.400451, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4648.515625, -2776.546630, 16.708789, 0.000000, 0.000000, -482.340759, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4692.309570, -2760.806884, 8.522870, 0.000000, 0.000000, -555.780639, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4674.633300, -2800.545654, 13.672698, 0.000000, 0.000000, -457.800811, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4681.472167, -2848.616210, 16.251869, 0.000000, 0.000000, -518.400817, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4687.951171, -2833.714355, 10.046930, 0.000000, 0.000000, -424.561004, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4677.637207, -2817.960937, 15.839488, 0.000000, 0.000000, -424.561004, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4676.097167, -2908.084716, 15.839488, 0.000000, 0.000000, -457.920806, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4684.277832, -2951.629882, 14.532428, 0.000000, 0.000000, -368.100738, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4598.811523, -2945.077636, 14.532428, 0.000000, 0.000000, -261.720764, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4543.287109, -2969.661621, 14.707288, 0.000000, 0.000000, -261.720764, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4526.880859, -3013.836914, 15.393090, 0.000000, 0.000000, -261.720764, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4532.424316, -3054.006103, 5.339088, 0.000000, 0.000000, -384.600738, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4576.493652, -3045.339599, 15.850978, 0.000000, 0.000000, -475.380706, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4672.798828, -3058.350585, 13.116728, 0.000000, 0.000000, -585.600830, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4642.005859, -3049.520751, 15.769080, 0.000000, 0.000000, -447.121002, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4733.335449, -3040.312255, 14.441598, 0.000000, 0.000000, -580.080993, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4778.586914, -3011.450683, 14.441598, 0.000000, 0.000000, -672.960937, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4770.554687, -2916.835205, 16.436019, 0.000000, 0.000000, -814.260925, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4838.704589, -2904.073242, 16.436019, 0.000000, 0.000000, -941.820190, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4791.820800, -2882.148681, 10.949378, 0.000000, 0.000000, -837.360229, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4865.854980, -2878.779052, 15.290658, 0.000000, 0.000000, -846.360595, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4907.109375, -2899.871582, 15.290658, 0.000000, 0.000000, -753.420837, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4939.269531, -2879.975097, 15.290658, 0.000000, 0.000000, -849.360900, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4968.044433, -2882.315917, 15.728348, 0.000000, 0.000000, -905.520629, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5474.038085, -3624.705566, 14.944898, 0.000000, 0.000000, 90.960189, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5530.685546, -3607.668945, 14.944898, 0.000000, 0.000000, 202.080154, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5590.725585, -3607.407714, 13.033928, 0.000000, 0.000000, 91.740173, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5571.969726, -3693.916748, 12.517040, 0.000000, 0.000000, 171.480117, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5578.799804, -3582.769531, 16.358770, 0.000000, 0.000000, 46.080150, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5625.285156, -3538.236328, 15.378950, 0.000000, 0.000000, 122.880187, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5590.458007, -3518.008056, 13.724470, 0.000000, 0.000000, 12.780179, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5683.864746, -3523.577636, 15.097438, 0.000000, 0.000000, 112.920196, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5784.411132, -3658.902587, 15.097438, 0.000000, 0.000000, 192.840164, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5771.542968, -3617.922363, 7.595048, 0.000000, 0.000000, 77.700126, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5782.618164, -3730.321533, 7.595048, 0.000000, 0.000000, 181.080139, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5710.623535, -3724.224853, 16.694839, 0.000000, 0.000000, 181.080139, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5653.223144, -3735.422363, 14.124138, 0.000000, 0.000000, 117.540138, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5746.105957, -3765.905517, 15.640500, 0.000000, 0.000000, 110.520126, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5169.122558, -3784.282226, 16.239759, 0.000000, 0.000000, 190.140243, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5226.325683, -3770.314453, 9.924928, 0.000000, 0.000000, 190.140243, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5296.282714, -3772.028808, 15.274310, 0.000000, 0.000000, -10.739740, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5363.182128, -3785.498779, 16.702150, 0.000000, 0.000000, 113.640243, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5356.435058, -3766.876953, 12.508218, 0.000000, 0.000000, 25.320249, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5426.901367, -3789.827392, 16.702150, 0.000000, 0.000000, 226.920181, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5466.242187, -3766.661621, 14.010780, 0.000000, 0.000000, 226.920181, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5521.881347, -3770.473388, 12.421580, 0.000000, 0.000000, 181.140182, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5507.464355, -3811.927734, 15.787520, 0.000000, 0.000000, 117.480186, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5523.577636, -3911.944335, 15.340108, 0.000000, 0.000000, 226.920181, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5507.832031, -3862.955078, 16.097089, 0.000000, 0.000000, 42.120189, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5416.439941, -3965.640869, 16.097089, 0.000000, 0.000000, 42.120189, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5476.906738, -3962.517822, 16.097089, 0.000000, 0.000000, 42.120189, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5302.863281, -3959.034912, 13.871890, 0.000000, 0.000000, 42.120189, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5316.526855, -3997.338867, 13.549400, 0.000000, 0.000000, -95.099822, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5318.614746, -3963.051757, 7.228549, 0.000000, 0.000000, -95.099822, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5303.007324, -4044.935058, 13.549400, 0.000000, 0.000000, -166.079833, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5322.408691, -4031.945312, 10.838910, 0.000000, 0.000000, -140.039947, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5389.822753, -4079.830322, 16.413869, 0.000000, 0.000000, -140.039947, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5432.743164, -4085.648193, 16.413869, 0.000000, 0.000000, -226.379928, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5469.648925, -4073.167480, 5.131810, 0.000000, 0.000000, -187.019927, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5457.246582, -4141.309570, 16.413869, 0.000000, 0.000000, -98.099937, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5469.336914, -4160.021484, 15.411700, 0.000000, 0.000000, -98.099937, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5455.117187, -4229.715332, 10.056200, 0.000000, 0.000000, -132.119918, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5457.767089, -4263.713378, 16.413869, 0.000000, 0.000000, -28.559930, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5475.369628, -4308.470703, 15.397608, 0.000000, 0.000000, -28.559930, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5455.146484, -4405.089843, 16.014789, 0.000000, 0.000000, -28.559930, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5468.755859, -4457.825195, 15.515460, 0.000000, 0.000000, -28.559930, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5457.691406, -4487.389160, 16.014789, 0.000000, 0.000000, -28.559930, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5453.608886, -4509.717773, 14.600040, 0.000000, 0.000000, -67.559936, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5474.197265, -4550.605468, 16.065549, 0.000000, 0.000000, -28.559930, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5463.861816, -4625.596679, 15.595218, 0.000000, 0.000000, -28.559930, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5422.572753, -4614.188476, 15.215860, 0.000000, 0.000000, 63.360069, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5474.197265, -4550.605468, 16.065549, 0.000000, 0.000000, -28.559930, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5382.349609, -4606.757812, 15.215860, 0.000000, 0.000000, -13.859918, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5350.227050, -4623.518554, 12.288378, 0.000000, 0.000000, -86.579917, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5302.739257, -4608.761230, 15.215860, 0.000000, 0.000000, 121.080070, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(622, 5324.114257, -4554.634277, 0.002928, 0.000000, 0.000000, 941.937194, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5403.166015, -4557.349609, 16.791820, 0.000000, 0.000000, 37.380031, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5253.591308, -4621.239257, 14.782250, 0.000000, 0.000000, 29.940080, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5196.217285, -4631.268066, 14.542658, 0.000000, 0.000000, 121.080070, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5165.882324, -4606.311523, 14.782250, 0.000000, 0.000000, 29.940080, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5099.787597, -4630.195312, 13.783728, 0.000000, 0.000000, 29.940080, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5056.295898, -4615.794433, 16.125429, 0.000000, 0.000000, 104.760093, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5012.622558, -4624.942871, 14.167738, 0.000000, 0.000000, 71.400070, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4980.150390, -4611.190917, 15.490159, 0.000000, 0.000000, 153.720092, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4986.569824, -4524.650390, 15.490159, 0.000000, 0.000000, 282.240051, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4981.124023, -4348.756347, 16.390260, 0.000000, 0.000000, 229.800048, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4954.970703, -4328.073730, 8.101948, 0.000000, 0.000000, 161.520080, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4907.911621, -4340.494140, 16.341829, 0.000000, 0.000000, 229.800048, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4845.523925, -4327.059570, 16.341829, 0.000000, 0.000000, 309.000122, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4792.178710, -4340.935546, 15.775918, 0.000000, 0.000000, 216.540069, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4800.837890, -4336.370605, 12.272688, 0.000000, 0.000000, 320.339996, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4728.548828, -4333.587402, 16.341829, 0.000000, 0.000000, 309.000122, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4665.192382, -4376.623535, 16.341829, 0.000000, 0.000000, 201.660186, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4678.428222, -4458.530273, 12.569608, 0.000000, 0.000000, 162.480224, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4619.580566, -4564.036132, 14.906128, 0.000000, 0.000000, 162.480224, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4522.188964, -4550.005859, 14.906128, 0.000000, 0.000000, 123.060218, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4415.987304, -4628.948242, 14.906128, 0.000000, 0.000000, 3.240230, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4402.790039, -4522.051757, 14.906128, 0.000000, 0.000000, 103.560226, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4410.422363, -4292.678710, 14.906128, 0.000000, 0.000000, 103.560226, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4397.708984, -4213.566406, 12.827158, 0.000000, 0.000000, -37.079780, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4334.716796, -4192.621582, 16.205549, 0.000000, 0.000000, -61.559780, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4009.983886, -4261.295410, 14.918660, 0.000000, 0.000000, -61.559780, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(622, 3997.637695, -4333.307128, -3.527478, 0.000000, 0.000000, 919.136474, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(622, 4058.949462, -4207.081542, -3.527478, 0.000000, 0.000000, 1110.297363, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(622, 4050.376953, -4148.574707, -3.527478, 0.000000, 0.000000, 1326.236694, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 3997.859130, -4137.158203, 13.532778, 0.000000, 0.000000, -159.599731, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 3950.624023, -4079.529296, 16.299249, 0.000000, 0.000000, -289.199707, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 3882.655761, -4070.754150, 16.299249, 0.000000, 0.000000, -371.339782, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 3932.413085, -4329.926269, 14.918660, 0.000000, 0.000000, 181.260238, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 3899.730957, -4330.333496, 7.431540, 0.000000, 0.000000, 59.940219, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 3817.575683, -4313.025878, 15.830510, 0.000000, 0.000000, 59.940219, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 3813.269287, -4183.315917, 15.020858, 0.000000, 0.000000, 161.700225, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 3837.252929, -4084.776367, 12.966650, 0.000000, 0.000000, 161.700225, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(622, 3812.345703, -4195.665527, -3.527478, 0.000000, 0.000000, 1142.938598, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4295.024902, -4149.488281, 16.205549, 0.000000, 0.000000, 8.820219, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4411.943847, -4155.570800, 16.205549, 0.000000, 0.000000, 33.960220, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4488.398925, -4113.686523, 16.205549, 0.000000, 0.000000, -62.459770, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4497.597656, -4019.696777, 14.242118, 0.000000, 0.000000, -163.379745, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4477.390136, -3993.959472, 15.771860, 0.000000, 0.000000, -212.459701, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4495.307128, -3939.498779, 7.644868, 0.000000, 0.000000, -258.059600, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4588.264648, -3922.593017, 15.105348, 0.000000, 0.000000, -258.059600, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4609.161132, -3906.131347, 7.591310, 0.000000, 0.000000, -315.959411, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4625.442871, -3781.570068, 7.599840, 0.000000, 0.000000, -315.959411, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4699.253906, -3788.117675, 16.497980, 0.000000, 0.000000, -461.879516, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4734.156250, -3781.189453, 11.665988, 0.000000, 0.000000, -461.879516, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4819.320800, -3787.464111, 16.377649, 0.000000, 0.000000, -576.299560, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 4924.538574, -3776.954833, 16.278190, 0.000000, 0.000000, -679.979553, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(740, 4862.838867, -2894.633300, 1.247390, 0.000000, 0.000000, -154.079971, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(740, 4690.139160, -3059.032958, 1.247390, 0.000000, 0.000000, -76.859992, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(740, 4575.979492, -2945.054687, 1.247390, 0.000000, 0.000000, -190.319992, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(740, 4627.810058, -2769.878417, -17.650699, 0.000000, 0.000000, -190.319992, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(740, 4416.459960, -2857.591064, -17.650699, 0.000000, 0.000000, -224.099914, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(740, 4362.761230, -3205.073242, -17.650699, 0.000000, 0.000000, -224.099914, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(740, 4472.139648, -3413.839111, -3.588880, 0.000000, 0.000000, -224.099914, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(740, 4627.511230, -3623.056152, -3.588880, 0.000000, 0.000000, -408.839874, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(740, 4880.155273, -3780.833251, 0.598268, 0.000000, 0.000000, -315.719909, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(740, 5449.914062, -3963.681640, 0.598268, 0.000000, 0.000000, -315.719909, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(740, 5169.289550, -4483.849609, 0.598268, 0.000000, 0.000000, -315.719909, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5258.565429, -4321.615722, 16.014789, 0.000000, 0.000000, 69.120071, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5261.900878, -4474.425781, 11.237000, 0.000000, 0.000000, -66.179916, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(710, 5159.885253, -4385.848144, 11.237000, 0.000000, 0.000000, -66.179916, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(740, 4857.456542, -4336.521972, 0.598268, 0.000000, 0.000000, -315.719909, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(740, 4441.679199, -4152.829589, 0.598268, 0.000000, 0.000000, -315.719909, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(740, 4490.667968, -3972.979248, -12.687890, 0.000000, 0.000000, -380.339965, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(737, 4915.628417, -4193.311035, 1.563240, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(737, 4884.514160, -4194.248046, 1.563240, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(737, 4915.768554, -4169.439941, 1.563240, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(737, 4884.403320, -4169.392089, 1.563240, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1211, 4877.216308, -4161.753906, 2.001348, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1211, 5024.480468, -4100.493652, 1.919909, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1211, 5106.735839, -4226.246093, 1.884899, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1211, 4879.195800, -4305.872558, 1.896780, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1211, 4635.266601, -4325.829101, 1.907490, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1211, 4446.612792, -4370.679199, 1.885400, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1211, 4578.354003, -4028.198242, 1.872220, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1211, 4639.931152, -4111.566406, 1.915539, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1211, 4739.096191, -3955.038574, 1.901389, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1211, 5157.235839, -3900.593017, 1.860579, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1211, 5354.653320, -3930.672851, 1.908048, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1211, 5276.775390, -4045.908447, 1.897809, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1211, 4917.716308, -3608.908935, 1.859230, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1211, 4812.754882, -3566.959716, 1.895110, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1211, 4755.209472, -3313.636962, 1.893620, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1211, 4803.319824, -3043.583251, 1.873970, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1211, 4871.124023, -3285.989746, 1.894448, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(3509, 4910.907226, -3372.717041, 1.478919, 0.000000, 0.000000, -138.959976, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1211, 5075.082031, -3313.167480, 1.882230, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1211, 5058.839355, -3554.142089, 1.907299, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1267, 5237.634277, -3815.537841, 16.731500, 0.000000, 0.000000, 0.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1267, 5133.226074, -4003.529052, 17.428300, 0.000000, 0.000000, 90.000000, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1267, 5053.158691, -4259.278808, 17.428300, 0.000000, 0.000000, 187.620056, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1267, 4635.869140, -4185.238769, 17.428300, 0.000000, 0.000000, 187.620056, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1267, 4856.763183, -3953.170654, 17.428300, 0.000000, 0.000000, 103.020057, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1267, 4668.053710, -3567.807373, 17.428300, 0.000000, 0.000000, 194.460098, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1267, 4684.991210, -3286.760742, 17.428300, 0.000000, 0.000000, 183.180099, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1267, 4911.221679, -3121.905517, 17.428300, 0.000000, 0.000000, 264.299987, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1267, 5134.661621, -3428.696044, 17.428300, 0.000000, 0.000000, 264.299987, 0, 0, -1, 800.00, 800.00);
	tmpobjid = CreateDynamicObject(1267, 5047.907226, -3553.273681, 17.428300, 0.000000, 0.000000, 264.299987, 0, 0, -1, 800.00, 800.00);
	return true;
}
stock RemoveObjects(playerid)
{
	RemoveBuildingForPlayer(playerid, 722, -686.281, -1954.320, 14.953, 0.250);
	RemoveBuildingForPlayer(playerid, 722, -737.968, -1874.257, 6.171, 0.250);
	RemoveBuildingForPlayer(playerid, 6189, 836.445, -2003.523, -2.640, 0.250);
	RemoveBuildingForPlayer(playerid, 6191, 836.445, -2003.523, -2.640, 0.250);
	RemoveBuildingForPlayer(playerid, 1461, 820.148, -2061.062, 12.539, 0.250);
	RemoveBuildingForPlayer(playerid, 1461, 820.148, -2055.242, 12.539, 0.250);
	RemoveBuildingForPlayer(playerid, 1280, 820.281, -2019.000, 12.234, 0.250);
	RemoveBuildingForPlayer(playerid, 1280, 820.281, -2015.062, 12.234, 0.250);
	RemoveBuildingForPlayer(playerid, 1280, 820.281, -2002.968, 12.234, 0.250);
	RemoveBuildingForPlayer(playerid, 1280, 820.281, -1999.031, 12.234, 0.250);
	RemoveBuildingForPlayer(playerid, 1280, 820.281, -1968.789, 12.234, 0.250);
	RemoveBuildingForPlayer(playerid, 1280, 820.281, -1977.179, 12.234, 0.250);
	RemoveBuildingForPlayer(playerid, 1280, 820.281, -1924.515, 12.234, 0.250);
	RemoveBuildingForPlayer(playerid, 1280, 820.281, -1932.906, 12.234, 0.250);
	RemoveBuildingForPlayer(playerid, 1280, 820.281, -1901.117, 12.234, 0.250);
	RemoveBuildingForPlayer(playerid, 1280, 820.281, -1892.734, 12.234, 0.250);
	RemoveBuildingForPlayer(playerid, 638, 820.343, -2058.164, 12.539, 0.250);
	RemoveBuildingForPlayer(playerid, 638, 820.585, -1928.273, 12.539, 0.250);
	RemoveBuildingForPlayer(playerid, 1231, 820.359, -1885.070, 14.570, 0.250);
	RemoveBuildingForPlayer(playerid, 792, 820.929, -2066.179, 12.171, 0.250);
	RemoveBuildingForPlayer(playerid, 792, 820.929, -2036.695, 12.171, 0.250);
	RemoveBuildingForPlayer(playerid, 792, 820.929, -2008.914, 12.171, 0.250);
	RemoveBuildingForPlayer(playerid, 1461, 820.789, -2011.796, 12.539, 0.250);
	RemoveBuildingForPlayer(playerid, 792, 820.929, -1991.492, 12.171, 0.250);
	RemoveBuildingForPlayer(playerid, 1461, 820.789, -2005.984, 12.539, 0.250);
	RemoveBuildingForPlayer(playerid, 1231, 821.007, -1986.093, 14.570, 0.250);
	RemoveBuildingForPlayer(playerid, 792, 820.929, -1973.492, 12.171, 0.250);
	RemoveBuildingForPlayer(playerid, 1461, 820.789, -1980.562, 12.539, 0.250);
	RemoveBuildingForPlayer(playerid, 1461, 820.789, -1965.976, 12.539, 0.250);
	RemoveBuildingForPlayer(playerid, 792, 820.929, -1950.171, 12.171, 0.250);
	RemoveBuildingForPlayer(playerid, 1461, 820.789, -1936.296, 12.539, 0.250);
	RemoveBuildingForPlayer(playerid, 1231, 820.835, -1917.734, 14.570, 0.250);
	RemoveBuildingForPlayer(playerid, 1461, 820.789, -1921.703, 12.539, 0.250);
	RemoveBuildingForPlayer(playerid, 1231, 820.835, -1907.578, 14.570, 0.250);
	RemoveBuildingForPlayer(playerid, 1461, 820.789, -1904.507, 12.539, 0.250);
	RemoveBuildingForPlayer(playerid, 1461, 820.789, -1889.921, 12.539, 0.250);
	RemoveBuildingForPlayer(playerid, 1231, 821.546, -2048.898, 14.570, 0.250);
	RemoveBuildingForPlayer(playerid, 1281, 821.812, -2042.296, 12.617, 0.250);
	RemoveBuildingForPlayer(playerid, 1281, 824.796, -2036.679, 12.617, 0.250);
	RemoveBuildingForPlayer(playerid, 1281, 821.812, -2031.351, 12.617, 0.250);
	RemoveBuildingForPlayer(playerid, 1231, 821.109, -2023.742, 14.570, 0.250);
	RemoveBuildingForPlayer(playerid, 1231, 821.070, -1996.250, 14.570, 0.250);
	RemoveBuildingForPlayer(playerid, 1231, 821.101, -1961.125, 14.570, 0.250);
	RemoveBuildingForPlayer(playerid, 1281, 821.812, -1956.046, 12.617, 0.250);
	RemoveBuildingForPlayer(playerid, 1231, 821.101, -1940.679, 14.570, 0.250);
	RemoveBuildingForPlayer(playerid, 1281, 821.812, -1945.101, 12.617, 0.250);
	RemoveBuildingForPlayer(playerid, 1281, 824.156, -1950.429, 12.617, 0.250);
	RemoveBuildingForPlayer(playerid, 792, 821.085, -1912.976, 12.171, 0.250);
	RemoveBuildingForPlayer(playerid, 792, 821.085, -1897.023, 12.171, 0.250);
	RemoveBuildingForPlayer(playerid, 1281, 821.812, -1879.921, 12.617, 0.250);
	RemoveBuildingForPlayer(playerid, 792, 821.085, -1874.625, 12.171, 0.250);
	RemoveBuildingForPlayer(playerid, 1281, 824.156, -1874.304, 12.617, 0.250);
	RemoveBuildingForPlayer(playerid, 1281, 821.812, -1868.976, 12.617, 0.250);
	RemoveBuildingForPlayer(playerid, 792, 851.796, -2049.000, 12.171, 0.250);
	RemoveBuildingForPlayer(playerid, 792, 851.796, -2066.359, 12.171, 0.250);
	RemoveBuildingForPlayer(playerid, 1231, 852.453, -2060.335, 14.570, 0.250);
	RemoveBuildingForPlayer(playerid, 1461, 852.734, -2055.242, 12.539, 0.250);
	RemoveBuildingForPlayer(playerid, 638, 852.531, -2058.164, 12.539, 0.250);
	RemoveBuildingForPlayer(playerid, 1280, 852.609, -2042.554, 12.234, 0.250);
	RemoveBuildingForPlayer(playerid, 1231, 852.453, -2039.687, 14.570, 0.250);
	RemoveBuildingForPlayer(playerid, 638, 852.531, -2036.390, 12.539, 0.250);
	RemoveBuildingForPlayer(playerid, 1461, 852.734, -2033.468, 12.539, 0.250);
	RemoveBuildingForPlayer(playerid, 1280, 852.609, -2030.453, 12.234, 0.250);
	RemoveBuildingForPlayer(playerid, 1231, 851.757, -2023.742, 14.570, 0.250);
	RemoveBuildingForPlayer(playerid, 1280, 852.609, -2026.523, 12.234, 0.250);
	RemoveBuildingForPlayer(playerid, 792, 851.796, -2018.031, 12.171, 0.250);
	RemoveBuildingForPlayer(playerid, 1281, 851.007, -1992.578, 12.617, 0.250);
	RemoveBuildingForPlayer(playerid, 1231, 851.757, -2012.703, 14.570, 0.250);
	RemoveBuildingForPlayer(playerid, 1231, 851.757, -1994.937, 14.570, 0.250);
	RemoveBuildingForPlayer(playerid, 1280, 852.609, -2008.890, 12.234, 0.250);
	RemoveBuildingForPlayer(playerid, 1280, 852.609, -2004.960, 12.234, 0.250);
	RemoveBuildingForPlayer(playerid, 1461, 852.734, -1997.367, 12.539, 0.250);
	RemoveBuildingForPlayer(playerid, 638, 852.531, -2000.640, 12.539, 0.250);
	RemoveBuildingForPlayer(playerid, 1281, 848.562, -1986.671, 12.617, 0.250);
	RemoveBuildingForPlayer(playerid, 792, 851.976, -1986.882, 12.171, 0.250);
	RemoveBuildingForPlayer(playerid, 1281, 851.007, -1981.632, 12.617, 0.250);
	RemoveBuildingForPlayer(playerid, 1231, 851.757, -1978.531, 14.570, 0.250);
	RemoveBuildingForPlayer(playerid, 1280, 852.609, -1974.273, 12.234, 0.250);
	RemoveBuildingForPlayer(playerid, 1280, 852.609, -1970.335, 12.234, 0.250);
	RemoveBuildingForPlayer(playerid, 792, 851.796, -1955.929, 12.171, 0.250);
	RemoveBuildingForPlayer(playerid, 1231, 852.210, -1961.125, 14.570, 0.250);
	RemoveBuildingForPlayer(playerid, 1231, 852.210, -1950.593, 14.570, 0.250);
	RemoveBuildingForPlayer(playerid, 638, 852.531, -1965.320, 12.539, 0.250);
	RemoveBuildingForPlayer(playerid, 1280, 852.609, -1942.289, 12.234, 0.250);
	RemoveBuildingForPlayer(playerid, 1280, 852.609, -1946.218, 12.234, 0.250);
	RemoveBuildingForPlayer(playerid, 792, 851.796, -1937.187, 12.171, 0.250);
	RemoveBuildingForPlayer(playerid, 1461, 852.734, -1935.375, 12.539, 0.250);
	RemoveBuildingForPlayer(playerid, 1461, 852.734, -1929.812, 12.539, 0.250);
	RemoveBuildingForPlayer(playerid, 638, 852.531, -1932.328, 12.539, 0.250);
	RemoveBuildingForPlayer(playerid, 1280, 852.609, -1926.687, 12.234, 0.250);
	RemoveBuildingForPlayer(playerid, 1280, 852.609, -1922.750, 12.234, 0.250);
	RemoveBuildingForPlayer(playerid, 1231, 852.210, -1918.742, 14.570, 0.250);
	RemoveBuildingForPlayer(playerid, 1281, 848.328, -1909.382, 12.617, 0.250);
	RemoveBuildingForPlayer(playerid, 1281, 851.007, -1904.335, 12.617, 0.250);
	RemoveBuildingForPlayer(playerid, 1281, 851.007, -1915.281, 12.617, 0.250);
	RemoveBuildingForPlayer(playerid, 792, 851.796, -1909.906, 12.171, 0.250);
	RemoveBuildingForPlayer(playerid, 1231, 852.210, -1901.242, 14.570, 0.250);
	RemoveBuildingForPlayer(playerid, 1280, 852.609, -1897.023, 12.234, 0.250);
	RemoveBuildingForPlayer(playerid, 638, 852.531, -1886.859, 12.539, 0.250);
	RemoveBuildingForPlayer(playerid, 1280, 852.609, -1893.085, 12.234, 0.250);
	RemoveBuildingForPlayer(playerid, 1461, 852.734, -1883.351, 12.539, 0.250);
	RemoveBuildingForPlayer(playerid, 1461, 852.734, -1889.835, 12.539, 0.250);
	RemoveBuildingForPlayer(playerid, 1231, 851.625, -1879.781, 14.570, 0.250);
	RemoveBuildingForPlayer(playerid, 792, 851.796, -1874.585, 12.171, 0.250);
	RemoveBuildingForPlayer(playerid, 1231, 851.625, -1869.250, 14.570, 0.250);
	RemoveBuildingForPlayer(playerid, 1231, 820.359, -1864.554, 14.570, 0.250);
	RemoveBuildingForPlayer(playerid, 1280, 820.281, -1850.210, 12.234, 0.250);
	RemoveBuildingForPlayer(playerid, 1280, 820.281, -1854.148, 12.234, 0.250);
	RemoveBuildingForPlayer(playerid, 1461, 820.789, -1857.164, 12.539, 0.250);
	RemoveBuildingForPlayer(playerid, 638, 820.585, -1860.085, 12.539, 0.250);
	RemoveBuildingForPlayer(playerid, 1231, 820.265, -1839.875, 14.570, 0.250);
	RemoveBuildingForPlayer(playerid, 792, 820.515, -1846.937, 12.046, 0.250);
	RemoveBuildingForPlayer(playerid, 1231, 819.195, -1828.687, 14.101, 0.250);
	RemoveBuildingForPlayer(playerid, 1231, 852.210, -1843.976, 14.539, 0.250);
	RemoveBuildingForPlayer(playerid, 792, 851.796, -1848.898, 12.171, 0.250);
	RemoveBuildingForPlayer(playerid, 1461, 852.734, -1851.867, 12.539, 0.250);
	RemoveBuildingForPlayer(playerid, 638, 852.531, -1855.109, 12.539, 0.250);
	RemoveBuildingForPlayer(playerid, 1280, 852.609, -1864.882, 12.234, 0.250);
	RemoveBuildingForPlayer(playerid, 1280, 852.609, -1860.953, 12.234, 0.250);
	RemoveBuildingForPlayer(playerid, 1231, 853.906, -1828.453, 13.851, 0.250);
	//--��������� � ������
	RemoveBuildingForPlayer(playerid, 6190, 836.312, -1866.757, -0.539, 0.250);
	RemoveBuildingForPlayer(playerid, 6189, 836.445, -2003.523, -2.640, 0.250);
	RemoveBuildingForPlayer(playerid, 6191, 836.445, -2003.523, -2.640, 0.250);
	RemoveBuildingForPlayer(playerid, 1461, 820.148, -2061.062, 12.539, 0.250);
	RemoveBuildingForPlayer(playerid, 1461, 820.148, -2055.242, 12.539, 0.250);
	RemoveBuildingForPlayer(playerid, 1280, 820.281, -2019.000, 12.234, 0.250);
	RemoveBuildingForPlayer(playerid, 1280, 820.281, -2015.062, 12.234, 0.250);
	RemoveBuildingForPlayer(playerid, 1280, 820.281, -2002.968, 12.234, 0.250);
	RemoveBuildingForPlayer(playerid, 1280, 820.281, -1999.031, 12.234, 0.250);
	RemoveBuildingForPlayer(playerid, 1280, 820.281, -1968.789, 12.234, 0.250);
	RemoveBuildingForPlayer(playerid, 1280, 820.281, -1977.179, 12.234, 0.250);
	RemoveBuildingForPlayer(playerid, 1280, 820.281, -1924.515, 12.234, 0.250);
	RemoveBuildingForPlayer(playerid, 1280, 820.281, -1932.906, 12.234, 0.250);
	RemoveBuildingForPlayer(playerid, 1280, 820.281, -1901.117, 12.234, 0.250);
	RemoveBuildingForPlayer(playerid, 1280, 820.281, -1892.734, 12.234, 0.250);
	RemoveBuildingForPlayer(playerid, 638, 820.343, -2058.164, 12.539, 0.250);
	RemoveBuildingForPlayer(playerid, 638, 820.585, -1928.273, 12.539, 0.250);
	RemoveBuildingForPlayer(playerid, 1231, 820.359, -1885.070, 14.570, 0.250);
	RemoveBuildingForPlayer(playerid, 792, 820.929, -2066.179, 12.171, 0.250);
	RemoveBuildingForPlayer(playerid, 792, 820.929, -2036.695, 12.171, 0.250);
	RemoveBuildingForPlayer(playerid, 792, 820.929, -2008.914, 12.171, 0.250);
	RemoveBuildingForPlayer(playerid, 1461, 820.789, -2011.796, 12.539, 0.250);
	RemoveBuildingForPlayer(playerid, 792, 820.929, -1991.492, 12.171, 0.250);
	RemoveBuildingForPlayer(playerid, 1461, 820.789, -2005.984, 12.539, 0.250);
	RemoveBuildingForPlayer(playerid, 1231, 821.007, -1986.093, 14.570, 0.250);
	RemoveBuildingForPlayer(playerid, 792, 820.929, -1973.492, 12.171, 0.250);
	RemoveBuildingForPlayer(playerid, 1461, 820.789, -1980.562, 12.539, 0.250);
	RemoveBuildingForPlayer(playerid, 1461, 820.789, -1965.976, 12.539, 0.250);
	RemoveBuildingForPlayer(playerid, 792, 820.929, -1950.171, 12.171, 0.250);
	RemoveBuildingForPlayer(playerid, 1461, 820.789, -1936.296, 12.539, 0.250);
	RemoveBuildingForPlayer(playerid, 1231, 820.835, -1917.734, 14.570, 0.250);
	RemoveBuildingForPlayer(playerid, 1461, 820.789, -1921.703, 12.539, 0.250);
	RemoveBuildingForPlayer(playerid, 1231, 820.835, -1907.578, 14.570, 0.250);
	RemoveBuildingForPlayer(playerid, 1461, 820.789, -1904.507, 12.539, 0.250);
	RemoveBuildingForPlayer(playerid, 1461, 820.789, -1889.921, 12.539, 0.250);
	RemoveBuildingForPlayer(playerid, 1231, 821.546, -2048.898, 14.570, 0.250);
	RemoveBuildingForPlayer(playerid, 1281, 821.812, -2042.296, 12.617, 0.250);
	RemoveBuildingForPlayer(playerid, 1281, 824.796, -2036.679, 12.617, 0.250);
	RemoveBuildingForPlayer(playerid, 1281, 821.812, -2031.351, 12.617, 0.250);
	RemoveBuildingForPlayer(playerid, 1231, 821.109, -2023.742, 14.570, 0.250);
	RemoveBuildingForPlayer(playerid, 1231, 821.070, -1996.250, 14.570, 0.250);
	RemoveBuildingForPlayer(playerid, 1231, 821.101, -1961.125, 14.570, 0.250);
	RemoveBuildingForPlayer(playerid, 1281, 821.812, -1956.046, 12.617, 0.250);
	RemoveBuildingForPlayer(playerid, 1231, 821.101, -1940.679, 14.570, 0.250);
	RemoveBuildingForPlayer(playerid, 1281, 821.812, -1945.101, 12.617, 0.250);
	RemoveBuildingForPlayer(playerid, 1281, 824.156, -1950.429, 12.617, 0.250);
	RemoveBuildingForPlayer(playerid, 792, 821.085, -1912.976, 12.171, 0.250);
	RemoveBuildingForPlayer(playerid, 792, 821.085, -1897.023, 12.171, 0.250);
	RemoveBuildingForPlayer(playerid, 1281, 821.812, -1879.921, 12.617, 0.250);
	RemoveBuildingForPlayer(playerid, 792, 821.085, -1874.625, 12.171, 0.250);
	RemoveBuildingForPlayer(playerid, 1281, 824.156, -1874.304, 12.617, 0.250);
	RemoveBuildingForPlayer(playerid, 1281, 821.812, -1868.976, 12.617, 0.250);
	RemoveBuildingForPlayer(playerid, 792, 851.796, -2049.000, 12.171, 0.250);
	RemoveBuildingForPlayer(playerid, 792, 851.796, -2066.359, 12.171, 0.250);
	RemoveBuildingForPlayer(playerid, 1231, 852.453, -2060.335, 14.570, 0.250);
	RemoveBuildingForPlayer(playerid, 1461, 852.734, -2055.242, 12.539, 0.250);
	RemoveBuildingForPlayer(playerid, 638, 852.531, -2058.164, 12.539, 0.250);
	RemoveBuildingForPlayer(playerid, 1280, 852.609, -2042.554, 12.234, 0.250);
	RemoveBuildingForPlayer(playerid, 1231, 852.453, -2039.687, 14.570, 0.250);
	RemoveBuildingForPlayer(playerid, 638, 852.531, -2036.390, 12.539, 0.250);
	RemoveBuildingForPlayer(playerid, 1461, 852.734, -2033.468, 12.539, 0.250);
	RemoveBuildingForPlayer(playerid, 1280, 852.609, -2030.453, 12.234, 0.250);
	RemoveBuildingForPlayer(playerid, 1231, 851.757, -2023.742, 14.570, 0.250);
	RemoveBuildingForPlayer(playerid, 1280, 852.609, -2026.523, 12.234, 0.250);
	RemoveBuildingForPlayer(playerid, 792, 851.796, -2018.031, 12.171, 0.250);
	RemoveBuildingForPlayer(playerid, 1281, 851.007, -1992.578, 12.617, 0.250);
	RemoveBuildingForPlayer(playerid, 1231, 851.757, -2012.703, 14.570, 0.250);
	RemoveBuildingForPlayer(playerid, 1231, 851.757, -1994.937, 14.570, 0.250);
	RemoveBuildingForPlayer(playerid, 1280, 852.609, -2008.890, 12.234, 0.250);
	RemoveBuildingForPlayer(playerid, 1280, 852.609, -2004.960, 12.234, 0.250);
	RemoveBuildingForPlayer(playerid, 1461, 852.734, -1997.367, 12.539, 0.250);
	RemoveBuildingForPlayer(playerid, 638, 852.531, -2000.640, 12.539, 0.250);
	RemoveBuildingForPlayer(playerid, 1281, 848.562, -1986.671, 12.617, 0.250);
	RemoveBuildingForPlayer(playerid, 792, 851.976, -1986.882, 12.171, 0.250);
	RemoveBuildingForPlayer(playerid, 1281, 851.007, -1981.632, 12.617, 0.250);
	RemoveBuildingForPlayer(playerid, 1231, 851.757, -1978.531, 14.570, 0.250);
	RemoveBuildingForPlayer(playerid, 1280, 852.609, -1974.273, 12.234, 0.250);
	RemoveBuildingForPlayer(playerid, 1280, 852.609, -1970.335, 12.234, 0.250);
	RemoveBuildingForPlayer(playerid, 792, 851.796, -1955.929, 12.171, 0.250);
	RemoveBuildingForPlayer(playerid, 1231, 852.210, -1961.125, 14.570, 0.250);
	RemoveBuildingForPlayer(playerid, 1231, 852.210, -1950.593, 14.570, 0.250);
	RemoveBuildingForPlayer(playerid, 638, 852.531, -1965.320, 12.539, 0.250);
	RemoveBuildingForPlayer(playerid, 1280, 852.609, -1942.289, 12.234, 0.250);
	RemoveBuildingForPlayer(playerid, 1280, 852.609, -1946.218, 12.234, 0.250);
	RemoveBuildingForPlayer(playerid, 792, 851.796, -1937.187, 12.171, 0.250);
	RemoveBuildingForPlayer(playerid, 1461, 852.734, -1935.375, 12.539, 0.250);
	RemoveBuildingForPlayer(playerid, 1461, 852.734, -1929.812, 12.539, 0.250);
	RemoveBuildingForPlayer(playerid, 638, 852.531, -1932.328, 12.539, 0.250);
	RemoveBuildingForPlayer(playerid, 1280, 852.609, -1926.687, 12.234, 0.250);
	RemoveBuildingForPlayer(playerid, 1280, 852.609, -1922.750, 12.234, 0.250);
	RemoveBuildingForPlayer(playerid, 1231, 852.210, -1918.742, 14.570, 0.250);
	RemoveBuildingForPlayer(playerid, 1281, 848.328, -1909.382, 12.617, 0.250);
	RemoveBuildingForPlayer(playerid, 1281, 851.007, -1904.335, 12.617, 0.250);
	RemoveBuildingForPlayer(playerid, 1281, 851.007, -1915.281, 12.617, 0.250);
	RemoveBuildingForPlayer(playerid, 792, 851.796, -1909.906, 12.171, 0.250);
	RemoveBuildingForPlayer(playerid, 1231, 852.210, -1901.242, 14.570, 0.250);
	RemoveBuildingForPlayer(playerid, 1280, 852.609, -1897.023, 12.234, 0.250);
	RemoveBuildingForPlayer(playerid, 638, 852.531, -1886.859, 12.539, 0.250);
	RemoveBuildingForPlayer(playerid, 1280, 852.609, -1893.085, 12.234, 0.250);
	RemoveBuildingForPlayer(playerid, 1461, 852.734, -1883.351, 12.539, 0.250);
	RemoveBuildingForPlayer(playerid, 1461, 852.734, -1889.835, 12.539, 0.250);
	RemoveBuildingForPlayer(playerid, 1231, 851.625, -1879.781, 14.570, 0.250);
	RemoveBuildingForPlayer(playerid, 792, 851.796, -1874.585, 12.171, 0.250);
	RemoveBuildingForPlayer(playerid, 1231, 851.625, -1869.250, 14.570, 0.250);
	RemoveBuildingForPlayer(playerid, 1231, 820.359, -1864.554, 14.570, 0.250);
	RemoveBuildingForPlayer(playerid, 1280, 820.281, -1850.210, 12.234, 0.250);
	RemoveBuildingForPlayer(playerid, 1280, 820.281, -1854.148, 12.234, 0.250);
	RemoveBuildingForPlayer(playerid, 1461, 820.789, -1857.164, 12.539, 0.250);
	RemoveBuildingForPlayer(playerid, 638, 820.585, -1860.085, 12.539, 0.250);
	RemoveBuildingForPlayer(playerid, 1231, 820.265, -1839.875, 14.570, 0.250);
	RemoveBuildingForPlayer(playerid, 792, 820.515, -1846.937, 12.046, 0.250);
	RemoveBuildingForPlayer(playerid, 1231, 819.195, -1828.687, 14.101, 0.250);
	RemoveBuildingForPlayer(playerid, 1231, 852.210, -1843.976, 14.539, 0.250);
	RemoveBuildingForPlayer(playerid, 792, 851.796, -1848.898, 12.171, 0.250);
	RemoveBuildingForPlayer(playerid, 1461, 852.734, -1851.867, 12.539, 0.250);
	RemoveBuildingForPlayer(playerid, 638, 852.531, -1855.109, 12.539, 0.250);
	RemoveBuildingForPlayer(playerid, 1280, 852.609, -1864.882, 12.234, 0.250);
	RemoveBuildingForPlayer(playerid, 1280, 852.609, -1860.953, 12.234, 0.250);
	RemoveBuildingForPlayer(playerid, 1231, 853.906, -1828.453, 13.851, 0.250);
	return true;
}
stock Interior()
{
	Create3DTextLabel("Teacher Panel\n{FFFFFF}Press 'ALT' to open the panel", -1, 1386.6650,-1904.4753,1224.9299+0.35, 15.0, 0);
	CreateObject(18981,1416.85546875,-1923.65429688,1226.33496094,0.00000000,89.79675293,0.00000000); 
	CreateObject(19450,1429.29699707,-1919.96704102,1228.50598145,0.00000000,0.00000000,0.00000000); 
	CreateObject(19450,1429.31701660,-1914.79101562,1228.50598145,0.00000000,0.00000000,0.00000000); 
	CreateObject(18981,1416.73901367,-1911.17895508,1226.33496094,0.00000000,89.79632568,0.00000000); 
	CreateObject(18981,1392.05603027,-1925.56005859,1226.28503418,0.00000000,89.79632568,0.00000000); 
	CreateObject(19450,1403.80700684,-1927.10705566,1228.50598145,0.00000000,0.00000000,0.00000000);
	CreateObject(19450,1403.81152344,-1902.22460938,1228.50598145,0.00000000,0.00000000,0.00000000);
	CreateObject(19450,1398.93298340,-1913.16894531,1228.50598145,0.00000000,0.00000000,270.00000000);
	CreateObject(19450,1403.80895996,-1917.81298828,1228.50598145,0.00000000,0.00000000,0.00000000);
	CreateObject(19388,1403.81701660,-1908.47399902,1228.50195312,0.00000000,0.00000000,0.00000000);
	CreateObject(19358,1403.81799316,-1911.66601562,1228.50195312,0.00000000,0.00000000,0.00000000);
	CreateObject(18981,1416.21289062,-1911.18652344,1226.33496094,0.00000000,89.79125977,0.00000000);
	CreateObject(19462,1402.04296875,-1908.78601074,1226.71594238,0.00000000,89.80020142,0.00000000);
	CreateObject(19462,1402.04797363,-1899.28405762,1226.71594238,0.00000000,89.79675293,0.00000000);
	CreateObject(19450,1400.31896973,-1901.75097656,1225.05505371,0.00000000,0.00000000,0.00000000);
	CreateObject(19450,1400.32604980,-1909.50097656,1225.05505371,0.00000000,0.00000000,0.00000000);
	CreateObject(19462,1398.58398438,-1908.45996094,1225.79003906,0.00000000,89.79632568,0.00000000);
	CreateObject(19462,1398.57897949,-1898.86096191,1225.79003906,0.00000000,89.79632568,0.00000000);
	CreateObject(19450,1396.90002441,-1909.48999023,1224.12902832,0.00000000,0.00000000,0.00000000); 
	CreateObject(19450,1396.90698242,-1900.42199707,1224.12902832,0.00000000,0.00000000,0.00000000);
	CreateObject(19462,1395.28503418,-1908.44995117,1224.83898926,0.00000000,89.79632568,0.00000000);
	CreateObject(19462,1395.30505371,-1898.99804688,1224.83898926,0.00000000,89.79675293,0.00000000);
	CreateObject(19450,1393.50000000,-1909.48303223,1223.17797852,0.00000000,0.00000000,0.00000000);
	CreateObject(19450,1393.52197266,-1900.37500000,1223.17797852,0.00000000,0.00000000,0.00000000);
	CreateObject(19464,1400.86596680,-1912.99597168,1227.40100098,0.00000000,0.00000000,269.75000000);
	CreateObject(19464,1396.41394043,-1912.97399902,1227.40100098,0.00000000,0.00000000,269.74731445);
	CreateObject(19462,1391.88305664,-1908.44396973,1223.83801270,0.00000000,89.79632568,0.00000000);
	CreateObject(19462,1388.45605469,-1908.43994141,1223.83801270,0.00000000,89.79632568,0.00000000);
	CreateObject(19462,1384.98205566,-1908.47497559,1223.83801270,0.00000000,89.79632568,0.00000000);
	CreateObject(19462,1384.88500977,-1898.97399902,1223.83801270,0.00000000,89.79632568,0.00000000);
	CreateObject(19462,1388.33496094,-1898.93395996,1223.83801270,0.00000000,89.79632568,0.00000000);
	CreateObject(19462,1391.81005859,-1898.85595703,1223.83801270,0.00000000,89.79675293,0.00000000);
	CreateObject(19464,1390.56201172,-1912.98205566,1227.40100098,0.00000000,0.00000000,269.74731445);
	CreateObject(19464,1390.56799316,-1912.99304199,1222.42504883,0.00000000,180.00000000,89.74731445);
	CreateObject(19464,1385.29101562,-1912.96899414,1222.42504883,0.00000000,179.99450684,89.74731445);
	CreateObject(19464,1385.21105957,-1912.95703125,1227.40100098,0.00000000,0.00000000,269.74731445);
	CreateObject(19464,1400.77502441,-1897.46704102,1227.40100098,0.00000000,0.00000000,269.74731445);
	CreateObject(19464,1396.37500000,-1897.42504883,1227.40100098,0.00000000,0.00000000,269.74731445);
	CreateObject(19464,1391.26696777,-1897.37902832,1222.42504883,0.00000000,179.99450684,89.74731445);
	CreateObject(19464,1390.89794922,-1897.37194824,1227.40100098,0.00000000,0.00000000,269.74731445);
	CreateObject(19464,1386.01599121,-1897.37304688,1222.42504883,0.00000000,179.99450684,89.74731445);
	CreateObject(19464,1385.94201660,-1897.36303711,1227.40100098,0.00000000,0.00000000,269.74731445);
	CreateObject(1656,1471.04504395,-1857.85705566,1206.64904785,0.00000000,0.00000000,0.00000000); 
	CreateObject(14394,1399.29895020,-1914.12304688,1225.92895508,0.00000000,0.00000000,0.00000000); 
	CreateObject(14394,1395.99902344,-1914.15100098,1224.92895508,0.00000000,0.00000000,0.00000000); 
	CreateObject(14394,1392.65002441,-1914.27795410,1224.07995605,0.00000000,0.00000000,0.00000000); 
	CreateObject(2184,1400.97399902,-1898.83898926,1226.79699707,0.00000000,0.00000000,272.00000000); //object(med_office6_desk_2) (1) 
	CreateObject(2184,1401.10400391,-1905.41601562,1226.79699707,0.00000000,0.00000000,271.99951172); //object(med_office6_desk_2) (2) 
	CreateObject(2184,1397.38305664,-1898.56994629,1225.84802246,0.00000000,0.00000000,271.99951172); //object(med_office6_desk_2) (3) 
	CreateObject(2184,1397.41394043,-1902.93896484,1225.84802246,0.00000000,0.00000000,271.99951172); //object(med_office6_desk_2) (4) 
	CreateObject(2184,1397.40905762,-1907.17199707,1225.84802246,0.00000000,0.00000000,271.99951172); //object(med_office6_desk_2) (5) 
	CreateObject(2184,1394.00500488,-1898.54699707,1224.92297363,0.00000000,0.00000000,271.99951172); //object(med_office6_desk_2) (6) 
	CreateObject(2184,1394.03295898,-1902.99902344,1224.92297363,0.00000000,0.00000000,271.99951172); //object(med_office6_desk_2) (7) 
	CreateObject(2184,1393.98400879,-1907.36804199,1224.92297363,0.00000000,0.00000000,271.99951172); //object(med_office6_desk_2) (8) 
	CreateObject(19464,1403.81701660,-1900.19799805,1227.40100098,0.00000000,0.00000000,179.74731445); //object(wall104) (13) 
	CreateObject(19464,1403.74804688,-1904.70300293,1227.40100098,0.00000000,0.00000000,179.99731445); //object(wall104) (14) 
	CreateObject(19464,1403.76098633,-1912.18603516,1227.40100098,0.00000000,0.00000000,179.99450684); //object(wall104) (15) 
	CreateObject(2079,1398.70605469,-1899.14794922,1226.51403809,0.00000000,0.00000000,345.25000000); //object(swank_din_chair_2) (1) 
	CreateObject(2079,1402.57104492,-1900.29296875,1227.44104004,0.00000000,0.00000000,17.24536133); //object(swank_din_chair_2) (2) 
	CreateObject(2079,1398.76098633,-1903.42199707,1226.51403809,0.00000000,0.00000000,345.24536133); //object(swank_din_chair_2) (3) 
	CreateObject(2079,1398.81604004,-1904.50402832,1226.51403809,0.00000000,0.00000000,17.24304199); //object(swank_din_chair_2) (4) 
	CreateObject(2079,1395.50000000,-1907.84094238,1225.56103516,0.00000000,0.00000000,345.24536133); //object(swank_din_chair_2) (5) 
	CreateObject(2079,1398.92297363,-1908.80102539,1226.51403809,0.00000000,0.00000000,17.24304199); //object(swank_din_chair_2) (6) 
	CreateObject(2079,1395.44104004,-1909.01794434,1225.56201172,0.00000000,0.00000000,17.24304199); //object(swank_din_chair_2) (8) 
	CreateObject(2079,1398.86621094,-1907.69433594,1226.51403809,0.00000000,0.00000000,345.24536133); //object(swank_din_chair_2) (9) 
	CreateObject(2079,1395.40600586,-1903.51403809,1225.56103516,0.00000000,0.00000000,345.24536133); //object(swank_din_chair_2) (11) 
	CreateObject(2079,1395.26403809,-1898.98596191,1225.56103516,0.00000000,0.00000000,345.24536133); //object(swank_din_chair_2) (12) 
	CreateObject(2079,1395.30895996,-1900.03894043,1225.56201172,0.00000000,0.00000000,17.24304199); //object(swank_din_chair_2) (13) 
	CreateObject(2079,1398.75976562,-1900.10449219,1226.51403809,0.00000000,0.00000000,17.23754883); //object(swank_din_chair_2) (14) 
	CreateObject(2079,1402.40905762,-1899.30297852,1227.44104004,0.00000000,0.00000000,348.24304199); //object(swank_din_chair_2) (15) 
	CreateObject(2079,1402.35400391,-1906.06298828,1227.44104004,0.00000000,0.00000000,348.23913574); //object(swank_din_chair_2) (16) 
	CreateObject(2079,1402.40295410,-1906.97497559,1227.44104004,0.00000000,0.00000000,17.24304199); //object(swank_din_chair_2) (17) 
	CreateObject(19464,1383.32397461,-1900.14294434,1226.42602539,0.00000000,0.00000000,359.74731445); //object(wall104) (16) 
	CreateObject(19464,1383.26196289,-1905.68103027,1226.42602539,0.00000000,0.00000000,359.74731445); //object(wall104) (17) 
	CreateObject(19464,1383.29101562,-1909.96301270,1226.42602539,0.00000000,0.00000000,359.74731445); //object(wall104) (18) 
	CreateObject(19464,1383.21594238,-1909.96704102,1229.22595215,0.00000000,0.00000000,359.74731445); //object(wall104) (19) 
	CreateObject(19464,1382.96594238,-1909.98205566,1229.22595215,0.00000000,0.00000000,359.74731445); //object(wall104) (20) 
	CreateObject(19464,1383.26293945,-1904.30200195,1229.22595215,0.00000000,0.00000000,359.74731445); //object(wall104) (21) 
	CreateObject(19464,1383.29797363,-1900.02600098,1229.22595215,0.00000000,0.00000000,359.74731445); //object(wall104) (22) 
	CreateObject(14455,1383.68395996,-1907.79394531,1225.60095215,0.00000000,0.00000000,270.00000000); //object(gs_bookcase) (1) 
	CreateObject(14455,1383.74804688,-1898.21801758,1225.60095215,0.00000000,0.00000000,270.00000000); //object(gs_bookcase) (2) 
	CreateObject(3077,1384.00402832,-1905.12597656,1223.92700195,0.00000000,0.00000000,270.00000000); //object(nf_blackboard) (1) 
	CreateObject(18092,1387.25500488,-1905.11999512,1224.37194824,0.00000000,0.00000000,270.00000000); //object(ammun3_counter) (1) 
	CreateObject(2853,1387.52404785,-1906.69897461,1224.87194824,0.00000000,0.00000000,0.00000000); //object(gb_bedmags03) (1) 
	CreateObject(2828,1387.10705566,-1903.20605469,1224.87194824,0.00000000,0.00000000,112.25000000); //object(gb_ornament02) (1) 
	CreateObject(2824,1387.64099121,-1905.12695312,1224.87194824,0.00000000,0.00000000,102.00000000); //object(gb_novels02) (1) 
	CreateObject(2813,1387.14404297,-1907.32104492,1224.87194824,0.00000000,0.00000000,0.00000000); //object(gb_novels01) (1) 
	CreateObject(2190,1387.66894531,-1904.18103027,1224.87194824,0.00000000,0.00000000,276.99996948); //object(pc_1) (1) 
	CreateObject(3017,1387.69702148,-1903.34899902,1224.89404297,0.00000000,0.00000000,91.50000000); //object(arch_plans) (1) 
	CreateObject(2164,1387.55603027,-1897.49694824,1223.95605469,0.00000000,0.00000000,0.00000000); //object(med_office_unit_5) (1) 
	CreateObject(2164,1390.50500488,-1897.51403809,1223.95605469,0.00000000,0.00000000,0.00000000); //object(med_office_unit_5) (2) 
	CreateObject(2079,1395.42382812,-1904.54199219,1225.56201172,0.00000000,0.00000000,17.24304199); //object(swank_din_chair_2) (18) 
	CreateObject(1714,1386.43847656,-1905.56835938,1223.92895508,0.00000000,0.00000000,119.99816895); //object(kb_swivelchair1) (1) 
	CreateObject(19461,1429.25305176,-1914.87402344,1228.50598145,0.00000000,0.00000000,0.25000000); //object(wall101) (2) 
	CreateObject(19461,1429.27050781,-1920.00097656,1228.50598145,0.00000000,0.00000000,0.24719238); //object(wall101) (3) 
	CreateObject(19461,1424.55078125,-1924.52832031,1228.50598145,0.00000000,0.00000000,271.24694824); //object(wall101) (4) 
	CreateObject(19461,1408.17199707,-1931.26000977,1228.50598145,0.00000000,0.00000000,271.24145508); //object(wall101) (6) 
	CreateObject(19461,1424.58203125,-1910.07226562,1228.50598145,0.00000000,0.00000000,271.24145508); //object(wall101) (7) 
	CreateObject(19461,1408.47399902,-1903.78100586,1228.50598145,0.00000000,0.00000000,271.24694824); //object(wall101) (9) 
	CreateObject(19461,1403.83105469,-1926.91296387,1228.50598145,0.00000000,0.00000000,0.24719238); //object(wall101) (10) 
	CreateObject(19461,1403.83898926,-1917.51000977,1228.50598145,0.00000000,0.00000000,0.24719238); //object(wall101) (11) 
	CreateObject(19461,1403.87097168,-1914.03198242,1228.50598145,0.00000000,0.00000000,0.24719238); //object(wall101) (12) 
	CreateObject(19397,1403.84301758,-1908.46398926,1228.51696777,0.00000000,0.00000000,0.00000000); //object(wall045) (1) 
	CreateObject(19461,1403.83996582,-1902.13000488,1228.50598145,0.00000000,0.00000000,0.24719238); //object(wall101) (13) 
	CreateObject(18070,1407.70300293,-1917.32800293,1227.30895996,0.00000000,0.00000000,89.50000000); //object(gap_counter) (1) 
	CreateObject(2190,1409.89794922,-1916.18994141,1227.81896973,0.00000000,0.00000000,276.99829102); //object(pc_1) (2) 
	CreateObject(2190,1409.59301758,-1919.12097168,1227.81896973,0.00000000,0.00000000,225.99829102); //object(pc_1) (3) 
	CreateObject(1714,1407.80200195,-1917.49096680,1226.80505371,0.00000000,0.00000000,119.99813843); //object(kb_swivelchair1) (2) 
	CreateObject(2164,1404.08398438,-1919.17504883,1226.83105469,0.00000000,0.00000000,90.00000000); //object(med_office_unit_5) (3) 
	CreateObject(2164,1404.06701660,-1916.47399902,1226.83105469,0.00000000,0.00000000,90.00000000); //object(med_office_unit_5) (4) 
	CreateObject(1569,1429.19299316,-1915.51794434,1226.87597656,0.00000000,0.00000000,270.75000000); //object(adam_v_door) (1) 
	CreateObject(1569,1429.23095703,-1918.51904297,1226.87597656,0.00000000,0.00000000,90.25000000); //object(adam_v_door) (2) 
	CreateObject(638,1418.04394531,-1916.40905762,1227.53796387,0.00000000,0.00000000,0.00000000); //object(kb_planter_bush) (1) 
	CreateObject(638,1417.02697754,-1918.96203613,1227.53796387,0.00000000,0.00000000,270.00000000); //object(kb_planter_bush) (2) 
	CreateObject(638,1414.87500000,-1918.95397949,1227.53796387,0.00000000,0.00000000,270.00000000); //object(kb_planter_bush) (3) 
	CreateObject(638,1418.03796387,-1917.95996094,1227.53796387,0.00000000,0.00000000,0.00000000); //object(kb_planter_bush) (4) 
	CreateObject(638,1417.05297852,-1915.38305664,1227.53796387,0.00000000,0.00000000,270.00000000); //object(kb_planter_bush) (5) 
	CreateObject(638,1414.88500977,-1915.38195801,1227.53796387,0.00000000,0.00000000,270.00000000); //object(kb_planter_bush) (6) 
	CreateObject(638,1413.89294434,-1916.42395020,1227.53796387,0.00000000,0.00000000,0.00000000); //object(kb_planter_bush) (7) 
	CreateObject(638,1413.90002441,-1917.97497559,1227.53796387,0.00000000,0.00000000,0.00000000); //object(kb_planter_bush) (8) 
	CreateObject(1280,1418.75500488,-1917.19494629,1227.24499512,0.00000000,0.00000000,180.00000000); //object(parkbench1) (1) 
	CreateObject(1280,1415.97302246,-1914.55297852,1227.24499512,0.00000000,0.00000000,269.99450684); //object(parkbench1) (2) 
	CreateObject(1280,1415.93200684,-1919.80297852,1227.24499512,0.00000000,0.00000000,89.98901367); //object(parkbench1) (3) 
	CreateObject(19373,1415.99694824,-1917.15405273,1226.76098633,0.00000000,89.80001831,0.00000000); //object(wall021) (1) 
	CreateObject(870,1415.81103516,-1917.16503906,1227.08801270,0.00000000,0.00000000,0.00000000); //object(veg_pflowers2wee) (1) 
	CreateObject(870,1416.45104980,-1917.47705078,1227.08801270,0.00000000,0.00000000,310.00000000); //object(veg_pflowers2wee) (2) 
	CreateObject(870,1415.39697266,-1916.79895020,1227.08801270,0.00000000,0.00000000,309.99572754); //object(veg_pflowers2wee) (3) 
	CreateObject(870,1415.18896484,-1917.42102051,1227.08801270,0.00000000,0.00000000,309.99572754); //object(veg_pflowers2wee) (4) 
	CreateObject(870,1416.31604004,-1916.85400391,1227.08801270,0.00000000,0.00000000,309.99572754); //object(veg_pflowers2wee) (5)
	CreateObject(1703,1425.66699219,-1910.88696289,1226.86901855,0.00000000,0.00000000,0.00000000); //object(kb_couch02) (1) 
	CreateObject(1703,1421.16699219,-1910.90905762,1226.86901855,0.00000000,0.00000000,0.00000000); //object(kb_couch02) (2) 
	CreateObject(1703,1423.26562500,-1923.63671875,1226.86901855,0.00000000,0.00000000,179.99450684); //object(kb_couch02) (3) 
	CreateObject(1703,1427.66601562,-1923.65295410,1226.86901855,0.00000000,0.00000000,179.99450684); //object(kb_couch02) (4) 
	CreateObject(15038,1424.40295410,-1910.76000977,1227.46594238,0.00000000,0.00000000,0.00000000); //object(plant_pot_3_sv) (1) 
	CreateObject(15038,1424.45605469,-1923.91101074,1227.46594238,0.00000000,0.00000000,0.00000000); //object(plant_pot_3_sv) (2) 
	CreateObject(1280,1408.51904297,-1904.35803223,1227.24499512,0.00000000,0.00000000,91.98901367); //object(parkbench1) (4) 
	CreateObject(15038,1410.30957031,-1904.30468750,1227.46594238,0.00000000,0.00000000,0.00000000); //object(plant_pot_3_sv) (3) 
	CreateObject(15038,1406.58605957,-1904.17895508,1227.46594238,0.00000000,0.00000000,0.00000000); //object(plant_pot_3_sv) (4) 
	CreateObject(1280,1408.04602051,-1930.68298340,1227.24499512,0.00000000,0.00000000,269.98901367); //object(parkbench1) (5) 
	CreateObject(15038,1409.96801758,-1930.88696289,1227.41601562,0.00000000,0.00000000,0.00000000); //object(plant_pot_3_sv) (5) 
	CreateObject(15038,1406.19897461,-1930.83398438,1227.46594238,0.00000000,0.00000000,0.00000000); //object(plant_pot_3_sv) (6) 
	CreateObject(19450,1413.25598145,-1898.96203613,1228.57495117,0.00000000,0.00000000,0.00000000); //object(wall090) (22) 
	CreateObject(19450,1418.08703613,-1898.84899902,1228.57495117,0.00000000,0.00000000,270.00000000); //object(wall090) (23) 
	CreateObject(19450,1424.68652344,-1898.81542969,1228.57495117,0.00000000,0.00000000,270.00000000); //object(wall090) (24) 
	CreateObject(19450,1429.66394043,-1903.48205566,1228.57495117,0.00000000,0.00000000,0.00000000); //object(wall090) (25) 
	CreateObject(19397,1416.42480469,-1906.99511719,1228.57897949,0.00000000,0.00000000,46.49963379); //object(wall045) (2) 
	CreateObject(19369,1414.18298340,-1904.86596680,1228.57800293,0.00000000,0.00000000,46.50512695); //object(wall017) (1) 
	CreateObject(19369,1418.68359375,-1909.13378906,1228.57800293,0.00000000,0.00000000,46.49414062); //object(wall017) (2) 
	CreateObject(19450,1429.16296387,-1903.47204590,1228.57495117,0.00000000,0.00000000,0.00000000); //object(wall090) (27) 
	CreateObject(19450,1429.15100098,-1905.15002441,1228.57495117,0.00000000,0.00000000,0.00000000); //object(wall090) (28) 
	CreateObject(1492,1415.83898926,-1906.46899414,1226.80700684,0.00000000,0.00000000,315.99975586); //object(gen_doorint02) (1) 
	CreateObject(19450,1424.59301758,-1909.95495605,1228.57495117,0.00000000,0.00000000,270.00000000); //object(wall090) (29) 
	CreateObject(19388,1416.44335938,-1906.99121094,1228.50195312,0.00000000,0.00000000,46.49414062); //object(wall036) (2)
	CreateObject(19358,1414.32421875,-1904.96777344,1228.50195312,0.00000000,0.00000000,46.49414062); //object(wall006)
	CreateObject(19358,1418.55957031,-1909.00097656,1228.50195312,0.00000000,0.00000000,46.74133301); //object(wall006) (3) 
	CreateObject(1492,1403.90600586,-1907.70300293,1226.80700684,0.00000000,0.00000000,269.99975586); //object(gen_doorint02) (2) 
	CreateObject(15038,1415.53405762,-1905.50195312,1227.46594238,0.00000000,0.00000000,0.00000000); //object(plant_pot_3_sv) (3) 
	CreateObject(15038,1417.74499512,-1907.78295898,1227.46594238,0.00000000,0.00000000,0.00000000); //object(plant_pot_3_sv) (3) 
	CreateObject(1703,1422.52404785,-1908.95495605,1226.86901855,0.00000000,0.00000000,179.99450684); //object(kb_couch02) (3) 
	CreateObject(1703,1427.60498047,-1908.97802734,1226.86901855,0.00000000,0.00000000,179.99450684); //object(kb_couch02) (3) 
	CreateObject(2165,1425.64196777,-1900.45996094,1226.87402344,0.00000000,0.00000000,90.00000000); //object(med_office_desk_1) (1) 
	CreateObject(2166,1428.52905273,-1900.74694824,1226.87304688,0.00000000,0.00000000,179.50000000); //object(med_office_desk_2) (1) 
	CreateObject(1714,1426.88696289,-1900.31494141,1226.87402344,0.00000000,0.00000000,289.99816895); //object(kb_swivelchair1) (1) 
	CreateObject(2009,1414.91394043,-1900.34997559,1226.83398438,0.00000000,0.00000000,180.00000000); //object(officedesk2l) (1) 
	CreateObject(2079,1415.65698242,-1901.22204590,1227.46899414,0.00000000,0.00000000,17.23754883); //object(swank_din_chair_2) (14) 
	CreateObject(1714,1414.13903809,-1900.32397461,1226.87402344,0.00000000,0.00000000,39.99511719); //object(kb_swivelchair1) (1) 
	CreateObject(2079,1427.78796387,-1902.55798340,1227.46899414,0.00000000,0.00000000,299.23754883); //object(swank_din_chair_2) (14) 
	CreateObject(2370,1423.79101562,-1909.29003906,1226.86206055,0.00000000,0.00000000,0.00000000); //object(shop_set_1_table) (1) 
	CreateObject(15038,1424.17797852,-1908.96997070,1228.34094238,0.00000000,0.00000000,0.00000000); //object(plant_pot_3_sv) (3)
	CreateObject(2200,1419.84497070,-1899.13000488,1226.84997559,0.00000000,0.00000000,0.00000000); //object(med_office5_unit_1) (1) 
	CreateObject(2164,1418.07202148,-1899.00598145,1226.84204102,0.00000000,0.00000000,0.00000000); //object(med_office_unit_5) (5) 
	CreateObject(2164,1422.06799316,-1899.00195312,1226.84204102,0.00000000,0.00000000,0.00000000); //object(med_office_unit_5) (6) 
	CreateObject(2162,1413.39001465,-1901.15100098,1228.36096191,0.00000000,0.00000000,90.00000000); //object(med_office_unit_1) (1) 
	CreateObject(2161,1428.99597168,-1900.24804688,1227.92602539,0.00000000,0.00000000,270.00000000); //object(med_office_unit_4) (1) 
	CreateObject(2257,1429.04602051,-1905.16503906,1228.88403320,0.00000000,0.00000000,270.00000000); //object(frame_clip_4) (1) 
	CreateObject(2258,1424.10400391,-1909.85595703,1229.12805176,0.00000000,0.00000000,180.00000000); //object(frame_clip_5) (1) 
	CreateObject(19450,1429.28198242,-1929.42504883,1228.57604980,0.00000000,0.00000000,0.00000000); //object(wall090) (3) 
	CreateObject(19450,1424.54296875,-1924.60302734,1228.57495117,0.00000000,0.00000000,270.50000000); //object(wall090) (24)
	CreateObject(19461,1429.27197266,-1929.45495605,1226.32995605,0.00000000,0.00000000,359.99719238); //object(wall101) (3) 
	CreateObject(19461,1424.54895020,-1924.60595703,1226.32995605,0.00000000,0.00000000,270.50000000); //object(wall101) (3) 
	CreateObject(19450,1429.28894043,-1931.27600098,1228.57604980,0.00000000,0.00000000,0.00000000); //object(wall090) (5) 
	CreateObject(19461,1429.27001953,-1931.28100586,1226.32995605,0.00000000,0.00000000,359.99450684); //object(wall101) (3) 
	CreateObject(19450,1424.47998047,-1936.10595703,1228.57495117,0.00000000,0.00000000,270.49987793); //object(wall090) (24) 
	CreateObject(19461,1424.43701172,-1936.08105469,1226.32995605,0.00000000,0.00000000,270.49987793); //object(wall101) (3) 
	CreateObject(19450,1414.95202637,-1936.16699219,1228.57495117,0.00000000,0.00000000,270.49987793); //object(wall090) (24) 
	CreateObject(19461,1414.93505859,-1936.14904785,1226.32995605,0.00000000,0.00000000,270.49987793); //object(wall101) (3) 
	CreateObject(19369,1418.68359375,-1909.13378906,1228.57800293,0.00000000,0.00000000,46.49414062); //object(wall017) (2) 
	CreateObject(19369,1418.67797852,-1925.66101074,1228.50305176,0.00000000,0.00000000,313.49487305); //object(wall017) (2) 
	CreateObject(19397,1416.33300781,-1927.85803223,1228.50402832,0.00000000,0.00000000,313.49487305); //object(wall045) (2) 
	CreateObject(19369,1414.07702637,-1930.00500488,1228.50305176,0.00000000,0.00000000,313.49487305); //object(wall017) (2) 
	CreateObject(19450,1413.06298828,-1935.89697266,1228.57604980,0.00000000,0.00000000,0.00000000); //object(wall090) (8) 
	CreateObject(19461,1413.09497070,-1935.82397461,1226.32995605,0.00000000,0.00000000,359.99450684); //object(wall101) (3) 
	CreateObject(19358,1414.22705078,-1929.89294434,1228.50195312,0.00000000,0.00000000,313.49487305); //object(wall006) (2) 
	CreateObject(19388,1416.34094238,-1927.87500000,1228.50195312,0.00000000,0.00000000,313.49487305); //object(wall036) (2) 
	CreateObject(19358,1418.63305664,-1925.71203613,1228.50195312,0.00000000,0.00000000,313.49487305); //object(wall006) (2) 
	CreateObject(19369,1418.64099121,-1925.73303223,1226.32604980,0.00000000,0.00000000,313.49487305); //object(wall017) (2) 
	CreateObject(19369,1418.07702637,-1926.26599121,1226.32604980,0.00000000,0.00000000,313.49487305); //object(wall017) (2) 
	CreateObject(19369,1414.68896484,-1929.48400879,1226.32604980,0.00000000,0.00000000,313.49487305); //object(wall017) (2) 
	CreateObject(19369,1412.40197754,-1931.65197754,1226.32604980,0.00000000,0.00000000,313.49487305); //object(wall017) (2) 
	CreateObject(1492,1416.91296387,-1927.30603027,1226.73205566,0.00000000,0.00000000,223.99975586); //object(gen_doorint02) (1) 
	CreateObject(2164,1429.15405273,-1926.71594238,1226.84204102,0.00000000,0.00000000,270.00000000); //object(med_office_unit_5) (7) 
	CreateObject(2164,1429.17199707,-1933.49304199,1226.84204102,0.00000000,0.00000000,270.00000000); //object(med_office_unit_5) (8) 
	CreateObject(2200,1429.07995605,-1929.87695312,1226.84997559,0.00000000,0.00000000,270.00000000); //object(med_office5_unit_1) (2) 
	CreateObject(2112,1424.34399414,-1930.68005371,1227.25402832,0.00000000,0.00000000,0.00000000); //object(med_dinning_4) (1) 
	CreateObject(2112,1423.04394531,-1930.68298340,1227.25402832,0.00000000,0.00000000,0.00000000); //object(med_dinning_4) (2) 
	CreateObject(2112,1421.66894531,-1930.68603516,1227.25402832,0.00000000,0.00000000,0.00000000); //object(med_dinning_4) (3) 
	CreateObject(2112,1420.31994629,-1930.68994141,1227.25402832,0.00000000,0.00000000,0.00000000); //object(med_dinning_4) (4) 
	CreateObject(1714,1425.47399902,-1930.56494141,1226.86596680,0.00000000,0.00000000,284.00000000); //object(kb_swivelchair1) (5) 
	CreateObject(1715,1424.39904785,-1929.36499023,1226.86303711,0.00000000,0.00000000,0.00000000); //object(kb_swivelchair2) (1) 
	CreateObject(1715,1423.04797363,-1929.35095215,1226.86303711,0.00000000,0.00000000,0.00000000); //object(kb_swivelchair2) (2) 
	CreateObject(1715,1421.67297363,-1929.36303711,1226.86303711,0.00000000,0.00000000,0.00000000); //object(kb_swivelchair2) (3) 
	CreateObject(1715,1420.37304688,-1929.34802246,1226.86303711,0.00000000,0.00000000,0.00000000); //object(kb_swivelchair2) (4) 
	CreateObject(1715,1420.39404297,-1931.74902344,1226.86303711,0.00000000,0.00000000,180.00000000); //object(kb_swivelchair2) (5) 
	CreateObject(1715,1421.67004395,-1931.75500488,1226.86303711,0.00000000,0.00000000,179.99450684); //object(kb_swivelchair2) (6) 
	CreateObject(1715,1422.96997070,-1931.76000977,1226.86303711,0.00000000,0.00000000,179.99450684); //object(kb_swivelchair2) (7) 
	CreateObject(1715,1424.29504395,-1931.76599121,1226.86303711,0.00000000,0.00000000,179.99450684); //object(kb_swivelchair2) (8) 
	CreateObject(1703,1422.28503418,-1935.43298340,1226.86901855,0.00000000,0.00000000,179.99450684); //object(kb_couch02) (3) 
	CreateObject(15038,1419.44995117,-1935.45898438,1227.46594238,0.00000000,0.00000000,0.00000000); //object(plant_pot_3_sv) (3) 
	CreateObject(15038,1423.12304688,-1935.52905273,1227.46594238,0.00000000,0.00000000,0.00000000); //object(plant_pot_3_sv) (3) 
	CreateObject(2009,1414.72094727,-1934.56799316,1226.83398438,0.00000000,0.00000000,269.99450684); //object(officedesk2l) (2) 
	CreateObject(2161,1413.16503906,-1935.54003906,1227.92602539,0.00000000,0.00000000,89.25000000); //object(med_office_unit_4) (2) 
	CreateObject(2079,1414.63500977,-1935.45703125,1227.46899414,0.00000000,0.00000000,203.23754883); //object(swank_din_chair_2) (14) 
	CreateObject(2571,1422.30395508,-1926.14294434,1226.85400391,0.00000000,0.00000000,0.00000000); //object(hotel_single_1) (1) 
	CreateObject(9339,1411.40905762,-1923.40600586,1227.52197266,89.80020142,89.80093384,359.99890137); //object(sfnvilla001_cm) (1) 
	CreateObject(9339,1411.98999023,-1923.94995117,1227.52197266,89.79632568,89.79705811,269.99426270); //object(sfnvilla001_cm) (2) 
	CreateObject(9339,1411.39196777,-1924.53100586,1227.52197266,89.79675293,89.79675293,359.99450684); //object(sfnvilla001_cm) (3) 
	CreateObject(9339,1410.88793945,-1923.91198730,1227.52197266,89.79125977,89.79125977,269.99450684); //object(sfnvilla001_cm) (4) 
	CreateObject(9339,1411.97900391,-1911.82299805,1227.52197266,89.79156494,89.79040527,269.99536133); //object(sfnvilla001_cm) (5) 
	CreateObject(9339,1411.38793945,-1911.28698730,1227.52197266,89.79632568,89.79702759,359.99423218); //object(sfnvilla001_cm) (6) 
	CreateObject(9339,1411.39904785,-1912.41198730,1227.52197266,89.79632568,89.79663086,359.99465942); //object(sfnvilla001_cm) (7) 
	CreateObject(9339,1410.85302734,-1911.83496094,1227.52197266,89.79125977,89.78576660,269.99450684); //object(sfnvilla001_cm) (8) 
	CreateObject(4141,1411.44396973,-1912.15600586,1257.40405273,89.80020142,0.00000000,0.00000000); //object(hotelexterior1_lan) (1) 
	CreateObject(4141,1411.44396973,-1908.10302734,1257.40405273,89.79632568,0.00000000,0.00000000); //object(hotelexterior1_lan) (2) 
	CreateObject(4141,1390.34399414,-1907.90698242,1257.40405273,89.79632568,0.00000000,0.00000000); //object(hotelexterior1_lan) (3) 
	CreateObject(4141,1386.29101562,-1908.54394531,1257.05505371,89.79675293,0.00000000,0.00000000); //object(hotelexterior1_lan) (4) 
	CreateObject(4141,1413.29504395,-1912.14599609,1257.40405273,89.79675293,0.00000000,0.00000000); //object(hotelexterior1_lan) (5) 
	CreateObject(18075,1408.91699219,-1926.01696777,1230.21801758,0.00000000,0.00000000,0.00000000); //object(lightd) (2) 
	CreateObject(18075,1408.55603027,-1910.46997070,1230.21801758,0.00000000,0.00000000,0.00000000); //object(lightd) (3) 
	CreateObject(18075,1424.09594727,-1917.36596680,1230.21801758,0.00000000,0.00000000,0.00000000); //object(lightd) (4) 
	CreateObject(18075,1422.54602051,-1903.89697266,1230.14294434,0.00000000,0.00000000,0.00000000); //object(lightd) (5) 
	CreateObject(18075,1423.35803223,-1931.31298828,1230.16796875,0.00000000,0.00000000,0.00000000); //object(lightd) (6) 
	CreateObject(18075,1399.46594238,-1904.73095703,1229.84301758,0.00000000,0.00000000,0.00000000); //object(lightd) (7) 
	CreateObject(18075,1390.06799316,-1904.64904785,1229.84301758,0.00000000,0.00000000,0.00000000); //object(lightd) (8) 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000);
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000);
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000);
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000);
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000);
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000);  
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000);  
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000);
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000);
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000);
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000);
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000);
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000);
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000);
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000);
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000);
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000);
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000);
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000);
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000);
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000);
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000);
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000);
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000);
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000);
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000);
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000);
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000);
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000);
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000);
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000);
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000);
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000);
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000);
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000);
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000);
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000);
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000);
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000);
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000);
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000);
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000);
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000);
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000);
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000);
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); //
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); //
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); //
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); //
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); //
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); // 
	CreateObject(1337,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000,0.00000000); //
	return true;
}
/* �������� */
forward IsValidAccount(playerid);
forward OnPlayerRegister(playerid);
forward LoadPlayerAccount(playerid);