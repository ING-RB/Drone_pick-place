function [nvPairs, detected] = convertFlagsToNameValuePairs(nvPairs, options)
% This function is undocumented and may change in a future release.

% Copyright 2022 The MathWorks, Inc.

%convertFlagsToNameValuePairs convert flags to name/value pairs
%   nvPairs = convertFlagsToNameValuePairs(nvPairs) checks if nvPairs{1}
%   a valid line specification. If so, it converts it from a single
%   linespec into the corresponding name/value pairs, which are appended to
%   the beginning of the list of name/value pairs.
%
%   Optional name/value pairs:
%       LineStyleProperty - property name to use when converting line style
%       into a name/value pairs.
%
%       ColorProperty - property name to use when converting color from a
%       line specification into a name/value pairs.
%
%       MarkerProperty - property name to use when converting marker from a
%       line specification into a name/value pairs.
%
%       FillWithNone = false (default)
%           If line style is specified but not marker, then marker = ''
%           If marker is specified but not line style, then line style = ''
%
%       FillWithNone = true
%           If line style is specified but not marker, then marker = 'none'
%           If marker is specified but not line style, then line style = 'none'
%
%       Flags - struct where each field name corresponds to a flag (such as
%       'filled') and the corresponding value is a list of name/value pairs
%       (in a cell-array) to use to replace the flag.
%
%       If Flags is an empty struct (default) the first input is checked
%       for a line specification. If Flags is non-empty, then a mix of line
%       specification + at most one flag is allowed in the first two
%       inputs.

arguments
    % List of input name/value pairs, possibly including a linespec.
    nvPairs (1,:) cell

    % Property name for the line style.
    options.LineStyleProperty (1,1) string = "LineStyle"

    % Property name for the color.
    options.ColorProperty (1,1) string = "Color"

    % Property name for the marker.
    options.MarkerProperty (1,1) string = "Marker"

    % Should line style or marker be none if the other is populated?
    options.FillWithNone (1,1) logical = false

    % Flags
    options.Flags (1,1) struct = struct()
end

detected = false(1,3);
newArgs = cell(1,0);
for n = 1:(1 + ~isempty(options.Flags))
    [done, nvPairs, newArgs, options, detected] = ...
        helper(nvPairs, newArgs, options, detected);
    if done
        break
    end
end
nvPairs = [newArgs nvPairs];

end

function [done, nvPairs, newArgs, options, detected] = ...
    helper(nvPairs, newArgs, options, detected)

% Abort early if there are no name/value pairs.
done = true;
if numel(nvPairs) == 0
    return
end

nextArg = nvPairs{1};
if ~(ischar(nextArg) && isrow(nextArg)) && ~isStringScalar(nextArg)
    return
end

% Check if the next input argument is a recognized flag.
flags = fieldnames(options.Flags);
for f = 1:numel(flags)
    matchLength = max(1,strlength(nextArg));
    flag = flags{f};
    if strncmpi(nextArg, flag, matchLength)
        newArgs = [newArgs options.Flags.(flag)]; %#ok<AGROW> 
        nvPairs = nvPairs(2:end);
        options.Flags = rmfield(options.Flags, flag);
        done = false;
        return
    end
end

% Abort if another line spec has already been detected.
if any(detected)
    return
end

if options.FillWithNone
    % If line style is specified but not marker, then marker = 'none'
    % If marker is specified but not line style, then line style = 'none'
    [lineStyle, color, marker, msg]=colstyle(nextArg, 'plot');
else
    % If line style is specified but not marker, then marker = ''
    % If marker is specified but not line style, then line style = ''
    [lineStyle, color, marker, msg]=colstyle(nextArg);
end

% First argument is not a valid line spec.
if ~isempty(msg)
    return
end

% Found a line spec, so keep looking for other flags.
done = false;

% Create name/value pairs from the line spec.
lineSpecNVPairs = cell(1,6);
keep = false(1,6);
if ~isempty(lineStyle)
    keep(1:2) = true;
    lineSpecNVPairs{1} = options.LineStyleProperty;
    lineSpecNVPairs{2} = lineStyle;
end

if ~isempty(color)
    keep(3:4) = true;
    lineSpecNVPairs{3} = options.ColorProperty;
    lineSpecNVPairs{4} = color;
end

if ~isempty(marker)
    keep(5:6) = true;
    lineSpecNVPairs{5} = options.MarkerProperty;
    lineSpecNVPairs{6} = marker;
end

% Append the new name/value pairs to the argument list.
detected = keep(1:2:end);
newArgs = [newArgs lineSpecNVPairs(keep)];
nvPairs = nvPairs(2:end);

end
