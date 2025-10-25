function appendBracesIndexOperation(except, indexArgument)
%APPENDBRACESINDEXOPERATION If except is an ArrowException, an IndexOperation
%whose Type property is set to Braces is appended to the IndexOperations
%vector on the ArrowException object.

% Copyright 2022 The MathWorks, Inc.
    arguments
        except
    end
    arguments(Repeating)
        indexArgument
    end

    if isa(except, "matlab.io.internal.arrow.error.ArrowException")
        except = appendBracesIndexOperation(except, indexArgument{:});
    end
    throw(except);
end
