classdef (Sealed) matlabRelease
%matlabRelease returns the current MATLAB release information.
%
%   matlabRelease displays the MATLAB release information.
%   R = matlabRelease returns a class with the MATLAB release information.
%
%   Properties:
%     Release - Release name
%     Stage   - Stage, either prerelease or release.
%     Update  - Update number
%     Date    - Date of the release
%
%   See also isMATLABReleaseOlderThan

%   Copyright 2019-2023 The MathWorks, Inc.

    properties (SetAccess = private)
        Release
        Stage
        Update
        Date
    end
    methods
        function obj = matlabRelease
            persistent matlabReleaseRelease;
            persistent matlabReleaseStage;
            persistent matlabReleaseUpdate;
            persistent matlabReleaseDate;
            if isempty(matlabReleaseRelease)
                matlabReleaseRelease = matlab.internal.matlabRelease.release;
                matlabReleaseStage   = matlab.internal.matlabRelease.stage;
                matlabReleaseUpdate  = matlab.internal.matlabRelease.update;
                matlabReleaseDate    = datetime(matlab.internal.matlabRelease.date,'InputFormat','yyyy-MM-dd');
            end
            obj.Release = matlabReleaseRelease;
            obj.Stage   = matlabReleaseStage;
            obj.Update  = matlabReleaseUpdate;
            obj.Date    = matlabReleaseDate;
        end
    end
end
