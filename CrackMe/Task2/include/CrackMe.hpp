#pragma once

#include <SFML/Audio.hpp>
#include <SFML/Graphics.hpp>
#include "CrackeMe_utilities.hpp"
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
using namespace sf;

//Window properties
const unsigned int MODE_WIDTH 					= 640;
const unsigned int MODE_HEIGHT					= 358;

//Background properties
const Int32 TIME_TO_UPDATE						= 100;
const unsigned int BACKGROUND_FRAMES			= 15360;

//Button properties
const unsigned int BUTTON_WIDTH					= 313;
const unsigned int BUTTON_HEIGHT				= 130;

//Main block tittle properties
#define _MAIN_BLOCK_TITLE_COLOR_ 255, 255, 255
const char MAIN_BLOCK_TITLE[]					= "CrackYou";
const unsigned int MAIN_BLOCK_TITLE_SIZE		= 24;
const unsigned int MAIN_BLOCK_TITLE_X 			= MODE_WIDTH / 2 - strlen(MAIN_BLOCK_TITLE) * MAIN_BLOCK_TITLE_SIZE / 3;
const unsigned int MAIN_BLOCK_TITLE_Y			= 10;

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
