function checkFolderExistence(folder)
%checkFolderExistence Checks if the folder exists, throws an error if not.

%   Copyright 2014-2020 The MathWorks, Inc.
if exist(folder, 'dir') ~= 7
    errId = 'MATLAB:mapreduceio:serialmapreducer:folderNotForWriting';
    msgText = message('MATLAB:mapreduceio:serialmapreducer:folderNotForWriting',...
        folder);
    baseException = MException(errId, msgText);
    causeException = MException('MATLAB:mapreduceio:mapreduce:noFolder',...
        message('MATLAB:mapreduceio:mapreduce:noFolder'));
    err = addCause(baseException, causeException);
    throw(err);
end
