function fileName = newFileResolver(fileName,expectedExtension)
% This function is undocumented and may change in a future release.

%  Copyright 2017-2024 The MathWorks, Inc.
import matlab.automation.internal.mustBeTextScalar;
import matlab.automation.internal.mustContainCharacters;
import matlab.automation.internal.parentFolderResolver;

mustBeTextScalar(fileName,'fileName');
mustContainCharacters(fileName,'fileName');

if isfolder(fileName)
    error(message('MATLAB:automation:io:FileIO:InvalidFilenameMatchesFolderName',fileName));
end

if nargin > 1
    [~, ~, extension] = fileparts(char(fileName));
    if isempty(extension) && ~isempty(expectedExtension)
        error(message('MATLAB:automation:io:FileIO:MissingFileExtension',expectedExtension))
    elseif ~strcmpi(extension,expectedExtension)
        error(message('MATLAB:automation:io:FileIO:WrongFileExtension',expectedExtension));
    end
end



fileName = parentFolderResolver(fileName);
end