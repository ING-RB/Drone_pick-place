function validatePkgName(pkgName)
% Validate interface name

%   Copyright 2024 The MathWorks, Inc.

% Check if the package name type is correct
try
    validateattributes(pkgName,{'char','string'},{'scalartext'});
catch
     error(message('MATLAB:CPP:InvalidPackageName'));
end
% Check if package name is a valid MATLAB name
if ~isvarname(pkgName)
    error(message('MATLAB:CPP:InvalidPackageName'));
end

end

