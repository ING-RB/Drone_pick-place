function [millis,template,validComparison] = isequalUtil(argsMillis) %#codegen
%ISEQUALUTIL Convert durations into millisecond values that can be compared directly with isequal.
%   MILLIS = ISEQUALUTIL(ARGSMILLIS) converts the durations in cell array
%   ARGSMILLIS into corresponding millisecond values.
%
%   [MILLIS,TEMPLATE] = ISEQUALUTIL(ARGSMILLIS) returns a TEMPLATE
%   duration, which has the same format as the first duration object in
%   ARGS.
%
%   [MILLIS,TEMPLATE,VALIDCOMPARISON] = ISEQUALUTIL(ARGSMILLIS) returns a
%   flag VALIDCOMPARISON indicating whether or not isequal on the durations
%   in ARGSMILLIS is a valid comparison.

%   Copyright 2014-2020 The MathWorks, Inc.
template = duration(matlab.internal.coder.datatypes.uninitialized);
coder.unroll()
for i = 1:length(argsMillis)
    if isa(argsMillis{i},'duration')
        template.fmt = argsMillis{i}.fmt;
        break;
    end
end

millis = cell(size(argsMillis));
validComparison = true;
coder.unroll()
for i = 1:length(argsMillis)
    [millis{i},validComparison_i] = toMillisLocal(argsMillis{i},template);
    validComparison = validComparison && validComparison_i;
end
end

function [millis,validComparison] = toMillisLocal(arg,template)
if isa(arg,'duration')
    millis = arg.millis;
    validComparison = true;
elseif isa(arg, 'missing')
    millis = double(arg);
    validComparison = true;
elseif isstring(arg) || ischar(arg) || iscellstr(arg)
    % Autoconvert text using the first duration as a template
    millis = matlab.internal.coder.duration.compareUtil(arg,template);
    validComparison = true;
else
    % Numeric input treated as a multiple of 24 hours.
    [millis, validComparison] = matlab.internal.coder.timefun.datenumToMillis(arg);
end
end
