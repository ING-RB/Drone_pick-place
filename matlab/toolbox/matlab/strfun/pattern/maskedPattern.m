function newPat = maskedPattern(pat,mask)
%

% Copyright 2019-2023 The MathWorks, Inc.

    narginchk(1,2);

    try
        if nargin == 1
            mask = inputname(1);
            if isempty(mask)
                error(message('MATLAB:pattern:MissingMask'));
            end
        end
            
        newPat = matlab.internal.pattern.maskedPattern(pat,mask);
	
    catch e
        throw(e);
    end
end
