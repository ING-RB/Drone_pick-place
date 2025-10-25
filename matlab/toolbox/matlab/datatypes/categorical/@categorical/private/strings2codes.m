function [is,us] = strings2codes(s)
%STRINGS2CODES Handle strings that will become undefined elements.

%   Copyright 2013-2019 The MathWorks, Inc.

if ischar(s)
    us = strtrim(s);
    
    % Set '<undefined>' or '' as undefined elements
    if ~isempty(us) && us(1) ~= '<' % first char of categorical.undefLabel or categorical.missingLabel
        % Avoid more expensive checks in the most common cases where the
        % RHS is not '<undefined>', '<missing>' or '' or another empty string.
        is = 1;
    elseif (us == "") || matches(us,categorical.undefLabel)
        is = 0;
        us = {};
    elseif matches(us,categorical.missingLabel)
        throwAsCaller(MException(message('MATLAB:categorical:InvalidUndefinedChar', us, categorical.undefLabel, categorical.missingLabel)));
    else
        is = 1;
    end
    is = uint8(is); % cast to int because callers may rely on an integer class
elseif isstring(s) % scalar strings - have checked that it is scalar already
    us = strip(s);
    
    % Set '' and the missing string as undefined elements.  Don't allow
    % "<undefined>" or "<missing>" for strings.
    if ismissing(us) || strlength(us)==0
        is = 0;
        us = {};
    elseif any(us == categorical.undefLabel | us == categorical.missingLabel) % don't allow "<undefined>" or "<missing>"
        throwAsCaller(MException(message('MATLAB:categorical:InvalidUndefinedString', char(us), categorical.undefLabel, categorical.missingLabel)));
    else % create a category
        is = 1;
        us = char(us);
    end
    is = uint8(is); % cast to int because callers may rely on an integer class
else % iscellstr(s)
    [us,~,is] = unique(strtrim(s));

    us = us(:); % force cellstr to a column
    hasMissingLabel = matches(us,categorical.missingLabel);
    if any(hasMissingLabel)
        throwAsCaller(MException(message('MATLAB:categorical:InvalidMissingChar', categorical.missingLabel)));
    end

    % Set '<undefined>' or '' as undefined elements
    locs = (us == "") | matches(us,categorical.undefLabel);

    if any(locs)
        convert = (1:length(us))' - cumsum(locs);
        convert(locs) = 0;
        is = convert(is);
        us(locs) = [];
    end

    is = reshape(is,size(s));

    % Set code class based on number of strings (i.e. categories)
    is = categorical.castCodes(is, numel(us));
end
