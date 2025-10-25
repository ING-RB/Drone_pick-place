classdef (Hidden)pointCloudBase < handle
    % pointCloudImpl Implementation class for pointCloud for code generation.

    % Copyright 2018-2024 The MathWorks, Inc.
    %#codegen

    properties (GetAccess = public, SetAccess = protected)
        % Location is an M-by-3 or M-by-N-by-3 matrix. Each entry specifies
        % the x, y, z coordinates of a point.
        Location = single([]);
    end

    properties(Dependent)
        % Count specifies the number of points in the point cloud.
        Count;
        % XLimits is a 1-by-2 vector that specifies the range of point
        % locations along X axis.
        XLimits;
        % YLimits is a 1-by-2 vector that specifies the range of point
        % locations along Y axis.
        YLimits;
        % ZLimits is a 1-by-2 vector that specifies the range of point
        % locations along Z axis.
        ZLimits;
    end

    properties (Access = public)
        % Color is an M-by-3 or M-by-N-by-3 uint8 matrix. Each entry
        % specifies the RGB color of a point.
        Color = uint8([]);

        % Normal is an M-by-3 or M-by-N-by-3 matrix. Each entry
        % specifies the x, y, z component of a normal vector.
        Normal = single([]);

        % Intensity is an M-by-1 or M-by-N matrix. Each entry
        % specifies the grayscale intensity of a point.
        Intensity = single([]);
    end

    properties(Access = public, Hidden)
        %RangeData Range data
        %   RangeData is an M-by-3 or M-by-N-by-3 matrix containing range
        %   data for each point. Range data is specified as range, pitch
        %   and yaw.
        RangeData = single([]); % 2018a
    end

    properties(Access = protected, Transient)
        Kdtree = [];
    end

    properties(Access = protected)
        %3.0 R2019b
        %4.0 R2020b: Major refactor
        Version = 4.0;
    end

    properties(Access = protected, Transient)
        IsSimulation;
    end

    properties(Access = protected)
        %Internal cache for the dependent axes limits properties
        XLimitsInternal;
        YLimitsInternal;
        ZLimitsInternal;
    end


    methods
        %------------------------------------------------------------------
        % Constructor
        %------------------------------------------------------------------
        function this = pointCloudBase(varargin)

            this.initializeTargetMode;

            this.pcshs('pointCloud');

            narginchk(1, 7);

            [xyzPoints, C, nv, I, rangeData] = this.validateAndParseInputs(varargin{:});

            this.Location = xyzPoints;

            this.Color     = C;
            this.Normal    = nv;
            this.Intensity = I;
            this.RangeData = rangeData;
        end
    end

    % Abstract methods for the public APIs
    methods (Access=public, Abstract)
        [indices, dists] = findNearestNeighbors(this, varargin)
        [indices, dists, numNeighbors] = findNeighborsInRadius(this, varargin)
        indices = findPointsInROI(this, varargin)
        ptCloudOut = select(this, varargin)
        [ptCloudOut, indicesOut] = removeInvalidPoints(this)
        indices = findPointsInCylinder(this, varargin)
    end

    methods (Access=public, Abstract, Hidden)
        %Abstract methods for public internal tools
        [indices, dists, valid] = multiQueryKNNSearchImpl(this, points, K)
        [indices, dists, valid] = multiQueryRadiusSearchImpl(this, points, radius)
        normals = surfaceNormalImpl(this, K)
    end

    methods (Access=protected, Abstract)
        %Abstract methods for helper functions
        initializeTargetMode(this)

        lim = computeLimits(this, axis)

        allDists = bruteForce(this, point)

        [indices, dists] = kdtreeKNNSearch(this, point, K, maxLeafChecks)
        [indices, dists, numNeighbors] = kdtreeRadiusSearch(this, point, radius, maxLeafChecks)
        indices = kdtreeBoxSearch(this, roi)

        [indices, dists] = approximateOrganizedKNNSearch(this, point, K, camMatrix)
        [indices, dists] = approximateOrganizedRadiusSearch(this, point, radius, camMatrix)
        indices = approximateOrganizedBoxSearch(this, roi, camMatrix)
    end

    methods
        %------------------------------------------------------------------
        % Writable Property
        %------------------------------------------------------------------
        function set.Color(this, value)

            this.Color = this.validateColor(value, this.Location); %#ok<MCSUP>
        end
        %------------------------------------------------------------------
        function set.Normal(this, value)

            this.Normal = this.validateNormal(value, this.Location); %#ok<MCSUP>
        end
        %------------------------------------------------------------------
        function set.Intensity(this, value)

            this.Intensity = this.validateIntensity(value, this.Location); %#ok<MCSUP>
        end
        %------------------------------------------------------------------
        function set.RangeData(this, value)

            this.RangeData = this.validateRange(value, this.Location); %#ok<MCSUP>
        end

        %------------------------------------------------------------------
        % Dependent Property
        %------------------------------------------------------------------
        function count = get.Count(this)

            if ~this.isOrganized
                count = size(this.Location, 1);
            else
                count = size(this.Location, 1) * size(this.Location, 2);
            end
        end

        %------------------------------------------------------------------
        function xlim = get.XLimits(this)

            if(isempty(this.XLimitsInternal))
                this.XLimitsInternal = this.computeLimits(1);
            end

            xlim = this.XLimitsInternal;
        end

        %------------------------------------------------------------------
        function ylim = get.YLimits(this)

            if(isempty(this.YLimitsInternal))
                this.YLimitsInternal = this.computeLimits(2);
            end

            ylim = this.YLimitsInternal;
        end

        %------------------------------------------------------------------
        function zlim = get.ZLimits(this)

            if(isempty(this.ZLimitsInternal))
                this.ZLimitsInternal = this.computeLimits(3);
            end

            zlim = this.ZLimitsInternal;
        end
    end

    methods (Access=public, Hidden)

        %------------------------------------------------------------------
        % helper function to get subset for each property
        %------------------------------------------------------------------
        function [loc, c, nv, intensity, r] = subsetImpl(this, indices, outputSize)
            this.pcshs;

            if nargin < 3
                outputSize = 'selected';
            end

            [loc, c, nv, intensity, r] = pointclouds.internal.pc.getSubset( ...
                this.Location, this.Color, this.isOrganized, this.Normal, ...
                this.Intensity, this.RangeData, indices, outputSize);
        end

    end

    methods (Access=protected)
        %------------------------------------------------------------------
        % K nearest neighbor search implementation
        %------------------------------------------------------------------
        function [indices, dists] = findNearestNeighborsImpl(this, varargin)

            this.pcshs;
            this.arrayNotSupported('findNearestNeighbors');

            if(this.Count==0) % Empty point cloud
                indices = cast([],'uint32');
                dists = cast([],class(this.Location));
                return;
            end

            [points, K, camMatrix, doSort, maxLeafChecks] = this.validateAndParseKnnSearchOption(varargin{:});

            points = cast(points, class(this.Location));
            numQueryPoints = size(points, 1);
            K = min(double(K), numel(this.Location)/3);

            if numQueryPoints==1 % Single query
                if this.Count < 500
                    % Use brute-force if there are fewer than 500 points
                    [indices, dists] = this.bruteForceKNNSearch(points, K);

                elseif ~isempty(camMatrix)
                    % Use fast approximate search for organized point clouds
                    % when camera matrix is provided
                    [indices, dists] = this.approximateOrganizedKNNSearch(...
                        points, K, camMatrix);

                else
                    % Use k-d tree based search
                    [indices, dists] = this.kdtreeKNNSearch(points, K, ...
                        maxLeafChecks);
                end

                % Sort the result if specified
                if doSort
                    [dists, ind] = sort(dists);
                    indices = indices(ind);
                end

                if nargout > 1
                    dists = sqrt(dists);
                end
            else % Multiple queries
                if ~isempty(camMatrix)
                    % Use fast approximate search for organized point clouds
                    % when camera matrix is provided
                    dists = zeros(K,numQueryPoints, class(this.Location));
                    indices = zeros(K,numQueryPoints, "uint32");
                    isFirstValidQueryPoint = true;

                    for i=1:coder.internal.indexInt(numQueryPoints)
                        isQueryPointInvalid = any(isnan(points(i,:)));
                        if ~isQueryPointInvalid
                            if isFirstValidQueryPoint==true
                                isFirstValidQueryPoint = false;
                                [indicesFirst, distsFirst] = this.approximateOrganizedKNNSearch(...
                                    points(i,:), K, camMatrix);
                                validK = size(indicesFirst,1);
                                dists = zeros(validK,numQueryPoints, class(this.Location));
                                indices = zeros(validK,numQueryPoints, "uint32");
                                indices(:,i) = indicesFirst;
                                dists(:,i) = distsFirst;
                            else
                                [indices(:,i), dists(:,i)] = this.approximateOrganizedKNNSearch(...
                                    points(i,:), K, camMatrix);
                            end

                            % Sort the result if specified
                            if doSort
                                [dists(:,i), ind] = sort(dists(:,i));
                                indices(:,i) = indices(ind,i);
                            end
                        end
                    end
                else
                    % Use k-d tree based search, result is already sorted
                    [indices, dists] = this.kdtreeKNNSearch(points, K, ...
                        maxLeafChecks);
                end

                if nargout > 1
                    dists = sqrt(dists);
                end
            end
        end

        %------------------------------------------------------------------
        % Radius search implementation
        %------------------------------------------------------------------
        function [indices, dists, numNeighbors] = findNeighborsInRadiusImpl(this, varargin)

            this.pcshs;
            this.arrayNotSupported('findNeighborsInRadius');

            [points, radius, camMatrix, doSort, maxLeafChecks] = ...
                this.validateAndParseRadiusSearchOption(varargin{:});

            points = cast(points, class(this.Location));
            numQueryPoints = size(points,1);
            radius = double(radius);

            if(this.Count==0) % Empty point cloud
                if (numQueryPoints==1) && coder.internal.isConst(size(points))
                    indices = coder.nullcopy(zeros(coder.ignoreConst(0),coder.ignoreConst(0),'uint32'));
                    dists = coder.nullcopy(zeros(coder.ignoreConst(0),coder.ignoreConst(0),'like',this.Location));
                else
                    indices = coder.nullcopy({});
                    dists = coder.nullcopy({});
                end
                numNeighbors = zeros([numQueryPoints, 1], 'uint32');
                return;
            end

            if (numQueryPoints==1) && coder.internal.isConst(size(points)) % Single query
                useRangeSearch = this.isOrganized && all(points==0) && ~isempty(this.RangeData);
                if this.Count < 500
                    % Use brute-force if there are fewer than 500 points
                    [indices, dists] = this.bruteForceRadiusSearch(points, radius);

                elseif ~isempty(camMatrix)
                    % Use fast approximate search for organized point clouds
                    % when camera matrix is provided
                    [indices, dists] = this.approximateOrganizedRadiusSearch(...
                        points, radius, camMatrix);

                elseif useRangeSearch
                    % Use range for Lidar point clouds if query point is the
                    % origin
                    [indices, dists] = this.rangeBasedRadiusSearch(radius);

                else
                    % Use k-d tree based search
                    [indices, dists] = this.kdtreeRadiusSearch(points, radius, ...
                        maxLeafChecks);
                end

                % Sort the result if specified
                if doSort
                    [dists, ind] = sort(dists);
                    indices = indices(ind);
                end

                if nargout > 1 && ~useRangeSearch
                    dists = sqrt(dists);
                end

                if nargout > 2
                    numNeighbors = uint32(size(indices,1));
                end
            else % Multiple queries
                if ~isempty(camMatrix)
                    dists = coder.nullcopy(cell(numQueryPoints, 1));
                    indices = coder.nullcopy(cell(numQueryPoints, 1));
                    numNeighbors = zeros(numQueryPoints, 1, "uint32");
                    for i=1:coder.internal.indexInt(numQueryPoints)
                        isQueryPointInvalid = any(isnan(points(i,:)));
                        if ~isQueryPointInvalid
                            % Use fast approximate search for organized point clouds
                            % when camera matrix is provided
                            [indices{i}, dists{i}] = this.approximateOrganizedRadiusSearch(...
                                points(i,:), radius, camMatrix);
                            % Sort the result if specified
                            if doSort
                                [dists{i}, ind] = sort(dists{i});
                                indices{i} = indices{i}(ind);
                            end
                            numNeighbors(i) = uint32(size(indices{i,1},1));
                        else
                            numNeighbors(i) = uint32(0);
                        end
                    end
                else
                    % Use k-d tree based search
                    [indices, dists, numNeighbors] = this.kdtreeRadiusSearch(points, radius, ...
                        maxLeafChecks);
                end

                if nargout > 1
                    dists = cellfun(@sqrt, dists, 'UniformOutput', false);
                end
            end
        end

        %------------------------------------------------------------------
        % Box search implementation
        %------------------------------------------------------------------
        function indices = findPointsInROIImpl(this, varargin)

            this.pcshs;
            this.arrayNotSupported('findPointsInROI');

            [roi, camMatrix] = this.validateAndParseBoxSearchOption(varargin{:});

            if ~isempty(camMatrix)
                % Use fast approximate search for organized point clouds
                % when camera matrix is provided
                indices = this.approximateOrganizedBoxSearch(roi, camMatrix);

            else
                % Replacing the kdTreeBoxSearch with bruteForceBoxSearch
                % for better performance in simulation and codegen
                indices = this.bruteForceBoxSearch(roi);
            end
        end
        %------------------------------------------------------------------
        % Cylindrical neighborhood search implementation
        %------------------------------------------------------------------
        function indices = findPointsInCylinderImpl(this, varargin)

            this.pcshs;
            this.arrayNotSupported('findPointsInCylinder');

            [radius, height, center, verticalAxis] = validateAndParseFindPointsInCylinder(varargin{:});

            % radius can be a scalar or a 2-element vector.
            if numel(radius) == 1
                rMin = 0;
                rMax = radius;
            else
                rMin = radius(1);
                rMax = radius(2);
            end

            % Rotate the coordinate frame if vertical axis is specified as 'X' or 'Y'.
            if strcmpi(verticalAxis, 'Z')
                xaxisIdx = 1;
                yaxisIdx = 2;
                zaxisIdx = 3;
            elseif strcmpi(verticalAxis, 'X')
                xaxisIdx = 2;
                yaxisIdx = 3;
                zaxisIdx = 1;
            else % Y-up
                xaxisIdx = 3;
                yaxisIdx = 1;
                zaxisIdx = 2;
            end

            % If rMin is set to 0, comparison can be skipped.
            rMinCheck = rMin ~= 0;

            % If all points already lie within the cylinder radius rMax, comparison can be skipped.
            rMaxCheck = (max(abs(this.XLimits - center(xaxisIdx)), [], 2).^2 + max(abs(this.YLimits - center(yaxisIdx)), [], 2).^2) > rMax;

            % If user inputs non-infinite value for Height, comparison is needed in the z-direction.
            zCheck = ~isinf(height);

            % Determine whether the input pointCloud is organized. Return the same format.
            isOrganized = ndims(this.Location) == 3;

            % Compute the lower and upper bounds in up-direction using input Height;
            zMin = center(zaxisIdx) - height/2;
            zMax = center(zaxisIdx) + height/2;

            if isOrganized
                x = this.Location(:, :, xaxisIdx);
                y = this.Location(:, :, yaxisIdx);
                z = this.Location(:, :, zaxisIdx);
                indices = logical(ones(size(this.Location, 1:2)));
            else
                x = this.Location(:, xaxisIdx);
                y = this.Location(:, yaxisIdx);
                z = this.Location(:, zaxisIdx);
                indices = logical(ones(size(this.Location, 1), 1));
            end

            switch sum([rMinCheck, rMaxCheck, zCheck])
                case 1
                    if rMaxCheck
                        % Most common case, solid cylinder without height limit.
                        distanceSquare = this.squaredDistance(x, y, center, xaxisIdx, yaxisIdx);
                        indices = distanceSquare <= rMax^2;

                    elseif rMinCheck
                        % Also common, exclude a solid cylinder around the origin.
                        distanceSquare = this.squaredDistance(x, y, center, xaxisIdx, yaxisIdx);
                        indices = distanceSquare >= rMin^2;

                    else % Apply zCheck
                        indices = z <= zMax & z >= zMin;
                    end

                case 2
                    distanceSquare = this.squaredDistance(x, y, center, xaxisIdx, yaxisIdx);
                    if ~zCheck
                        % Also a common use case, a hollow cylinder with inf-heights.
                        indices = distanceSquare <= rMax^2 & distanceSquare >= rMin^2;

                    elseif ~rMinCheck % rMaxCheck + zCheck
                        indices = distanceSquare <= rMax^2 & z <= zMax & z >= zMin;

                    else % rMinCheck + zCheck
                        indices = distanceSquare >= rMin^2 & z <= zMax & z >= zMin;
                    end

                case 3
                    % In this case, all comparison needs to take place.
                    distanceSquare = this.squaredDistance(x, y, center, xaxisIdx, yaxisIdx);
                    indices = distanceSquare <= rMax^2 & distanceSquare >= rMin^2 & z <= zMax & z >= zMin;
            end
        end

        %------------------------------------------------------------------
        % helper function for extractValidPoints
        %------------------------------------------------------------------
        function indices = extractValidPointsImpl(this)

            tf = isfinite(this.Location);

            if ~this.isOrganized
                indices = (sum(tf, 2) == 3);
            else
                indices = (sum(reshape(tf, [], 3), 2) == 3);
            end
        end

        %------------------------------------------------------------------
        % helper functions for approximateOrganized Search functions
        %------------------------------------------------------------------
        function [projectionOfPoint, KRKRT] = computeProjectedPoints(~,point, camMatrix)

            camMatrix = cast(camMatrix, class(point));

            % Product of Camera and Rotation Matrix
            KR = camMatrix(1:3, :);
            KRKRT = KR * KR';

            projectionOfPoint = point * KR + camMatrix(4, :);
        end

        %------------------------------------------------------------------
        function projectionOfPoints = computeProjectedPointsInBox(~, KR, roi, Kt)

            % Calculate the corner points of bounding box
            bBoxPoints = [roi(1,1) roi(2,1) roi(3,1);...
                roi(1,1) roi(2,1) roi(3,2);...
                roi(1,1) roi(2,2) roi(3,1);...
                roi(1,2) roi(2,1) roi(3,1);...
                roi(1,2) roi(2,2) roi(3,2);...
                roi(1,2) roi(2,2) roi(3,1);...
                roi(1,2) roi(2,1) roi(3,2);...
                roi(1,1) roi(2,2) roi(3,2)];

            projectionOfPoints = bBoxPoints * KR + Kt;
        end

        %------------------------------------------------------------------
        function [tf, height, width, minRowPt, minColPt] = findPointsInBox(this, projectionOfPoints, roi)

            colPts = ((projectionOfPoints(:,1) ./ projectionOfPoints(:,3)));
            rowPts = ((projectionOfPoints(:,2) ./ projectionOfPoints(:,3)));

            minRowPt = floor(min(rowPts));
            maxRowPt = ceil(max(rowPts));
            minColPt = floor(min(colPts));
            maxColPt = ceil(max(colPts));

            [height, width , ~] = size(this.Location);

            minRowPt = min(height, max(1, minRowPt+1));
            minColPt = min(width, max(1, minColPt+1));

            maxRowPt = min(height, max(1, maxRowPt+1));
            maxColPt = min(width, max(1, maxColPt+1));

            reducedCloud = this.Location(minRowPt:maxRowPt, minColPt:maxColPt, :);
            X = reducedCloud(:,:,1);
            Y = reducedCloud(:,:,2);
            Z = reducedCloud(:,:,3);

            tf = X >= roi(1,1) & X <= roi(1,2);
            tf = tf & Y >= roi(2,1) & Y <= roi(2,2);
            tf = tf & Z >= roi(3,1) & Z <= roi(3,2);
        end

    end

    methods (Access = protected)
        %------------------------------------------------------------------
        function flag = isOrganized(this)
            %Returns true if the given pointCloud is an organized point
            %cloud. Note: isOrganized is a method instead of a non-tunable
            %property to assist constant folding in set & get methods.
            flag = ~ismatrix(this.Location);
        end

        %------------------------------------------------------------------
        function arrayNotSupported(this, functionName)

            if ~isscalar(this)
                coder.internal.error('vision:pointcloud:arrayNotSupported', functionName);
            end
        end

        %------------------------------------------------------------------
        function pcshs(~,varargin)

            if nargin == 1
                sourceName = '';
            else
                sourceName = varargin{1};
            end

            if isempty(coder.target)
                try
                    pointclouds.internal.pc.shs(sourceName);
                catch ME
                    throwAsCaller(ME)
                end
            end
        end
    end

    methods (Access=private)
        %------------------------------------------------------------------
        % Brute Force Search functions
        %------------------------------------------------------------------
        function [indices, dists] = bruteForceKNNSearch(this, point, K)

            allDists = bruteForce(this, point);

            % This function will ensure returning actual number of neighbors
            % The result is already sorted
            [dists, indices] = vision.internal.partialSort(allDists, K);
            tf = isfinite(dists);
            indices = indices(tf);
            dists = dists(tf);
        end

        %------------------------------------------------------------------
        function [indices, dists] = bruteForceRadiusSearch(this, point, radius)

            allDists = bruteForce(this, point);

            indices = uint32(find(allDists <= radius^2))';

            if(~this.IsSimulation && isempty(indices))
                dists = zeros(size(indices), 'like', allDists);
            else
                dists   = allDists(indices)';

                % Filter out anything that is not finite
                isFinite = isfinite(dists);

                indices = indices(isFinite);
                dists   = dists(isFinite);
            end
        end

        %------------------------------------------------------------------
        function indices = bruteForceBoxSearch(this, roi)
            % Scalarized code is more appropriate to code generation mode
            % for better run-time performance

            if this.isOrganized
                ptCloudCoords = reshape(this.Location,[],3);
            else
                ptCloudCoords = this.Location;
            end

            % Getting the number of points in pointcloud
            numPoints = coder.internal.indexInt(this.Count);

            inROI = false(numPoints,1);
            zOffset = coder.internal.indexInt(2*numPoints);

            % Search through the points
            if isempty(coder.target)
                inROI = ...
                    ptCloudCoords(:,1) >= roi(1)  & ...
                    ptCloudCoords(:,1) <= roi(4)  & ...
                    ptCloudCoords(:,2) >= roi(2)  & ...
                    ptCloudCoords(:,2) <= roi(5)  & ...
                    ptCloudCoords(:,3) >= roi(3)  & ...
                    ptCloudCoords(:,3) <= roi(6);
            else
                for ptIter = 1:numPoints
                    if coder.isColumnMajor
                        inROI(ptIter) = ptCloudCoords(ptIter)>=roi(1) & ptCloudCoords(ptIter)<=roi(4) ...
                            & ptCloudCoords(ptIter + numPoints)>=roi(2) & ptCloudCoords(ptIter + numPoints)<=roi(5) ...
                            & ptCloudCoords(ptIter + zOffset)>=roi(3) & ptCloudCoords(ptIter + zOffset)<=roi(6);
                    else
                        inROI(ptIter) = ptCloudCoords(ptIter,1)>=roi(1) & ptCloudCoords(ptIter,1)<=roi(4) ...
                            & ptCloudCoords(ptIter,2)>=roi(2) & ptCloudCoords(ptIter,2)<=roi(5) ...
                            & ptCloudCoords(ptIter,3)>=roi(3) & ptCloudCoords(ptIter,3)<=roi(6);
                    end
                end
            end
            % Finding the indices within ROI
            indices = uint32(find(inROI));
        end
        %------------------------------------------------------------------
        % Range Based Search functions
        %------------------------------------------------------------------
        function [indices, dists] = rangeBasedRadiusSearch(this, radius)

            % Use range data directly if query point is the
            % origin
            range = this.RangeData(:,:,1);

            indices = uint32(find(range <= radius));
            dists   = range(indices);
        end

        %------------------------------------------------------------------
        % Helper function to compute the squared distance
        %------------------------------------------------------------------
        function indices = squaredDistance(this, x, y, center, xaxisIdx, yaxisIdx)
            indices = (x - center(xaxisIdx)).^2 + (y - center(yaxisIdx)).^2;
        end
    end

    methods (Access=protected, Abstract)
        %Abstract methods for validation functions
        [xyzPoints, color, normal, intensity, rangeData] = validateAndParseInputs(this, varargin)
        validateXYZPoints(this, xyzPoints)

        [point, radius, camMatrix, doSort, maxLeafChecks] = validateAndParseRadiusSearchOption(this,varargin)
        [point, K, camMatrix, doSort, maxLeafChecks] = validateAndParseKnnSearchOption(this,varargin)
        [roi, camMatrix] = validateAndParseBoxSearchOption(this,varargin)
        [radius, height, center, verticalAxis] = validateAndParseFindPointsInCylinder(this, varargin)
    end

    methods (Access=protected)
        %------------------------------------------------------------------
        % parameter validation
        %------------------------------------------------------------------
        function validateMaxLeafChecks(~,value)

            % Validate MaxLeafChecks
            if any(isinf(value))
                validateattributes(value,{'double'}, {'real','nonsparse','scalar','positive'});
            else
                validateattributes(value,{'double'}, {'real','nonsparse','scalar','nonnan','integer','positive'});
            end
        end
        %------------------------------------------------------------------
        function validateQueryPoints(~,points)
            
            validateattributes(points, {'single', 'double'}, ...
                {'real', 'nonsparse', 'nonnan', 'finite', 'nonempty', 'size', [NaN, 3]}, '', 'points');
        end
        %------------------------------------------------------------------
        function validateK(~,K)

            validateattributes(K, {'single', 'double'}, ...
                {'real', 'nonsparse', 'scalar', 'nonnan', 'finite', 'integer', 'positive'}, '', 'K');
        end
        %------------------------------------------------------------------
        function validateCamMatrix(~,camMatrix)

            if(~isempty(camMatrix))
                validateattributes(camMatrix, {'single', 'double'}, ...
                    {'real', 'nonsparse', 'nonnan', 'finite', 'size', [4, 3]}, '', 'camMatrix');
            end
        end
        %------------------------------------------------------------------
        function validateSort(~,sort)

            validateattributes(sort, {'logical'}, {'scalar'});
        end
        %------------------------------------------------------------------
        function validateRadius(~,r)

            validateattributes(r, {'single', 'double'}, ...
                {'real', 'nonsparse', 'scalar', 'nonnan', 'finite', 'nonnegative'}, '', 'radius');
        end
        %------------------------------------------------------------------
        function validateROI(~,roi)

            validateattributes(roi, {'single', 'double'}, ...
                {'real', 'nonsparse', 'nonnan', 'numel', 6}, '', 'roi');
        end
        %------------------------------------------------------------------
        function tf = checkOutputSize(~,value)

            validatestring(value,{'selected','full'});
            tf = true;
        end
        %------------------------------------------------------------------
        function I = validateIntensity(~, value, xyzPoints)

            % Numeric objects not supported such as gpuArray
            pointclouds.internal.validateNotObject(value,'pointCloud','Intensity');

            % Check non-size attributes.
            validTypes = {'uint8', 'uint16', 'single', 'double'};
            validateattributes(value, validTypes, {'real', 'nonsparse'}, ...
                'pointCloud', 'Intensity');

            % Check size attributes.
            if ~isempty(value)
                isOrganizedPtCloud = ~ismatrix(xyzPoints);
                if isOrganizedPtCloud
                    coder.internal.errorIf( ...
                        ~(ismatrix(value) && ...
                        size(value,1)==size(xyzPoints,1) && ...
                        size(value,2)==size(xyzPoints,2)), ...
                        'vision:pointcloud:unmatchedXYZIntensity');
                else
                    coder.internal.errorIf( ...
                        ~(iscolumn(value) && ...
                        size(value,1)==size(xyzPoints,1) && ...
                        size(value,2)==1), ...
                        'vision:pointcloud:unmatchedXYZIntensity');
                end
            end

            % Convert single or double intensity values to same type as of
            % xyzPoints.
            if isa(value, 'uint8') || isa(value, 'uint16')
                I = value;
            else
                I = cast(value, 'like', xyzPoints);
            end
        end
        %------------------------------------------------------------------
        function color = validateColor(~, input, xyzPoints)

            % Check non-size attributes.
            validTypes = {'uint8', 'uint16', 'single', 'double', ...
                'string', 'char'};
            validateattributes(input, validTypes, {'real', 'nonsparse'}, ...
                'pointCloud', 'Color');

            % Validate range of color values for single or double datatypes.
            if isa(input, 'single') || isa(input, 'double')

                isInputOutOfRange = any(input < 0 | input > 1 | ...
                    isinf(input) | isnan(input), 'all');

                coder.internal.errorIf(isInputOutOfRange, ...
                    'vision:pointcloud:colorOutOfRange')
            end

            % Process the color value based on the syntax used.
            isInputScalarRGBTriplet = isequal(size(input), [1 3]);
            isInputColorString = ischar(input) || isstring(input);

            if isInputColorString || isInputScalarRGBTriplet

                if isInputColorString
                    % Convert color string to an RGB triplet.
                    rgbTriplet = pointclouds.internal.convertColorSpecToRGB(input, ...
                        'uint8', 'pointCloud', 'Color');
                else
                    rgbTriplet = input;
                end

                % Reshape 1-by-3 triplet to 1-by-1-by-3 triplet for
                % organized point clouds.
                isOrganizedPtCloud = ~ismatrix(xyzPoints);
                if isOrganizedPtCloud
                    rgb = reshape(rgbTriplet, [1 1 3]);
                else
                    rgb = rgbTriplet;
                end

                % Get the number of points in each dimension of the point
                % cloud which can be [M,1] or [M,N,1] depending on its organization.
                numPoints = [size(xyzPoints, 1:ndims(xyzPoints)-1) 1];

                % Expand scalar RGB triplet to an array.
                value = repmat(rgb, numPoints);
            else

                % Numeric objects not supported such as gpuArray
                pointclouds.internal.validateNotObject(input,'pointCloud','Color');

                % Check size attributes.
                coder.internal.errorIf( ...
                    ~isempty(input) && ...
                    ~isequal(size(input), size(xyzPoints)), ...
                    'vision:pointcloud:unmatchedXYZColor');

                value = input;
            end

            % Convert single or double color values to uint8.
            if isa(value, 'uint8') || isa(value, 'uint16')
                color = value;
            else
                % im2uint8 cannot be used here as there cannot be a dependency
                % on IPT which is not a shared library or belong to
                % matlab.
                color = uint8(255*value);
            end
        end
        %------------------------------------------------------------------
        function normal = validateNormal(~, value, xyzPoints)

            % Numeric objects not supported such as gpuArray
            pointclouds.internal.validateNotObject(value,'pointCloud','Normal');

            % Check non-size attributes
            validateattributes(value, {'single', 'double'}, ...
                {'real', 'nonsparse'}, 'pointCloud', 'Normal');

            % Check size attributes
            coder.internal.errorIf( ...
                ~isempty(value) && ...
                ~isequal(size(value), size(xyzPoints)), ...
                'vision:pointcloud:unmatchedXYZNormal');

            normal = cast(value, 'like', xyzPoints);
        end
        %------------------------------------------------------------------
        function range = validateRange(~, value, xyzPoints)

            % Check non-size attributes
            validateattributes(value,{'single', 'double'}, ...
                {'real','nonsparse'}, 'pointCloud');

            % Check size attributes
            coder.internal.errorIf( ...
                ~isempty(value) && ...
                ~isequal(size(value), size(xyzPoints)), ...
                'vision:pointcloud:unmatchedXYZRange');

            range = cast(value, 'like', xyzPoints);
        end
        %------------------------------------------------------------------
        function validateInputRadius(~, input)
            if isscalar(input)
                validateattributes(input, {'single', 'double'}, {'positive'}, 'findPointsInCylinder', 'radius');
            else
                validateattributes(input, {'single', 'double'}, {'numel', 2, 'nonnegative', 'increasing'}, 'findPointsInCylinder', 'radius');
            end
        end
        %------------------------------------------------------------------
        function validateCenter(~, input)
            validateattributes(input, {'single', 'double'}, {'numel', 3, 'real', 'finite'}, 'findPointsInCylinder', 'Center');
        end

    end

    %----------------------------------------------------------------------
    % Constant Folding Assistance
    %----------------------------------------------------------------------
    methods (Static, Hidden)
        %------------------------------------------------------------------
        function props = matlabCodegenNontunableProperties(~)

            props = {'IsSimulation'};
        end
    end
end
