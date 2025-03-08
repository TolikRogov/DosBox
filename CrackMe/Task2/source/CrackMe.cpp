#include "CrackMe.hpp"

CrackMeStatusCode FileInfo(Hacking* data) {
	FILE* file_to_hack = fopen(data->file_path, "r");
	if (!file_to_hack)
		CRACKME_ERROR_CHECK(CRACKME_FILE_OPEN_ERROR);

	fprintf(stdout, "======================================================================""\n");
	fprintf(stdout, GREEN("\tFILE '%s' was opened!")"\n", data->file_path);
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
	FILE* file_to_hack = fopen(data->file_path, "r");
	if (!file_to_hack)
		CRACKME_ERROR_CHECK(CRACKME_FILE_OPEN_ERROR);

	if(setvbuf(file_to_hack, data->buffer, _IOLBF, data->file_size))
		CRACKME_ERROR_CHECK(CRACKME_FILE_READ_ERROR)

	fprintf(stdout, "======================================================================""\n");
	fprintf(stdout, GREEN("\tReading from FILE '%s' was successful")"\n", data->file_path);
	fprintf(stdout, "======================================================================""\n");

	for (size_t i = 0; i < data->file_size; i++) {
		fprintf(stdout, "%c", data->buffer[i]);
	}

	if (fclose(file_to_hack))
		CRACKME_ERROR_CHECK(CRACKME_FILE_CLOSE_ERROR);

	return CRACKME_NO_ERROR;
}

const wchar_t* CrackMeErrorsMessenger(CrackMeStatusCode status) {
	switch(status) {
		case CRACKME_NO_ERROR:							return L"CRACKME ERROR - NO ERROR";
		case CRACKME_FONT_LOAD_ERROR:					return L"CRACKME ERROR - LOADING FONT FROM FILE ERROR";
		case CRACKME_IMG_LOAD_ERROR:					return L"CRACKME ERROR - LOADING INAGE FROM FILE ERROR";
		case CRACKME_FILE_OPEN_ERROR:					return L"CRACKME ERROR - FILE WAS NOT OPENED";
		case CRACKME_FILE_CLOSE_ERROR:					return L"CRACKME ERROR - FILE WAS NOT CLOSED";
		case CRACKME_ALLOCATION_ERROR:					return L"CRACKME ERROR - MEMORY WAS ALLOCATED WITH ERROR";
		case CRACKME_FILE_READ_ERROR:					return L"CRACKME ERROR - READING FROM FILE HAPPENED WITH ERROR";
		default: 										return L"UNDEFINED ERROR";
	}
}
