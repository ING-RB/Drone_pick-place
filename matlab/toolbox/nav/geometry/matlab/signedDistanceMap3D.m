classdef signedDistanceMap3D < handle
%

%   Copyright 2024 The MathWorks, Inc.

%#codegen

    properties (Access = ?nav.algs.internal.InternalAccess)
        %TsdfmapBuiltin C++ MCOS Object
        TsdfmapBuiltin

        %ColorbarLinks Stores property links for display of 2nd colorbar
        ColorbarLinks

        %ThemeListener Listeners for updating colors when theme changes
        ThemeListener

        %ScatterHandle Handle for storing scatterplot
        ScatterHandle
    end

    properties (GetAccess = public, SetAccess = protected)
        %Resolution Grid resolution in cells per meter
        %
        %   Default: 1 cell/meter
        Resolution

        %FullTracing Determines whether full or local raycasting occurs
        %
        %   false - Inserted rays only update voxels within
        %           +/-TruncationDistance of the ray's endpoint
        %
        %              (Default)
        %
        %   true  - All voxels between the ray origin and
        %           TruncationDistance past the ray endpoint are updated
        FullTracing

        %TruncationDistance Max distance from occupied boundary
        %
        %   If not provided, the default TruncationDistance will be set to
        %   the minimum distance required to ensure that the TSDF region is
        %   extends at least 3 voxels thick on either side of the occupied
        %   boundary.
        %
        %   Default: 4 (voxels)
        TruncationDistance
    end

    properties (Dependent)
        %NumActiveVoxels Number of active voxels in the map
        %
        %   Active voxels are those that contain computed distance values
        NumActiveVoxels

        %MapLimits Min and max limits of active voxels in XYZ
        MapLimits
    end

    methods
        function obj = signedDistanceMap3D(nv)
            arguments
                nv.Resolution (1,1) {mustBeNumeric, mustBePositive, mustBeFinite} = 1.0;                    % cell/m
                nv.FullTracing (1,1) {mustBeNumericOrLogical, mustBeMember(nv.FullTracing,[0,1])} = false   % logical
                nv.TruncationDistance (1,1) = nan                                                           % m
            end

            if isnan(nv.TruncationDistance)
                % The minimum truncation distance
                nv.TruncationDistance = 3/nv.Resolution;
            else
                nav.geometry.internal.TSDFUtils.validateTruncationDistance(3/nv.Resolution,nv.TruncationDistance);
            end

            % Construct builtin
            if coder.target("MATLAB")
                obj.TsdfmapBuiltin = nav.geometry.internal.TsdfmapBuiltin(nv.Resolution, ...
                        nv.TruncationDistance,logical(nv.FullTracing));
            else
                obj.TsdfmapBuiltin = nav.geometry.internal.coder.tsdfmapBuildable(nv.Resolution, ...
                    nv.TruncationDistance,logical(nv.FullTracing));
            end
        end

        function insertPointCloud(obj,origin,pt)
        %
            arguments
                obj
                origin (1,3) double {mustBeReal}
                pt (:,3) double {mustBeReal}
            end
            goodPts = vecnorm(pt-origin,2,2) > 1e-7;
            if any(goodPts)
                obj.TsdfmapBuiltin.insertPointCloud(1,origin,pt(goodPts,:));
            end
        end

        function dist = distance(obj,pts,nv)
        %
            arguments
                obj
                pts (:,3) double {mustBeReal, mustBeFinite}
                nv.InterpolationMethod (1,1) string {mustBeMember(nv.InterpolationMethod,{'nearest','linear','quadratic'})} = "nearest"
            end
            switch nv.InterpolationMethod
                case "nearest"
                    iMethod = 0;
                case "linear"
                    iMethod = 1;
                case "quadratic"
                    iMethod = 2;
            end
            dist = obj.TsdfmapBuiltin.distance(pts,iMethod);
        end

        function grad = gradient(obj,pts,nv)
        %
            arguments
                obj
                pts (:,3) double {mustBeReal, mustBeFinite}
                nv.InterpolationMethod (1,1) string {mustBeMember(nv.InterpolationMethod,{'linear','quadratic'})} = "linear"
            end
            switch nv.InterpolationMethod
                case "linear"
                    iMethod = 1;
                case "quadratic"
                    iMethod = 2;
            end
            if obj.TsdfmapBuiltin.NumVDB == 0
                grad = nan(size(pts,1),3);
            else
                grad = obj.TsdfmapBuiltin.gradient(pts,iMethod);
            end
        end

        function [vertices,faces] = mesh(obj)
        %
            output = obj.TsdfmapBuiltin.createMesh(1, false, 0);
            vertices = output{1};
            faces = output{2};
        end

        function voxStruct = activeVoxels(obj)
        %
            arguments
                obj
            end

            % Retrieve voxels for all VDB objects being managed
            voxStruct = obj.TsdfmapBuiltin.activeVoxels();
        end

        function [h,hBar] = show(obj,nv)
        %
            arguments
                obj
                nv.Parent (1,1) {mustBeA(nv.Parent,{'matlab.graphics.axis.Axes','matlab.graphics.GraphicsPlaceholder'})} = matlab.graphics.GraphicsPlaceholder
                nv.IsoRange (1,2) {mustBeNonNan} = [-inf inf];
                nv.Colorbar (1,1) matlab.lang.OnOffSwitchState = 'off'
                nv.FastUpdate (1,1) matlab.lang.OnOffSwitchState = 'off'
            end
            
            % Validate inputs
            validateattributes(nv.IsoRange,{'numeric'},{"increasing"},'IsoRange');

            % Display object
            voxStruct = obj.activeVoxels;
            if nargout == 0
                nav.geometry.internal.TSDFUtils.showImpl(obj,voxStruct,nv);
            else
                [h,hBar] = nav.geometry.internal.TSDFUtils.showImpl(obj,voxStruct,nv);
            end
        end

        function numVoxel = get.Resolution(obj)
        %get.Resolution
            numVoxel = obj.TsdfmapBuiltin.Resolution;
        end

        function numVoxel = get.FullTracing(obj)
        %get.FullTracing
            numVoxel = obj.TsdfmapBuiltin.FullTracing;
        end

        function numVoxel = get.TruncationDistance(obj)
        %get.TruncationDistance
            numVoxel = obj.TsdfmapBuiltin.TruncationDistance;
        end

        function numVoxel = get.NumActiveVoxels(obj)
        %get.NumActiveVoxels
            numVoxel = obj.TsdfmapBuiltin.NumActiveVoxel;
        end

        function bounds = get.MapLimits(obj)
        %get.MapLimits
            bounds = obj.TsdfmapBuiltin.MapLimits;
        end

        function cObj = copy(obj)
        %
            cObj = signedDistanceMap3D;

            % Copy over serialized information
            data = obj.TsdfmapBuiltin.serialize();
            if coder.target("MATLAB")
                cObj.TsdfmapBuiltin.deserialize(data);
            else
                cObj.TsdfmapBuiltin = obj.TsdfmapBuiltin.deserialize(data);
            end
        end
    end

    methods (Hidden,Static)
        function obj = loadobj(S)
        % Create empty map
            obj = signedDistanceMap3D;

            % Populate with serialized data
            obj.TsdfmapBuiltin.deserialize(S.Data);
        end
    end

    methods (Hidden)
        function S = saveobj(obj)
            S = struct('Data',{obj.TsdfmapBuiltin.serialize});
        end
        function [dMax,dRange] = depthInfo(obj,~,isoRange)
        %depthInfo Compute distance interval for visualization
            td = obj.TruncationDistance;
            dRange = [max(isoRange(1),-td) min(isoRange(2),td)];
            dMax = max(abs(dRange));
        end
    end
end
