function tf = isscript(files)
% ISSCRIPT Is the file a script file?

%   Copyright 2012-2020 The MathWorks, Inc.

    tf = false(1,numel(files));
    if ~isempty(files)
        parser = matlab.depfun.internal.MatlabInspector.MFileParser('get');
    end    
    for k=1:numel(files)
        pth = files{k};
        % Can't be a script if it isn't a MATLAB file.
        if ~isempty(pth) && isMcode(pth) ...
            && matlab.depfun.internal.cacheExist(pth, 'file') == 2 
            r = parseFile(parser, pth);
            tf(k) = r.type(1) == 'S'; % S stands for ScriptFile
        end
        end
    end

