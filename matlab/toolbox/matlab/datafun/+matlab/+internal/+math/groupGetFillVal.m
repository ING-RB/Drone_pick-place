function fillval = groupGetFillVal(x,f,prefix)
% GROUPGETFILLVAL Determine the fill value to use for empty groups in
% reduceByGroup (groupsummary or pivot) based on the class of the output of
% function handle f.
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.

%   Copyright 2019-2024 The MathWorks, Inc.

% Determine type of fill values

numInput = numel(x);
if numInput == 1 && isempty(x{1})
    funempty = str2func([class(x{1}) '.empty']);
    fillval = f(funempty(1,0));
elseif any(matches(prefix,["nummissing","nnz","numunique"]))
    fillval = 0;
elseif numInput == 1 && strcmp(prefix,"sum")
    funempty = str2func([class(x{1}) '.empty']);
    fillval = f(funempty(0,1));
elseif ~strncmp(prefix,"fun",3)
    fillval = missing;
else % function handle
    emptyX = cell(size(x));
    for j = 1:numel(x)
        funempty = str2func([class(x{j}) '.empty']);
        emptyX{j} = funempty(1,0);
    end
    % Try to determine fill value by calling function handle on an empty
    % and if that errors, then try to use missing
    try
        fillval = f(emptyX{:});
    catch
        fillval = missing;
    end
    if isempty(fillval) && ~all(cellfun(@isempty,x))
        fillval = missing;
    end
end
% Try to correct fill value when missing can't be converted to output
% type, otherwise just try what we have already
try
    c = cellfun(@(y){y(1)},x);
    d1 = f(c{:});
    if isinteger(d1)
        fillval = cast(NaN,class(d1));
    elseif islogical(d1)
        fillval = false;
    elseif ischar(d1)
        fillval = ' ';
    elseif strcmp(prefix,"none") && iscell(x{1})
        if iscellstr(x{1})
            fillval = {''};
        else
            fillval = {[]};
        end
    end
catch
end
