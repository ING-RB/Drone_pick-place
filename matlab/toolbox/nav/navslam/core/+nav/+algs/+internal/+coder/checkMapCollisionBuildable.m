classdef checkMapCollisionBuildable < coder.ExternalDependency
%This class is for internal use only. It may be removed in the future.

%checkMapCollisionBuildable Buildable class for map/mesh collision code generation
%
%   See also nav.algs.internal.checkMapCollisionBuiltins.

% Copyright 2022-2024 The MathWorks, Inc.

%#codegen

%% Methods inherited from coder.ExternalDependency
    methods (Static)
        function name = getDescriptiveName(~)
        %getDescriptiveName Get name for external dependency
            name = 'checkMapCollisionBuildable';
        end

        function updateBuildInfo(buildInfo, buildConfig) %#ok<INUSD>
        %updateBuildInfo Add headers, libraries, and sources to the build info

        % Always use full sources for code generation
            buildInfo.addSourcePaths({fullfile(matlabroot,'toolbox', ...
                                               'nav','navslam','builtins','libsrc','collisionmapcodegen','collisionmap')});
            buildInfo.addSourceFiles('checkmapcollision_api.cpp');
            buildInfo.addSourceFiles('checkMapCollision.cpp');
            buildInfo.addSourceFiles('CollisionMap.cpp');
        end

        function isSupported = isSupportedContext(~)
        %isSupportedContext Determine if external dependency supports this build context

        % Code generation is supported for both host and target
        % (portable) code generation.
            isSupported = true;

        end
    end

    methods (Static, Access = protected)
        function addCommonHeaders(buildInfo)
        %addCommonHeaders Add include path for codegen APIs.

            includePath = fullfile(matlabroot, 'extern', 'include', 'nav');
            buildInfo.addIncludePaths(includePath, 'Navigation Toolbox Includes');
        end
    end

    methods (Static)
        function varargout = intersect(mapPtr,geomPtr,pos,quat,returnDistance, ...
                                       exhaustive,checkNarrowPhase, checkBroadPhase, returnVoxels, ...
                                       searchDepth)
        %intersect_codegen Codegen path for the map/mesh intersect routine
            coder.cinclude('checkmapcollision_api.hpp');

            % Create dynamicVoxel matrix for potentially varsize outputs
            ctrWrapper  = shared.robotics.internal.coder.dynamicMatrixBuildable([inf 3]); % Voxel center(s)
            sizeWrapper = shared.robotics.internal.coder.dynamicMatrixBuildable([inf 1]); % Voxel size(s)

            % Allocate geom AABB info
            bboxCtr = zeros(1,3);
            bMin    = zeros(1,3);
            bMax    = zeros(1,3);

            % Create distance/witness-point outputs
            dist = nan;
            p1 = nan(3,1);
            p2 = nan(3,1);

            % Execute collision check
            isColliding = false;
            isColliding = coder.ceval('checkmapcollisioncodegen_checkCollision',mapPtr.Octomap,geomPtr, ...
                                      coder.ref(pos),...
                                      coder.ref(quat),...
                                      coder.ref(dist),...
                                      logical(exhaustive), ...
                                      logical(checkNarrowPhase), ...
                                      logical(checkBroadPhase), ...
                                      uint32(searchDepth), ...
                                      coder.ref(p1), ...
                                      coder.ref(p2), ...
                                      coder.ref(ctrWrapper.Ptr), ...
                                      coder.ref(sizeWrapper.Ptr), ...
                                      bboxCtr, ...
                                      bMin, ...
                                      bMax);

            [varargout{1:2}] = deal(isColliding, [bboxCtr;bMin;bMax]);

            % Convert results to details struct
            if returnDistance
                [varargout{3:4}] = deal(dist,[p1 p2]); %#ok<*CCAT>
            end
            if returnVoxels
                % Retrieve collision-voxel info from opaque C++ pointers
                [varargout{nargout-1:nargout}] = deal(ctrWrapper.getData(),sizeWrapper.getData());
            end
        end
    end

    methods (Static)
        function details = createDetailsStruct(isColliding, returnDistance, returnVoxels, varargin)
        %createDetailsStruct Populate the details structure
        %   Constructs and populates the DETAILS structure, which may contain
        %   additional collision-checking results requested in the OPTIONS input.
        %
        %   See occupancyMap3DCollisionOptions for description of all available options

        % Create output structure
            details = struct();

            % Second output contains Distance and Colliding Voxel info
            if returnDistance
                details.DistanceInfo = struct('Distance',varargin{3},'WitnessPoints',varargin{4});
            end
            if returnVoxels
                details.VoxelInfo = struct('Location',varargin{end-1},'Size',varargin{end});
            end

            if any(isColliding) && returnDistance
                details.DistanceInfo.Distance(:)      = nan;
                details.DistanceInfo.WitnessPoints(:) = nan;
            end
        end
    end
end
