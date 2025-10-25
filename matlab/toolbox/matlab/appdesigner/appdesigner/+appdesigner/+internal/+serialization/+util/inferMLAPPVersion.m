function mlappVersion = inferMLAPPVersion(matFileName)
    % INFERMLAPPVERSION extract MLAPP version from MAT file
    % try to load MLAPP MAT file code field only in order to check version
    % note: this is quickest way to check MAT file belongs to version 1 or version 2
    %    because loading whole MAT file is expensive when loading all components
    % return version 1 if code field is not availble,
    %   V1 structs have only the 'appData' field and do not have code field
    % return version 2 if code field is availble,
    %   V2 structs have the 'appData', 'code', and 'components'
    %
    % Copyright 2021 The MathWorks, Inc.

    import appdesigner.internal.serialization.app.AppVersion;

    % Disable warning during load code fild
    % Supress warning for load('appModel.mat', 'code') when reading Version 1 MLAPP file 
    previousWarning = warning('off', 'MATLAB:load:variableNotFound');
    [lastWarnStr, lastWarnId] = lastwarn();

    loadObj = load(matFileName,'code');
    if isempty(fieldnames(loadObj))
        mlappVersion = AppVersion.MLAPPVersionOne;
    else
        mlappVersion = AppVersion.MLAPPVersionTwo;
    end

    warning(previousWarning);
    lastwarn(lastWarnStr, lastWarnId);
end

