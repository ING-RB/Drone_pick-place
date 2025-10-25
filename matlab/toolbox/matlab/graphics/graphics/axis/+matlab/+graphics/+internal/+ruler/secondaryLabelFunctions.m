function secondaryLabelFunctions(xyz, varargin)
% This function is undocumented and may change in a future release.

%   Copyright 2023 The MathWorks, Inc.

import matlab.graphics.chart.internal.inputparsingutils.peelFirstArgParent
import matlab.graphics.chart.internal.inputparsingutils.splitPositionalFromPV

[ax, args] = peelFirstArgParent(varargin);
nargs = numel(args);

% Check for axes first arg.
if ~isempty(ax)
    if isa(ax,'matlab.graphics.axis.Axes')
        if nargs < 1 
            throwAsCaller(MException(message("MATLAB:narginchk:notEnoughInputs")))
        end
    else
        throwAsCaller(MException("MATLAB:graphics:secondarylabel:InvalidTarget",...
            message("MATLAB:graphics:yyaxis:NotAxesArgument")))
    end
else
    ax = gca;
end
rulerProp = "Active"+upper(xyz)+"Ruler";
rulers = get(ax, rulerProp); % cell array if >1 axes

% Grab the positional string argument if present.
numRequired = 0;
hasOptional = true;
[posargs, pvpairs] = splitPositionalFromPV(args, numRequired, hasOptional);

stringArg = [];
if ~isempty(posargs)
    [stringArg, ex] = validateStringArg(posargs{1});
    if ~isempty(ex)
        throwAsCaller(ex);
    end
end

% Handle the auto/manual cases.
if isscalar(stringArg) && (strcmpi(stringArg, "auto") || strcmpi(stringArg, "manual"))
    if ~isempty(pvpairs)
        throwAsCaller(MException(message("MATLAB:graphics:secondarylabel:ArgsAfterAutoManual")))
    end
    doAutoManual(rulers,stringArg);
    return;
end

% Check the Visible NV pair if present.
visVal = [];
if ~isempty(pvpairs)
    for i = 1:numel(pvpairs)/2
        [visVal,ex] = validateVisibleNV(pvpairs{2*i-1}, pvpairs{2*i});
        if ~isempty(ex)
            throwAsCaller(ex);
        end
    end
end

% Update the SecondaryLabel's visibility and string.
doUpdateSecondaryLabel(rulers,stringArg,visVal);
end

function [stringArg, ex] = validateStringArg(stringArg)
ex = [];
badStringEx = MException("MATLAB:graphics:secondarylabel:FlagMustBeString", ...
        message("MATLAB:hg:datatypes:NumericOrStringDataType:ArrayClass"));
try 
    stringArg = string(stringArg);
    if ~isvector(stringArg)
        ex = badStringEx;
    end
catch
    ex = badStringEx;
end
end

function [val,ex] = validateVisibleNV(prop, val)
ex = []; 
if ~strcmpi(prop, "Visible")
    ex = MException(message("MATLAB:graphics:secondarylabel:InvalidPropName",prop));
    return;
end
try
    val = matlab.lang.OnOffSwitchState(val);
catch
    ex = MException(message("MATLAB:graphics:secondarylabel:InvalidVisibleValue"));
end
if ~isscalar(val)
    ex = MException(message("MATLAB:graphics:secondarylabel:InvalidVisibleValue"));
end
end

function doAutoManual(rulers,autoMan)
secLabels = getRulerSecondaryLabels(rulers);
set(secLabels, 'VisibleMode', autoMan);
set(secLabels, 'StringMode', autoMan);
end

function doUpdateSecondaryLabel(rulers,stringVal,visVal)
% If a string argument was provided, we will always turn on the label's
% visibility and set the String value. Note that "" is considered
% non-empty, so users will be able to set the string to "".
secLabels = getRulerSecondaryLabels(rulers);
if ~isempty(stringVal)
    visVal = matlab.lang.OnOffSwitchState("on");
    set(secLabels, 'String', stringVal);
end

if ~isempty(visVal)
    set(secLabels, 'Visible', visVal);
end
end

function secLabels = getRulerSecondaryLabels(rulers)
if iscell(rulers)
    secLabels = get([rulers{:}],'SecondaryLabel');
    secLabels = [secLabels{:}];
else
    secLabels = rulers.SecondaryLabel;
end
end
