function obj = setFileParts(obj, hp)
    [pathName, fcnName, ext] = fileparts(char(hp.fullTopic));
    hp.topic = char(hp.topic);
    inClass = false;
    if hp.isContents
        pathName = hp.topic;
        hp.topic = 'Contents';
    elseif hp.isDir
        if hp.suppressedImplicit
            pathName = '';
        else
            pathName = hp.topic;
        end
        fcnName = [fcnName, ext];
        if ~isempty(hp.objectSystemName)
            fcnName = regexp(fcnName, '\w+', 'match', 'once');
        end
    elseif any(fcnName==filemarker)
        methodSplit = regexp(fcnName, filemarker, 'split', 'once');
        if ~matlab.lang.internal.introspective.containers.isClassDirectory(pathName)
            pathName = fullfile(pathName, ['@' methodSplit{1}]);
        end
        fcnName = methodSplit{2};
    elseif strcmp(regexp(pathName, '(?<=[@+])[^@+]*$', 'match', 'once'), fcnName)
        % @ dir Class
        inClass = true;
    elseif fcnName ~= ""
        if pathName == "" && contains(hp.objectSystemName, '.')
            fcnName = regexp(hp.topic, '\w*$', 'match', 'once');
        end
        if hp.isMCOSClassOrConstructor
            inClass = true;
            className = fcnName;
            if pathName == ""
                pathName = className;
            else
                pathName = append(pathName, '/@', className);
            end
        end
    end
    obj.InClass = inClass;
    obj.FunctionName = fcnName;
    obj.PathName = pathName;
    obj.Extension = ext;
end

%   Copyright 2021-2024 The MathWorks, Inc.
