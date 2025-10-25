function d = readdictionary(filename, opts)
%

%   Copyright 2024 The MathWorks, Inc.


% TODO: readdictionary to accept reader that has data from a string
% makeLevelReaderFromString()

    arguments
        filename (1, 1) string {mustBeFile}
        opts(1, 1) struct
    end

    import matlab.io.json.internal.read.*

    r = Reader(filename, opts);

    if opts.DictionarySelector ~= ""
        status = cdSelector(r, opts.DictionarySelector);
        if (~status)
            error(message('MATLAB:io:json:common:UnmatchedJSONPointer', opts.DictionarySelector));
        end
    end

    if ~ismissing(opts.DictionaryNodeName)
        status = cdNodeName(r, opts.DictionaryNodeName);
        if (~status)
            error(message('MATLAB:io:json:common:NodeNameNotFound', opts.DictionaryNodeName));
        end
    end

    d = convertReaderToDictionary(r, opts);
end
