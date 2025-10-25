function files = getLocalizedFileList(folder, filename, extension)
    arguments
        folder (1,1) string
        filename (1,1) string
        extension (1,1) string = ".json"
    end

    if ~startsWith(extension, ".")
        extension = "." + extension;
    end
    
    files = string.empty;

    docLang = matlab.internal.doc.services.getDocLanguageLocale;
    if docLang ~= matlab.internal.doc.services.DocLanguage.ENGLISH
        locFileName = filename + "_" + docLang.getDirectory + extension;
        locFile = fullfile(folder, locFileName);
        if isfile(locFile)
            files = locFile;
        end
    end
    
    enFileName = filename + extension;
    enFile = fullfile(folder, enFileName);
    if isfile(enFile)
        files = [files enFile];
    end

end