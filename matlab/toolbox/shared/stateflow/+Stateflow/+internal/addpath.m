function retVal = addpath(dirPath)
%

%   Copyright 2021 The MathWorks, Inc.

    try
        addpath(dirPath);
    catch ME %#ok<NASGU> 
    end
    retVal = '';
end
