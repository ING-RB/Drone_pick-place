function validateUserIncludePath(userIncludePath)
% Validate User header include path

%   Copyright 2018-2023 The MathWorks, Inc.
if ~iscellstr(userIncludePath)  
    if isempty(userIncludePath)
        error(message('MATLAB:CPP:PathNotFound',''));
    end
    try
        validateattributes(userIncludePath,{'char','string'},{'vector','row'});
    catch ME
        error(message('MATLAB:CPP:InvalidInputType','IncludePath'));
    end
 
    if ismissing(userIncludePath)
        error(message('MATLAB:CPP:InvalidInputType','IncludePath'));
    end
    
else
    if ~isrow(userIncludePath)
        error(message('MATLAB:CPP:InvalidInputType','IncludePath'));
    end
end

if ~isempty(find(startsWith(userIncludePath, "<"), 1))
    % atleast one userIncludePath seems to refer to a 'RootPaths' key
    % defer validation
    return;
end

userIncludePath = cellstr(convertStringsToChars(userIncludePath));
for index = 1:length(userIncludePath)
    if isempty(dir(userIncludePath{index}))
        error(message('MATLAB:CPP:PathNotFound',userIncludePath{index}));
    end
    % Error if the header file is a wildcard character
    if strfind(userIncludePath{index}, '*') > 0
        error(message('MATLAB:CPP:InvalidInputType','IncludePath'));
    end
end
end
