classdef meshtsdfBuildable < coder.ExternalDependency & nav.algs.internal.InternalAccess
%This class is for internal use only. It may be removed in the future.

%meshtsdfBuildable Buildable class for meshtsdf code generation
%
%   See also meshtsdf

% Copyright 2023-2024 The MathWorks, Inc.

%#codegen
    properties (Access = ?nav.algs.internal.InternalAccess)
        %TSDF
        TSDF
    end
    properties (Dependent, SetAccess = protected)
        %Resolution Grid resolution in cells per meter
        Resolution

        %TruncationDistance Max distance from mesh surface
        TruncationDistance

        %FillInterior Determines if negative distances are computed
        % to center of mesh
        FillInterior

        %NumActiveVoxel Total number active voxels across all mesh
        NumActiveVoxel

        %MapLimits XYZ limits containing all active voxels
        MapLimits

        %VDBID Nx1 array of IDs managed by object
        VDBID

        %NumVDB Number of discretized meshes
        NumVDB
    end

    %% Methods inherited from coder.ExternalDependency
    methods (Static)
        function name = getDescriptiveName(~)
        %getDescriptiveName Get name for external dependency

            name = 'meshTSDFBuildable';
        end

        function updateBuildInfo(buildInfo, buildContext)
        %updateBuildInfo Add headers, libraries, and sources to the build info

        % Add vdbvolumecodegen header
            nav.geometry.internal.coder.meshtsdfBuildable.addCommonHeaders(buildInfo, buildContext);

            % Add vdbvolumecodegen libraries
            nav.geometry.internal.coder.meshtsdfBuildable.addLibraries(buildInfo, buildContext);
        end

        function isSupported = isSupportedContext(buildContext)
        %isSupportedContext Determine if external dependency supports this build context

        % Code generation is currently only supported for host
        % (non-portable) code generation.
            isSupported = buildContext.isMatlabHostTarget();
            if ~isSupported
                nav.algs.internal.error('nav:navalgs', 'meshtsdf:portablecodegen');
            end
        end
    end

    methods (Static, Access = protected)
        function addCommonHeaders(buildInfo,~)
        %addCommonHeaders Add include path for codegen APIs.
            includePath = fullfile(matlabroot, 'extern', 'include', 'nav');
            buildInfo.addIncludePaths(includePath, 'Navigation Toolbox Includes');
        end
        function addLibraries(buildInfo,buildContext)
        %addLibraries Add paths and names for prebuilt libraries
        % Link against vdbvolumecodegen module
            [linkLibPath,binPath,dynExt] = nav.geometry.internal.coder.buildableTools.addCodegenModule('vdbvolumecodegen',buildInfo,buildContext);

            % Make sure correct 3p dependencies are present
            libpattern = nav.geometry.internal.coder.buildableTools.getVDBLibraryNames(dynExt);
            
            for i = 1:numel(libpattern)
                % Find all libraries for 3p pattern
                buildInfo.addNonBuildFiles(libpattern{i},binPath,'');
            end
        end
    end

    methods
        function obj = meshtsdfBuildable(res,truncDist,fillInterior,useFastSweep)
            coder.cinclude('vdbmanager_api.hpp');

            % Allocate opaque for tsdf manager
            obj.TSDF = coder.opaquePtr('void',coder.internal.null);

            % Constuct tsdf object
            obj.TSDF = coder.ceval('vdbmanager_initialize',res,truncDist,...
                                   logical(fillInterior),logical(useFastSweep));
        end

        function meshAdded = addMeshes(obj,meshStruct)
        %addMeshes Discretize mesh and compute TSDF
            coder.cinclude('vdbmanager_api.hpp');
            N = numel(meshStruct);
            meshAdded = zeros(N,1);
            for i = 1:N
                V = meshStruct(i).Vertices;
                F = meshStruct(i).Faces;
                meshAdded(i) = coder.ceval('vdbmanager_addMesh',obj.TSDF,meshStruct(i).ID,...
                                           meshStruct(i).Pose, ...
                                           size(V,1), coder.rref(V), ...
                                           size(F,1), coder.rref(F));
            end
        end

        function removeID(obj,id)
        %removeID Remove one or more TSDF
            coder.cinclude('vdbmanager_api.hpp');
            coder.ceval('vdbmanager_removeIDs',obj.TSDF,id,numel(id));
        end

        function meshUpdated = updatePoses(obj,poseStruct)
        %updatePoses Update pose of one or more TSDF
            coder.cinclude('vdbmanager_api.hpp');

            N = numel(poseStruct);
            meshUpdated = nan(N,1);

            for i = 1:numel(poseStruct)
                meshUpdated(i) = coder.ceval('vdbmanager_updatePose',obj.TSDF, poseStruct(i).ID, coder.ref(poseStruct(i).Pose));
            end
        end

        function dist = distance(obj,pts,iMethod)
        %distance Compute distance to the zero level set
            coder.cinclude('vdbmanager_api.hpp');
            N = size(pts,1);
            dist = zeros(N,1);
            coder.ceval('vdbmanager_distance',obj.TSDF,...
                        coder.rref(pts), N, iMethod, coder.ref(dist));
        end

        function grad = gradient(obj,pts,iMethod)
        %gradient Compute gradient of the signed distance field
            coder.cinclude('vdbmanager_api.hpp');
            N = size(pts,1);
            grad = zeros(N,3);
            coder.ceval('vdbmanager_gradient',obj.TSDF,coder.rref(pts),N,iMethod,coder.ref(grad));
        end

        function poseStruct = getPoses(obj)
        %getPose Retrieve poses for one or more TSDF
            coder.cinclude('vdbmanager_api.hpp');

            % Define pose struct
            refScalar = 0;
            coder.varsize('refScalar',[inf 1]);
            poseElem = struct("ID",refScalar,"Pose",eye(4));
            ids = obj.VDBID;
            poseStruct = repmat(poseElem,numel(ids),1);
            
            for i = 1:numel(poseStruct)
                poseStruct(i).ID = ids(i);
                coder.ceval('vdbmanager_getPoseFrom',obj.TSDF,ids(i),coder.ref(poseStruct(i).Pose));
            end
        end

        function voxStruct = activeVoxels(obj)
        %activeVoxels Return voxel info
            coder.cinclude('vdbmanager_api.hpp');

            % Define ActiveVoxels struct
            id = obj.VDBID;
            nMesh = numel(id);
            vszVal = 0;
            vszPt = [0 0 0];
            coder.varsize("vszVal",[inf 1]);
            coder.varsize("vszPt",[inf 3]);
            voxStructElem = struct("ID",nan,"Distances",vszVal,"Centers",...
                                   vszPt,"Sizes",vszVal);
            voxStruct = repmat(voxStructElem,nMesh,1);

            % Allocate outputs
            for i = 1:numel(id)
                nVox = obj.getNumActiveVoxelInMesh(id(i));
                voxStruct(i).ID = id(i);
                voxStruct(i).Distances = nan(nVox,1);
                voxStruct(i).Centers = nan(nVox,3);
                voxStruct(i).Sizes = nan(nVox,1);
                coder.ceval('vdbmanager_getActiveVoxelFrom',obj.TSDF,voxStruct(i).ID,...
                    coder.ref(voxStruct(i).Centers),...
                    coder.ref(voxStruct(i).Distances),...
                    coder.ref(voxStruct(i).Sizes));
            end
        end

        function data = serialize(obj)
        %serialize Save object to char-array
            coder.cinclude('vdbmanager_api.hpp');
            sz = nan;
            sz = coder.ceval('vdbmanager_getSerializeSize',obj.TSDF);
            data = blanks(sz);
            coder.ceval('vdbmanager_serialize',obj.TSDF,coder.ref(data));
        end

        function delete(obj)
        %delete Deallocate object
            coder.cinclude('vdbmanager_api.hpp');
            coder.ceval('vdbmanager_cleanup',obj.TSDF);
        end

        function res = get.Resolution(obj)
        %get.Resolution
            coder.cinclude('vdbmanager_api.hpp');
            res = nan;
            res = coder.ceval('vdbmanager_getResolution',obj.TSDF);
        end

        function truncDist = get.TruncationDistance(obj)
        %get.TruncationDistance
            coder.cinclude('vdbmanager_api.hpp');
            truncDist = nan;
            truncDist = coder.ceval('vdbmanager_getTruncDist',obj.TSDF);
        end

        function fillInterior = get.FillInterior(obj)
        %get.FillInterior
            coder.cinclude('vdbmanager_api.hpp');
            fillInterior = nan;
            fillInterior = coder.ceval('vdbmanager_getFillInterior',obj.TSDF);
        end

        function numVoxel = get.NumActiveVoxel(obj)
        %get.NumActiveVoxel
            coder.cinclude('vdbmanager_api.hpp');
            numVoxel = nan;
            numVoxel = coder.ceval('vdbmanager_getNumActiveVoxel',obj.TSDF);
        end

        function numVoxel = getNumActiveVoxelInMesh(obj,id)
        %getNumActiveVoxelInMesh Retrieve number of active voxel in tsdf
            coder.cinclude('vdbmanager_api.hpp');
            numVoxel = nan;
            numVoxel = coder.ceval('vdbmanager_getNumActiveVoxelInVDB',obj.TSDF,id);
        end

        function bbox = get.MapLimits(obj)
        %get.MapLimits
            coder.cinclude('vdbmanager_api.hpp');
            bbox = zeros(2,3);
            coder.ceval('vdbmanager_getActiveBoundingBox',obj.TSDF,coder.ref(bbox));
        end

        function numMesh = get.NumVDB(obj)
        %get.NumVDB
            coder.cinclude('vdbmanager_api.hpp');
            numMesh = nan;
            numMesh = coder.ceval('vdbmanager_getNumVDB',obj.TSDF);
        end
        
        function id = get.VDBID(obj)
        %get.VDBID
            coder.cinclude('vdbmanager_api.hpp');
            N = obj.NumVDB();
            id = nan(N,1);
            coder.ceval('vdbmanager_getID',obj.TSDF,coder.ref(id));
        end
    end

    methods (Static)
        function obj = deserialize(data)
        %deserialize Reconstruct tsdf object from char-array
            coder.cinclude('vdbmanager_api.hpp');

            % Initialize dummy object
            obj = nav.geometry.internal.coder.meshtsdfBuildable(1,3,0,0);

            % Clean up dummy
            coder.ceval('vdbmanager_cleanup',obj.TSDF);

            % Deserialize true object
            sz = numel(data);
            obj.TSDF = coder.ceval('vdbmanager_deserialize',coder.rref(data),sz);
        end
    end
end
