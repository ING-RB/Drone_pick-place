function isOlder = isMATLABReleaseOlderThan(release, stage, update)
%isMATLABReleaseOlderThan returns true if the current MATLAB release is
%older than specified MATLAB release.
%
%   tf = isMATLABReleaseOlderThan( release )
%   tf = isMATLABReleaseOlderThan( release, stage )
%   tf = isMATLABReleaseOlderThan( release, stage, update )
%
%   where
%     release - Release name
%     stage   - Stage, either prerelease or release
%     update  - Update number
%
%  Examples:
%
%       if isMATLABReleaseOlderThan("R2020b")
%           error("MATLAB releases older than R2020b release are not supported.");
%       end
%
%       if isMATLABReleaseOlderThan("R2020b", "release", 2)
%           error("MATLAB releases older than R2020b release update 2 are not supported.");
%       end
%
%   See also matlabRelease.

% Copyright 2019-2020 The MathWorks, Inc.

    arguments
       % Intentionally omit data type to avoid type casting
        release {mustBeTextScalar, mustBeValidRelease}
        stage   {mustBeTextScalar} = "prerelease";
        update  (1,1) {mustBeInteger, mustBeNonnegative} = 0
    end

    % Custom permissive validation for stage.
    stage = validatestring(stage, ["prerelease", "release"]);

    % After validation for newer releases:
    %   First character is R (and might be lower case).
    %   Last character is a or b (and might be upper case).
    % After validation for older releases (i.e. R14, R14SP2):
    %   A suffix of SP might be present (and might be lower case).
    release = lower(release);

    currentMATLAB = matlabRelease;
    lowerCurrentMATLABRelease = lower(currentMATLAB.Release);

    if release == lowerCurrentMATLABRelease
       if stage == currentMATLAB.Stage
           isOlder =  update > currentMATLAB.Update;
       else
           isOlder =  stage > currentMATLAB.Stage;
       end
    else
       isOlder =  release > lowerCurrentMATLABRelease;
    end
end

% Custom validation function validates the release name.
function mustBeValidRelease(releaseString)
    % Valid releases include R10 (version 5.2) 1998 and later.
    % Look for patterns like R10, R14SP1, R2006a, R2020a, r2020A, or R2100g
    % Disallow leading and trailing white spaces.
    if ~isempty(regexp(releaseString,'^[Rr][0-9]{4}[A-Za-z]([Ss][Pp]\d)?$', 'once')) ...
        || ~isempty(regexp(releaseString,'^[Rr]1[0-4](\.\d|[Ss][Pp]\d)?$', 'once'))
            return;
    end
    error(message('MATLAB:isMATLABReleaseOlderThan:invalidReleaseInput'))
end

