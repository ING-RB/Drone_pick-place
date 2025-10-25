% Comapres two matlab.mpm.Package scalar objects for not equality.
%
%   Two Package objects are equal if either they both have same PackageRoot
%   or if PackageRoot is missing, they both have same ID and Version and 
%   comes from same Repository.

% Copyright 2024 The MathWorks, Inc.

function isNe = ne(pkg, otherPkg)
    isNe = ~eq(pkg, otherPkg);
end



