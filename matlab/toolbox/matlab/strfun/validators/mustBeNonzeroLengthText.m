function mustBeNonzeroLengthText(text)
%
    
% Copyright 2020-2023 The MathWorks, Inc.

    if ~istext(text) 
        throwAsCaller(MException("MATLAB:validators:mustBeNonzeroLengthText", message("MATLAB:validators:mustBeText")));
    elseif ~all(strlength(text)>0,'all')
        throwAsCaller(MException("MATLAB:validators:mustBeNonzeroLengthText", message("MATLAB:validators:nonzeroLengthText")));
    end
end
