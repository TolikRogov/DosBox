#include "CrackMe.hpp"

CrackMeStatusCode RunCrack(Hacking* data) {
	if (data->crack_status == DONE_CRACK) {
		PRINT_MESSAGE(YELLOW("WARNING: Crack or file checking for crack has already been! Please, change file!"))
		return CRACKME_NO_ERROR;
	}

	CrackMeStatusCode crackme_status = CRACKME_NO_ERROR;

	crackme_status = FileInfo(data);
	CRACKME_ERROR_CHECK(crackme_status);

	data->buffer = (buffer_t*)calloc(data->file_size, sizeof(buffer_t));
	if (!data->buffer)
		CRACKME_ERROR_CHECK(CRACKME_ALLOCATION_ERROR);

	crackme_status = ReadFromFile(data);
	CRACKME_ERROR_CHECK(crackme_status);

	crackme_status = ChangeBytesInBuffer(data);
	if (crackme_status == CRACKME_FILE_WRITE_ERROR)
		PRINT_MESSAGE(YELLOW("WARNING: writing to the file was cancelled!"))
	else {
		CRACKME_ERROR_CHECK(crackme_status);
		crackme_status = WriteToFile(data);
		CRACKME_ERROR_CHECK(crackme_status);
	}

	if (data->buffer) {
		free(data->buffer);
		data->buffer = NULL;
	}

	return CRACKME_NO_ERROR;
}

CrackMeStatusCode FileInfo(Hacking* data) {
	FILE* file_to_hack = fopen(data->file_path, "rb");
	if (!file_to_hack)
		CRACKME_ERROR_CHECK(CRACKME_FILE_OPEN_ERROR);

	PRINT_MESSAGE(GREEN("The file was opened!"))

	PRINT_TO_STDOUT(LINE)

	struct stat file_info = {};
	stat(data->file_path, &file_info);

	struct tm * timeinfo;
    char buff[20];

	timeinfo = localtime(&file_info.st_ctimespec.tv_sec);
    strftime(buff, 20, "%b %d %H:%M", timeinfo);
	fprintf(stdout, BLUE("%30s: ") YELLOW("%s")"\n", "Last file correction time", buff);

	timeinfo = localtime(&file_info.st_mtimespec.tv_sec);
    strftime(buff, 20, "%b %d %H:%M", timeinfo);
	fprintf(stdout, BLUE("%30s: ") YELLOW("%s")"\n", "Last file modification time", buff);

	data->file_size = (size_t)file_info.st_size;
	fprintf(stdout, BLUE("%30s: ") YELLOW("%lld") BLUE(" bytes")"\n", "File size", file_info.st_size);

	PRINT_TO_STDOUT(LINE)

	if (fclose(file_to_hack))
		CRACKME_ERROR_CHECK(CRACKME_FILE_CLOSE_ERROR);

	return CRACKME_NO_ERROR;
}

CrackMeStatusCode ReadFromFile(Hacking* data) {
	FILE* file_to_hack = fopen(data->file_path, "rb");
	if (!file_to_hack)
		CRACKME_ERROR_CHECK(CRACKME_FILE_OPEN_ERROR);

	if (fread(data->buffer, sizeof(buffer_t), data->file_size, file_to_hack) != data->file_size)
		CRACKME_ERROR_CHECK(CRACKME_FILE_READ_ERROR);

	PRINT_MESSAGE(GREEN("Reading from the file was successful"))

#ifdef _DEBUG_
	PRINT_TO_STDOUT(LINE)
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
	PRINT_TO_STDOUT(LINE)
#endif

	if (fclose(file_to_hack))
		CRACKME_ERROR_CHECK(CRACKME_FILE_CLOSE_ERROR);

	return CRACKME_NO_ERROR;
}

CrackMeStatusCode ChangeBytesInBuffer(Hacking* data) {
	CrackMeStatusCode crackme_status = CRACKME_NO_ERROR;

	FILE* file_to_hack = fopen(data->file_path, "rb");
	if (!file_to_hack)
		CRACKME_ERROR_CHECK(CRACKME_FILE_OPEN_ERROR);

	size_t flag_index = 0;
	enum FlagStatus{FLAG_NOT_CHANGED, FLAG_CHANGED} flag_status = FLAG_CHANGED;
	crackme_status = ChangeFlag(data, &flag_index);
	if (crackme_status == CRACKME_ALREADY_CRACK ||
		crackme_status == CRACKME_SEQ_NOT_FOUND)
		flag_status = FLAG_NOT_CHANGED;
	else
		CRACKME_ERROR_CHECK(crackme_status);

	size_t jump_index = 0;
	enum JumpStatus{JUMP_NOT_CHANGED, JUMP_CHANGED} jump_status = JUMP_CHANGED;
	crackme_status = ChangeJump(data, &jump_index);
	if (crackme_status == CRACKME_ALREADY_CRACK ||
		crackme_status == CRACKME_SEQ_NOT_FOUND)
		jump_status = JUMP_NOT_CHANGED;
	else
		CRACKME_ERROR_CHECK(crackme_status);

	crackme_status = CRACKME_FILE_WRITE_ERROR;
	if (jump_status || flag_status) {
		PRINT_TO_STDOUT(LINE)
		for (size_t i = 0; i < data->file_size; i++) {
			if (i % 8 == 0)
				fprintf(stdout, "%.8zx: ", (unsigned long)i);
			if ((i == flag_index && flag_status) || (i == jump_index && jump_status))
				fprintf(stdout, GREEN("%.2x"), data->buffer[i]);
			else if ((i == flag_index && !flag_status) || (i == jump_index && !jump_status))
				fprintf(stdout, YELLOW("%.2x"), data->buffer[i]);
			else
				fprintf(stdout, "%.2x", data->buffer[i]);
			if ((i + 1) % 2 == 0)
				fprintf(stdout, " ");
			if ((i + 1) % 8 == 0)
				fprintf(stdout, "\n");
		}
		fprintf(stdout, "\n");
		PRINT_TO_STDOUT(LINE)
		crackme_status = CRACKME_NO_ERROR;
	}

	data->crack_status = DONE_CRACK;

	if (fclose(file_to_hack))
		CRACKME_ERROR_CHECK(CRACKME_FILE_CLOSE_ERROR);

	return crackme_status;
}

CrackMeStatusCode ChangeFlag(Hacking* data, size_t* flag_index) {

	if (!data || !flag_index)
		CRACKME_ERROR_CHECK(CRACKME_NULL_POINTER);

	CrackMeStatusCode crackme_status = CRACKME_NO_ERROR;

	for (size_t i = 0; i < data->file_size - 3; i++) {
		if (data->buffer[i] 	== 0x00 && data->buffer[i + 1] == 0x61 &&
			data->buffer[i + 3] == 0x61) {
			*flag_index = i + 2;
			if (data->buffer[i + 2] == 0x30)
				break;
		}
	}

	if (!*flag_index) {
		PRINT_MESSAGE(RED("ERROR: subsequence for flag not found!"))
		crackme_status = CRACKME_SEQ_NOT_FOUND;
	}
	if (*flag_index && data->buffer[*flag_index] == NEW_FLAG) {
		PRINT_MESSAGE(YELLOW("WARNING: flag has already been changed!"))
		crackme_status = CRACKME_ALREADY_CRACK;
	}
	if (*flag_index && data->buffer[*flag_index] != NEW_FLAG) {
		PRINT_MESSAGE(GREEN("Flag was found in the file and changed!"))
		data->buffer[*flag_index] = NEW_FLAG;
	}

	return crackme_status;
}

CrackMeStatusCode ChangeJump(Hacking* data, size_t* jump_index) {

	if (!data || !jump_index)
		CRACKME_ERROR_CHECK(CRACKME_NULL_POINTER);

	CrackMeStatusCode crackme_status = CRACKME_NO_ERROR;

	for (size_t i = 0; i < data->file_size - 5; i++) {
		if (data->buffer[i] 	== 0xA1 && data->buffer[i + 1] == 0x02 &&
			data->buffer[i + 3] == 0x0A && data->buffer[i + 4] == 0xB4 &&
			data->buffer[i + 5] == 0x09) {
			*jump_index = i + 2;
			if (data->buffer[i + 2] == 0x74)
				break;
		}
	}

	if (!*jump_index) {
		PRINT_MESSAGE(RED("ERROR: subsequence for flag not found!"))
		crackme_status = CRACKME_SEQ_NOT_FOUND;
	}
	if (*jump_index && data->buffer[*jump_index] == NEW_JUMP) {
		PRINT_MESSAGE(YELLOW("WARNING: flag has already been changed!"))
		crackme_status = CRACKME_ALREADY_CRACK;
	}
	if (*jump_index && data->buffer[*jump_index] != NEW_JUMP) {
		fprintf(stdout, GREEN("\tJump was found in FILE '%s' and changed!")"\n", data->file_path);
		data->buffer[*jump_index] = NEW_JUMP;
	}
	fprintf(stdout, "======================================================================""\n");

	return crackme_status;
}

CrackMeStatusCode WriteToFile(Hacking* data) {
	FILE* file_to_hack = fopen(data->file_path, "wb");
	if (!file_to_hack)
		CRACKME_ERROR_CHECK(CRACKME_FILE_OPEN_ERROR);

	if (fwrite(data->buffer, sizeof(buffer_t), data->file_size, file_to_hack) != data->file_size)
		CRACKME_ERROR_CHECK(CRACKME_FILE_WRITE_ERROR);

	fprintf(stdout, "======================================================================""\n");
	fprintf(stdout, GREEN("\tWriting to FILE '%s' was successful")"\n", data->file_path);
	fprintf(stdout, "======================================================================""\n");

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
