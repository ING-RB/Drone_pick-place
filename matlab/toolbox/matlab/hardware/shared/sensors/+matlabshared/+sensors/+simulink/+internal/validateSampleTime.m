function newTime = validateSampleTime(newTime)
% Sample time must be a real scalar value or 2 element array.
%#codegen

%   Copyright 2021 The MathWorks, Inc.

coder.allowpcode('plain');
validateattributes(newTime,{'numeric'},{'nonempty','nonnan'},'','''Sample time''');
isOk = isreal(newTime) && ...
    (all(all(isfinite(newTime))) || all(all(isinf(newTime)))) && ... %need to work all dimensions to scalar logical
    numel(newTime) == 1;

coder.internal.errorIf(~isOk,'matlab_sensors:general:InvalidSampleTimeNeedScalar');
if ~isreal(newTime)
    newTime = real(newTime);
end

coder.internal.errorIf((newTime(1) < 0.0 && newTime(1) ~= -1.0),'matlab_sensors:general:InvalidSampleTimeNeedPositive');

if numel(newTime) == 2
    coder.internal.errorIf((newTime(1) > 0.0 && newTime(2) >= newTime(1)),'matlab_sensors:general:InvalidSampleTimeNeedSmallerOffset');
    coder.internal.errorIf((newTime(1) == -1.0 && newTime(2) ~= 0.0),'matlab_sensors:general:InvalidSampleTimeNeedZeroOffset');
    coder.internal.errorIf((newTime(1) == 0.0 && newTime(2) ~= 1.0),'matlab_sensors:general:InvalidSampleTimeNeedOffsetOne');
end

end