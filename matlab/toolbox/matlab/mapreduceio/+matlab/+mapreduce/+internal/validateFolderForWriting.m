function validateFolderForWriting(folder)
%VALIDATEFOLDERFORWRITING Validates a local folder for writing.
%   Check if the given local folder exists, if so, try to open
%   a file in it. If the folder does not exist, try to create it.
%
%   See also datastore, mapreduce, tall.

%   Copyright 2016-2020 The MathWorks, Inc.
    if ~exist(folder, 'dir')
        [s, errmsg] = mkdir(folder);
        if ~s
            errID = 'MATLAB:mapreduceio:serialmapreducer:createFolderFailed';
            msgText = message('MATLAB:mapreduceio:serialmapreducer:createFolderFailed', folder);
            baseException = MException(errID, msgText);
            causeException = MException('MATLAB:mapreduceio:serialmapreducer:createFolderFailed', errmsg);
            err = addCause(baseException, causeException);
            throw(err);
        end
    else
        testF = fullfile(folder, 'testFile');
        [fh, errmsg] = fopen(testF, 'a');
        if fh == -1
            errID = 'MATLAB:mapreduceio:serialmapreducer:folderNotForWriting';
            msgText = message('MATLAB:mapreduceio:serialmapreducer:folderNotForWriting', folder);
            baseException = MException(errID, msgText);
            causeException = MException('MATLAB:mapreduceio:serialmapreducer:folderNotForWriting', errmsg);
            err = addCause(baseException, causeException);
            throw(err);
        end
        fclose(fh);
        delete(testF);
    end
end
