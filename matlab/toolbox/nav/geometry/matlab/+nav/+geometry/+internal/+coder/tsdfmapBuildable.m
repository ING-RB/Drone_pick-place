classdef tsdfmapBuildable < coder.ExternalDependency & nav.algs.internal.InternalAccess
%This class is for internal use only. It may be removed in the future.

%tsdfmapBuildable Buildable class for meshtsdf code generation
%
%   See also meshtsdf

% Copyright 2023-2024 The MathWorks, Inc.

%#codegen
    properties (Access = ?nav.algs.internal.InternalAccess)
        %DistVDB
        DistVDB

        %WeightVDB
        WeightVDB
    end
    properties (Dependent, SetAccess = protected)
        %Resolution Grid resolution in cells per meter
        Resolution

        %TruncationDistance Max distance from mesh surface
        TruncationDistance

        %NumActiveVoxel Total number active voxels across all mesh
        NumActiveVoxel

        %MapLimits XYZ limits containing all active voxels
        MapLimits

        %NumVDB Number of contained VDBVolume layers
        NumVDB
    end
    properties (SetAccess = protected)
        %FullTracing
        FullTracing
    end

    %% Methods inherited from coder.ExternalDependency
    methods (Static)
        function name = getDescriptiveName(~)
        %getDescriptiveName Get name for external dependency

            name = 'tsdfmapBuildable';
        end

        function updateBuildInfo(buildInfo, buildContext)
        %updateBuildInfo Add headers, libraries, and sources to the build info

        % Add vdbvolumecodegen header
            nav.geometry.internal.coder.tsdfmapBuildable.addCommonHeaders(buildInfo, buildContext);

            % Add vdbvolumecodegen libraries
            nav.geometry.internal.coder.tsdfmapBuildable.addLibraries(buildInfo, buildContext);
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
        function obj = tsdfmapBuildable(res,truncDist,fullTracing)
            coder.cinclude('vdbmanager_api.hpp');

            % Allocate opaque for tsdf manager
            obj.DistVDB = coder.opaquePtr('void',coder.internal.null);
            obj.WeightVDB = coder.opaquePtr('void',coder.internal.null);
            fillInterior = false;
            useFastSweep = false;

            % Constuct tsdf object
            obj.DistVDB = coder.ceval('vdbmanager_initialize',res,truncDist,...
                                   fillInterior,useFastSweep);
            obj.WeightVDB = coder.ceval('vdbmanager_initialize',res,truncDist,...
                                   fillInterior,useFastSweep);
            obj.FullTracing = fullTracing;
        end

        function insertPointCloud(obj,id,origin,pts)
        %insertPointCloud Integrate sensor data into tsdf
            coder.cinclude('vdbmanager_api.hpp');

            % Integrate sensor data
            coder.ceval('tsdfmap_insertPointCloud',obj.DistVDB, ...
                obj.WeightVDB,uint64(id),logical(obj.FullTracing), ...
                coder.rref(origin),coder.rref(pts),uint64(size(pts,1)));
        end

        function out = createMesh(obj,id,fillHoles,minWeight)
        %createMesh Generate an iso-surface mesh from active voxels
            coder.cinclude('vdbmanager_api.hpp');

            % Create dynamicVoxel matrix for potentially varsize outputs
            vertPtr = coder.opaquePtr('double',coder.internal.null);
            facePtr = coder.opaquePtr('double',coder.internal.null);
            nVert = uint64(0);
            nFace = uint64(0);

            % Extract mesh data
            coder.ceval('tsdfmap_createMesh',obj.DistVDB,obj.WeightVDB, ...
                uint64(id), logical(fillHoles), single(minWeight), coder.ref(vertPtr), ...
                coder.ref(nVert),coder.ref(facePtr),coder.ref(nFace));

            % Copy data to MATLAB
            V = nan(nVert,3);
            F = nan(nFace,3);
            V = obj.copyAndCleanOpaque(vertPtr,V,nVert*3);
            F = obj.copyAndCleanOpaque(facePtr,F,nFace*3);

            out = {V,F};
        end

        function dist = distance(obj,pts,iMethod)
        %distance Compute distance to the zero level set
            coder.cinclude('vdbmanager_api.hpp');
            N = size(pts,1);
            dist = zeros(N,1);
            coder.ceval('vdbmanager_distance',obj.DistVDB,...
                        coder.rref(pts), N, iMethod, coder.ref(dist));
        end

        function grad = gradient(obj,pts,iMethod)
        %gradient Compute gradient of the signed distance field
            coder.cinclude('vdbmanager_api.hpp');
            N = size(pts,1);
            grad = zeros(N,3);
            coder.ceval('vdbmanager_gradient',obj.DistVDB,coder.rref(pts),N,iMethod,coder.ref(grad));
        end

        function voxStruct = activeVoxels(obj)
        %activeVoxels Return voxel info
            coder.cinclude('vdbmanager_api.hpp');

            % Define ActiveVoxels struct
            if obj.NumVDB > 0
                id = 1;
            else
                id = [];
            end
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
                nVox = obj.getNumActiveVoxel(id(i));
                voxStruct(i).ID = id(i);
                voxStruct(i).Distances = nan(nVox,1);
                voxStruct(i).Centers = nan(nVox,3);
                voxStruct(i).Sizes = nan(nVox,1);
                coder.ceval('vdbmanager_getActiveVoxelFrom',obj.DistVDB,voxStruct(i).ID,...
                    coder.ref(voxStruct(i).Centers),...
                    coder.ref(voxStruct(i).Distances),...
                    coder.ref(voxStruct(i).Sizes));
            end
        end

        function data = serialize(obj)
        %serialize Save object to char-array
            coder.cinclude('vdbmanager_api.hpp');
            distData = obj.serializeVDB(obj.DistVDB);
            weightData = obj.serializeVDB(obj.WeightVDB);
            data = {distData, weightData, obj.FullTracing};
        end

        function delete(obj)
        %delete Deallocate object
            coder.cinclude('vdbmanager_api.hpp');
            coder.ceval('vdbmanager_cleanup',obj.DistVDB);
            coder.ceval('vdbmanager_cleanup',obj.WeightVDB);
        end

        function res = get.Resolution(obj)
        %get.Resolution
            coder.cinclude('vdbmanager_api.hpp');
            res = nan;
            res = coder.ceval('vdbmanager_getResolution',obj.DistVDB);
        end

        function truncDist = get.TruncationDistance(obj)
        %get.TruncationDistance
            coder.cinclude('vdbmanager_api.hpp');
            truncDist = nan;
            truncDist = coder.ceval('vdbmanager_getTruncDist',obj.DistVDB);
        end

        function numVoxel = get.NumActiveVoxel(obj)
        %get.NumActiveVoxel
            coder.cinclude('vdbmanager_api.hpp');
            numVoxel = nan;
            numVoxel = coder.ceval('vdbmanager_getNumActiveVoxel',obj.DistVDB);
        end

        function nVDB = get.NumVDB(obj)
        %get.NumVDB
            coder.cinclude('vdbmanager_api.hpp');
            nVDB = nan;
            nVDB = coder.ceval('vdbmanager_getNumVDB',obj.DistVDB);
        end

        function numVoxel = getNumActiveVoxel(obj,id)
        %getNumActiveVoxel Retrieve number of active voxel in tsdf
            coder.cinclude('vdbmanager_api.hpp');
            numVoxel = nan;
            numVoxel = coder.ceval('vdbmanager_getNumActiveVoxelInVDB',obj.DistVDB,id);
        end
        
        function fullTracing = get.FullTracing(obj)
        %get.FullTracing
            fullTracing = double(obj.FullTracing);
        end

        function set.FullTracing(obj,fullTracing)
        %set.FullTracing
            obj.FullTracing = logical(fullTracing);
        end
        
        function bbox = get.MapLimits(obj)
        %get.MapLimits
            coder.cinclude('vdbmanager_api.hpp');
            bbox = zeros(2,3);
            coder.ceval('vdbmanager_getActiveBoundingBox',obj.DistVDB,coder.ref(bbox));
        end
    end

    methods (Static)
        function obj = deserialize(data)
        %deserialize Reconstruct tsdf object from char-array
            % Initialize dummy object
            obj = nav.geometry.internal.coder.tsdfmapBuildable(1,3,false);
            obj.DistVDB = obj.deserializeVDB(obj.DistVDB,data{1});
            obj.WeightVDB = obj.deserializeVDB(obj.WeightVDB,data{2});
            obj.FullTracing = data{3};
        end
    end

    methods (Static,Hidden)
        function vdbData = serializeVDB(vdb)
            coder.cinclude('vdbmanager_api.hpp');
            sz = nan;
            sz = coder.ceval('vdbmanager_getSerializeSize',vdb);
            vdbData = blanks(sz);
            coder.ceval('vdbmanager_serialize',vdb,coder.ref(vdbData));
        end
        function vdbMgr = deserializeVDB(vdbMgr,vdbData)
            coder.cinclude('vdbmanager_api.hpp');

            % Clean up dummy
            coder.ceval('vdbmanager_cleanup',vdbMgr);

            % Deserialize true object
            disp('serializedSize');
            sz = numel(vdbData);
            vdbMgr = coder.ceval('vdbmanager_deserialize',coder.rref(vdbData),sz);
        end
        function destBuffer = copyAndCleanOpaque(opaquePtr,destBuffer,nElem)
        %copyAndCleanOpaque C-supported copying and cleanup of dynamically allocated array
            if nElem > 0
                nBytePer = uint64(0);
                nBytePer = coder.ceval('sizeof',destBuffer(1));
                coder.ceval('memcpy',coder.ref(destBuffer),opaquePtr,nBytePer*uint64(nElem));
    
                % Clean up opaque pointers
                coder.ceval('tsdfmap_freeDoublePtr', opaquePtr);
            end
        end
    end
end
