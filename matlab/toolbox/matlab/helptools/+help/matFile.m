function helpStr = matFile(fullPath, justH1)
%help.matFile Provides the help text for MAT files.

%   Copyright 2018-2020 The MathWorks, Inc.
    
    if nargin < 2
        justH1 = false;
    end
    
    [~, matFileName] = fileparts(fullPath);
    try
        if justH1
            helpStr = getString(message('MATLAB:help:DefaultMatfileHelp', matFileName));
        else
            helpStr = getString(message('MATLAB:help:MatfileBanner', matFileName));
            w = warning('off');
            cleanup = onCleanup(@()warning(w));    
            helpStr = append(helpStr, evalc(compose("whos('-file', %s)", mat2str(fullPath))));
            helpStr = append(helpStr, '    See also LOAD, SAVE, MATFILE', newline);
        end
    catch e
        helpStr = append(e.message, newline);
    end
end
