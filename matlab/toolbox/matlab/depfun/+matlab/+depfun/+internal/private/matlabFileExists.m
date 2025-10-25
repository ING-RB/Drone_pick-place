function [tf, file] = matlabFileExists(fcnPath)
% Use the WHICH and EXIST caches to determine if the file exists.

%   Copyright 2013-2020 The MathWorks, Inc.

    function [tf, w] = fileExists(file)
        w = matlab.depfun.internal.cacheWhich(file);
        tf = ~isempty(w) || matlab.depfun.internal.cacheExist(file,'file') ~= 0;
    end

    % Test in order of expected frequency.
    tf = false;
    
    % If the file has an extension, don't add one.
    ext = extension(fcnPath);
    if ~isempty(ext)
        [tf, pth] = fileExists(fcnPath);
        if ~isempty(pth)
            file = pth;
        else
        file = fcnPath;
        end
        return;
    end
    
    % This could be a loop over some extList = {'.m', '.p', '.mlx'}.
    % I've unrolled the loop in hopes of better performance. Premature
    % optimization? Used nesting to avoid repeating ext strings.
    % note that MatlabInspector and genManifest use the reverse ordering
    %some day the ordering below may also need to be reversed.    
    import matlab.depfun.internal.requirementsConstants
    
    k = 1;
    while ~tf && k <= requirementsConstants.executableMatlabFileExtSize
        file = [fcnPath ...
                requirementsConstants.executableMatlabFileExt_reverseOrder{k}];
        [tf, pth] = fileExists(file);
        if ~isempty(pth)
            file = pth;
        end
        k = k + 1;
    end
    
    if ~tf
        file = '';
    end
end
