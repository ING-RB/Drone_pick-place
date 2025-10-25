function filePath = getDefaultMLintConfigFilePath()
%GETDEFAULTMLINTCONFIGFILEPATH returns the default MLint configuration file
%path
    stringFilePath = fullfile(prefdir, "MLintDefaultSettings.txt");
    % Convert file path to a char array so settings can use it
    filePath = char(stringFilePath);
end