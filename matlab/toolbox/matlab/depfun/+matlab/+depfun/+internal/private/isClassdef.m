function tf = isClassdef(files)
% isClassdef Does file contain a MATLAB class defintion?

%   Copyright 2013-2020 The MathWorks, Inc.

    import matlab.depfun.internal.requirementsConstants
    
    if ischar(files)
        files = { files };
    end
    
    tf = false(1,numel(files));
    if ~isempty(files)
        parser = matlab.depfun.internal.MatlabInspector.MFileParser('get');
    end    
    for f = 1:numel(files)
        file  = files{f};
        % Make sure this is a MATLAB function (file name must end with .m 
        % or .mlx). If it's a .p file, look for the .m file instead.
        ext = extension(file);
        if strcmp(ext, '.p')
            file(end-1:end) = '.m';
            ext = '.m';
        end

        if ismember(ext, requirementsConstants.analyzableMatlabFileExt_reverseOrder)
            tf = hasClassDef(parser, file);
        elseif isempty(ext)
            k = 1;
            while ~tf && k <= requirementsConstants.analyzableMatlabFileExtSize
                tf = hasClassDef(parser, [file ...
                        requirementsConstants.analyzableMatlabFileExt{k}]);
                k = k + 1;
            end
        end
    end
end

function tf = hasClassDef(parser, file)
    tf = false;
    % If the MATLAB file exists, does it contain CLASSDEF?
    if matlab.depfun.internal.cacheExist(file, 'file')
        r = parseFile(parser, file);
        tf = r.type(1) == 'C'; % C stands for ClassDefinitionFile
    end
end
