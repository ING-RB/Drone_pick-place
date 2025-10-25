function [fullName, timeStamp, usingCache] = getFileInfo(matFileOrFcnCall)
%

%   Copyright 2020-2023 The MathWorks, Inc.

    usingCache = true;
    try
        if ~endsWith(matFileOrFcnCall, '.mat')
            % Input argument matFile is not a mat file but a function or a function call
            tokens = regexp(matFileOrFcnCall, '(.*)\((.*)\)', 'tokens');
            if ~isempty(tokens)
                % function call
                functionName = tokens{1}{1};
                functionArgs = strtrim(tokens{1}{2});
                if ~isempty(functionArgs)
                    % Nontrivial function call, it might return different
                    % matobjs with same arguments.
                    usingCache = false;
                end
            else
                functionName = matFileOrFcnCall;
            end
            fileName = which(functionName);
        else
            if isfile(matFileOrFcnCall)
                fileName = matFileOrFcnCall;
            else
                % matFileOrFcnCall is not file, try if it is a file on
                % MATLAB path.
                fileName = which(matFileOrFcnCall);
            end
        end
        fileInfo = dir(fileName);
        fullName = [fileInfo.folder, filesep, fileInfo.name];
        timeStamp = fileInfo.datenum;
    catch
        fullName = matFileOrFcnCall;
        timeStamp = 0;
        usingCache = false;
    end

    assert(all(char(fullName) < 128), message("dlcoder_spkg:cnncodegen:UnsupportedNonAsciiFilePath", matFileOrFcnCall));
end
