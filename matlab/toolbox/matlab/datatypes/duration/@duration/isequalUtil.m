function [argsMillis,template] = isequalUtil(argsMillis)
%

%ISEQUALUTIL Convert durations into millisecond values that can be compared directly with isequal.
%   ARGSMILLIS = ISEQUALUTIL(ARGSMILLIS) converts the durations in cell
%   array ARGSMILLIS into corresponding millisecond values.
%
%   [ARGSMILLIS,TEMPLATE] = ISEQUALUTIL(ARGSMILLIS) returns a TEMPLATE
%   duration, which has the same format property as the first duration
%   object in ARGS.

%   Copyright 2014-2024 The MathWorks, Inc.

import matlab.internal.datatypes.throwInstead

try
    for i = 1:length(argsMillis)
        if isa(argsMillis{i},'duration')
            template = argsMillis{i};
            break;
        end
    end
    for i = 1:length(argsMillis)
        argsMillis{i} = toMillisLocal(argsMillis{i},template);
    end
catch ME
    throwAsCaller(throwInstead(ME, ...
        {'MATLAB:datetime:DurationConversion'}, ...
        message('MATLAB:duration:InvalidComparison',class(argsMillis{i}),'duration')));
end
end


%-----------------------------------------------------------------------
function millis = toMillisLocal(arg,template)
import matlab.internal.datetime.datenumToMillis
if isa(arg,'duration')
    millis = arg.millis;
elseif isa(arg, 'missing')
    millis = double(arg);
elseif isstring(arg) || ischar(arg) || iscellstr(arg)
    % Autoconvert text using the first duration as a template
    millis = duration.compareUtil(arg,template);
else
    % Numeric input treated as a multiple of 24 hours.
    millis = datenumToMillis(arg);
end
end
