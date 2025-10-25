function out = divisionOutputAdaptor(methodName, numerator, denominator)
%divisionOutputAdaptor calculate output adaptor for LDIVIDE and RDIVIDE

% Copyright 2016-2022 The MathWorks, Inc.

% Now that we support maths on tables we need to deal with those
% recursively.
if istabular(numerator) || istabular(denominator)
    out = determineAdaptorForTabularMath( ...
        @(varargin) divisionOutputAdaptor(methodName, varargin{:}), ...
        methodName, numerator, denominator);
    return
end

% Type combination rules for division are complicated by the presence of
% 'duration'. 
cX = tall.getClass(numerator);
cY = tall.getClass(denominator);

if strcmp(cX, 'duration')
    if strcmp(cY, 'duration')
        cZ = 'double';
    else
        cZ = 'duration';
    end
elseif strcmp(cY, 'duration')
    % non-duration ./ duration is not permitted
    throwAsCaller(MException(message('MATLAB:bigdata:array:DurationAsDenominator')));
else
    cZ = calculateArithmeticOutputType(cX, cY);
end

out = matlab.bigdata.internal.adaptors.getAdaptorForType(cZ);
end
