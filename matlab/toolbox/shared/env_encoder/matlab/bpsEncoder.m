classdef bpsEncoder < matlabshared.env_encoder.internal.EnvEncoderBase & ...
        matlabshared.env_encoder.internal.ValueClassCustomDisplay
%

% Copyright 2023-2024 The MathWorks, Inc.

%#codegen

% Properties that are read-only
    properties (SetAccess=private, GetAccess=public)

        % Arrangement is the arrangement of basis point set

        Arrangement

        % EncodingSize define the number of points in basis point set

        EncodingSize

        % Size of the rectangle in rectangular-grid or rectangular-grid-3d arrangement

        Dimensions

        % Points is the Basis Point Set generated.

        Points

        % Center is the center of the Basis point set arrangement.

        Center

        % Radius of the ball in uniform-ball and uniform-ball-3d arrangement

        Radius
    end

    properties(Access=private)
        Environment
    end

    methods(Access=public)

        function obj = bpsEncoder(arrangement, encodingSize, nvPairs)
        %

            arguments
                arrangement {mustBeTextScalar} = "uniform-ball-3d";

                encodingSize {bpsEncoder.validateEncodingSize( ...
                    arrangement, encodingSize)} = ...
                    bpsEncoder.getDefaultEncodingSize(arrangement);

                nvPairs.Center {bpsEncoder.validatePropertyCenter( ...
                    arrangement, nvPairs.Center)} = ...
                    bpsEncoder.getDefaultPropertyCenter(arrangement);

                nvPairs.Radius (1,1) {bpsEncoder.validatePropertyRadius( ...
                    nvPairs.Radius)};


                nvPairs.Dimensions {bpsEncoder.validatePropertyDimensions( ...
                    arrangement, nvPairs.Dimensions)};
            end

            obj.initialize();
            % validate that arrangement is an unambiguous, case-insensitive match
            % to any of valid Arrangement.
            arrangement = bpsEncoder.validateArrangement(arrangement);
            % validate that Radius property is input only with uniform-ball
            % and uniform-ball-3d arrangements. Also validate that
            % Dimensions property is only input with rectangular-grid and
            % rectangular-grid-3d arrangements.
            bpsEncoder.validateRadiusDimensionsWithArrangement(arrangement, nvPairs);

            [radius, dimensions] = bpsEncoder.getDefaultRadiusAndDimension(arrangement, nvPairs);

            obj.Arrangement = string(arrangement);
            obj.EncodingSize = encodingSize;
            obj.Center = nvPairs.Center;
            obj.Radius = radius;
            obj.Dimensions = dimensions;

            arr = bpsEncoder.getArrangement();
            points = zeros(0,3);

            switch arrangement
              case {arr.uniformball, arr.uniformball3d}
                points = matlabshared.env_encoder.internal.basispoints( ...
                    arrangement, encodingSize, obj.Center, radius);
              case {arr.rectgrid, arr.rectgrid3d}
                points = matlabshared.env_encoder.internal.basispoints( ...
                    arrangement, encodingSize, obj.Center, dimensions);
            end
            obj.Points = points;
        end

        function [encoding,nearest] = encode(obj, environment)
        %

            obj.initialize();

            narginchk(2,2);
            % Validate the environment input. Also validate that
            % environment supplied is valid with the Arrangement chosen.
            validateEnvironment(obj, environment);
            obj.Environment = environment;

            type = class(environment);
            % Based on the type of the environment, call the appropriate function
            % to get encoding and nearest neighbor.
            switch type
              case {'double', 'single'}
                validateattributes(environment, "numeric", {'finite', 'real', 'size',[4, NaN]}, 'encode');

                [encoding, nearest] = matlabshared.env_encoder.internal.encodeSphere( ...
                    obj.Points, environment);

              case 'meshtsdf'
                if nargout < 2
                    encoding = encodeMeshTSDF(obj);
                else
                    [encoding, nearest] = encodeMeshTSDF(obj);
                end

              case {'occupancyMap', 'binaryOccupancyMap'}
                if coder.target("MATLAB")
                    if isa(environment, 'binaryOccupancyMap')
                        obj.initializeMap();
                    end
                end
                if nargout < 2
                    encoding = encode2DMaps(obj);
                else
                    [encoding, nearest] = encode2DMaps(obj);
                end
            end
        end
    end

    methods(Access = private)
        function validateEnvironment(obj, environment)
        % validateEnvironment validate the environment input. Also validate that
        % environment supplied is valid with the Arrangement chosen.

        % Validate that environment is one of the supported types.
            validateattributes(environment, {'double', 'single', 'meshtsdf', ...
                                             'occupancyMap', 'binaryOccupancyMap'},...
                               {'2d'}, 'environment');

            arr = obj.getArrangement();

            switch class(environment)
              case {'double', 'single', 'meshtsdf'}
                expectedArrangements = {arr.uniformball3d, arr.rectgrid3d};
                expectedErrorID = 'shared_env_encoder:bpsEncoder:Arrangement2DInvalidWith3DEnvironment';
              case {'occupancyMap', 'binaryOccupancyMap'}
                expectedArrangements = {arr.uniformball, arr.rectgrid};
                expectedErrorID = 'shared_env_encoder:bpsEncoder:Arrangement3DInvalidWith2DEnvironment';
            end

            if ~any(matches(expectedArrangements, obj.Arrangement))
                coder.internal.error(expectedErrorID,obj.Arrangement,expectedArrangements{1}, expectedArrangements{2});
            end
        end

        function [encoding, nearest] = encodeMeshTSDF(obj)
        % encodeMeshTSDF encode environment of type meshtsdf using
        % basispointset encoding

            tsdf = obj.Environment;
            bps = obj.Points;
            nearest = nan(height(bps),3);

            encoding = tsdf.distance(bps, InterpolationMethod="linear");
            surfaceVoxel = bpsEncoder.findVoxelsOnSurface(tsdf);
            % When the meshtsdf object is empty, return encoding as inf and
            % nearest point as NaN.
            if isempty(surfaceVoxel)
                encoding = inf(height(bps),1);
                return;
            end
            % find basis points at a distance of truncation distance. In
            % meshtsdf, all points that are farther than truncation
            % distance also returns truncation distance. Hence all points
            % that are truncation distance away are considered as outside
            % truncation distance and kdtree is used for finding the
            % distance.
            bpsOutsideIdx = (encoding - tsdf.TruncationDistance) > -sqrt(eps);
            bpsOutside = bps(bpsOutsideIdx,:);
            % A basis point is inside the truncation distance if the
            % encoding value is negative or when encoding distance is less than
            % truncation distance.
            bpsInsideIdx = ~bpsOutsideIdx;
            if ~isempty(bpsOutside)

                if coder.target("MATLAB")
                    [index, dist] = matlabshared.env_encoder.internal.mex.kdtreeWrapper(...
                        surfaceVoxel, bpsOutside);
                else
                    [index, dist] = matlabshared.env_encoder.internal.impl.kdtreeWrapper(...
                        surfaceVoxel, bpsOutside);
                end
                dist = dist';
                encoding(bpsOutsideIdx) = dist;
                nearest(bpsOutsideIdx,:) = surfaceVoxel(index,:);
            end

            if nargout > 1
                grad = tsdf.gradient(bps(bpsInsideIdx,:), "InterpolationMethod","linear");
                nearest(bpsInsideIdx,:) = bps(bpsInsideIdx,:) - encoding(bpsInsideIdx).*normalize(grad,2,"norm");
            end

        end

        function [encoding, nearestPoint] = encode2DMaps(obj)
        % encode2DMaps encode environment of type occupancyMap,
        % binaryOccupancyMap using basispointset encoding.

            points = obj.Points;
            map = obj.Environment;
            % Unknown areas in occupancyMap is considered as occupied.
            mapMatrix = logical(map.checkOccupancy);
            % Get signed distance field
            sdf = signedDistanceMap(mapMatrix, Resolution=map.Resolution);
            sdf.GridLocationInWorld = map.GridLocationInWorld;
            % Compute distance in world frame
            [encoding, isValid] = sdf.distance(points);
            encoding = encoding(:);
            nearestPoint = zeros(height(points),2);
            isInValid = ~isValid;
            if any(isInValid)
                % Some basis points are outside the map boundary. This
                % needs to be handled separately since signedDistanceMap
                % can not find distance for query points outside map boundary.
                [dist,nearestPtForOutsideBPS] = findDistanceForOutsidePoints(obj, points(isInValid,:));
                encoding(isInValid) = dist;
                nearestPoint(isInValid,:) = nearestPtForOutsideBPS;
            end
            if nargout > 1 && any(isValid)
                % Compute coordinates of nearest obstacles in the world frame
                nearestPts = sdf.closestBoundary(points(isValid,:));
                nearestPts = squeeze(nearestPts);
                nearestPoint(isValid,:) = nearestPts;
            end
        end

        function [dist,nearestPoints] = findDistanceForOutsidePoints(obj, outsidePts)
        % findDistanceForOutsidePoints find distance from basis points
        % which are outside map boundary to the nearest obstacle in the map.
        % Additionally, the nearest obstacle location is also returned.
            map = obj.Environment;
            % Unknown areas in occupancyMap is considered as occupied.
            occMat = logical(map.checkOccupancy);
            % Extracting obstacle list
            [I, J] = find(occMat);
            if isempty(I)
                numOutsidePoints = size(outsidePts,1);
                dist = inf(numOutsidePoints,1);
                nearestPoints = nan(numOutsidePoints,2);
                return;
            end
            obstacleList = map.grid2world([I, J]);

            if coder.target("MATLAB")
                [index, dist] = matlabshared.env_encoder.internal.mex.kdtreeWrapper(...
                    obstacleList, outsidePts);
            else
                [index, dist] = matlabshared.env_encoder.internal.impl.kdtreeWrapper(...
                    obstacleList, outsidePts);
            end
            nearestPoints = obstacleList(index,:);
        end

    end

    methods (Access = protected)
        function groups = getPropertyGroups(obj)
        %

        % getPropertyGroups Custom property group display.
        %   This function overrides the method in the
        %   CustomDisplay base class.

            propList = struct(...
                "Arrangement", obj.Arrangement,...
                "EncodingSize", obj.EncodingSize,...
                "Center", obj.Center);

            arr =  bpsEncoder.getArrangement();
            switch obj.Arrangement
                % If the arrangement is rectangular-grid, set the
                % attribute to vector of size 1x2
              case {arr.rectgrid, arr.rectgrid3d}
                propList.Dimensions = obj.Dimensions;
              case {arr.uniformball, arr.uniformball3d}
                propList.Radius = obj.Radius;
            end

            propList.Points = obj.Points;
            groups = matlab.mixin.util.PropertyGroup(propList);
        end
    end

    methods(Static, Access=private)

        function surfaceCenters = findVoxelsOnSurface(tsdf)
        % findVoxelsOnSurface return the center of the voxels on the
        % surface of all the geometries.

            activeVoxs = tsdf.activeVoxels();
            numObjs = size(activeVoxs,1);
            celLWidth = 1/tsdf.Resolution;
            surfaceVox = cell(numObjs,1);
            % Loop over all the geometries and find voxels with truncation
            % distance lesser than cellWidth/2. These voxels are on the
            % surface of the geometry.
            for i=1:numObjs
                surfaceVoxIdx = activeVoxs(i).Distances < (celLWidth/2);
                surfaceVox{i} = activeVoxs(i).Centers(surfaceVoxIdx,:);
            end
            surfaceCenters = cell2mat(surfaceVox);
        end

        function [arr, arrangements] =  getArrangement()
        % getArrangement return a struct containing the valid arrangement options.
        % Additionally it returns a cell array of arrangements.

            arrangements = {'uniform-ball', 'uniform-ball-3d', 'rectangular-grid', 'rectangular-grid-3d'};
            fields = {'uniformball', 'uniformball3d', 'rectgrid', 'rectgrid3d'};
            % For codegen, using a loop to create the structure. cell2struct is not
            % supported for codegen.
            for i=1:length(fields)
                arr.(fields{i}) = arrangements{i};
            end
        end

        function arrangement = validateArrangement(arrangementInput)
        %validateArrangement validate property Arrangement

            [~, allArrangements] =  bpsEncoder.getArrangement();

            % validate that the 'arrangement' is an unambiguous, case-insensitive match
            % to any of options in 'arrangementOptions'.
            arrangement = validatestring(arrangementInput, allArrangements, 'bpsEncoder');
        end

        function validateEncodingSize(arrangement, encodingSizeInput)
        % validateEncodingSize validate encodingSize property
            arr =  bpsEncoder.getArrangement();

            % codegen does not allow cell array with different types on
            % different execution paths. Here attributes{2} is a string in
            % uniform-ball arrangement but it is a vector in
            % rectangular-grid arrangement. Hence doing validation
            % adjacent to definition of attributes.
            switch arrangement

                % Set the attribute to a scalar when the arrangement is
                % uniform-ball or uniform-ball-3d
              case {arr.uniformball, arr.uniformball3d}
                attributes = {"scalar", "integer", "positive", "finite", "nonnan"};

                % Validate that encodingSize is valid in accordance with the
                % arrangement.
                validateattributes(encodingSizeInput,"numeric",attributes, ...
                                   'bpsEncoder','encodingSize');

                % If the arrangement is rectangular-grid, set the
                % attribute to vector of size 1x2
              case arr.rectgrid
                attributes = {"size",[1 2],"integer", "positive", "finite", "nonnan"};

                validateattributes(encodingSizeInput,"numeric",attributes, ...
                                   'bpsEncoder','encodingSize');

                % If the arrangement is rectangular-grid-3d, set the
                % attribute to a vector of size 1x3
              case arr.rectgrid3d
                attributes = {"size",[1 3],"integer", "positive", "finite", "nonnan"};

                validateattributes(encodingSizeInput,"numeric",attributes, ...
                                   'bpsEncoder','encodingSize');
            end

        end

        function validatePropertyCenter(arrangement, center)
        % validatePropertyCenter verify that the Center property
        % is valid in accordance with the Arrangement.

            arr =  bpsEncoder.getArrangement();

            switch arrangement
              case {arr.uniformball, arr.rectgrid}
                % For 2D arrangements verify that the center is of size
                % 1-by-2 and verify other characteristics of Center
                attributes = {"size",[1 2], "real", "finite", "nonnan"};
                validateattributes(center,"numeric",attributes, 'bpsEncoder','Center');

              case {arr.uniformball3d arr.rectgrid3d}

                attributes = {"size",[1 3],"real", "finite", "nonnan"};
                % For 3D arrangements verify that the center is of size
                % 1-by-3 and verify other characteristics of Center
                validateattributes(center,"numeric",attributes, 'bpsEncoder','Center');
            end

        end

        function validatePropertyDimensions(arrangement, dimensions)
        % validatePropertyDimensions validate that value of Dimensions property
        % is valid. Also verify that the user set valid Arrangement
        % when supplying Dimensions property.

            arr =  bpsEncoder.getArrangement();
            switch arrangement
                % If the arrangement is rectangular-grid, set the
                % attribute to vector of size 1x2
              case arr.rectgrid
                attributes = {"size",[1 2], "real", "finite", "nonnan", "positive", "nonempty"};
                validateattributes(dimensions,"numeric",attributes, 'bpsEncoder','Dimensions');

              case arr.rectgrid3d
                % If the arrangement is rectangular-grid-3d, set the
                % attribute to a vector of size 1x3
                attributes = {"size",[1 3],"real", "finite", "nonnan", "positive", "nonempty"};
                validateattributes(dimensions,"numeric",attributes, 'bpsEncoder','Dimensions');
            end

        end

        function validatePropertyRadius(radius)
        % validatePropertyRadius validate that value of Radius property
        % is valid. Also verify that the user set valid Arrangement
        % when supplying Radius property.

            attributes = {"positive", "real", "finite", "nonnan"};
            validateattributes(radius,"numeric",attributes, 'bpsEncoder','Dimensions');
        end

        function validateRadiusDimensionsWithArrangement(arrangement, nvPairs)
        % validateRadiusDimensionsWithArrangement validate that Radius
        % property is input only with uniform-ball and uniform-ball-3d
        % arrangements. Also validate that Dimensions property is input
        % with rectangular-grid and rectangular-grid-3d arrangements.
        % Also validate both properties are not supplied together.

        % validate that Dimensions and Radius property is not supplied
        % together.
            if isfield(nvPairs, 'Radius') && isfield(nvPairs, 'Dimensions')
                coder.internal.error('shared_env_encoder:bpsEncoder:RadiusDimensionTogether');
            end

            arr =  bpsEncoder.getArrangement();

            isBallArrangement = strcmp(arrangement, arr.uniformball) || ...
                strcmp(arrangement, arr.uniformball3d);

            isGridArrangement = strcmp(arrangement, arr.rectgrid) || ...
                strcmp(arrangement, arr.rectgrid3d);

            % validate that Radius property is input only with uniform-ball
            % and uniform-ball-3d arrangements.
            if isBallArrangement && isfield(nvPairs, 'Dimensions')
                coder.internal.error(['shared_env_encoder:bpsEncoder:' ...
                                      'DimensionsForGridArrangement'], arrangement);
                %validate that Dimensions property is input
                % with rectangular-grid and rectangular-grid-3d arrangements.
            elseif isGridArrangement && isfield(nvPairs, 'Radius')
                coder.internal.error(['shared_env_encoder:bpsEncoder:' ...
                                      'RadiusForBallArrangement'], arrangement);
            end
        end

        function encodingSize = getDefaultEncodingSize(arrangement)
        % getDefaultEncodingSize return default value for encodingSize
        % based on the Arrangement provided.

            arr =  bpsEncoder.getArrangement();
            encodingSize = 64;
            switch arrangement
              case {arr.uniformball, arr.uniformball3d}
                encodingSize = 64;
              case arr.rectgrid
                encodingSize = [8 8];
              case arr.rectgrid3d
                encodingSize = [4 4 4];
            end
        end

        function center = getDefaultPropertyCenter(arrangement)
        % getDefaultPropertyCenter return default value for Center
        % based on Arrangement.

            arr =  bpsEncoder.getArrangement();
            center = [0 0 0];
            switch arrangement
              case {arr.uniformball, arr.rectgrid}
                center = [0 0];
              case {arr.uniformball3d arr.rectgrid3d}
                center = [0 0 0];
            end

        end

        function dimensions = getDefaultPropertyDimensions(arrangement)
        % getDefaultPropertyDimensions return default value for
        % Dimensions based on Arrangement.

            arr =  bpsEncoder.getArrangement();
            dimensions = [2 2 2];
            switch arrangement
              case arr.rectgrid
                dimensions = [2 2];
              case arr.rectgrid3d
                dimensions = [2 2 2];
            end
        end

        function [radius, dimensions] = getDefaultRadiusAndDimension(arrangement, nvPairs)
        % getDefaultRadiusAndDimension return Radius, Dimensions values
        % supplied by user through n-v pairs. If the values are not
        % supplied by the user then return the default value of Radius
        % and Dimensions based on the Arrangement.

            if isfield(nvPairs, 'Radius')
                radius = nvPairs.Radius;
            else
                radius = 1;
            end

            if isfield(nvPairs, 'Dimensions')
                dimensions = nvPairs.Dimensions;
            else
                dimensions = bpsEncoder.getDefaultPropertyDimensions(arrangement);
            end

        end
    end
end
