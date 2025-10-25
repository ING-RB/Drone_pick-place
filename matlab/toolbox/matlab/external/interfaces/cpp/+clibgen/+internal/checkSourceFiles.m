function checkSourceFiles(headerFiles,sourceFiles)
% Errors if same source file between HeaderFiles and SourceFiles

%   Copyright 2024 The MathWorks, Inc.

srcFilename = sourceFiles;
if (~isempty(srcFilename) && ...
        ~iscellstr(srcFilename)) %#ok
    srcFilename = cellstr(convertStringsToChars(srcFilename));
end

if iscellstr(srcFilename)
    srcFileList = '';
    for hIndex = 1:length(headerFiles)
        [~,filename,ext] = fileparts(headerFiles{hIndex});
        if (strcmp(ext,'.hpp') || strcmp(ext,'.h') || strcmp(ext,'.hxx'))
            continue;
        end
        hfilename = [filename ext];
        for sIndex = 1:length(srcFilename)
            [~,filename,ext] = fileparts(srcFilename{sIndex});
            sfilename = [filename ext];
            if strcmp(sfilename,hfilename)
                if isempty(srcFileList)
                   srcFileList =  sfilename;
                   break;
                else
                    srcFileList = [srcFileList ', ' sfilename]; %#ok
                    break;
                end
            end
        end
    end
    if ~isempty(srcFileList)
        error(message('MATLAB:CPP:DuplicateSourceFiles',srcFileList));
    end
else
    if ~isempty(srcFilename)
       [~,filename,ext] = fileparts(srcFilename);
       srcFileList = [filename ext];
       for hIndex = 1:length(headerFiles)
           [~,filename,ext] = fileparts(headerFiles{hIndex});
           hfilename = [filename ext];
           if strcmp(srcFileList,hfilename)
               error(message('MATLAB:CPP:DuplicateSourceFiles',srcFileList));
           end
       end
    end
end
end
