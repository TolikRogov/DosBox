#include "CrackMe.hpp"

CrackMeStatusCode RunCrack(Hacking* data) {
	if (data->crack_status == DONE_CRACK) {
		fprintf(stdout, "======================================================================""\n");
		fprintf(stdout, YELLOW("WARNING: Crack or file checking for crack has already been! Please, change file!")"\n");
		fprintf(stdout, "======================================================================""\n");
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
	CRACKME_ERROR_CHECK(crackme_status);

	crackme_status = WriteToFile(data);
	CRACKME_ERROR_CHECK(crackme_status);

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

	fprintf(stdout, "======================================================================""\n");
	fprintf(stdout, GREEN("\tFILE '%s' was opened!")"\n", data->file_path);
	fprintf(stdout, "======================================================================""\n");

	fprintf(stdout, "======================================================================""\n");

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

	fprintf(stdout, "======================================================================""\n");

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

	fprintf(stdout, "======================================================================""\n");
	fprintf(stdout, GREEN("\tReading from FILE '%s' was successful")"\n", data->file_path);
	fprintf(stdout, "======================================================================""\n");

#ifdef _DEBUG_
	fprintf(stdout, "======================================================================""\n");
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
	fprintf(stdout, "======================================================================""\n");
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
	crackme_status = ChangeFlag(data, &flag_index);
	CRACKME_ERROR_CHECK(crackme_status);

	size_t jump_index = 0;
	crackme_status = ChangeJump(data, &jump_index);
	CRACKME_ERROR_CHECK(crackme_status);

#ifdef _DEBUG_
	fprintf(stdout, "======================================================================""\n");
	for (size_t i = 0; i < data->file_size; i++) {
		if (i % 8 == 0)
			fprintf(stdout, "%.8zx: ", (unsigned long)i);
		if (i == flag_index || i == jump_index)
			fprintf(stdout, GREEN("%.2x"), data->buffer[i]);
		else
			fprintf(stdout, "%.2x", data->buffer[i]);
		if ((i + 1) % 2 == 0)
			fprintf(stdout, " ");
		if ((i + 1) % 8 == 0)
			fprintf(stdout, "\n");
	}
	fprintf(stdout, "\n");
	fprintf(stdout, "======================================================================""\n");
#endif

	data->crack_status = DONE_CRACK;

	if (fclose(file_to_hack))
		CRACKME_ERROR_CHECK(CRACKME_FILE_CLOSE_ERROR);

	return CRACKME_NO_ERROR;
}

CrackMeStatusCode ChangeFlag(Hacking* data, size_t* flag_index) {

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

	fprintf(stdout, "======================================================================""\n");
	if (!*flag_index)
		fprintf(stdout, RED("ERROR: subsequence for flag not found!")"\n");
	if (*flag_index && data->buffer[*flag_index] == NEW_FLAG)
		fprintf(stdout, YELLOW("WARNING: flag has already been changed!")"\n");
	if (*flag_index && data->buffer[*flag_index] != NEW_FLAG) {
		fprintf(stdout, GREEN("\tFlag was found in FILE '%s' and changed!")"\n", data->file_path);
		data->buffer[*flag_index] = NEW_FLAG;
	}
	fprintf(stdout, "======================================================================""\n");

	return CRACKME_NO_ERROR;
}

CrackMeStatusCode ChangeJump(Hacking* data, size_t* jump_index) {

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

	fprintf(stdout, "======================================================================""\n");
	if (!*jump_index)
		fprintf(stdout, RED("ERROR: subsequence for jump not found!")"\n");
	if (*jump_index && data->buffer[*jump_index] == NEW_JUMP)
		fprintf(stdout, YELLOW("WARNING: jump has already been changed!")"\n");
	if (*jump_index && data->buffer[*jump_index] != NEW_JUMP) {
		fprintf(stdout, GREEN("\tJUMP was found in FILE '%s' and changed!")"\n", data->file_path);
		data->buffer[*jump_index] = NEW_JUMP;
	}
	fprintf(stdout, "======================================================================""\n");

	return CRACKME_NO_ERROR;
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
		default: 										return L"UNDEFINED ERROR";
	}
}
