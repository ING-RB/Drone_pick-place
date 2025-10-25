classdef ReedsSheppBuildable < matlabshared.planning.internal.coder.AutonomousBuildable
%This class is for internal use only. It may be removed in the future.

%ReedsSheppBuildable Class implementing the ReedsShepp methods that are compatible with code generation

% Copyright 2018-2021 The MathWorks, Inc.

%#codegen


%% Static methods supporting code generation for autonomousReedsShepp* builtins
    methods (Static)

        function [cost, motionLengths, motionTypes] = ...
                autonomousReedsSheppSegments(startPose, goalPose, turningRadius, ...
                                             forwardCost, reverseCost, pathSegments, disabledTypes)
            %autonomousReedsSheppSegments Codegen-compatible version of autonomousReedsSheppSegments builtin

            coder.inline('always');

            % TBB is only used during MEX on host platform
            tbbPart = matlabshared.planning.internal.coder.ReedsSheppBuildable.tbbAPIPart;
            coder.cinclude(['autonomouscodegen_reeds_shepp' tbbPart '_api.hpp']);

            reeds_sheppPathTypeStrings = matlabshared.planning.internal.ReedsSheppConnection.AllPathTypes;
            reeds_sheppTotalNumPaths = numel(reeds_sheppPathTypeStrings);

            [numStartPoses, numGoalPoses, maxNumPoses] = ...
                matlabshared.planning.internal.coder.ReedsSheppBuildable.numPoses(startPose, goalPose);

            % Extract the disabled path types
            allPathTypes = true(1,reeds_sheppTotalNumPaths);
            numDisabledPathTypes = 0;
            for i = 1:length(disabledTypes)
                % Use an explicit strcmp here, since ismember is not
                % supported with cell arrays in code generation.
                match = strcmp(disabledTypes{i}, reeds_sheppPathTypeStrings);
                if any(match)
                    numDisabledPathTypes = numDisabledPathTypes + 1;
                    allPathTypes(match) = false;
                end
            end

            % Set the total number of expected output paths
            numPaths = 1;
            isOptimal = true;
            if strcmp(pathSegments, 'all')
                isOptimal = false;
                numPaths = reeds_sheppTotalNumPaths - numDisabledPathTypes;
            end

            % Preallocate outputs. Do not initialize memory in codegen,
            % since the C function will assign all elements.
            cost = coder.nullcopy(zeros(numPaths,maxNumPoses));
            motionLengths = coder.nullcopy(zeros(5,numPaths,maxNumPoses));
            motionTypes = coder.nullcopy(zeros(5,numPaths,maxNumPoses));

            % Call the C API
            coder.ceval(['autonomousReedsSheppSegmentsCodegen' tbbPart '_real64'],...
                        coder.rref(startPose),    ...
                        uint32(numStartPoses), ...
                        coder.rref(goalPose),    ...
                        uint32(numGoalPoses), ...
                        turningRadius,  ...
                        forwardCost, ...
                        reverseCost, ...
                        coder.rref(allPathTypes), ...
                        uint32(numDisabledPathTypes), ...
                        uint32(numPaths), ...
                        isOptimal, ...
                        uint32(nargout), ...
                        coder.ref(cost), ...
                        coder.ref(motionLengths), ...
                        coder.ref(motionTypes));
        end

        function dist = autonomousReedsSheppDistance(startPose, goalPose, turningRadius, reverseCost)
        %autonomousReedsSheppDistance Codegen-compatible version of autonomousReedsSheppDistance builtin

            coder.inline('always');

            % TBB is only used during MEX on host platform
            tbbPart = matlabshared.planning.internal.coder.ReedsSheppBuildable.tbbAPIPart;
            coder.cinclude(['autonomouscodegen_reeds_shepp' tbbPart '_api.hpp']);

            [numStartPoses, numGoalPoses, maxNumPoses] = ...
                matlabshared.planning.internal.coder.ReedsSheppBuildable.numPoses(startPose, goalPose);

            % Preallocate outputs. Do not initialize memory in codegen,
            % since the C function will assign all elements.
            dist = coder.nullcopy(zeros(maxNumPoses,1));

            % Call the C API
            coder.ceval(['autonomousReedsSheppDistanceCodegen' tbbPart '_real64'],...
                        coder.rref(startPose), ...
                        uint32(numStartPoses), ...
                        coder.rref(goalPose), ...
                        uint32(numGoalPoses), ...
                        turningRadius, ...
                        reverseCost, ...
                        coder.ref(dist));
        end

        function poses = autonomousReedsSheppInterpolate(startPose, goalPose, ...
                                                         connectionDistance, numSteps, turningRadius, reverseCost)
            %autonomousReedsSheppInterpolate Codegen-compatible version of autonomousReedsSheppInterpolate builtin

            coder.inline('always');
            coder.cinclude('autonomouscodegen_reeds_shepp_api.hpp');

            % Preallocate output (4 transition poses included)
            % Do not initialize memory in codegen,
            % since the C function will assign all elements.
            poses = coder.nullcopy(zeros(numSteps + 4, 3));

            % Call the C API
            coder.ceval('autonomousReedsSheppInterpolateCodegen_real64',...
                        coder.rref(startPose), ...
                        coder.rref(goalPose), ...
                        connectionDistance, ...
                        uint32(numSteps), ...
                        turningRadius, ...
                        reverseCost, ...
                        coder.ref(poses));
        end
        
        function [poses, directions] = autonomousReedsSheppInterpolateSegments(startPose, goalPose, samples, ...
                turningRadius, segLengths, segDirections, segTypes)
            %autonomousReedsSheppInterpolateSegments Codegen-compatible version
            %   of autonomousReedsSheppInterpolateSegments builtin for 7 number of
            %   inputs.
            
            coder.inline('always');
            coder.cinclude('autonomouscodegen_reeds_shepp_api.hpp');
            
            
            % Preallocate outputs. Do not initialize memory in codegen,
            % since the C function will assign all elements.
            poses = coder.nullcopy(zeros(numel(samples), 3));
            directions = coder.nullcopy(zeros(numel(samples), 1));
            
            % Call the C API
            coder.ceval('autonomousReedsSheppInterpolateSegmentsCodegen_real64',...
                coder.rref(startPose), ...
                coder.rref(goalPose), ...
                coder.rref(samples), ...
                uint32(numel(samples)), ...
                turningRadius, ...
                coder.rref(segLengths), ...
                coder.rref(segDirections),...
                coder.rref(segTypes), ...
                coder.ref(poses), ...
                coder.ref(directions));
        end
    end

    %% Static method overloads of coder.ExternalDependency
    methods (Static)

        function name = getDescriptiveName(~)
        %getDescriptiveName Get name for external dependency

            name = 'ReedsSheppBuildable';
        end

        function updateBuildInfo(buildInfo, buildConfig)
        %updateBuildInfo Add headers, libraries, and sources to the build info

            matlabshared.planning.internal.coder.AutonomousBuildable.addCommonHeaders(buildInfo);

            % Assign build info
            % Special treatment if it's MEX on host platform
            if buildConfig.isCodeGenTarget('mex')
                % Use host-specific libraries
                matlabshared.planning.internal.coder.AutonomousBuildable.updateBuildInfoForHostCodegen(buildInfo, buildConfig);
            else
                % Use full sources
                buildInfo.addSourcePaths({fullfile(matlabroot,'toolbox', ...
                                                   'shared','autonomous','builtins','libsrc','autonomouscodegen','reeds_shepp')});
                buildInfo.addSourceFiles('autonomouscodegen_reeds_shepp.cpp');
            end
        end
    end
end
