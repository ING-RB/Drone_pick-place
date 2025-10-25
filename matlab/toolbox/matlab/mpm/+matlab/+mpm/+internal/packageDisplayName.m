function displayName = packageDisplayName(pkg)
%

%   Copyright 2024 The MathWorks, Inc.

if strcmp(pkg.DisplayName, "") || strcmp(pkg.DisplayName, pkg.Name)
    displayName = pkg.Name;
else
    displayName = pkg.DisplayName + " "+ "(" + pkg.Name + ")";
end
end
