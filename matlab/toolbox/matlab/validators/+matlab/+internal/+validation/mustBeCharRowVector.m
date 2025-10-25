function mustBeCharRowVector(value, propName)
% mustBeCharRowVector is for internal use only and may be removed or
% modified at any time

% mustBeCharRowVector checks if the input data is scalar text - scalar char
% or char row vector or a scalar/empty string. An error is issued if the 
% input is not scalar text.

%   Copyright 2019-2020 The MathWorks, Inc.
    if ~(ischar(value) || (isstring(value) && (isempty(value) || isscalar(value))))
        errorID = 'MATLAB:class:RequireScalarText';
        messageObject = message(errorID, propName);
        E = MException(errorID, messageObject.getString);
        throw(E);
    end
end
