function E = createValidatorExceptionWithValue(V, ID1, ID2)
% createValidatorExceptionWithValue creates different validator exceptions depending on the input value V.
    
%   Copyright 2020-2024 The MathWorks, Inc.

    if isempty(V)
        E = matlab.internal.validation.util.createValidatorException(ID1);
    else
        E = matlab.internal.validation.util.createValidatorException(ID2, V);
    end
end
