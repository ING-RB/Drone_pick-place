function files = replaceIfExist(files, replacements)
%

%   Copyright 2014-2020 The MathWorks, Inc.

    replacingFiles = ~strcmp(files, replacements);
    pos = find(replacingFiles);
    fileMustExist = replacements(replacingFiles);
    for k=1:numel(fileMustExist)
        if matlab.depfun.internal.cacheExist(fileMustExist{k},'file') == 2
            files{pos(k)} = replacements{pos(k)};
        end
    end
end
