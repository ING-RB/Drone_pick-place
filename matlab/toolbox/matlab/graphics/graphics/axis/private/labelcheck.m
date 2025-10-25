function [targets, label, nvPairs] = labelcheck(propname, args)
% Input checking helper for title, subtitle, xlabel, ylabel, and zlabel.

%   Copyright 2013-2022 The MathWorks, Inc.

import matlab.graphics.chart.internal.inputparsingutils.peelFirstArgParent
import matlab.graphics.chart.internal.inputparsingutils.splitPositionalFromPV
import matlab.graphics.internal.validatePartialPropertyNames

supportDoubleAxesHandle = true;
[targets, args] = peelFirstArgParent(args, supportDoubleAxesHandle);

cmdName = lower(propname);
try
    hasOptional = propname == "Title";
    [label, nvPairs] = splitPositionalFromPV(args, 1, hasOptional);
catch ex
    if ex.identifier == "MATLAB:class:BadParamValuePairs"
        throwAsCaller(ex)
    else
        id = "MATLAB:" + cmdName + ":InvalidNumberOfInputs";
        throwAsCaller(MException(id, ex.message));
    end
end

% validatePartialPropertyNames normalizes property names (fills-in
% incomplete names and fixes case) and will throw if there are any invalid
% property names (i.e. a name that doesn't exist on Text or is ambiguous).
propNames = validatePartialPropertyNames(...
    'matlab.graphics.primitive.Text', nvPairs(1:2:end));
nvPairs(1:2:end) = cellstr(propNames);

% Search for a Parent name/value pair.
parentNVPairs = find(propNames == "Parent");
if ~isempty(parentNVPairs)
    % Capture value of the last Parent name/value pair.
    targets = nvPairs{2*parentNVPairs(end)};

    % Remove Parent name/value pairs from the list of name/value pairs.
    nvPairs(2*parentNVPairs+[-1;0]) = [];
end

% Only allow a homogeneous vector. If the vector is heterogeneous, the
% class of the entire vector will be closest common baseclass.
commonBaseClass = class(targets);
isHomogeneous=all(arrayfun(@(t)strcmp(class(t),commonBaseClass),targets), 'all');
if ~isHomogeneous
    throwAsCaller(MException(message('MATLAB:rulerFunctions:MixedAxesVector')))
end

if isempty(targets)
    targets = gca;

    if isa(targets,'matlab.graphics.chart.Chart')
        % If the target is a chart, stop now and return. The caller will
        % dispatch to the chart's method.
        return;
    end
end

% Name/value pairs may have included an invalid object.
msg = message("MATLAB:title:InvalidTarget");
ex = MException("MATLAB:" + cmdName + ":InvalidTarget", msg.getString());
if ~isa(targets, 'matlab.graphics.Graphics')
    % This will catch non-graphics objects or deleted graphics objects.
    if ~all(isgraphics(targets))
        throwAsCaller(ex);
    end
    targets = handle(targets);
elseif ~all(isvalid(targets))
    throwAsCaller(ex);
end

if ~all(isprop(targets, propname))
    classParts = strsplit(class(targets),'.');
    msg = message('MATLAB:Chart:UnsupportedConvenienceFunction', ...
        cmdName, classParts{end});
    throwAsCaller(MException(msg));
end

for n = 1:numel(targets)
    t = targets(n).(propname);

    if ~isscalar(t) ...
       || ~isa(t,'matlab.graphics.Graphics') ...
       || ~isprop(t,'String')
        throwAsCaller(ex);
    end
end

end
