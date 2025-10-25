classdef pointCloud < pointclouds.internal.pointCloudBase & ...
        matlab.mixin.internal.indexing.ParenAssign & ...
        matlab.mixin.internal.indexing.Paren
    % This pointCloud class is for code generation.

    % Copyright 2018-2024 The MathWorks, Inc.
    %#codegen

    properties(Access = protected, Transient)
        LocationHandle; % For shared library codegen
    end

    properties(Access = protected) % For shared library codegen
        HasKdtreeConstructed = false;
        HasLocationHandleAllocated = false;
    end

    properties(Access = private, Transient)
        IsCodegenTargetHost;
        IsGPUTarget;
    end

    properties(Access = private, Hidden) % For array of pointClouds codegen
        PointCloudArrayData
    end

    methods
        %------------------------------------------------------------------
        %     Constructor
        %------------------------------------------------------------------
        function this = pointCloud(varargin)

            this = this@pointclouds.internal.pointCloudBase(varargin{:});
            initializePointCloudArray(this);

            axLimits = cast([],'like',this.Location);
            coder.varsize('axLimits');

            this.XLimitsInternal = axLimits;
            this.YLimitsInternal = axLimits;
            this.ZLimitsInternal = axLimits;

            this.initializeKdTree();
        end

        %------------------------------------------------------------------
        % Copy point cloud
        %------------------------------------------------------------------
        function ptCloud = copy(obj)
            % Make a copy except the internal K-dtree
            ptCloud = pointCloud(obj.Location, 'Color', obj.Color, ...
                'Normal', obj.Normal, 'Intensity', obj.Intensity);
            ptCloud.RangeData = obj.RangeData;
        end

        %------------------------------------------------------------------
        % K nearest neighbor search
        %------------------------------------------------------------------
        function [indices, dists] = findNearestNeighbors(this, varargin)

            if ~this.IsGPUTarget
                [indices, dists] = this.findNearestNeighborsImpl(varargin{:});
            else
                % If GPU Codegen is enabled use GPU implementation

                % GPU implementation
                % The output distance values are always sorted in the GPU
                % implementation. Since, all the brute-force and k-D tree
                % implementations return a distance-sorted output.

                this.pcshs;
                this.arrayNotSupported('findNearestNeighbors');

                if(this.Count==0) % Empty point cloud
                    indices = cast([],'uint32');
                    dists = cast([],class(this.Location));
                    return;
                end

                [points, K, ~, ~, ~] = this.validateAndParseKnnSearchOption(varargin{:});

                points = cast(points, class(this.Location));
                numQueryPoints = size(points, 1);
                K = min(double(K), numel(this.Location)/3);

                if numQueryPoints==1 % single query
                    [indices, dists] = vision.internal.codegen.gpu.PointCloudImpl.findNearestNeighborsImpl(this.Location, points, K);
                else % multiple queries
                    [indices, dists] =  vision.internal.codegen.gpu.PointCloudImpl.multiQueryKNNSearchImpl(this.Location, points, K);
                    % Sort the indices according to distances
                    [dists,indexOrder] = gpucoder.sort(dists);
                    % Optimize/Vectorize this step for better performance
                    for qryIter = 1:coder.internal.indexInt(numQueryPoints)
                        indices(:,qryIter) = indices(indexOrder(:,qryIter),qryIter);
                    end
                    if nargout > 1
                        dists = sqrt(dists);
                    end
                end
            end
        end

        %------------------------------------------------------------------
        % Radius search
        %------------------------------------------------------------------
        function [indices, dists, numNeighbors] = findNeighborsInRadius(this, varargin)

            if ~this.IsGPUTarget
                [indices, dists, numNeighbors] = this.findNeighborsInRadiusImpl(varargin{:});
            else
                % If GPU Codegen is enabled use GPU implementation

                this.pcshs;
                this.arrayNotSupported('findNeighborsInRadius');

                [points, radius, ~, doSort, ~] = ...
                    this.validateAndParseRadiusSearchOption(varargin{:});

                points = cast(points, class(this.Location));
                numQueryPoints = size(points,1);
                radius = double(radius);

                % As implementations other than 'bruteForceRadiusSearch'
                % return distance-sorted outputs, we check to see if the
                % number of points is greater than 500 or if the user asks
                % for a sorted output.
                doSortDist = (this.Count > 500) || doSort;

                if(this.Count==0) % Empty point cloud
                    indices = coder.nullcopy({});
                    dists = coder.nullcopy({});
                    numNeighbors = zeros([numQueryPoints, 1], 'uint32');
                    return;
                end

                if numQueryPoints==1 % single query
                    [indices,dists] = ...
                        vision.internal.codegen.gpu.PointCloudImpl.findNeighborsInRadiusImpl(...
                            this.Location,this.RangeData, points, radius, doSortDist);
                    numNeighbors = uint32(size(indices,1));
                else % multiple queries
                    % GPU implementation is not optimized for multi-query 
                    % radius search, use Kdtree based radius search instead.
                    searchOpts.eps = 0;

                    coder.internal.compileWarning('vision:pointcloud:GPUMultiQueryRadiusSearchWarning');

                    this.buildKdtree();
                    
                    if ~this.IsCodegenTargetHost
                        [indices, dists, numNeighbors] = vision.internal.buildable.kdtreeBuildablePortable.kdtreeRadiusSearch(this.Kdtree, ...
                            class(this.Location), points, radius, searchOpts);
                    else
                        [indices, dists, numNeighbors] = vision.internal.buildable.kdtreeBuildable.kdtreeRadiusSearch(this.Kdtree, ...
                            class(this.Location), points, radius, searchOpts);
                    end
                    if nargout > 1
                        dists = cellfun(@sqrt, dists, 'UniformOutput', false);
                    end
                end
            end
        end

        %------------------------------------------------------------------
        % Box search
        %------------------------------------------------------------------
        function indices = findPointsInROI(this, varargin)

            if ~this.IsGPUTarget
                indices = this.findPointsInROIImpl(varargin{:});
            else
                % If GPU Codegen is enabled use GPU implementation
                % GPU Coder implementation
                this.pcshs;
                this.arrayNotSupported('findPointsInROI');

                [~, ~] = this.validateAndParseBoxSearchOption(varargin{:});

                this.validateROI(varargin{1});
                inputROI = varargin{1};
                indices = vision.internal.codegen.gpu.PointCloudImpl.findPointsInROIImpl(this.Location, inputROI);
            end
        end

        %------------------------------------------------------------------
        % Find cylinder
        %------------------------------------------------------------------
        function indices = findPointsInCylinder(this, varargin)

            if ~this.IsGPUTarget
                indices = this.findPointsInCylinderImpl(this, varargin{:});
            else
                coder.internal.error('vision:pointcloud:unsupportedFindPointsInCylinderGPU');
            end
        end

        %------------------------------------------------------------------
        % Obtain a subset of this point cloud object
        %------------------------------------------------------------------
        function ptCloudOut = select(this, varargin)

            this.pcshs;
            narginchk(2, 5);

            this.arrayNotSupported('select');

            props =  struct( ...
                'CaseSensitivity', false, ...
                'StructExpand',    true, ...
                'PartialMatching', false);
            if  mod(nargin, 2) == 0 % select(this, indices)
                if ~isa(varargin{1}, 'logical')
                    validateattributes(varargin{1}, {'numeric'}, ...
                        {'real', 'nonsparse', 'integer'});
                    indices = varargin{1};
                    %Checks lower and upper bounds of indices
                    coder.internal.errorIf(~isempty(indices) && (min(indices(:)) < 1 || max(indices(:)) > this.Count),...
                        'vision:pointcloud:indicesOutofRangeForSelect');

                else
                    sz = size(this.Location);
                    sz(end) = 1;
                    validateattributes(varargin{1}, {'logical'}, ...
                        {'real', 'nonsparse', 'size', sz});
                    if ~this.IsGPUTarget()
                        indices = find(varargin{1});
                    else
                        indices = varargin{1};
                    end
                end

                defaults = struct('OutputSize', 'selected');
                pvPairs = struct('OutputSize', uint32(0));
                optarg = eml_parse_parameter_inputs(pvPairs, props, varargin{2:end});
                outputSize = eml_get_parameter_value(optarg.OutputSize, ...
                    defaults.OutputSize, varargin{2:end});

                validatestring(outputSize, {'selected', 'full'}, 'select');
            else
                % Subscript syntax is only for organized point cloud
                if ~this.isOrganized
                    coder.internal.error('vision:pointcloud:organizedPtCloudOnly');
                end
                row = varargin{1};
                validateattributes(row, {'numeric'}, ...
                    {'real', 'nonsparse', 'vector', 'integer'});
                column = varargin{2};
                validateattributes(column, {'numeric'}, ...
                    {'real', 'nonsparse', 'vector', 'integer'});

                %Checks lower and upper bounds of row and column
                minRow    = min(row(:));
                maxRow    = max(row(:));
                minColumn = min(column(:));
                maxColumn = max(column(:)) ;
                coder.internal.errorIf(minRow < 1 || maxRow > size(this.Location,1) || minColumn < 1 || maxColumn > size(this.Location, 2),...
                    'vision:pointcloud:subscriptsOutofRangeForSelect');

                defaults = struct('OutputSize', 'selected');
                pvPairs = struct('OutputSize', uint32(0));
                optarg = eml_parse_parameter_inputs(pvPairs, props, varargin{3:end});
                outputSize = eml_get_parameter_value(optarg.OutputSize, ...
                    defaults.OutputSize, varargin{3:end});

                validatestring(outputSize,{'selected', 'full'}, 'select');
                indices = sub2ind([size(this.Location,1), size(this.Location,2)], row, column);
            end

            % Obtain the subset for every property
            if ~this.IsGPUTarget
                [loc, c, nv, intensity, r] = this.subsetImpl(indices, outputSize);
            else
                coder.inline('never');
                [loc, c, nv, intensity, r] = ...
                    vision.internal.codegen.gpu.PointCloudImpl.subsetImpl(this.Location, this.Color,...
                    this.Normal,this.Intensity,this.RangeData,indices,this.isOrganized,outputSize);
            end

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
                if ~this.IsGPUTarget
                    indicesOut = find(indices);
                else
                    % GPU implementation equivalent for 'find' function
                    outMat = cumsum(indices(:));
                    outLength = 0;

                    % Compute output size
                    % outLength = outMat(end) would copy the complete
                    % outMat array from GPU to CPU.
                    % This hardcoded loop will transform into a kernel and
                    % avoid redundant copy of the complete array and
                    % instead copy only the last value. If one iteration is
                    % used, the loop would transform into an expression so
                    % running the loop twice will prevent this.
                    coder.gpu.kernel;
                    for i = 1:2
                        outLength = outMat(this.Count);
                    end

                    indicesOut = coder.nullcopy(zeros(outLength,1));
                    coder.gpu.kernel;
                    for i = 1:this.Count
                        if indices(i)
                            indicesOut(outMat(i)) = i;
                        end
                    end
                end
            end
        end

        %------------------------------------------------------------------
        % delete function
        %------------------------------------------------------------------
        function delete(this)
            if coder.internal.preferMATLABHostCompiledLibraries()
                if this.HasLocationHandleAllocated
                    vision.internal.buildable.kdtreeBuildable.kdtreeDeleteLocationPointer(this.LocationHandle, class(this.Location));
                    this.HasLocationHandleAllocated = false;
                end

                if this.HasKdtreeConstructed
                    vision.internal.buildable.kdtreeBuildable.kdtreeDelete(this.Kdtree, class(this.Location));
                    this.HasKdtreeConstructed = false;
                end
            else % portable code
                if this.HasLocationHandleAllocated
                    vision.internal.buildable.kdtreeBuildablePortable.kdtreeDeleteLocationPointer(this.LocationHandle, class(this.Location));
                    this.HasLocationHandleAllocated = false;
                end

                if this.HasKdtreeConstructed
                    vision.internal.buildable.kdtreeBuildablePortable.kdtreeDelete(this.Kdtree, class(this.Location));
                    this.HasKdtreeConstructed = false;
                end
            end
        end
    end

    methods (Access = public, Hidden)
        %------------------------------------------------------------------
        function [location, color, normals, intensity, rangeData, indices] = extractValidPoints(this)

            this.pcshs;
            this.arrayNotSupported('removeInvalidPoints');

            if ~this.IsGPUTarget
                indices = this.extractValidPointsImpl();
                [location, color, normals, intensity, rangeData] = this.subsetImpl(indices);
            else
                % If GPU Codegen is enabled use GPU implementation
                indices = vision.internal.codegen.gpu.PointCloudImpl.extractValidPoints(this.Location);
                [location, color, normals, intensity, rangeData] = ...
                    vision.internal.codegen.gpu.PointCloudImpl.subsetImpl(this.Location, this.Color,...
                    this.Normal,this.Intensity,this.RangeData,indices,this.isOrganized,'selected');
            end

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
                {'nonsparse', 'scalar', 'positive', 'integer', 'real'}, 'multiQueryKNNSearchImpl', 'K');

            K = min(double(K), this.Count);

            % Use exact search in Kdtree
            searchOpts.eps = 0;

            if this.IsGPUTarget
                [indices, dists, valid] =  vision.internal.codegen.gpu.PointCloudImpl.multiQueryKNNSearchImpl(this.Location, points, K);

            elseif this.IsCodegenTargetHost
                this.buildKdtree();
                [indices, dists, valid] = vision.internal.buildable.kdtreeBuildable.kdtreeKNNSearch(this.Kdtree, ...
                    class(this.Location), points, K, searchOpts);
            else
                this.buildKdtree();
                [indices, dists, valid] = vision.internal.buildable.kdtreeBuildablePortable.kdtreeKNNSearch(this.Kdtree, ...
                    class(this.Location), points, K, searchOpts);
            end
        end

        %------------------------------------------------------------------
        % helper function to support multiple queries in radius search
        % indicesCell, distsCell: returned in cell array of size numQueries x 1
        % valid: uint32 array of size numQueries-by-1
        % Note: distsCell contains the squared distances from each query to
        % the indexed data.
        %------------------------------------------------------------------
        function [indicesCell, distsCell, valid] = multiQueryRadiusSearchImpl(this, points, radius)

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

            if this.IsGPUTarget
                coder.internal.compileWarning('vision:pointcloud:GPUMultiQueryRadiusSearchWarning');
            end

            this.buildKdtree();

            if coder.internal.isConst(size(points)) && size(points,1) == 1 && size(points,2) == 3
                indicesCell = coder.nullcopy(cell(1,1));
                distsCell = coder.nullcopy(cell(1,1));

                if ~this.IsCodegenTargetHost
                    [indicesCell{1}, distsCell{1}, valid] = vision.internal.buildable.kdtreeBuildablePortable.kdtreeRadiusSearch(this.Kdtree, ...
                        class(this.Location), points, radius, searchOpts)
                else
                    [indicesCell{1}, distsCell{1}, valid] = vision.internal.buildable.kdtreeBuildable.kdtreeRadiusSearch(this.Kdtree, ...
                        class(this.Location), points, radius, searchOpts);
                end

            else
                if ~this.IsCodegenTargetHost
                    [indicesCell, distsCell, valid] = vision.internal.buildable.kdtreeBuildablePortable.kdtreeRadiusSearch(this.Kdtree, ...
                        class(this.Location), points, radius, searchOpts);
                else
                    [indicesCell, distsCell, valid] = vision.internal.buildable.kdtreeBuildable.kdtreeRadiusSearch(this.Kdtree, ...
                        class(this.Location), points, radius, searchOpts);
                end
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

            % Use a feature control to enable portable code generation.
            coder.extrinsic('pointclouds.internal.codegen.portableCodegenFeature');

            this.pcshs;

            % Check if the input K is a compile-time constant or not. This
            % is specific to GPU code generation. As this would not have
            % any affect on MATLAB simulation/MATLAB Coder
            isNumNgbrsConstant = coder.internal.isConst(K);

            % Reset K if there are not enough points
            K = min(double(K), this.Count);

            if this.Count <= 2
                normals = NaN(size(this.Location), 'like', this.Location);
                return;
            end

            % MATLAB C/C++ Codegen implementation.
            % For GPU code generation, the number of neighbors (K) should be
            % compile-time constant. If for GPU code generation, K is
            % not compile time constant, a warning is displayed and MATLAB
            % codegen path is invoked.
            if ~this.IsGPUTarget || ~isNumNgbrsConstant
                if this.IsGPUTarget
                    coder.internal.compileWarning('vision:pointcloud:GPUSurfaceImplWarning');
                end

                % MATLAB Codegen Implementation
                if this.isOrganized
                    loc = reshape(this.Location, [], 3);
                else
                    loc = this.Location;
                end

                this.buildKdtree();

                % Use exact search in Kdtree
                searchOpts.eps = 0;

                if this.IsCodegenTargetHost
                    [indices, ~, valid] = vision.internal.buildable.kdtreeBuildable.kdtreeKNNSearch(this.Kdtree, ...
                        class(this.Location), loc, K, searchOpts);
                else
                    [indices, ~, valid] = vision.internal.buildable.kdtreeBuildablePortable.kdtreeKNNSearch(this.Kdtree, ...
                        class(this.Location), loc, K, searchOpts);
                end

                enablePortableCodegenFeature = coder.const(pointclouds.internal.codegen.portableCodegenFeature());
                if this.IsCodegenTargetHost || ~enablePortableCodegenFeature
                    tempNormals = vision.internal.buildable.PCANormalBuildable.PCANormal_core(loc, ...
                        indices, valid, class(this.Location));
                else % portable code generation path
                    tempNormals = vision.internal.codegen.pc.visionPCANormal(loc, indices, valid);
                end

                if this.isOrganized
                    normals = reshape(tempNormals, size(this.Location));
                else
                    normals = tempNormals;
                end
            else
                % GPU coder implementation to compute the normals
                normals =  vision.internal.codegen.gpu.PointCloudImpl.surfaceNormalImpl(this.Location, K);
            end
        end
        %------------------------------------------------------------------
        % paren assign function for array of point clouds objects
        %------------------------------------------------------------------
        function this = parenAssign(this, rhs, idx, varargin)

            coder.internal.errorIf(numel(varargin)>0, ...
                'vision:pointcloud:oneDimIndexing');
            checkPtCloudsSimiliarity(this, rhs);

            if ischar(idx) && strcmp(idx, ':')
                idx = 1 : numel(this);
            elseif ischar(idx)
                coder.internal.errorIf(true, 'vision:pointcloud::oneDimIndexing');
            end

            farthestElement = max(idx);

            if farthestElement > numel(this)
                % Copy over curent elements
                if isrow(this)
                    dataArray = coder.nullcopy( cell(1, farthestElement) );
                else
                    dataArray = coder.nullcopy( cell(farthestElement, 1) );
                end
                for n = 1 : numel(this)
                    dataArray{n} = this.PointCloudArrayData{n};
                end

                % Replace/add new elements
                for n = 1 : numel(idx)
                    dataArray{idx(n)} = rhs.PointCloudArrayData{n};
                end
                this.PointCloudArrayData = dataArray;
            else
                % No need to grow cell array, just replace data
                for n = 1 : numel(idx)
                    this.PointCloudArrayData{idx(n)} = rhs.PointCloudArrayData{n};
                end
            end
        end
        %------------------------------------------------------------------
        %paren reference function for array of point clouds objects
        %------------------------------------------------------------------
        function this1 = parenReference(this, idx, varargin)
            coder.internal.errorIf(numel(varargin)>0,...
                'vision:pointcloud:oneDimIndexing');

            this1 = makeEmptyPtCloud(this);

            if ischar(idx) && strcmpi(idx, ':')
                return;
            elseif ischar(idx)
                coder.internal.errorIf(true, 'vision:pointcloud:oneDimIndexing');
            end

            % Maintain sizing
            if isrow(this)
                dataArray = coder.nullcopy( cell(1, numel(idx)) );
            else
                dataArray = coder.nullcopy( cell(numel(idx), 1) );
            end

            for n = 1 : numel(idx)
                dataArray{n} = this.PointCloudArrayData{idx(n)};
            end

            this1.PointCloudArrayData      = dataArray;
            this1.Location  = dataArray{1}.Location;
            this1.Color     = dataArray{1}.Color;
            this1.Normal    = dataArray{1}.Normal;
            this1.Intensity = dataArray{1}.Intensity;

        end

        %------------------------------------------------------------------
        % creating an empty point cloud object
        %------------------------------------------------------------------
        function obj = makeEmptyPtCloud(this)
            locClass = class(this.Location);
            colorClass = class(this.Color);
            intensityClass = class(this.Intensity);
            if ~this.isOrganized
                location  = zeros(coder.ignoreConst(0),3, locClass);
                color     = zeros(coder.ignoreConst(0),3, colorClass);
                normal    = zeros(coder.ignoreConst(0),3, locClass);
                intensity = zeros(coder.ignoreConst(0),coder.ignoreConst(0), intensityClass);
            else
                location  = zeros(coder.ignoreConst(0), coder.ignoreConst(0), 3, locClass);
                color     = zeros(coder.ignoreConst(0), coder.ignoreConst(0), 3, colorClass);
                normal    = zeros(coder.ignoreConst(0), coder.ignoreConst(0), 3, locClass);
                intensity = zeros(coder.ignoreConst(0), coder.ignoreConst(0), intensityClass);
            end
            pc = pointCloud(location, 'Color', color, 'Normal', normal...
                ,'Intensity', intensity);
            obj = repmat(pc,0,0);
        end

        %------------------------------------------------------------------
        % initialize the properties of point cloud array objects
        %------------------------------------------------------------------
        function initializePointCloudArray(this)

            data = {pointclouds.internal.codegen.pc.pointCloudArray(this)};
            coder.varsize('dataArray');
            dataArray = data;
            this.PointCloudArrayData = dataArray;
        end

        %------------------------------------------------------------------
        % calculate the number of pointClouds in point cloud array
        %------------------------------------------------------------------
        function n = numel(this)
            n = numel(this.PointCloudArrayData);
        end

        %------------------------------------------------------------------
        % overloading the isscalar functionality
        %------------------------------------------------------------------
        function n = isscalar(this)
            n = numel(this.PointCloudArrayData)==1;
        end

        %------------------------------------------------------------------
        % overloading the repmat functionality
        %------------------------------------------------------------------
        function this = repmat(this, varargin)
            coder.internal.assert( numel(varargin)<3, ...
                'vision:pointcloud:oneDimIndexing');

            % validate repmat(obj,[a, b, ...]) syntax
            if numel(varargin)==1 && ~isscalar(varargin{1})
                in = varargin{1};

                % Only indexing up to two dimensions
                coder.internal.assert( numel(in)<=2 && ...
                    (in(1)<=1 || in(2)<=1), ...
                    'vision:pointcloud:oneDimIndexing');
            end

            if numel(varargin)==2 && isscalar(varargin{1}) && isscalar(varargin{2})
                coder.internal.assert( varargin{1} <=1 && varargin{2}<=1, ...
                    'vision:pointcloud:oneDimIndexing');
            end
            this.PointCloudArrayData = repmat(this.PointCloudArrayData, varargin{:});
        end

        %------------------------------------------------------------------
        % overloading the horzcat functionality
        %------------------------------------------------------------------
        function this = horzcat(this, varargin)

            coder.internal.assert(...
                isrow(this), 'MATLAB:catenate:matrixDimensionMismatch');
            num = numel(varargin);
            for n = 1 : num
                checkPtCloudsSimiliarity(this, varargin{n});
            end

            % initialize  pointCloudArray data
            data       = pointclouds.internal.codegen.pc.pointCloudArray(this);
            dataArray  = repmat({data}, 1, coder.ignoreConst(0));

            % copy over current elements
            for n=1:numel(this)
                dataArray{end+1} = this.PointCloudArrayData{n};
            end

            % copy over new elements
            for n=1:num
                for nn = 1:numel(varargin{n})
                    dataArray{end+1} = varargin{n}.PointCloudArrayData{nn};
                end
            end

            % Assign dataArray to corresponding Data property
            this.PointCloudArrayData = dataArray;
        end

        %------------------------------------------------------------------
        % overloading the vertcat functionality
        %------------------------------------------------------------------
        function this = vertcat(this, varargin)

            coder.internal.assert(...
                isa(this, class(this)), ...
                'vision:pointcloud:invalidClass');
            coder.internal.errorIf(...
                isrow(this), 'MATLAB:catenate:matrixDimensionMismatch');

            num = numel(varargin);
            for n = 1 : num
                checkPtCloudsSimiliarity(this, varargin{n});
            end

            % initialize  pointCloudArray data
            data       = pointclouds.internal.codegen.pc.pointCloudArray(this);
            dataArray  = repmat({data}, coder.ignoreConst(0), 1);

            % copy over current elements
            for n=1:numel(this)
                dataArray{end+1} = this.PointCloudArrayData{n};
            end

            % copy over new elements
            for n=1:num
                for nn = 1:numel(varargin{n})
                    dataArray{end+1} = varargin{n}.PointCloudArrayData{nn};
                end
            end

            % Assign dataArray to corresponding Data property
            this.PointCloudArrayData = dataArray;
        end

        %------------------------------------------------------------------
        % overloading the transpose functionality
        %------------------------------------------------------------------
        function this = transpose(this)

            % Transpose is not supported for cell arrays in code
            % generation. Use reshape instead for transpose because these
            % are 1-D arrays.
            if isrow(this)
                this.PointCloudArrayData = reshape(this.PointCloudArrayData, numel(this), 1);
            else
                this.PointCloudArrayData = reshape(this.PointCloudArrayData, 1, numel(this));
            end
        end

        %------------------------------------------------------------------
        % overloading the ctranspose functionality
        %------------------------------------------------------------------
        function this = ctranspose(this)

            this = transpose(this);
        end

        %------------------------------------------------------------------
        % overloading the reshape functionality
        %------------------------------------------------------------------
        function this = reshape(this, varargin)

            coder.internal.assert( numel(varargin)<3, ...
                'vision:pointcloud:oneDimIndexing');

            if numel(varargin)==2
                coder.internal.assert(...
                    ~(isempty(varargin{1}) || isempty(varargin{2})), ...
                    'driving:oneDimArrayBehavior:reshapeWithEmpties');
            end

            this.PointCloudArrayData = reshape(this.PointCloudArrayData, varargin{:});
        end

        %------------------------------------------------------------------
        % overloading the isempty functionality
        %------------------------------------------------------------------
        function ie = isempty(this)

            ie = numel(this)== 0;
        end

        %------------------------------------------------------------------
        function n = end(this,varargin)
            % Only 1-D indexing is supported, so end is always numel.
            n = numel(this);
        end

        %------------------------------------------------------------------
        function l = length(this)
            % For a 1-D array, length is numel
            l = numel(this);
        end

        %------------------------------------------------------------------
        function y = isrow(this)
            y = isrow(this.PointCloudArrayData);
        end

        %------------------------------------------------------------------
        function checkPtCloudsSimiliarity(this, that)
            coder.internal.errorIf(~isa(this, class(that)),...
                'vision:pointcloud:invalidClass');
            coder.internal.errorIf(this.isOrganized ~= that.isOrganized,...
                'vision:pointcloud:differentPointCloudTypes');
            coder.internal.errorIf(~isa(this.Location, class(that.Location)),...
                'vision:pointcloud:differentTypes');
            coder.internal.errorIf(~isa(this.Intensity, class(that.Intensity)),...
                'vision:pointcloud:differentTypes');
        end

        %------------------------------------------------------------------
        % Assign the properties of one point cloud to another
        % Required for g3095319
        %------------------------------------------------------------------
        function obj1 = assign(obj1, obj)
            obj1.Location = obj.Location;
            obj1.Color = obj.Color;
            obj1.Normal = obj.Normal;
            obj1.Intensity = obj.Intensity;
            obj1.RangeData = obj.RangeData;
            obj1.PointCloudArrayData = obj.PointCloudArrayData;
        end
    end

    methods (Access = protected)
        %------------------------------------------------------------------
        %Initialize all target mode flags
        %------------------------------------------------------------------
        function initializeTargetMode(this)

            this.IsSimulation = isempty(coder.target);
            this.IsCodegenTargetHost = coder.internal.preferMATLABHostCompiledLibraries();
            this.IsGPUTarget = coder.gpu.internal.isGpuEnabled;
        end

        %------------------------------------------------------------------
        % helper function for computing XLimits, YLimits and ZLimits
        %------------------------------------------------------------------
        function limits = computeLimits(this, dim)

            tf = ~isnan(this.Location);

            if ~this.isOrganized
                tf = (sum(tf, 2) == 3);
                if nnz(tf)
                    limits = [min(this.Location(tf, dim)), max(this.Location(tf, dim))];
                else
                    limits = zeros(0, 2, class(this.Location));
                end
            else
                tf = (sum(tf, 3) == 3);
                X = this.Location(:, :, dim);
                if nnz(tf)
                    limits = [min(X(tf)), max(X(tf))];
                else
                    limits = zeros(0, 2, class(this.Location));
                end
            end
        end

        %------------------------------------------------------------------
        % helper function to index data
        %------------------------------------------------------------------
        function buildKdtree(this)

            if this.IsCodegenTargetHost
                if ~this.HasLocationHandleAllocated
                    this.LocationHandle = vision.internal.buildable.kdtreeBuildable.kdtreeGetLocationPointer(this.Location, class(this.Location));
                    this.HasLocationHandleAllocated = true;
                end

                if ~this.HasKdtreeConstructed
                    % Build a Kdtree to index the data
                    this.Kdtree = vision.internal.buildable.kdtreeBuildable.kdtreeConstruct(class(this.Location));
                    this.HasKdtreeConstructed = true;
                    createIndex = true;

                elseif vision.internal.buildable.kdtreeBuildable.kdtreeNeedsReindex(this.Kdtree, class(this.Location), this.LocationHandle)
                    createIndex = true;

                else
                    createIndex = false;
                end

                if createIndex
                    vision.internal.buildable.kdtreeBuildable.kdtreeIndex(this.Kdtree, class(this.Location), this.LocationHandle, this.Count, 3);
                end
            else % portable code
                if ~this.HasLocationHandleAllocated
                    this.LocationHandle = vision.internal.buildable.kdtreeBuildablePortable.kdtreeGetLocationPointer(this.Location, class(this.Location));
                    this.HasLocationHandleAllocated = true;
                end

                if ~this.HasKdtreeConstructed
                    % Build a Kdtree to index the data
                    this.Kdtree = vision.internal.buildable.kdtreeBuildablePortable.kdtreeConstruct(class(this.Location));
                    this.HasKdtreeConstructed = true;
                    createIndex = true;

                elseif vision.internal.buildable.kdtreeBuildablePortable.kdtreeNeedsReindex(this.Kdtree, class(this.Location), this.LocationHandle)
                    createIndex = true;

                else
                    createIndex = false;
                end

                if createIndex
                    vision.internal.buildable.kdtreeBuildablePortable.kdtreeIndex(this.Kdtree, class(this.Location), this.LocationHandle, this.Count, 3);
                end
            end
        end
    end

    methods (Access = protected)
        %------------------------------------------------------------------
        % helper function for bruteForce methods
        %------------------------------------------------------------------
        function allDists = bruteForce(this, point)

            if this.IsCodegenTargetHost
                if this.isOrganized
                    numPoints1 = size(point, 1);
                    numPoints2 = size(this.Location,1) * size(this.Location,2);

                    allDists = vision.internal.buildable.ComputeMetricBuildable.ComputeMetric_core(...
                        point, reshape(this.Location, [], 3), 'ssd', numPoints1, ...
                        numPoints2, class(this.Location));

                else
                    numPoints1 = size(point, 1);
                    numPoints2 = size(this.Location,1);

                    allDists = vision.internal.buildable.ComputeMetricBuildable.ComputeMetric_core(...
                        point, this.Location, 'ssd', numPoints1, numPoints2, ...
                        class(this.Location));
                end
            else
                if this.isOrganized
                    features = reshape(this.Location, [], 3);

                else
                    features = this.Location;
                end

                numPoints1 = size(point, 1);
                numPoints2 = this.Count;
                featDims = size(point, 2);

                allDists = zeros(numPoints1,numPoints2, 'like', this.Location);
                for c = 1:numPoints2
                    for r = 1:numPoints1
                        allDists(r, c) = sum((point(r, 1:featDims) - ...
                            features(c, 1:featDims)).^2);
                    end
                end
            end
        end

        %------------------------------------------------------------------
        % kdtree methods
        %------------------------------------------------------------------
        function [indices, dists] = kdtreeKNNSearch(this, points, K, maxLeafChecks)

            searchOpts.eps = 0;

            if this.IsCodegenTargetHost
                this.buildKdtree();

                [indices, dists, valid] = vision.internal.buildable.kdtreeBuildable.kdtreeKNNSearch(this.Kdtree, ...
                    class(this.Location), points, K, searchOpts);
            else
                this.buildKdtree();

                [indices, dists, valid] = vision.internal.buildable.kdtreeBuildablePortable.kdtreeKNNSearch(this.Kdtree, ...
                    class(this.Location), points, K, searchOpts);
            end
            if size(points, 1)==1
                % This step will ensure returning actual number of neighbors
                indices = indices(1:valid(1), 1);
                dists = dists(1:valid(1), 1 );
            end
        end

        %------------------------------------------------------------------
        function [indices, dists, numNeighbors] = kdtreeRadiusSearch(this, points, radius, maxLeafChecks)

            searchOpts.eps = 0;

            if this.IsCodegenTargetHost
                this.buildKdtree();

                [indices, dists, numNeighbors] = vision.internal.buildable.kdtreeBuildable.kdtreeRadiusSearch(...
                    this.Kdtree, class(this.Location), points, radius, searchOpts);

            else
                this.buildKdtree();

                [indices, dists, numNeighbors] = vision.internal.buildable.kdtreeBuildablePortable.kdtreeRadiusSearch(...
                    this.Kdtree, class(this.Location), points, radius, searchOpts);
            end
        end

        %------------------------------------------------------------------
        function indices = kdtreeBoxSearch(this, roi)

            if this.IsCodegenTargetHost
                this.buildKdtree();

                indices = vision.internal.buildable.kdtreeBuildable.kdtreeBoxSearch(this.Kdtree, ...
                    class(this.Location), roi);

            else
                this.buildKdtree();

                indices = boxSearch(this.Kdtree, roi);
            end

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
            if this.IsCodegenTargetHost
                [indices, dists] = vision.internal.buildable.searchOrganizedPointCloudBuildable.searchOrganizedPointCloud_core(...
                    this.Location, point, K, projectionOfPoint, KRKRT, ...
                    'knnSearch');
            else
                [indices, dists] = vision.internal.buildable.searchOrganizedPointCloudBuildablePortable.searchOrganizedPointCloud_core(...
                    this.Location, point, K, projectionOfPoint, KRKRT, ...
                    'knnSearch');
            end
        end

        %------------------------------------------------------------------
        function [indices, dists] = approximateOrganizedRadiusSearch(this, point, radius, camMatrix)

            coder.internal.errorIf(~this.isOrganized, 'vision:pointcloud:organizedPtCloudOnly');
            [projectionOfPoint, KRKRT] = this.computeProjectedPoints(point, camMatrix);

            if this.IsCodegenTargetHost
                [indices, dists] = vision.internal.buildable.searchOrganizedPointCloudBuildable.searchOrganizedPointCloud_core(...
                    this.Location, point, radius, projectionOfPoint, KRKRT, ...
                    'radiusSearch');
            else
                [indices, dists] = vision.internal.buildable.searchOrganizedPointCloudBuildablePortable.searchOrganizedPointCloud_core(...
                    this.Location, point, radius, projectionOfPoint, KRKRT, ...
                    'radiusSearch');
            end
        end

        %------------------------------------------------------------------
        function indices = approximateOrganizedBoxSearch(this, roi, camMatrix)

            coder.internal.errorIf(~this.isOrganized, 'vision:pointcloud:organizedPtCloudOnly');

            % Product of Camera and Rotation Matrix
            KR = camMatrix(1:3, :);
            camMatrixArray = repmat(camMatrix(4, :), 8, 1);
            projectionOfPoints = this.computeProjectedPointsInBox(KR, roi, camMatrixArray);

            [tf, height, width, minRowPt, minColPt] = this.findPointsInBox(projectionOfPoints, roi);

            if ~isrow(tf)
                % Find the indices of the points which satisfy the constraints
                [row, col] = find(tf);
            else
                % Handle find() separately for row vectors in code generation
                [rowTemp, colTemp] = find(tf');
                row = colTemp';
                col = rowTemp';
            end

            if ~isempty(row)
                indices = uint32(sub2ind([height, width], row+minRowPt-1, col+minColPt-1));
            else
                indices = uint32([]);
            end
        end
    end

    methods (Access = protected)
        %------------------------------------------------------------------
        function [xyzPoints, C, nv, I, rangeData] = validateAndParseInputs(this,varargin)

            % Validate and parse inputs
            pvPairs = struct(...
                'Color', uint32(0),...
                'Normal', uint32(0),...
                'Intensity', uint32(0));

            props =  struct( ...
                'CaseSensitivity', false, ...
                'StructExpand',    true, ...
                'PartialMatching', false);

            this.validateXYZPoints(varargin{1})
            optarg = eml_parse_parameter_inputs(pvPairs, props, varargin{2:end});

            xyzPoints = varargin{1};

            if(ismatrix(xyzPoints))
                defaults = struct(...
                    'Color', uint8( zeros(0,0)),...
                    'Normal', single( zeros(0,0)),...
                    'Intensity', single( zeros(0,0)));
            else
                defaults = struct(...
                    'Color', uint8(zeros(0,0,0)),...
                    'Normal', single(zeros(0,0,0)),...
                    'Intensity', single(zeros(0,0)));
            end

            % Validation of these parameters happen in their respective set
            % methods.
            C = eml_get_parameter_value(optarg.Color, defaults.Color, varargin{2:end});
            nv  = eml_get_parameter_value(optarg.Normal, defaults.Normal, varargin{2:end});
            I = eml_get_parameter_value(optarg.Intensity, defaults.Intensity, varargin{2:end});

            if ismatrix(xyzPoints)
                rangeData = zeros(0, 0, 'like', xyzPoints);
            else
                rangeData = zeros(0, 0, 0, 'like', xyzPoints);
            end

            coder.varsize('C');
            coder.varsize('I');
            coder.varsize('nv');
            coder.varsize('rangeData');
        end

        %------------------------------------------------------------------
        function validateXYZPoints(~, xyzPoints)

            % Validate non-size attributes
            validateattributes(xyzPoints, {'single', 'double'}, {'real', 'nonsparse' });

            isMx3   = coder.internal.ndims(xyzPoints)==2 && size(xyzPoints,2)==3;
            isMxNx3 = coder.internal.ndims(xyzPoints)==3 && size(xyzPoints,3)==3;

            eml_invariant(coder.internal.ndims(xyzPoints)<=3, ...
                eml_message('vision:pointcloud:invalidXYZPoints'));

            isMx3 = isMx3 && eml_is_const(size(xyzPoints, 2));
            isMxNx3 = isMxNx3 && eml_is_const(size(xyzPoints, 3));

            coder.internal.errorIf( ~(isMx3 || isMxNx3), 'vision:pointcloud:invalidXYZPoints');
        end

        %------------------------------------------------------------------
        % parameter validation for search
        %------------------------------------------------------------------
        function [points, K, camMatrix, doSort, maxLeafChecks] = validateAndParseKnnSearchOption(this, varargin)

            this.validateQueryPoints(varargin{1});
            points = varargin{1};

            this.validateK(varargin{2});
            K = varargin{2};

            defaultOptInputs = struct('camMatrix', []);
            defaultParams = struct(...
                'Sort',         false,...
                'MaxLeafChecks',inf);

            camMatrix = cast(defaultOptInputs.camMatrix, class(points));
            doSort = defaultParams.Sort;
            maxLeafChecks = defaultParams.MaxLeafChecks;

            if length(varargin) > 2
                paramIdx = coder.internal.indexInt(0);
                numOptInputs = 0;
                for n = 3 : length(varargin)
                    if ischar(varargin{n})
                        paramIdx = coder.internal.indexInt(n);
                        break;
                    end
                    numOptInputs = numOptInputs + 1;
                end
                switch(numOptInputs)
                    case 0
                        camMatrix = cast(defaultOptInputs.camMatrix, class(points));
                    case 1
                        coder.internal.errorIf(this.IsGPUTarget, 'vision:pointcloud:GPUCamMatrixError');
                        this.validateCamMatrix(varargin{3});
                        camMatrix = varargin{3};
                end
                if paramIdx ~= 0
                    pvPairs = struct(...
                        'Sort', uint32(0),...
                        'MaxLeafChecks', uint32(0));

                    props =  struct( ...
                        'CaseSensitivity', false, ...
                        'StructExpand',    true, ...
                        'PartialMatching', false);
                    optarg = eml_parse_parameter_inputs(pvPairs, props, varargin{paramIdx:end});
                    doSort = eml_get_parameter_value(optarg.Sort, defaultParams.Sort, varargin{paramIdx:end});
                    maxLeafChecks = eml_get_parameter_value(optarg.MaxLeafChecks, defaultParams.MaxLeafChecks, varargin{paramIdx:end});

                    this.validateSort(doSort);
                    this.validateMaxLeafChecks(maxLeafChecks);
                end
            end
            if isinf(maxLeafChecks)
                % 0 indicates infinite search in internal function
                maxLeafChecks = 0;
            else
                coder.internal.errorIf(this.IsGPUTarget, 'vision:pointcloud:GPUMaxLeafCheckError');
            end
        end

        %------------------------------------------------------------------
        function [roi, camMatrix] = validateAndParseBoxSearchOption(this, varargin)

            this.validateROI(varargin{1});
            roi_ = varargin{1};

            defaultOptInputs = struct('camMatrix', []);
            camMatrix = defaultOptInputs.camMatrix;

            if length(varargin) > 1
                numOptInputs = 0;
                for n = 2 : length(varargin)
                    numOptInputs = numOptInputs + 1;
                end
                switch(numOptInputs)
                    case 0
                        camMatrix = cast(defaultOptInputs.camMatrix, 'double');
                    case 1
                        coder.internal.errorIf(this.IsGPUTarget, 'vision:pointcloud:GPUCamMatrixError');
                        this.validateCamMatrix(varargin{2});
                        camMatrix = cast(varargin{2}, 'double');
                end
            end
            if isvector(roi_)
                roi = reshape(roi_, [2, 3])';
            else
                roi = roi_;
            end

            if any(roi(:, 1) > roi(:, 2))
                coder.internal.error('vision:pointcloud:invalidROI');
            end

            roi = double(roi);
            camMatrix = double(camMatrix);
        end

        %------------------------------------------------------------------
        function [radius, height, center, verticalAxis] = validateAndParseFindPointsInCylinder(this, varargin)

            % Validate and parse inputs
            this.validateInputRadius(varargin{1})
            coder.varsize('radius');
            radius = varargin{1};

            props =  struct( ...
                'CaseSensitivity', false, ...
                'StructExpand',    true, ...
                'PartialMatching', false);

            pvPairs = struct(...
                'Height', single(inf),...
                'Center', single([0, 0, 0]),...
                'VerticalAxis', char('Z'));

            optarg = eml_parse_parameter_inputs(pvPairs, props, varargin{2:end});

            defaults = struct(...
                'Height', single(inf), ...
                'Center', single([0, 0, 0]), ...
                'VerticalAxis', char('Z'));

            height = eml_get_parameter_value(optarg.Height, defaults.Height, varargin{2:end});
            center = eml_get_parameter_value(optarg.Center, defaults.Center, varargin{2:end});
            verticalAxis = eml_get_parameter_value(optarg.VerticalAxis, defaults.VerticalAxis, varargin{2:end});
        end

        %------------------------------------------------------------------
        function [points, radius, camMatrix, doSort, maxLeafChecks] = validateAndParseRadiusSearchOption(this,varargin)

            this.validateQueryPoints(varargin{1});
            points = varargin{1};

            isQueryPointValid = size(points,1) >= 1 && size(points,2) == 3;
            coder.internal.errorIf(~isQueryPointValid, 'vision:pointcloud:invalidQueryPoint');

            this.validateRadius(varargin{2});
            radius = varargin{2};

            defaultOptInputs = struct('camMatrix', []);
            defaultParams = struct(...
                'Sort',         false,...
                'MaxLeafChecks',inf);

            camMatrix = cast(defaultOptInputs.camMatrix, class(points));
            doSort = defaultParams.Sort;
            maxLeafChecks = defaultParams.MaxLeafChecks;

            if length(varargin) > 2
                paramIdx = coder.internal.indexInt(0);
                numOptInputs = 0;
                for n = 3 : length(varargin)
                    if ischar(varargin{n})
                        paramIdx = coder.internal.indexInt(n);
                        break;
                    end
                    numOptInputs = numOptInputs + 1;
                end
                switch(numOptInputs)
                    case 0
                        camMatrix = cast(defaultOptInputs.camMatrix, class(points));
                    case 1
                        coder.internal.errorIf(this.IsGPUTarget, 'vision:pointcloud:GPUCamMatrixError');
                        this.validateCamMatrix(varargin{3});
                        camMatrix = varargin{3};
                end
                if paramIdx ~= 0
                    pvPairs = struct(...
                        'Sort', uint32(0),...
                        'MaxLeafChecks', uint32(0));

                    props =  struct( ...
                        'CaseSensitivity', false, ...
                        'StructExpand',    true, ...
                        'PartialMatching', false);
                    optarg = eml_parse_parameter_inputs(pvPairs, props, varargin{paramIdx:end});
                    doSort = eml_get_parameter_value(optarg.Sort, defaultParams.Sort, varargin{paramIdx:end});
                    maxLeafChecks = eml_get_parameter_value(optarg.MaxLeafChecks, defaultParams.MaxLeafChecks, varargin{paramIdx:end});

                    this.validateSort(doSort);
                    this.validateMaxLeafChecks(maxLeafChecks);
                end
            end

            if isinf(maxLeafChecks)
                % 0 indicates infinite search in internal function
                maxLeafChecks = 0;
            else
                coder.internal.errorIf(this.IsGPUTarget, 'vision:pointcloud:GPUMaxLeafCheckError');
            end
        end
    end

    methods (Access = private)
        %------------------------------------------------------------------
        % helper function to Initialize kdtree for code generation
        %------------------------------------------------------------------
        function initializeKdTree(this)
            % For shared library and portable codegen
            this.Kdtree = coder.opaquePtr('void', coder.internal.null);
            this.LocationHandle = coder.opaquePtr('void', coder.internal.null);
        end

    end

    %----------------------------------------------------------------------
    % Constant Folding Assistance
    %----------------------------------------------------------------------
    methods (Static, Hidden)
        %------------------------------------------------------------------
        function props = matlabCodegenNontunableProperties(~)

            props = {'IsCodegenTargetHost','IsGPUTarget'};
        end
    end
end
