#pragma once

#include <SFML/Audio.hpp>
#include <SFML/Graphics.hpp>
#include "CrackeMe_utilities.hpp"
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <sys/stat.h>
using namespace sf;

#define RED(str) 		"\033[31;1m" str "\033[0m"
#define YELLOW(str) 	"\033[33;4m" str "\033[0m"
#define GREEN(str) 		"\033[32;1m" str "\033[0m"
#define BLUE(str)		"\033[34;1m" str "\033[0m"
#define TEAL(str)		"\033[36;1m" str "\033[0m"

#define CRACKME_ERROR_CHECK(status) {																				 \
	if (status != CRACKME_NO_ERROR) {																				\
		fprintf(stderr, "\n\n" RED("Error (code %d): %ls, ") YELLOW("File: %s, Function: %s, Line: %d\n\n"),   		\
					status, CrackMeErrorsMessenger(status), __FILE__, __PRETTY_FUNCTION__, __LINE__);				\
		fclose(stderr);																								\
		return status;																								\
	}																												\
}

#define CRACKME_ERROR_MESSAGE(status) {																				 \
	if (status != CRACKME_NO_ERROR) {																				\
		fprintf(stderr, "\n\n" RED("Error (code %d): %ls, ") YELLOW("File: %s, Function: %s, Line: %d\n\n"),   		\
					status, CrackMeErrorsMessenger(status), __FILE__, __PRETTY_FUNCTION__, __LINE__);				\
		fclose(stderr);																								\
		break;																										\
	}																												\
}

enum CrackMeStatusCode {
	CRACKME_NO_ERROR,
	CRACKME_FONT_LOAD_ERROR,
	CRACKME_IMG_LOAD_ERROR,
	CRACKME_FILE_OPEN_ERROR,
	CRACKME_FILE_CLOSE_ERROR,
	CRACKME_ALLOCATION_ERROR,
	CRACKME_FILE_READ_ERROR,
};

const wchar_t* CrackMeErrorsMessenger(CrackMeStatusCode status);
