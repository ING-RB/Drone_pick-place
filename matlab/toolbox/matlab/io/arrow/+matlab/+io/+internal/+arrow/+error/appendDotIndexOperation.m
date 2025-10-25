function appendDotIndexOperation(except, variableName)
%APPENDDOTINDEXOPERATION If except is an ArrowException, an IndexOperation
%whose Type property is set to Dot is appended to the IndexOperations
%vector on the ArrowException object.

% Copyright 2022 The MathWorks, Inc.

    if isa(except, "matlab.io.internal.arrow.error.ArrowException")
        except = appendDotIndexOperation(except, variableName);
    end
    throw(except);
end
