function cleanWorkDir(workDir)
%

%   Copyright 2020 The MathWorks, Inc.

    if matlab.internal.examples.folderExists(workDir)
        cd(workDir);
        dinfo = dir(workDir);
        for i = 1 : length(dinfo)
            if ~dinfo(i).isdir
                fileName = dinfo(i).name; 
                if endsWith(fileName, '.slx') 
                    bdclose(fileName);
                end
                tmpFileName = strcat(erase(string(now),'.'), fileName);
                [status,msg] = movefile(fullfile(workDir, fileName), fullfile(workDir, tmpFileName));
                delete(fullfile(workDir, tmpFileName));
            else
                folderName = dinfo(i).name; 
                if ~(strcmp(folderName, '.') || strcmp(folderName, '..'))
                    rmdir(fullfile(workDir, folderName), 's')
                end
            end
        end
    end    
end
