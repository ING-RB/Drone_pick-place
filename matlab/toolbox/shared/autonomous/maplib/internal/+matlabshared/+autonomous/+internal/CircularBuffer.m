classdef CircularBuffer < matlabshared.autonomous.map.internal.InternalAccess
%This class is for internal use only. It may be removed in the future.

%CircularBuffer data structure that uses a fixed size buffer to store
%   only the most recent data equal to the size of the buffer.

%   Copyright 2019-2024 The MathWorks, Inc.

%#codegen
    
    properties
        %ConstVal scalar value used to initialize the grid and regions
        %affected by move
        ConstVal
        
        %DataType class of the values stored in the buffer
        DataType
    end
    
    properties (Access = {?matlabshared.autonomous.map.internal.InternalAccess})
        %Index circular buffer index object used to convert normal index to
        %circular buffer index
        Index
        
        %Buffer base grid matrix storing grid map data
        Buffer
    end
    
    properties (SetAccess = immutable)
        %BufferSize Dimensions of the internal buffer
        BufferSize
    end
    
    methods
        function obj = CircularBuffer(index,constVal,depth,matrix)
            %CircularBuffer Construct an instance of this class
            %   which uses specified index for indexing
            
            narginchk(1,4);
            
            % Construct matrix
            if nargin < 2
                constVal = 0;
            end
            if nargin < 3
                depth = 1;
            end

            coder.internal.prefer_const(depth); % g2607528

            if nargin < 4
                sz = [index.Size depth];
                mat = repmat(constVal, sz);
            else
                mat = reshape(matrix,index.Size(1),index.Size(2),prod(depth));
                sz = size(mat,[1 2 3]);
            end
            
            % Set properties
            obj.Index = index;
            obj.ConstVal = constVal;
            obj.DataType = class(mat);
            obj.BufferSize = sz;
            obj.Buffer = mat;
        end
        
        function matrix = getBlock(obj,index1, index2)
            %get return matrix value defined between index1 and index2
            [region,blockSize] = computeGetBoundaries(obj.Index,index1,index2);
            sz = size(obj.Buffer);
            sz(1:2) = blockSize;
            matrix = getBaseMatrix(obj,region,sz);
        end
        
        function values = getValueAtIndices(obj,indices)
            %get values at the specified grid indices
            
            ind =  obj.Index.toBaseMatrixIndex(indices);
            values = getBaseMatrixValueAtIndices(obj,ind);
        end
        
        function setBlock(obj,index, matrix)
            % set the block index as bottom left corner with new values
            % in matrix
            
            [reg, minimumMatrix] = computeSetBoundaries(obj.Index,index,matrix);
            
            setBaseMatrix(obj, reg, minimumMatrix);
        end
        
        function setValueAtIndices(obj,indices,values)
            % Sets the grid locations specified by indices to values
            
            ind =  obj.Index.toBaseMatrixIndex(indices);
            setBaseMatrixValueAtIndices(obj,ind,values);
            
        end
        
        function fillNewRegionsWithScalar(obj,constVal)
            %clearNewRegions fill new regions computed by Index with ConstVal
            
            if nargin < 2
                constVal = obj.ConstVal;
            end
            
            if obj.Index.DropEntireMap
                obj.Buffer(:) = constVal;
            else
                if obj.Index.DropTwoRegions(1)
                    % If wrapping occurred in y direction
                    if obj.Index.NewRegions(3) < 0
                        % If map is moving +y
                        obj.Buffer(1:obj.Index.NewRegions(1)-1,:,:) = constVal;
                        obj.Buffer(obj.Index.Head(1):end,:,:) = constVal;
                    else
                        % If map is moving -y
                        obj.Buffer(obj.Index.NewRegions(1):end,:,:) = constVal;
                        obj.Buffer(1:obj.Index.Head(1)-1,:,:) = constVal;
                    end
                else
                    % No wrapping occured in y-axis, update single region
                    top = min(obj.Index.NewRegions(1), obj.Index.NewRegions(1)+obj.Index.NewRegions(3));
                    bottom = top + abs(obj.Index.NewRegions(3))-1;
                    obj.Buffer(top:bottom,:,:) = constVal;
                end
                
                if obj.Index.DropTwoRegions(2)
                    % If wrapping occured in x direction
                    if obj.Index.NewRegions(4) > 0
                        % If map is moving +x
                        obj.Buffer(:,obj.Index.NewRegions(2):end,:) = constVal;
                        obj.Buffer(:,1:obj.Index.Head(2)-1,:) = constVal;
                    else
                        % If map is moving -x
                        obj.Buffer(:,1:obj.Index.NewRegions(2)-1,:) = constVal;
                        obj.Buffer(:,obj.Index.Head(2):end,:) = constVal;
                    end
                else
                    % No wrapping occured in x-axis, update single region
                    left  = min(obj.Index.NewRegions(2),(obj.Index.NewRegions(2)+obj.Index.NewRegions(4)));
                    right = left + abs(obj.Index.NewRegions(4))-1;
                    obj.Buffer(:,left:right,:) = constVal;
                end
            end
        end
        
        function newObj = copy(obj)
            %copy creates dep copy of circular buffer
            newObj = matlabshared.autonomous.internal.CircularBuffer(copy(obj.Index),obj.ConstVal,size(obj.Buffer,3),obj.Buffer);
        end
        
        function setBlockWithScalar(obj,index,blockSize,constVal)
            % replace the block index as bottom left corner with
            % constantVal
            indexStart = max(index, [1,1]);
            reg = obj.Index.toBaseMatrixIndex(indexStart, blockSize);
            
            setBaseMatrixBlockWithScalar(obj,reg,constVal);
        end
    end
    
    methods (Static, Hidden)
        function obj = loadobj(s)
            if isstruct(s)
                depth = size(s.Buffer,3);
                obj = matlabshared.autonomous.internal.CircularBuffer(copy(s.Index),s.ConstVal,depth);
                obj.Buffer = s.Buffer;
            else
                obj = s;
            end
        end
    end
    
    methods (Access = {?matlabshared.autonomous.map.internal.InternalAccess,...
                       ?matlab.unittest.TestCase})
                   
        function setBaseMatrixBlockWithScalar(obj,region,constVal)
            % Replaces base matrix block with constant
            
            % assign values in four parts seperated by the speration index
            % Quadrant1
            obj.Buffer(region(1,1):region(2,1), region(1,2):region(2,2),:) = constVal;
            % Quadrant2
            obj.Buffer(1:region(3,1), region(1,2):region(2,2), :) = constVal;
            % Quadrant3
            obj.Buffer(region(1,1):region(2,1), 1:region(3,2), :) = constVal;
            % Quadrant4
            obj.Buffer(1:region(3,1), 1:region(3,2), :) = constVal;
        end
        
        function setIndex(obj,index)
            %setindex replaces the Index 
            
            obj.Index = index;
        end 
        
        function matrix = getBaseMatrix(obj,region,blockSize)
            %getBaseMatrix returns the extracted block whose bouderies are
            % specifed by region. Region will be computed by index class.
            % Many circular buffers can use this functionality to reuse the
            % region computed by index.
            
            matrix = zeros(blockSize(1),blockSize(2),size(obj.Buffer,3), "like", obj.ConstVal);
            
            % Quadrant1
            matrix(1:region(4,1), 1:region(4,2), :) = obj.Buffer(region(1,1):region(2,1), region(1,2):region(2,2), :);
            % Quadranrt2
            matrix(region(4,1)+1:end, 1:region(4,2), :) = obj.Buffer(1:region(3,1), region(1,2):region(2,2), :);
            % Quadrant3
            matrix(1:region(4,1), region(4,2)+1:end, :) = obj.Buffer(region(1,1):region(2,1), 1:region(3,2), :);
            % Quadrant4
            matrix(region(4,1)+1:end, region(4,2)+1:end, :) = obj.Buffer(1:region(3,1), 1:region(3,2), :);
        end  
        
        function values = getBaseMatrixValueAtIndices(obj,indices)
            % Returns values of base matrix at specified base matrix indices
            % computed by index. The base matrix indices computed by index class 
            % can be reused by multiple circular buffers using this functionality.
            linearInd = size(obj.Buffer,1)*(indices(:,2)-1)+indices(:,1);
            dataDims = size(obj.Buffer,3);
            if dataDims == 1
                values = obj.Buffer(linearInd);
            else
                % Preallocate output
                nIdx = size(indices,1);
                pgSize = size(obj.Buffer,1)*size(obj.Buffer,2);
                values = repmat(obj.ConstVal,nIdx,1,dataDims);
                
                for i = 1:dataDims
                    % Convert to linear indices
                    values(:,:,i) = obj.Buffer(linearInd);
                    linearInd = linearInd+pgSize;
                end
            end
        end
        
        function setBaseMatrix(obj, region, newBlock)
            %setBaseMatrix set values in four parts specified by region
            
            % Quadrant1
            obj.Buffer(region(1,1):region(2,1), region(1,2):region(2,2),:) = newBlock(1:region(4,1), 1:region(4,2),:);
            % Quadrant2
            obj.Buffer(1:region(3,1), region(1,2):region(2,2),:) = newBlock(region(4,1)+1:end, 1:region(4,2),:);
            % Quadrant3
            obj.Buffer(region(1,1):region(2,1), 1:region(3,2),:) = newBlock(1:region(4,1), region(4,2)+1:end,:);
            % Quadrant4
            obj.Buffer(1:region(3,1), 1:region(3,2),:) = newBlock(region(4,1)+1:end, region(4,2)+1:end,:);
        end
        
        function setBaseMatrixValueAtIndices(obj,indices,values)
            % Sets values of base matrix at specified base matrix indices
            % computed by index. The base matrix indices computed by index class 
            % can be reused by multiple circular buffers using this functionality.
            
            linearInd = size(obj.Buffer,1)*(indices(:,2)-1)+indices(:,1);
            dataDims = size(obj.Buffer,3);
            if dataDims == 1
                obj.Buffer(linearInd) = values;
            else
                pageSize = size(obj.Buffer,1)*size(obj.Buffer,2);
                if isscalar(values)
                    for i = 1:dataDims
                        obj.Buffer(linearInd) = values;
                        linearInd = linearInd+pageSize;
                    end
                else
                    vals = values(:,1,:);
                    for i = 1:dataDims
                        obj.Buffer(linearInd) = vals(:,1,i);
                        linearInd = linearInd+pageSize;
                    end
                end
            end
        end
        
        function setBaseMatrixWithScalar(obj,constVal)
            % Fill a constant value at all locations of base matrix
            obj.Buffer(:) = constVal;
        end
    end

    methods (Static, Hidden)
        function result = matlabCodegenSoftNontunableProperties(~)
        %matlabCodegenSoftNontunableProperties Mark properties as nontunable during codegen
        %
        % Marking properties as 'Nontunable' indicates to Coder that
        % the property should be made compile-time Constant.
            result = {'BufferSize'};
        end
    end
end

