#include "CrackMe.hpp"

CrackMeStatusCode RunCrack(Cracker* cracker) {
	CrackMeStatusCode crackme_status = CRACKME_NO_ERROR;

	if (cracker->data->crack_status == DONE_CRACK) {
		PRINT_MESSAGE(YELLOW("WARNING: Crack or file checking for crack has already been! Please, change file!"))
		return CRACKME_NO_ERROR;
	}

	crackme_status = FileInfo(cracker);
	CRACKME_ERROR_CHECK(crackme_status);

	cracker->data->buffer = (buffer_t*)calloc(cracker->data->file_size, sizeof(buffer_t));
	if (!cracker->data->buffer)
		CRACKME_ERROR_CHECK(CRACKME_ALLOCATION_ERROR);

	crackme_status = ReadFromFile(cracker);
	CRACKME_ERROR_CHECK(crackme_status);

	crackme_status = ChangeBytesInBuffer(cracker);
	if (crackme_status == CRACKME_FILE_WRITE_ERROR) {
		PRINT_LINE
		fprintf(stdout, YELLOW("\tWARNING: writing to the file '%s' was cancelled!")"\n", cracker->data->file_path);
		PRINT_LINE
	}
	else {
		CRACKME_ERROR_CHECK(crackme_status);
		crackme_status = WriteToFile(cracker);
		CRACKME_ERROR_CHECK(crackme_status);
	}

	if (cracker->data->buffer) {
		free(cracker->data->buffer);
		cracker->data->buffer = NULL;
	}

	return CRACKME_NO_ERROR;
}

CrackMeStatusCode FileInfo(Cracker* cracker) {
	FILE* file_to_hack = fopen(cracker->data->file_path, "rb");
	if (!file_to_hack)
		CRACKME_ERROR_CHECK(CRACKME_FILE_OPEN_ERROR);

	PRINT_LINE
	fprintf(stdout, GREEN("\tThe file '%s' was opened!")"\n", cracker->data->file_path);
	PRINT_LINE

	PRINT_LINE
	struct stat file_info = {};
	stat(cracker->data->file_path, &file_info);

	struct tm * timeinfo;
    char buff[20];

	timeinfo = localtime(&file_info.st_ctimespec.tv_sec);
    strftime(buff, 20, "%b %d %H:%M", timeinfo);
	fprintf(stdout, BLUE("%30s: ") YELLOW("%s")"\n", "Last file correction time", buff);

	timeinfo = localtime(&file_info.st_mtimespec.tv_sec);
    strftime(buff, 20, "%b %d %H:%M", timeinfo);
	fprintf(stdout, BLUE("%30s: ") YELLOW("%s")"\n", "Last file modification time", buff);

	cracker->data->file_size = (size_t)file_info.st_size;
	fprintf(stdout, BLUE("%30s: ") YELLOW("%lld") BLUE(" bytes")"\n", "File size", file_info.st_size);
	PRINT_LINE

	if (fclose(file_to_hack))
		CRACKME_ERROR_CHECK(CRACKME_FILE_CLOSE_ERROR);

	return CRACKME_NO_ERROR;
}

CrackMeStatusCode ReadFromFile(Cracker* cracker) {
	Hacking* data = cracker->data;

	FILE* file_to_hack = fopen(data->file_path, "rb");
	if (!file_to_hack)
		CRACKME_ERROR_CHECK(CRACKME_FILE_OPEN_ERROR);

	if (fread(data->buffer, sizeof(buffer_t), data->file_size, file_to_hack) != data->file_size)
		CRACKME_ERROR_CHECK(CRACKME_FILE_READ_ERROR);

	PRINT_LINE
	fprintf(stdout, GREEN("\tReading from the file '%s' was successful")"\n", cracker->data->file_path);
	PRINT_LINE

#ifdef _DEBUG_
	PRINT_LINE
	for (size_t i = 0; i < data->file_size; i++) {
		if (i % 8 == 0)
			fprintf(stdout, "%.8zx: ", (unsigned long)i);
		fprintf(stdout, "%.2x", data->buffer[i]);
		if ((i + 1) % 2 == 0)
			fprintf(stdout, " ");
		if ((i + 1) % 8 == 0)
			fprintf(stdout, "\n");
	}
	fprintf(stdout, "\n");
	PRINT_LINE
#endif

	if (fclose(file_to_hack))
		CRACKME_ERROR_CHECK(CRACKME_FILE_CLOSE_ERROR);

	return CRACKME_NO_ERROR;
}

CrackMeStatusCode ChangeBytesInBuffer(Cracker* cracker) {
	Hacking* data = cracker->data;
	CrackMeStatusCode crackme_status = CRACKME_NO_ERROR;

	FILE* file_to_hack = fopen(data->file_path, "rb");
	if (!file_to_hack)
		CRACKME_ERROR_CHECK(CRACKME_FILE_OPEN_ERROR);

	crackme_status = AppliedMods(cracker);
	CRACKME_ERROR_CHECK(crackme_status);

	crackme_status = CRACKME_FILE_WRITE_ERROR;
	if (cracker->status) {
		PRINT_LINE
		PrintBytesMap(cracker);
		fprintf(stdout, "\n");
		PRINT_LINE
		crackme_status = CRACKME_NO_ERROR;
	}

	cracker->data->crack_status = DONE_CRACK;

	if (fclose(file_to_hack))
		CRACKME_ERROR_CHECK(CRACKME_FILE_CLOSE_ERROR);

	return crackme_status;
}

CrackMeStatusCode PrintBytesMap(Cracker* cracker) {
	Hacking* data = cracker->data;

	for (size_t i = 0; i < data->file_size; i++) {
		int status = GetModStatusByIndex(cracker->mods, i);
		if (i % 8 == 0)
			fprintf(stdout, "%.8zx: ", (unsigned long)i);
		if (status > 0)
			fprintf(stdout, GREEN("%.2x"), data->buffer[i]);
		else if (status == 0)
			fprintf(stdout, YELLOW("%.2x"), data->buffer[i]);
		else
			fprintf(stdout, "%.2x", data->buffer[i]);
		if ((i + 1) % 2 == 0)
			fprintf(stdout, " ");
		if ((i + 1) % 8 == 0)
			fprintf(stdout, "\n");
	}

	return CRACKME_NO_ERROR;
}

int GetModStatusByIndex(Modification* mods, size_t index) {
	for (size_t i = 0; i < MODS_AMOUNT; i++) {
		if (mods[i].index == index)
			return (int)mods[i].status;
	}
	return -1;
}

CrackMeStatusCode AppliedMods(Cracker* cracker) {
	CrackMeStatusCode crackme_status = CRACKME_NO_ERROR;
	Hacking* data = cracker->data;
	Modification* mods = cracker->mods;

	for (size_t i = 0; i < MODS_AMOUNT; i++) {
		crackme_status = mods[i].function(data, &mods[i].index);
		CRACKME_ERROR_CHECK(crackme_status);
		PRINT_LINE
		if (!(mods[i].index))
			fprintf(stdout, RED("\tERROR: subsequence for %s not found!")"\n", mods[i].name);
		if ((mods[i].index) && data->buffer[(mods[i].index)] == mods[i].new_value)
			fprintf(stdout, YELLOW("\tWARNING: %s has already been changed!")"\n", mods[i].name);
		if (mods[i].index && data->buffer[mods[i].index] != mods[i].new_value) {
			fprintf(stdout, GREEN("\tDestination was found in the file and %s was changed!")"\n", mods[i].name);
			data->buffer[mods[i].index] = mods[i].new_value;
			mods[i].status = mods[i].MOD_CHANGED;
		}
		PRINT_LINE
		cracker->status += (size_t)mods[i].status;
	}

	return CRACKME_NO_ERROR;
}

CrackMeStatusCode FindFlag(Hacking* data, size_t* flag_index) {

	if (!data || !flag_index)
		CRACKME_ERROR_CHECK(CRACKME_NULL_POINTER);

	for (size_t i = 0; i < data->file_size - 3; i++) {
		if (data->buffer[i] 	== 0x00 && data->buffer[i + 1] == 0x61 &&
			data->buffer[i + 3] == 0x61) {
			*flag_index = i + 2;
			if (data->buffer[i + 2] == 0x30)
				break;
		}
	}

	return CRACKME_NO_ERROR;
}

CrackMeStatusCode FindJump(Hacking* data, size_t* jump_index) {

	if (!data || !jump_index)
		CRACKME_ERROR_CHECK(CRACKME_NULL_POINTER);

	for (size_t i = 0; i < data->file_size - 5; i++) {
		if (data->buffer[i] 	== 0xA1 && data->buffer[i + 1] == 0x02 &&
			data->buffer[i + 3] == 0x0A && data->buffer[i + 4] == 0xB4 &&
			data->buffer[i + 5] == 0x09) {
			*jump_index = i + 2;
			if (data->buffer[i + 2] == 0x74)
				break;
		}
	}

	return CRACKME_NO_ERROR;
}

CrackMeStatusCode WriteToFile(Cracker* cracker) {
	Hacking* data = cracker->data;

	FILE* file_to_hack = fopen(data->file_path, "wb");
	if (!file_to_hack)
		CRACKME_ERROR_CHECK(CRACKME_FILE_OPEN_ERROR);

	if (fwrite(data->buffer, sizeof(buffer_t), data->file_size, file_to_hack) != data->file_size)
		CRACKME_ERROR_CHECK(CRACKME_FILE_WRITE_ERROR);

	PRINT_LINE
	fprintf(stdout, GREEN("\tWriting to the file '%s' was successful")"\n", cracker->data->file_path);
	PRINT_LINE

	if (fclose(file_to_hack))
		CRACKME_ERROR_CHECK(CRACKME_FILE_CLOSE_ERROR);

	return CRACKME_NO_ERROR;
}

const wchar_t* CrackMeErrorsMessenger(CrackMeStatusCode status) {
	switch(status) {
		case CRACKME_NO_ERROR:							return L"CRACKME ERROR - NO ERROR";
		case CRACKME_FONT_LOAD_ERROR:					return L"CRACKME ERROR - LOADING FONT FROM FILE ERROR";
		case CRACKME_IMG_LOAD_ERROR:					return L"CRACKME ERROR - LOADING INAGE FROM FILE ERROR";
		case CRACKME_MUSIC_LOAD_ERROR:					return L"CRACKME ERROR - LOADING MUSIC FROM FILE ERROR";
		case CRACKME_FILE_OPEN_ERROR:					return L"CRACKME ERROR - FILE WAS NOT OPENED";
		case CRACKME_FILE_CLOSE_ERROR:					return L"CRACKME ERROR - FILE WAS NOT CLOSED";
		case CRACKME_ALLOCATION_ERROR:					return L"CRACKME ERROR - MEMORY WAS ALLOCATED WITH ERROR";
		case CRACKME_FILE_READ_ERROR:					return L"CRACKME ERROR - READING FROM FILE HAPPENED WITH ERROR";
		case CRACKME_FILE_BUF_ERROR:					return L"CRACKME ERROR - ENABLE FILE BUFFERING WAS NOT SUCCESS";
		case CRACKME_FILE_WRITE_ERROR:					return L"CRACKME ERROR - WRITING TO FILE HAPPENED WITH ERROR";
		case CRACKME_NULL_POINTER:						return L"CRACKME ERROR - NULL POINTER";
		case CRACKME_ALREADY_CRACK:						return L"CRACKME ERROR - CURRENT CHANGES HAVE ALREADY BEEN DONE";
		case CRACKME_SEQ_NOT_FOUND:						return L"CRACKME ERROR - SEQUENCE FOR CHANGING WAS NOT FOUND";
		default: 										return L"UNDEFINED ERROR";
	}
}
