function checkCLinkage(headerFiles,sourceFiles,cLinkage)
% check if cLinkage is set correctly for .h and .c files

%   Copyright 2024 The MathWorks, Inc.

% If user passes .h under InterfaceGenerationFiles option and .c with same
% name as .h under SupportingSourceFiles option without setting CLinkage to
% true then C++ interface will throw error as it defines a C library and
% defines CLinkage to be true
if ~cLinkage
    for hIndex = 1:length(headerFiles)
        [~,hFilename,hExt] = fileparts(headerFiles{hIndex});
        if ~strcmp(hExt,'.h')
            continue;
        end
        srcFileList = '';
        if ~isempty(sourceFiles) && ...
            ~iscellstr(sourceFiles)
              srcFileList = cellstr(convertStringsToChars(sourceFiles));
        end
        for sIndex = 1:length(srcFileList)
            [~,sFilename,ext] = fileparts(srcFileList{sIndex});
            if strcmp(ext,'.c') && strcmp(hFilename,sFilename)
                error(message('MATLAB:CPP:NoCLinkageFlag',[hFilename,hExt],[sFilename ext]));
            end
        end
    end
end
end
