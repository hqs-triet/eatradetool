bool WriteFile(string filePath, string content)
{
    ResetLastError();
    
    int fHandler = INVALID_HANDLE;
    fHandler = FileOpen(filePath, FILE_WRITE|FILE_TXT|FILE_COMMON);
    if(fHandler != INVALID_HANDLE)
    {
        FileWriteString(fHandler, content);
        FileClose(fHandler);
    }
    else
    {
        Print(GetLastError());
        return false;
    }
    return false;
}
string ReadFile(string filePath)
{
    ResetLastError();
    
    
    if(FileIsExist(filePath, FILE_COMMON))
    {
        int fHandler = INVALID_HANDLE;
        fHandler = FileOpen(filePath, FILE_READ|FILE_TXT|FILE_COMMON);
        if(fHandler != INVALID_HANDLE)
        {
            string content = FileReadString(fHandler);
            FileClose(fHandler);
            return content;
        }
        else
            Print(GetLastError());
    }
    return "";
}