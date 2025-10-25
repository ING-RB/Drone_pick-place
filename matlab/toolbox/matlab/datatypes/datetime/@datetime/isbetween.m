function tf = isbetween(a,lowerLim,upperLim,intervalType,varargin)
%

%   Copyright 2014-2024 The MathWorks, Inc.

import matlab.internal.datatypes.getChoice
import matlab.internal.datatypes.parseArgs
import matlab.internal.datatypes.isScalarText

[aData,lData,uData] = isbetweenUtil(a,lowerLim,upperLim);

allowedIntervalTypes = ["closed" "open" "openright" "closedleft" "openleft" "closedright"];
defaultIntervalType = 1; % "closed"

if nargin < 4
    intervalType = defaultIntervalType;
else
    args = varargin;
    try
        % Check if the 4th input is an interval type.
        intervalType = getChoice(intervalType,allowedIntervalTypes, ...
            [1 2 3 3 4 4],[1 1 0 0 0 0],'MATLAB:datetime:isbetween:InvalidIntervalType');
    catch ME
        % If there were only 4 inputs then we got an invalid interval type,
        % so throw the error we got from getChoice. Otherwise treat the 4th
        % input as part of the name-value args.
        if nargin == 4
            throw(ME);
        else
            args = [{intervalType} args];
            intervalType = defaultIntervalType;
        end
    end
    
    % Parse name-value args if present.
    if ~isempty(args)
        pnames = {'OutputFormat'};
        dflts =  {'logical'     };
        outputFormat = parseArgs(pnames, dflts, args{:});
        % logical is the only allowed OutputFormat.
        validatestring(outputFormat,{'logical'},'isbetween','OutputFormat');
    end
end


try
    switch lower(intervalType)
    case 1 % "closed"
        tf = (relopSign(lData,aData) <= 0) & (relopSign(aData,uData) <= 0);
    case 2 % "open"
        tf = (relopSign(lData,aData) < 0) & (relopSign(aData,uData) < 0);
    case 3 % {"openright" "closedleft"}
        tf = (relopSign(lData,aData) <= 0) & (relopSign(aData,uData) < 0);
    case 4 % {"openleft" "closedright"}
        tf = (relopSign(lData,aData) < 0) & (relopSign(aData,uData) <= 0);
    end
catch ME
    matlab.internal.datatypes.throwInstead(ME,{'MATLAB:datetime:InputSizeMismatch' 'MATLAB:dimagree' 'MATLAB:sizeDimensionsMustMatch'}, ...
                                               'MATLAB:datetime:isbetween:InputSizeMismatch');
end


%-----------------------------------------------------------------------
function [aData,lData,uData] = isbetweenUtil(a,lower,upper)
% A single (valid) date string is accepted as a scalar datetime for any of the
% inputs. If the conversion fails, drop through to the catch-all error below.

import matlab.internal.datatypes.isScalarText
import matlab.internal.datatypes.isCharStrings

try
    % Require text inputs to be scalars, except allow cellstr for backwards compatibility.
    if isScalarText(a) || isCharStrings(a)
        % Either lower or upper must be a datetime
        if isa(lower,'datetime'), template = lower; else, template = upper; end
        a = autoConvertStrings(a,template);
    end
    if isScalarText(lower) || isCharStrings(lower)
        % Either a or upper must be a datetime
        if isa(upper,'datetime'), template = upper; else, template = a; end
        lower = autoConvertStrings(lower,template);
    end
    if isScalarText(upper) || isCharStrings(upper)
        % Either a or lower must be a datetime
        if isa(lower,'datetime'), template = lower; else, template = a; end
        upper = autoConvertStrings(upper,template);
    end
catch ME
    throwAsCaller(ME);
end

if ~isa(a,'datetime') || ~isa(lower,'datetime') || ~isa(upper,'datetime')
    error(message('MATLAB:datetime:isbetween:InvalidInput'));
end

% No size check needed; the logical expression in the main code will scalar/implicit
% expand and create the correct common size, or error.

checkCompatibleTZ(a.tz,lower.tz); checkCompatibleTZ(a.tz,upper.tz);

aData = a.data;
lData = lower.data;
uData = upper.data;
