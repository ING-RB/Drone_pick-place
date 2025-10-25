function [nameShadowed, precedenceShadowed] = isAppNameShadowed(fullFileName)
    % ISAPPNAMESHADOWED Check if the app's name is shadowed by the MATLAB current
    % working directory.
    % Uses mdbfileonpath to determine shadow status
    % g1532266, g3380421

    % Copyright 2016 - 2024 The MathWorks, Inc.
    
    [~, shadowStatus] = mdbfileonpath(fullFileName);
    
    nameShadowed = shadowStatus == FilePathState.FILE_SHADOWED_BY_PWD;

    precedenceShadowed = shadowStatus ~= FilePathState.FILE_WILL_RUN;
end