function mustBeSize(A,S,F)
%MUSTBESIZE Validate that value has the specified size
%   MUSTBESIZE(A,S,F) compares the result of size(A) with row vector S that
%   is a coded size vector where value -1 represents unrestricted dimension
%   length that matches any demension length.
%
%   Copyright 2021-2022 The MathWorks, Inc.

    arguments
        A
        S (1,:) {mustBeInteger}
        F {mustBeMember(F, ["relaxed", "strict"])} = "relaxed"
    end

    valid = matlab.lang.internal.isMatchingSize(size(A), S);

    if ~valid
        throwAsCaller(MException(message('MATLAB:validators:mustBeSize')));
    end

    % In strict mode, validate that the value A also matches specified shapes, which include
    %     row vector [1,-1]
    %     column vector [-1,1]
    %     2d and nd-array with unspecified dimension lengths, that is [-1,...,-1]
    if F == "strict"
        if isequal(S,[1,-1]) || isequal(S, [-1,1])
            if isempty(A) || isscalar(A)
                throwAsCaller(MException(message('MATLAB:validators:mustBeSize')));
            end
        elseif isequal(S,[-1,-1])
            if isempty(A) || size(A,1) == 1 || size(A,2) == 1
                throwAsCaller(MException(message('MATLAB:validators:mustBeSize')));
            end
        else 
            expectedDim = size(S,2);
            if (expectedDim >= 3 && size(find(S==-1),2) == expectedDim)
                if (isempty(A) || size(A, expectedDim) == 1)
                    throwAsCaller(MException(message('MATLAB:validators:mustBeSize')));
                end
            end
        end
    end
end
