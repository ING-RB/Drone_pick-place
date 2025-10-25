function [figFullFileName, codeFullFileName] = validateGUIDEApp(figFile)
%VALIDATEGUIDEAPP - Given a user-inputted FIG file, get the corresponding valid 
% full file path of the FIG File.  Normalize the file name and validate that 
% the FIG file corresponds to a GUIDE App.
%
% INPUT:
%   figFile {char or scalar string) - user-inputted file name of FIG File.
%       This should be of any of the following forms:
%        'myNewFile'
%        'myNewFile.fig'
%        'C:/username/myNewFile'
%        'C:/username/myNewFile.fig'
% 
% OUTPUTS:
%   figFullFileName {char} - valid, normalized full file name of the
%       inputted fig file.
%   codeFullFileName {char} - MATLAB File corresponding to the FIG File.

% Copyright 2020 The MathWorks, Inc.

% Obtain a validated FIG full file name based on the input.
guideFigFullFileName = appdesigner.internal.application.getValidatedFile(figFile, '.fig');

% For case-insensitive platforms, normalize fig file name and check for existence.
figFullFileName = appdesigner.internal.application.normalizeFullFileName(guideFigFullFileName, '.fig');

% Validate that a corresponding M File exists.
codeFullFileName = replace(figFullFileName,'.fig','.m');
if ~exist(codeFullFileName, 'file')
    error(message('appmigration:appmigration:InvalidCodeFileName', codeFullFileName));
end

end