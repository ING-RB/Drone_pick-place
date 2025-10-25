function helpStr = sfxFile(filePath)
%

%   Copyright 2017-2020 The MathWorks, Inc.
    if ~exist(filePath, 'file')
        % On Windows, help() calls this function multiple times with following input
        % arguments
        % 1. filePath
        % 2. filePath>constructor
        % 3. filePath>publicmethod1 and so on
        % Since sfx does not yet expose its constructor and public methods
        % to help function, we return empty helpStr.         
        helpStr = '';
        return;
    end
    [~, filename, ~] = fileparts(filePath);
    fileText = matlab.internal.getcode.sfxfile(filePath); 
    %ppatil: Temporarily, I am using a double newline as indicator of start of class.    
    tripleNewLines = [newline newline newline];
    helpStr = fileText(1:regexp(fileText, tripleNewLines, 'once'));
    helpStr = strrep(helpStr, '% ', ' ');
    helpStr = strrep(helpStr, '%#codegen ', ' ');
    helpStr = strrep(helpStr, '%%FILENAME%%', filename);
end
