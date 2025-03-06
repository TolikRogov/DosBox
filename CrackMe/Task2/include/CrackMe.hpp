#pragma once

#include <SFML/Audio.hpp>
#include <SFML/Graphics.hpp>
#include "CrackeMe_utilities.hpp"
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
using namespace sf;

//Window properties
const unsigned int MODE_WIDTH 					= 800;
const unsigned int MODE_HEIGHT					= 600;

//Top block properties
#define TOP_BLOCK_COLOR 242, 229, 85
const unsigned int TOP_BLOCK_PERCENT_SIZE 		= 0;
const unsigned int TOP_BLOCK_HEIGHT 			= int(MODE_HEIGHT / 100 * TOP_BLOCK_PERCENT_SIZE);

//Main block properties
#define MAIN_BLOCK_COLOR 201, 189, 153
const unsigned int MAIN_BLOCK_PERCENT_SIZE		= 100;
const unsigned int MAIN_BLOCK_HEIGHT 			= int(MODE_HEIGHT / 100 * MAIN_BLOCK_PERCENT_SIZE);

const char MAIN_BLOCK_TITLE[]					= "CrackYou";
const unsigned int MAIN_BLOCK_TITLE_SIZE		= 24;
const unsigned int MAIN_BLOCK_TITLE_X 			= MODE_WIDTH / 2 - strlen(MAIN_BLOCK_TITLE) * MAIN_BLOCK_TITLE_SIZE / 3;
const unsigned int MAIN_BLOCK_TITLE_Y			= 10;

//bottom block properties
#define BOTTOM_BLOCK_COLOR 230, 210, 75
const unsigned int BOTTOM_BLOCK_PERCENT_SIZE 	= 100 - TOP_BLOCK_PERCENT_SIZE - MAIN_BLOCK_PERCENT_SIZE;
const unsigned int BOTTOM_BLOCK_HEIGHT			= int(MODE_HEIGHT / 100 * BOTTOM_BLOCK_PERCENT_SIZE);

//Fonts
#define DATA_PATH	"data/"
#define FONTS_PATH 	DATA_PATH "fonts/"
#define UNISPACE FONTS_PATH "unispace/unispace.ttf"
