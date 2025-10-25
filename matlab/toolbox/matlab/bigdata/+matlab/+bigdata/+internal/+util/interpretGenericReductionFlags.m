function [nanFlagCell, precisionFlagCell] = interpretGenericReductionFlags(FCN_NAME, flags)
% Common code for interpreting reduction flags for generic types. This can
% be used for numeric types as well as containers such as table or
% timetable.

% Copyright 2022-2023 The MathWorks, Inc.

baseNanFlags = {'includenan', 'omitnan', 'includemissing', 'omitmissing'};
basePrecisionFlags = {'double', 'native', 'default'};
otherFlags = {}; % Flags to allow through but ignore

switch lower(FCN_NAME)
    case {'sum', 'prod', 'mean'}
        defaultNan = {'includenan'};
        defaultPrecision = {'default'};
        allowedNanFlags = baseNanFlags;
        allowedPrecisionFlags = basePrecisionFlags;
    case {'min', 'max'}
        defaultNan = {'omitnan'};
        defaultPrecision = {};
        allowedNanFlags = baseNanFlags;
        allowedPrecisionFlags = {};
        otherFlags = {'linear'};
    case 'var'
        defaultNan = {'includenan'};
        defaultPrecision = {};
        allowedNanFlags = baseNanFlags;
        allowedPrecisionFlags = {};
    case {'any', 'all'}
        defaultNan = {};
        defaultPrecision = {};
        allowedNanFlags = {};
        allowedPrecisionFlags = {};
    case {'median'}
        defaultNan = {'includenan'};
        defaultPrecision = {};
        allowedNanFlags = baseNanFlags;
        allowedPrecisionFlags = {};
    otherwise
        assert(false, 'Unrecognised reduction: %s', FCN_NAME);
end

allowedFlags = [allowedNanFlags, allowedPrecisionFlags, otherFlags];

parsedFlags = iParseFlags(FCN_NAME, flags, allowedFlags);

categories = {allowedNanFlags, allowedPrecisionFlags};
flags = cell(1, numel(categories));
defaults = {defaultNan, defaultPrecision};
for catIdx = 1:numel(categories)
    thisFlagCell = intersect(parsedFlags, categories{catIdx});
    if isempty(thisFlagCell)
        flags{catIdx} = defaults{catIdx};
    else
        % Need to error if multiple flags specified, or single flag specified multiple
        % times.
        if numel(thisFlagCell) >= 2 || ...
                sum(strcmp(thisFlagCell{1}, parsedFlags)) >= 2
            error(message('MATLAB:bigdata:array:MultipleOptionsSpecified', ...
                FCN_NAME, strjoin(categories{catIdx})));
        end
        flags{catIdx} = thisFlagCell(1);
    end
end
[nanFlagCell, precisionFlagCell] = deal(flags{:});
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% iParseFlags - given a cell of flags, and a cell of options, pick out the
% unambiguous case-insensitive matches. Error on invalid or ambiguous flag.
function parsedFlags = iParseFlags(FCN_NAME, flags, options)
validFlagsStr = strjoin(options);
parsedFlags = cell(1, numel(flags));
for idx = 1:length(flags)
    thisFlag = flags{idx};
    match = strncmpi(thisFlag, options, strlength(thisFlag));
    switch sum(match)
        case 0
            % no match
            if isempty(options)
                % No options are valid
                error(message('MATLAB:bigdata:array:NoOptionsAllowed', FCN_NAME));
            else
                error(message('MATLAB:bigdata:array:InvalidOption', thisFlag, FCN_NAME, validFlagsStr));
            end
        case 1
            parsedFlags{idx} = options{match};
        case 2
            % Special case for partial-matches of 'omit*' or 'include*'
            if strncmpi(thisFlag, "omit", strlength(thisFlag)) ...
                    || strncmpi(thisFlag, "include", strlength(thisFlag))
                validMatches = options(match);
                parsedFlags{idx} = validMatches{1};
            else
                error(message('MATLAB:bigdata:array:AmbiguousOption',thisFlag, FCN_NAME, validFlagsStr));
            end
        otherwise
            error(message('MATLAB:bigdata:array:AmbiguousOption',thisFlag, FCN_NAME, validFlagsStr));
    end
end
end

