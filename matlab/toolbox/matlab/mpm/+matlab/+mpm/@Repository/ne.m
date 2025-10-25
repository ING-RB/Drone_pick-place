% Compares two matlab.mpm.Repository scalar objects for not equality.
%
%   Two Repository objects are equal if either they both have same Location.

% Copyright 2024 The MathWorks, Inc.

function isNe = ne(repo,otherRepo)
    isNe = ~eq(repo,otherRepo);
end



