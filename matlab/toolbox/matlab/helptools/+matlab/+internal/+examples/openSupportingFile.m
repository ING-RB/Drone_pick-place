function openCompleted = openSupportingFile(workDir, metadata, fileName)
%

%   Copyright 2018-2023 The MathWorks, Inc.

invalidChar = {'/', '\'};
if contains(fileName, invalidChar)
    error(message("MATLAB:examples:SupportingFileInSubfolder",fileName));
end

openCompleted = false;
[~, ~, ext] = fileparts(string(fileName));
fileNameHasExtension = (strlength(ext) > 0);

fileNameList = cellfun(@(x) string(x.filename), metadata.files);

if ~fileNameHasExtension && ~isempty(fileNameList)
    modelName = fileName + ".slx";
    modelExists = any(contains(fileNameList, modelName));
    if modelExists
        open(fullfile(workDir, modelName))
        openCompleted = true;
        return;
    end
end

for iFiles = 1:numel(fileNameList)
    supportingFileName = fileNameList{iFiles};
    
    if isExecutableFile(supportingFileName) && ~fileNameHasExtension
        [~, supportingFileName, ~] = fileparts(supportingFileName);
    end

    if strcmp(fileName, supportingFileName)
        open(fullfile(workDir,fileNameList{iFiles}))
        openCompleted = true;
        return;
    end
end

error(message("MATLAB:examples:InvalidSupportingFile",fileName));

end

function isExecutable = isExecutableFile(filename)
isExecutable = false;
pattern = [".m", ".mlx", ".sfx", ".sldd", ".mlapp"];
if endsWith(filename, pattern)
    isExecutable = true;
end
end
