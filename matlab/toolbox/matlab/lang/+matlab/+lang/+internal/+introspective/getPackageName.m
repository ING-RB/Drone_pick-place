function packageName = getPackageName(packagePath)
    packageList = regexp(packagePath, '((^|[\\/])[@+]\w+)+(?=([\\/](\w+(\.\w+)?>\w+|\w+(\.\w+)?))?$)', 'match', 'once');
    packageList = regexp(packageList, '\w+', 'match');
    packageName = strjoin(packageList, '.');
end

%   Copyright 2007-2023 The MathWorks, Inc.
