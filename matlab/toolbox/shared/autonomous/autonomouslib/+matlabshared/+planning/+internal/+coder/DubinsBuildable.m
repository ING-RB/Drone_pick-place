classdef DubinsBuildable < matlabshared.planning.internal.coder.AutonomousBuildable
    %This class is for internal use only. It may be removed in the future.
    
    %DubinsBuildable Class implementing the Dubins methods that are compatible with code generation
    
    % Copyright 2018-2021 The MathWorks, Inc.
    
    %#codegen
    
    %% Static methods supporting code generation for autonomousDubins* builtins
    methods (Static)
        function [cost, motionLengths, motionTypes] = ...
                autonomousDubinsSegments(startPose, goalPose, turningRadius, pathSegments, disabledTypes)
            %autonomousDubinsSegments Codegen-compatible version of autonomousDubinsSegments builtin
            
            coder.inline('always');
            
            % TBB is only used during MEX on host platform
            tbbPart = matlabshared.planning.internal.coder.DubinsBuildable.tbbAPIPart;
            coder.cinclude(['autonomouscodegen_dubins' tbbPart '_api.hpp']);
            
            dubinsPathTypeStrings = matlabshared.planning.internal.DubinsConnection.AllPathTypes;
            dubinsTotalNumPaths = numel(dubinsPathTypeStrings);
            
            [numStartPoses, numGoalPoses, maxNumPoses] = ...
                matlabshared.planning.internal.coder.DubinsBuildable.numPoses(startPose, goalPose);
            
            % Extract the disabled path types
            allPathTypes = true(1,dubinsTotalNumPaths);
            numDisabledPathTypes = 0;
            for i = 1:length(disabledTypes)
                % Use an explicit strcmp here, since ismember is not
                % supported with cell arrays in code generation.
                match = strcmp(disabledTypes{i}, dubinsPathTypeStrings);
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
                numPaths = dubinsTotalNumPaths;
            end
            
            % Preallocate outputs. Do not initialize memory in codegen,
            % since the C function will assign all elements.
            cost = coder.nullcopy(zeros(numPaths,maxNumPoses));
            motionLengths = coder.nullcopy(zeros(3,numPaths,maxNumPoses));
            motionTypes = coder.nullcopy(zeros(3,numPaths,maxNumPoses));
            
            % Call the C API
            coder.ceval(['autonomousDubinsSegmentsCodegen' tbbPart '_real64'],...
                coder.rref(startPose),    ...
                uint32(numStartPoses), ...
                coder.rref(goalPose),    ...
                uint32(numGoalPoses), ...
                turningRadius,  ...
                coder.rref(allPathTypes), ...
                isOptimal, ...
                uint32(nargout), ...
                coder.ref(cost), ...
                coder.ref(motionLengths), ...
                coder.ref(motionTypes));
        end
        
        function dist = autonomousDubinsDistance(startPose, goalPose, turningRadius)
            %autonomousDubinsDistance Codegen-compatible version of autonomousDubinsDistance builtin
            
            coder.inline('always');
            
            % TBB is only used during MEX on host platform
            tbbPart = matlabshared.planning.internal.coder.DubinsBuildable.tbbAPIPart;
            coder.cinclude(['autonomouscodegen_dubins' tbbPart '_api.hpp']);
            
            [numStartPoses, numGoalPoses, maxNumPoses] = ...
                matlabshared.planning.internal.coder.DubinsBuildable.numPoses(startPose, goalPose);
            
            % Preallocate outputs. Do not initialize memory in codegen,
            % since the C function will assign all elements.
            dist = coder.nullcopy(zeros(maxNumPoses,1));
            
            % Call the C API
            coder.ceval(['autonomousDubinsDistanceCodegen' tbbPart '_real64'],...
                coder.rref(startPose), ...
                uint32(numStartPoses), ...
                coder.rref(goalPose), ...
                uint32(numGoalPoses), ...
                turningRadius, ...
                coder.ref(dist));
        end
        
        function poses = autonomousDubinsInterpolate(startPose, goalPose, ...
                maxDistance, numSteps, turningRadius)
            %autonomousDubinsInterpolate Codegen-compatible version of
            %   autonomousDubinsInterpolate builtin for 5 number of inputs
            
            coder.inline('always');
            coder.cinclude('autonomouscodegen_dubins_api.hpp');
            
            % Preallocate outputs. Do not initialize memory in codegen,
            % since the C function will assign all elements.
            poses = coder.nullcopy(zeros(numSteps + 2, 3));
            % Call the C API
            coder.ceval('autonomousDubinsInterpolateCodegen_real64',...
                coder.rref(startPose), ...
                coder.rref(goalPose), ...
                maxDistance, ...
                uint32(numSteps), ...
                turningRadius, ...
                coder.ref(poses));
        end
        
        function poses = autonomousDubinsInterpolateSegments(startPose, goalPose, samples, ...
                turningRadius, segLengths, segTypes)
            %autonomousDubinsInterpolateSegments Codegen-compatible version
            %   of autonomousDubinsInterpolateSegments builtin for 6 number of
            %   inputs.
            
            coder.inline('always');
            coder.cinclude('autonomouscodegen_dubins_api.hpp');
            
            
            % Preallocate outputs. Do not initialize memory in codegen,
            % since the C function will assign all elements.
            poses = coder.nullcopy(zeros(numel(samples), 3));
            
            % Call the C API
            coder.ceval('autonomousDubinsInterpolateSegmentsCodegen_real64',...
                coder.rref(startPose), ...
                coder.rref(goalPose), ...
                coder.rref(samples), ...
                uint32(numel(samples)), ...
                turningRadius, ...
                coder.rref(segLengths), ...
                coder.rref(segTypes), ...
                coder.ref(poses));
        end
    end
    
    %% Static method overloads of coder.ExternalDependency
    methods (Static)
        
        function name = getDescriptiveName(~)
            %getDescriptiveName Get name for external dependency
            
            name = 'DubinsBuildable';
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
                    'shared','autonomous','builtins','libsrc','autonomouscodegen','dubins')});
                buildInfo.addSourceFiles('autonomouscodegen_dubins.cpp');
            end
            
        end
    end
end
