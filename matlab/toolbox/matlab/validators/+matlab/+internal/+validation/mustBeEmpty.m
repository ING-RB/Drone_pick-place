function mustBeEmpty(A)
    %MUSTBEEMPTY Validate empty value
    %   MUSTBEEMPTY(A) Validate A is an empty array.
    %
    %   Copyright 2022 The MathWorks, Inc.
    
        if ~isempty(A)
            throwAsCaller(MException(message('MATLAB:validators:mustBeEmpty')));
        end
    end
    