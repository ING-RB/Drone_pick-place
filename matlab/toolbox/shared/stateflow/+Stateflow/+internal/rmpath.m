function retVal = rmpath(dirPath)
%

%   Copyright 2021 The MathWorks, Inc.

    try
        if contains(path, dirPath)
            rmpath(dirPath);
        end
    catch ME %#ok<NASGU> 
    end
    retVal = '';
end
