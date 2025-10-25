function runningAppFigures = getRunningAppFigures()
%

%   Copyright 2024 The MathWorks, Inc.

    runningAppFigures = findall(groot, 'Type', 'figure', '-property', 'RunningAppInstance', '-depth', 1);
end
