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

//Crack changes
#define NEW_JUMP 0x75 // jne
#define NEW_FLAG 0x31 // '1'

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

//Main block tittle properties
#define _MAIN_BLOCK_TITLE_COLOR_ 255, 255, 255
const char MAIN_BLOCK_TITLE[]					= "CrackYou";
const unsigned int MAIN_BLOCK_TITLE_SIZE		= 24;
const unsigned int MAIN_BLOCK_TITLE_X 			= MODE_WIDTH / 2 - strlen(MAIN_BLOCK_TITLE) * MAIN_BLOCK_TITLE_SIZE / 3;
const unsigned int MAIN_BLOCK_TITLE_Y			= 10;

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

CrackMeStatusCode RunCrack(Hacking* data);
CrackMeStatusCode FileInfo(Hacking* data);
CrackMeStatusCode ReadFromFile(Hacking* data);
CrackMeStatusCode ChangeBytesInBuffer(Hacking* data);
CrackMeStatusCode ChangeFlag(Hacking* data, size_t* flag_index);
CrackMeStatusCode ChangeJump(Hacking* data, size_t* jump_index);
CrackMeStatusCode WriteToFile(Hacking* data);
