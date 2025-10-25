function [is,us] = strings2codes(s)  %#codegen
%STRINGS2CODES Handle strings that will become undefined elements.

%   Copyright 2018-2019 The MathWorks, Inc.

if ischar(s) || isstring(s)
    ts = strtrim(char(s));
    
    % Set '<undefined>' or '' as undefined elements
    if ~isempty(ts) && ts(1) ~= '<' % first char of categorical.undefLabel or categorical.missingLabel
        % Avoid more expensive checks in the most common cases where the
        % RHS is not '<undefined>', '<missing>' or '' or another empty string.
        is = 1;
        us = ts;
    elseif strcmp(ts,char(zeros(0,0))) || strcmp(ts,char(zeros(1,0))) || ...
            strcmp(ts,categorical.undefLabel)
        is = 0;
        us = '';
    else
        coder.internal.errorIf(strcmp(ts,categorical.missingLabel), ...
            'MATLAB:categorical:InvalidUndefinedChar', ts, categorical.undefLabel, categorical.missingLabel);
        is = 1;
        us = ts;
    end
    is = uint8(is); % cast to int because callers may rely on an integer class
else % iscellstr(s)
    [usraw,~,is] = matlab.internal.coder.datatypes.cellstr_unique(...
        matlab.internal.coder.datatypes.cellstr_strtrim(s));
    
    us = reshape(usraw, [], 1); % force cellstr to a column
    if coder.internal.isConst(size(s))
        coder.varsize('us', [numel(s) 1], [true false]);
    end
    
    locs = false(size(us));
    for i = 1:numel(us)
        coder.internal.errorIf(strcmp(us{i},categorical.missingLabel), ...
            'MATLAB:categorical:InvalidMissingChar', categorical.missingLabel);
        % Set '<undefined>' or '' as undefined elements
        locs(i) = strcmp(us{i}, char(zeros(0,0))) || strcmp(us{i}, char(zeros(1,0))) || ...
            strcmp(us{i}, categorical.undefLabel);
    end

    if any(locs,1)
        convert = (1:length(us))' - cumsum(locs);
        convert(locs) = 0;
        is = convert(is);
        us(locs) = [];
    end

    is = reshape(is,size(s));

    coder.internal.assert(numel(us) <= categorical.maxNumCategories, ...
        'MATLAB:categorical:MaxNumCategoriesExceeded',categorical.maxNumCategories);

    % Set code class based on the number of strings
    is = categorical.castCodes(is, numel(s));
end
