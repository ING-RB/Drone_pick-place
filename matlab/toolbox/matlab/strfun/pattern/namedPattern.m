function newPat = namedPattern(pat,name,description)
%

% Copyright 2019-2023 The MathWorks, Inc.

    narginchk(1,3);

    try
        if nargin == 1
            name = inputname(1);
            if isempty(name)
               error(message('MATLAB:pattern:MissingName')); 
            end
        end
        
        if nargin < 3
            newPat = matlab.internal.pattern.namedPattern(pat,name);    
        else
            newPat = matlab.internal.pattern.namedPattern(pat,name,description);
        end
        
    catch e
       throw(e); 
    end
end
