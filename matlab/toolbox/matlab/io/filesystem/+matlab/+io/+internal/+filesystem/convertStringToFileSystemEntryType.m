function type = convertStringToFileSystemEntryType(sType)
    import matlab.io.FileSystemEntryType;
    if sType == "File"
        type = FileSystemEntryType.File;
    elseif sType == "Folder"
        type = FileSystemEntryType.Folder;
    elseif sType == "SymbolicLink"
        type = FileSystemEntryType.SymbolicLink;
    else
        type = FileSystemEntryType.None;
    end
end
