classdef pointCloud < matlab.mixin.Copyable & pointclouds.internal.pointCloudBase
    
    % Copyright 2014-2024 The MathWorks, Inc.
    
    %#codegen
    
    methods
        %------------------------------------------------------------------
        % Constructor
        %------------------------------------------------------------------
        function this = pointCloud(varargin)
            
            this = this@pointclouds.internal.pointCloudBase(varargin{:});
        end
        
        %------------------------------------------------------------------
        % K nearest neighbor search
        %------------------------------------------------------------------
        function [indices, dists] = findNearestNeighbors(this, varargin)
            [indices, dists] = this.findNearestNeighborsImpl(varargin{:});
        end
        
        %------------------------------------------------------------------
        % Radius search
        %------------------------------------------------------------------
        function [indices, dists, numNeighbors] = findNeighborsInRadius(this, varargin)
            [indices, dists, numNeighbors] = this.findNeighborsInRadiusImpl(varargin{:});
        end
        
        %------------------------------------------------------------------
        % Box search
        %------------------------------------------------------------------
        function indices = findPointsInROI(this, varargin)
            indices = this.findPointsInROIImpl(varargin{:});
        end

        %------------------------------------------------------------------
        % 
        %------------------------------------------------------------------
        function indices = findPointsInCylinder(this, varargin)
            indices = this.findPointsInCylinderImpl(this, varargin{:});
        end
        
        %------------------------------------------------------------------
        % Obtain a subset of this point cloud object
        %------------------------------------------------------------------
        function ptCloudOut = select(this, varargin)
            
            this.pcshs;
            narginchk(2, 5);
            
            this.arrayNotSupported('select');
            
            if  ~bitget(nargin, 1) % select(this, indices)
                [indices, outputSize] = this.validateAndParseSelectIndices(varargin{:});
            else
                % Subscript syntax is only for organized point cloud
                if ~this.isOrganized
                    error(message('vision:pointcloud:organizedPtCloudOnly'));
                end
                [indices, outputSize] = this.validateAndParseSelectSubscripts(varargin{:});
            end
            
            % Obtain the subset for every property
            [loc, c, nv, intensity, r] = this.subsetImpl(indices, outputSize);
            
            ptCloudOut = pointCloud(loc, 'Color', c, 'Normal', nv, ...
                'Intensity', intensity);
            ptCloudOut.RangeData = r;
        end
        
        %------------------------------------------------------------------
        function [ptCloudOut, indicesOut] = removeInvalidPoints(this)
            
            [location, color, normals, intensity, rangeData, indices] = ...
                this.extractValidPoints();
            
            ptCloudOut = pointCloud(location, 'Color', color, 'Normal', ...
                normals, 'Intensity', intensity);
            ptCloudOut.RangeData = rangeData;
            if nargout > 1
                
                indicesOut = find(indices);
            end
        end
        
    end
    
    methods (Access=public, Hidden)
        %------------------------------------------------------------------
        % helper function for removeInvalidPoints that returns valid
        % points. This function is helpful if a copy of pointCloud
        % need not be created which is an additional overhead.
        %------------------------------------------------------------------
        function [location, color, normals, intensity, rangeData, indices] = extractValidPoints(this)
            
            this.pcshs;
            this.arrayNotSupported('removeInvalidPoints');
            
            indices = this.extractValidPointsImpl();
            
            [location, color, normals, intensity, rangeData] = this.subsetImpl(indices);
        end
        
        %------------------------------------------------------------------
        % helper function to support multiple queries in KNN search
        % indices, dists: K-by-numQueries
        % valid: numQueries-by-1
        % Note, the algorithm may return less than K results for each
        % query. Therefore, only 1:valid(n) in n-th column of indices and
        % dists are valid results. Invalid indices are all zeros.
        %------------------------------------------------------------------
        function [indices, dists, valid] = multiQueryKNNSearchImpl(this, points, K)
            
            this.pcshs;
            this.arrayNotSupported('multiQueryKNNSearchImpl');
            
            % Validate the inputs
            validateattributes(points, {'single', 'double'}, ...
                {'real', 'nonsparse', 'size', [NaN, 3]}, 'multiQueryKNNSearchImpl', 'points');
            
            points = cast(points, 'like', this.Location);
            
            validateattributes(K, {'single', 'double'}, ...
                {'nonsparse', 'scalar', 'positive', 'integer','real'}, 'multiQueryKNNSearchImpl', 'K');
            
            K = min(double(K), this.Count);
            
            % Use exact search in Kdtree
            searchOpts.eps = 0;
            
            this.buildKdtree();
            [indices, dists, valid] = this.Kdtree.knnSearch(points, K, searchOpts);
        end
        
        %------------------------------------------------------------------
        % helper function to support multiple queries in radius search
        % indices, dists: returned in cell array of size numQueries-by-1
        % valid: uint32 array of size numQueries-by-1
        % Note: dists contains the squared distances from each query to
        % the indexed data.
        %------------------------------------------------------------------
        function [indices, dists, valid] = multiQueryRadiusSearchImpl(this, points, radius)
            
            this.pcshs;
            this.arrayNotSupported('multiQueryRadiusSearchImpl');
            
            % Validate the inputs
            validateattributes(points, {'single', 'double'}, ...
                {'real', 'nonsparse', 'size', [NaN, 3]}, 'multiQueryRadiusSearchImpl', 'points');
            
            points = cast(points, 'like', this.Location);
            
            validateattributes(radius, {'single', 'double'}, ...
                {'real', 'nonsparse', 'scalar', 'nonnan', 'finite', 'nonnegative'}, 'multiQueryRadiusSearchImpl', 'radius');
            
            radius = double(radius);
            
            % Use exact search in Kdtree
            searchOpts.eps = 0;
            
            this.buildKdtree();
            
            if size(points,1) ~= 1
                [indices, dists, valid] = this.Kdtree.radiusSearch(points, radius, searchOpts);
            else
                [indices{1}, dists{1}, valid] = this.Kdtree.radiusSearch(points, radius, searchOpts);
            end
        end
        
        %------------------------------------------------------------------
        % helper function to compute normals
        % normals: the same size of the Location matrix
        %
        % Note, the algorithm uses PCA to fit local planes around a point,
        % and chooses the normal direction (inward/outward) arbitrarily.
        %------------------------------------------------------------------
        function normals = surfaceNormalImpl(this, K)
            
            this.pcshs;
            
            % Reset K if there are not enough points
            K = min(double(K), this.Count);
            
            if this.Count <= 2
                normals = NaN(size(this.Location), 'like', this.Location);
                return;
            end
            
            this.buildKdtree();
            
            if this.isOrganized
                loc = reshape(this.Location, [], 3);
            else
                loc = this.Location;
            end
            
            % Use exact search in Kdtree
            searchOpts.eps = 0;
            % Setting the small grainsize (default = 2000) leads to
            % relatively high proportion of overheads. To overcome the
            % overheads caused by threads, need to increase the grainsize
            % with known parameter. TBB uses the auto_partitioner(default)
            % performs automatic chunk size as "grainsize/2 <= chunksize".
            % Choosing the optimum grainsize as "this.Count * 1.5" is
            % giving the significant performance. 
            searchOpts.grainSize = this.Count * 1.5;
            
            % Find K nearest neighbors for each point
            [indices, ~, valid] = this.Kdtree.knnSearch(loc, K, searchOpts);
            
            % Find normal vectors for each point
            normals = visionPCANormal(loc, indices, valid);
            
            if this.isOrganized
                normals = reshape(normals, size(this.Location));
            end
        end
    end
    
    methods(Access=protected)
        %------------------------------------------------------------------
        % helper function for bruteForce methods
        %------------------------------------------------------------------
        function allDists = bruteForce(this, point)

            % helper function for bruteForceKNNSearch and bruteForceRadiusSearch
            if this.isOrganized
                allDists = images.internal.builtins.SSDMetric(point', reshape(this.Location, [], 3)');
            else
                allDists = images.internal.builtins.SSDMetric(point', this.Location');
            end
        end
        
        %------------------------------------------------------------------
        % kdtree methods
        %------------------------------------------------------------------
        function [indices, dists] = kdtreeKNNSearch(this, points, K, maxLeafChecks)
            
            searchOpts.eps = 0;
            
            this.buildKdtree();
            [indices, dists, valid] = this.Kdtree.knnSearch(points, K, searchOpts);
            
            if size(points, 1) == 1
                % This step will ensure returning actual number of neighbors
                indices = indices(1:valid);
                dists = dists(1:valid);
            end
        end
        
        %------------------------------------------------------------------
        function [indices, dists, numNeighbors] = kdtreeRadiusSearch(this, point, radius, maxLeafChecks)
            
            searchOpts.eps = 0;
            
            this.buildKdtree();
            
            [indices, dists, numNeighbors] = this.Kdtree.radiusSearch(point, radius, searchOpts);
        end
        
        %------------------------------------------------------------------
        function indices = kdtreeBoxSearch(this, roi)
            
            this.buildKdtree();
            indices = this.Kdtree.boxSearch(roi);
            
            % Sort the indices as the output of the organized
            % method provides sorted indices.
            indices = sort(indices);
        end
        
        
        %------------------------------------------------------------------
        % approximateOrganized methods
        %------------------------------------------------------------------
        function [indices, dists] = approximateOrganizedKNNSearch(this, point, K, camMatrix)
            
            coder.internal.errorIf(~this.isOrganized, 'vision:pointcloud:organizedPtCloudOnly');
            [projectionOfPoint, KRKRT] = this.computeProjectedPoints(point, camMatrix);
            
            [indices, dists] = visionSearchOrganizedPointCloud(this.Location, ...
                point, K, projectionOfPoint, KRKRT, 'knnSearch');
        end
        
        %------------------------------------------------------------------
        function [indices, dists] = approximateOrganizedRadiusSearch(this, point, radius, camMatrix)
            
            coder.internal.errorIf(~this.isOrganized, 'vision:pointcloud:organizedPtCloudOnly');
            [projectionOfPoint, KRKRT] = this.computeProjectedPoints(point, camMatrix);
            
            [indices, dists] = visionSearchOrganizedPointCloud(this.Location, ...
                point, radius, projectionOfPoint, KRKRT, 'radiusSearch');
        end
        
        %------------------------------------------------------------------
        function indices = approximateOrganizedBoxSearch(this, roi, camMatrix)
            
            coder.internal.errorIf(~this.isOrganized, 'vision:pointcloud:organizedPtCloudOnly');
            
            % Product of Camera and Rotation Matrix
            KR = camMatrix(1:3, :);
            
            projectionOfPoints = this.computeProjectedPointsInBox(KR, roi, camMatrix(4,:));
            
            [tf, height, width, minRowPt, minColPt] = this.findPointsInBox(projectionOfPoints, roi);
            
            % Find the indices of the points which satisfy the constraints
            [row, col] = find(tf);
            
            if ~isempty(row)
                indices = uint32(sub2ind([height, width], row+minRowPt-1, col+minColPt-1));
            else
                indices = uint32([]);
            end
        end
        
    end
    
    methods (Access=protected)
        %------------------------------------------------------------------
        %Initialize all target mode flags
        %------------------------------------------------------------------
        function initializeTargetMode(this)
            
            this.IsSimulation = isempty(coder.target);
        end
        
        %------------------------------------------------------------------
        % helper function for computing XLimits, YLimits and ZLimits
        %------------------------------------------------------------------
        function limits = computeLimits(this, dim)
            
            tf = ~isnan(this.Location);
            
            if ~this.isOrganized
                tf = (sum(tf, 2) == 3);
                limits = [min(this.Location(tf, dim)), max(this.Location(tf, dim))];
            else
                tf = (sum(tf, 3) == 3);
                Ax = this.Location(:, :, dim);
                limits = [min(Ax(tf)), max(Ax(tf))];
            end
        end
        
        %------------------------------------------------------------------
        % helper function to index data
        %------------------------------------------------------------------
        function buildKdtree(this)
            
            if isempty(this.Kdtree)
                % Build a Kdtree to index the data
                this.Kdtree = vision.internal.Kdtree();
                createIndex = true;
            elseif this.Kdtree.needsReindex(this.Location)
                createIndex = true;
            else
                createIndex = false;
            end
            
            if createIndex
                this.Kdtree.index(this.Location);
            end
        end
    end
    
    methods (Access=protected)
        %------------------------------------------------------------------
        function [xyzPoints, color, normal, intensity, rangeData] = validateAndParseInputs(this,xyzPoints, options)
            
            arguments
                this pointCloud
                xyzPoints {validateXYZPoints(this,xyzPoints)}
            end
            arguments
                options.Color     = uint8([])
                options.Normal    = single([])
                options.Intensity = single([])
            end
            
            % Validation of these parameters happen in their respective set
            % methods.
            color     = options.Color;
            normal    = options.Normal;
            intensity = options.Intensity;
            
            if ismatrix(xyzPoints)
                rangeData = zeros(0, 0, 'like', xyzPoints);
            else
                rangeData = zeros(0, 0, 0, 'like', xyzPoints);
            end
        end
        
        %------------------------------------------------------------------
        function validateXYZPoints(~,xyzPoints)
            
            % Numeric objects not supported such as gpuArray
            pointclouds.internal.validateNotObject(xyzPoints,'pointCloud','xyzPoints');

            % Validate non-size attributes
            validateattributes(xyzPoints, {'single', 'double'}, {'real', 'nonsparse' });
            
            isMx3   = ismatrix(xyzPoints) && size(xyzPoints,2)==3;
            isMxNx3 = ndims(xyzPoints)==3 && size(xyzPoints,3)==3;
            
            if ~(isMx3 || isMxNx3)
                error(message('vision:pointcloud:invalidXYZPoints'))
            end
        end
        
        %------------------------------------------------------------------
        % parameter validation for search
        %------------------------------------------------------------------
        function [points, K, camMatrix, doSort, maxLeafChecks] = validateAndParseKnnSearchOption(this, points, K, camMatrix, options)
            
            arguments
                this pointCloud
                points                {validateQueryPoints(this,points)}
                K                     {validateK(this,K)}
                camMatrix             {validateCamMatrix(this,camMatrix)} = []
                options.Sort          {validateSort(this,options.Sort)} = false
                options.MaxLeafChecks {validateMaxLeafChecks(this,options.MaxLeafChecks)} = inf
            end
            
            doSort          = options.Sort;
            maxLeafChecks   = options.MaxLeafChecks;
            
            if isinf(maxLeafChecks)
                % 0 indicates infinite search in internal function
                maxLeafChecks = 0;
            end
        end
        
        %------------------------------------------------------------------
        function [points, radius, camMatrix, doSort, maxLeafChecks] = validateAndParseRadiusSearchOption(this, points, radius, camMatrix, options)
            
            arguments
                this pointCloud
                points                {validateQueryPoints(this,points)}
                radius                {validateRadius(this,radius)}
                camMatrix             {validateCamMatrix(this,camMatrix)} = []
                options.Sort          {validateSort(this,options.Sort)} = false
                options.MaxLeafChecks {validateMaxLeafChecks(this,options.MaxLeafChecks)} = inf
            end
            
            doSort        = options.Sort;
            maxLeafChecks = options.MaxLeafChecks;
            if isinf(maxLeafChecks)
                % 0 indicates infinite search in internal function
                maxLeafChecks = 0;
            end
        end
        
        %------------------------------------------------------------------
        function [roi, camMatrix] = validateAndParseBoxSearchOption(this, roi, camMatrix)
            
            arguments
                this pointCloud
                roi       {validateROI(this,roi)}
                camMatrix {validateCamMatrix(this,camMatrix)} = []
            end
            
            if isvector(roi)
                roi = reshape(roi, [2, 3])';
            end
            
            if any(roi(:, 1) > roi(:, 2))
                error(message('vision:pointcloud:invalidROI'));
            end
            
            roi = double(roi);
            camMatrix = double(camMatrix);
        end
        
        %------------------------------------------------------------------
        function [radius, height, center, verticalAxis] = validateAndParseFindPointsInCylinder(this, radius, options)
            
            arguments
                this                    pointCloud
                radius                  {validateInputRadius(this, radius)}
                options.Height          (1,1) {double, single, mustBePositive, mustBeReal, mustBeNonNan} = inf
                options.Center          {validateCenter(this, options.Center)} = [0, 0, 0]
                options.VerticalAxis    (1,1) char {mustBeMember(options.VerticalAxis, {'Z','z','Y','y','X','x'})} = 'Z'
            end
            height = options.Height;
            center = options.Center;
            verticalAxis = options.VerticalAxis;
        end
    end
    
    methods(Access=protected)
        %------------------------------------------------------------------
        % copy object
        %------------------------------------------------------------------
        % Override copyElement method:
        function cpObj = copyElement(obj)
            
            % Make a copy except the internal K-dtree
            cpObj = pointCloud(obj.Location, 'Color', obj.Color, ...
                'Normal', obj.Normal, 'Intensity', obj.Intensity);
            cpObj.RangeData = obj.RangeData;
        end
    end
    
    methods(Static, Access=private)
        %------------------------------------------------------------------
        % load object
        %------------------------------------------------------------------
        function this = loadobj(that)
            
            if isfield(that, 'Intensity')
                this = pointCloud(that.Location,...
                    'Color', that.Color, ...
                    'Normal', that.Normal, ...
                    'Intensity', that.Intensity);
            else
                this = pointCloud(that.Location,...
                    'Color', that.Color, ...
                    'Normal', that.Normal);
            end
            if isfield(that, 'RangeData')
                this.RangeData = that.RangeData;
            end
        end
    end
    
    methods(Access=private)
        %------------------------------------------------------------------
        % save object
        %------------------------------------------------------------------
        function that = saveobj(this)
            
            % save properties into struct
            that.Location      = this.Location;
            that.Color         = this.Color;
            that.Normal        = this.Normal;
            that.Intensity     = this.Intensity;
            that.RangeData     = this.RangeData;
            that.Version       = this.Version;
        end
        
        %------------------------------------------------------------------
        % parameter validation for select
        %------------------------------------------------------------------
        
        function [indices, outputSize] = validateAndParseSelectSubscripts(this, row, column, options)
            
            arguments
                this pointCloud
                row                {mustBeNumeric, mustBeReal, mustBeNonsparse,...
                    mustBeVector, mustBeInteger}
                column             {mustBeNumeric, mustBeReal, mustBeNonsparse,...
                    mustBeVector, mustBeInteger}
                options.OutputSize {checkOutputSize(this,options.OutputSize)} = 'selected'
            end
            
            outputSize = options.OutputSize;
            
            %Checks lower and upper bounds of row and column
            minRow    = min(row(:));
            maxRow    = max(row(:));
            minColumn = min(column(:));
            maxColumn = max(column(:));
            if minRow < 1 || maxRow > size(this.Location,1) || minColumn < 1 || maxColumn > size(this.Location, 2)
                error(message('vision:pointcloud:subscriptsOutofRangeForSelect'));
            end
            
            indices = sub2ind([size(this.Location,1), size(this.Location,2)], row, column);
        end
        
        function [indices, outputSize] = validateAndParseSelectIndices(this, indices, options)
            
            arguments
                this pointCloud
                indices {mustBeNumericOrLogical, mustBeReal, mustBeNonsparse,...
                    mustBeInteger, checkIndices(this,indices)}
                options.OutputSize {checkOutputSize(this,options.OutputSize)} = 'selected'
            end
            
            outputSize = options.OutputSize;
            if isa(indices, 'logical')
                indices = find(indices);
            end
            
        end
        
        function checkIndices(this,indices)
            
            %Checks lower and upper bounds of indices
            if ~isa(indices, 'logical') && ~isempty(indices) && (min(indices(:)) < 1 || max(indices(:)) > this.Count)
                error(message('vision:pointcloud:indicesOutofRangeForSelect'));
            end
            %Checks if the logical indices has the same dimensions as Location
            if isa(indices,'logical')
                if isvector(indices)
                    sz = [this.Count 1];
                else
                    %if the index is not a vector but a scalar or a
                    %matrix
                    sz = size(this.Location, 1:2);
                    if ~this.isOrganized
                        sz(2) = 1;
                    end
                end
                
                validateattributes(indices, 'logical', {'size', sz});
            end
        end
        
    end
    
    methods(Access=public, Static, Hidden)
        %------------------------------------------------------------------
        function name = matlabCodegenRedirect(~)
            
            name = 'pointclouds.internal.codegen.pc.pointCloud';
        end
    end
    
end

% Custom validator functions
function mustBeType(input,classNames)
% Test for specific class
validateattributes(input, classNames,{});
end

function mustBeVector(input)
validateattributes(input,{class(input)},{'vector'});
end
