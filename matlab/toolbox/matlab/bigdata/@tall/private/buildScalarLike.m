function y = buildScalarLike(fcn, supportedTypes, prototype)
%BUILDSCALARLIKE common code for building a tall scalar with attributes
%matching a prototype.

%   Copyright 2021 The MathWorks, Inc.

% Check type is supported
fcnName = func2str(fcn);
prototype = tall.validateTypeWithError(prototype, fcnName, 2, ...
    supportedTypes, "MATLAB:"+fcnName+":invalidPrototype");
% Build the value (has to be deferred since we typically can't detect
% complexity until all values are known).
y = clientfun(@(x) fcn("like",x), prototype);
% The result is a scalar with all attributes matching the prototype.
y.Adaptor = setKnownSize(resetSizeInformation(prototype.Adaptor), [1 1]);
end
