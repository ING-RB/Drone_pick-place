function code = sfxfile(filePath,writeFile)
%

%   Copyright 2018-2019 The MathWorks, Inc.

    try
        if ~exist('writeFile', 'var')
            writeFile = false;
        end
        [~, file1, ~] = fileparts(filePath);
        tempdirname = [tempdir file1 num2str(int8(rand))];
        if exist(tempdirname, 'dir')
            rmdir(tempdirname, 's');
        end
        unzip(filePath, tempdirname);
        code = fileread(fullfile(tempdirname, 'code', 'mcode'));
        if writeFile
            fileID = fopen([file1 '.m'],'w');
            nbytes = fprintf(fileID,'%s',code); %#ok<NASGU>
            fclose(fileID);
        end
    catch ME
        errId = 'MATLAB:lang:FileNotFound';
        Stateflow.internal.getRuntime().throwError(errId, getString(message(errId, filePath)), filePath, 'OnlyCMD');
    end

end
