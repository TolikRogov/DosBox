#pragma once

#include "CrackeMe_utilities.hpp"

typedef unsigned char buffer_t;

#define PRINT_TO_STDOUT(...) fprintf(stdout, __VA_ARGS__ "\n");
#define LINE "===================================================================================================="
#define PRINT_LINE PRINT_TO_STDOUT(LINE)
#define PRINT_MESSAGE(...) {			 \
	PRINT_LINE							\
	PRINT_TO_STDOUT("\t" __VA_ARGS__)	\
	PRINT_LINE							\
}										\

#define NEW_JUMP 0x75 //jne
#define NEW_FLAG 0x31 //'1'

//File to crack
#define TASK1_PATH "../Task1/"
#define COM_FILE TASK1_PATH "HACK.COM"

//Data segment
#define DATA_PATH	"data/"

//Fonts segment
#define FONTS_PATH 	DATA_PATH "fonts/"
#define UNISPACE FONTS_PATH "unispace/unispace.ttf"

//Images segment
#define IMAGES_PATH	DATA_PATH "img/"
#define BACKGROUND IMAGES_PATH "background.png"
#define BUTTON_HOVER_OFF IMAGES_PATH "button_hover_off.png"
#define BUTTON_HOVER_ON IMAGES_PATH "button_hover_on.png"

//Music segment
#define MUSIC_PATH DATA_PATH "music/"
#define BG_MUSIC MUSIC_PATH "RoboCop.mp3"

//Window properties
const unsigned int MODE_WIDTH 					= 640;
const unsigned int MODE_HEIGHT					= 358;

//Background properties
const Int32 TIME_TO_UPDATE						= 100;
const unsigned int BACKGROUND_FRAMES			= 15360;

//Button properties
const unsigned int BUTTON_WIDTH					= 152;
const unsigned int BUTTON_HEIGHT				= 63;
const unsigned int BUTTON_X						= int((MODE_WIDTH - BUTTON_WIDTH) / 2);
const unsigned int BUTTON_Y						= int(MODE_HEIGHT - 3 * BUTTON_HEIGHT / 2);

//Button text
#define _BUTTON_TEXT_COLOR_ 255, 255, 255
#define _BUTTON_TEXT_COLOR_HOVER_ 52, 252, 52
const char BUTTON_TEXT[]						= "Run";
const unsigned int BUTTON_TEXT_SIZE				= 18;
const unsigned int BUTTON_TEXT_X				= int((BUTTON_X + BUTTON_X + BUTTON_WIDTH) / 2) - int(strlen(BUTTON_TEXT) * BUTTON_TEXT_SIZE * 2 / 3 / 2);
const unsigned int BUTTON_TEXT_Y 				= int((BUTTON_Y + BUTTON_Y + BUTTON_HEIGHT) / 2) - int(BUTTON_TEXT_SIZE * 2 / 3);

//Main block tittle properties
#define _MAIN_BLOCK_TITLE_COLOR_ 255, 255, 255
const char MAIN_BLOCK_TITLE[]					= "CrackYou";
const unsigned int MAIN_BLOCK_TITLE_SIZE		= 24;
const unsigned int MAIN_BLOCK_TITLE_X 			= MODE_WIDTH / 2 - strlen(MAIN_BLOCK_TITLE) * MAIN_BLOCK_TITLE_SIZE / 3;
const unsigned int MAIN_BLOCK_TITLE_Y			= 10;

const size_t MODS_AMOUNT 						= 2;

enum CrackStatus {
	NO_CRACK,
	DONE_CRACK,
};

struct Hacking {
	const char* file_path;
	size_t file_size;

	buffer_t* buffer;
	CrackStatus crack_status;
};

typedef CrackMeStatusCode (*mod_func_t) (Hacking*, size_t*);

struct Modification {
	const char* name;
	size_t index;
	enum ModStatus{MOD_NOT_CHANGED, MOD_CHANGED} status = MOD_NOT_CHANGED;
	mod_func_t function;
	buffer_t new_value;
};

struct Cracker {
	Hacking* data;
	Modification mods[MODS_AMOUNT];
	size_t status;
};

CrackMeStatusCode RunCrack(Cracker* cracker);
CrackMeStatusCode FileInfo(Cracker* cracker);
CrackMeStatusCode ReadFromFile(Cracker* cracker);
CrackMeStatusCode ChangeBytesInBuffer(Cracker* cracker);
CrackMeStatusCode AppliedMods(Cracker* cracker);
CrackMeStatusCode PrintBytesMap(Cracker* cracker);
int GetModStatusByIndex(Modification* mods, size_t index);
CrackMeStatusCode FindFlag(Hacking* data, size_t* flag_index);
CrackMeStatusCode FindJump(Hacking* data, size_t* jump_index);
CrackMeStatusCode WriteToFile(Cracker* cracker);
