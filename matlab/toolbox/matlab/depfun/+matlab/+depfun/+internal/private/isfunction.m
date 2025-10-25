function tf = isfunction(files)
% ISFUNCTION Is the file a MATLAB function file?

%   Copyright 2012-2020 The MathWorks, Inc.

    tf = false(1,numel(files));
    if ~isempty(files)
        parser = matlab.depfun.internal.MatlabInspector.MFileParser('get');
    end
    for k=1:numel(files)
        pth = files{k};
        % Can't be a function if it isn't a MATLAB file.
        if ~isempty(pth) && isMcode(pth) && exist(pth, 'file') == 2 
            r = parseFile(parser, pth);
            tf(k) = r.type(1) == 'F'; % F stands for FunctionFile
        end
        end
    end
