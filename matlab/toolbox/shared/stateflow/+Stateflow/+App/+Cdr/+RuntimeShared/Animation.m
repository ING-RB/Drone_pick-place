classdef Animation < handle
%

%   Copyright 2018-2019 The MathWorks, Inc.

    methods

        function obj = Animation(~, ~, ~, ~)

        end

        function ex = runtimeException(~, ME)
            % Only second argument is actually used, we want to throw
            % version mismatch error when users try to run sfx models saved
            % in 19b or earlier releases
            assert(isequal(ME.identifier, 'MATLAB:sfx:VersionMismatch'), getString(message('MATLAB:sfx:VersionMismatch',Stateflow.App.Utils.escapeBackslash(ME.stack(1).file))));
            ex = ME;
        end
    end
    methods (Static)
        function obj = getAnimationObj(fileName,machineName, chartFileNumber, chartPath)
            obj = Stateflow.App.Cdr.RuntimeShared.Animation(fileName,machineName, chartFileNumber, chartPath);
        end

    end
end

% LocalWords:  runtimeexception navdeep
