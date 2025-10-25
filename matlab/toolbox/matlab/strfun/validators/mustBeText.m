function mustBeText(text)
%
    
% Copyright 2020-2023 The MathWorks, Inc.

    if ~istext(text)
        throwAsCaller(MException(message("MATLAB:validators:mustBeText")))
    end

end
