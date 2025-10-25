function throwTempStorageError(underlyingError)
%throwTempStorageError Throw customer-visible error describing a failure
% while using the temporary folder to store intermediate data.

%   Copyright 2018 The MathWorks, Inc.

if isa(underlyingError, 'matlab.bigdata.BigDataException')
    rethrow(underlyingError);
end
err = MException(message("MATLAB:bigdata:executor:TempStorageError"));
err = addCause(err, underlyingError);
matlab.bigdata.internal.throw(err);
end
