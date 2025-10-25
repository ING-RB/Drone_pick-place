classdef CircularBufferIndex < matlabshared.autonomous.map.internal.InternalAccess
%This class is for internal use only. It may be removed in the future.

%CircularBufferIndex index class useful for CircularBuffer.

%   Copyright 2019-2021 The MathWorks, Inc.

%#codegen
    
    properties (Access = {?matlabshared.autonomous.map.internal.InternalAccess})
        %Head grid index of the current lower left corner
        Head
        
        %Size number of rows and columns in the grid
        Size
        
        %NewRegions contains starting index of the region effected by move 
        %and effected number of rows and columns 
        %[rowIndex columnIndex numRowsToClear numberOfColumnsToClear]
        NewRegions
        %DropEntireMap flag is set when entire map is effected by move
        DropEntireMap
        %DropTwoRegions flag is set when number of rows/columns to clear
        %from the start index exceeds matrix dimensions
        DropTwoRegions
        
    end
    
    methods 
        function obj = CircularBufferIndex(bufferSize)
            %CircularBufferIndex Construct an instance of this class
            obj.Head = [1,1];
            validateattributes(bufferSize,{'numeric'},{'numel',2,'integer','positive'},'CircularBufferIndex','bufferSize');
            coder.internal.prefer_const(bufferSize); % g2607528
            obj.Size = bufferSize;
            obj.DropEntireMap = false;
            obj.NewRegions = zeros(1,4);
            obj.DropTwoRegions = false(1,2);
        end
        
        function shift(obj,cells)
            %shift moved head by specified number of cells and computes new
            %   regions
            nCells = abs(cells);
            if any(nCells >= obj.Size) 
               % Drop entire map when moved by distance greater than grid size 
               obj.DropEntireMap = true;
               obj.Head = obj.wrapIndex(obj.Head + cells);
               % Store offset info
               obj.NewRegions = [1 1 cells];
            else
                % Save start index
                startIndex = obj.Head;
                % Calculate end index
                endIndex = obj.Head + cells;
                % Wrap end index
                obj.Head = obj.wrapIndex(endIndex);
                % If wrapping occurs, mark which directions wrapped
                obj.DropTwoRegions = endIndex ~= obj.Head;
                % Store start and offset info
                obj.NewRegions = [startIndex cells];
            end
        end
        
        function newObj = copy(obj)
            newObj = matlabshared.autonomous.internal.CircularBufferIndex(obj.Size);
            newObj.Head = obj.Head;
            newObj.Size = obj.Size;
            newObj.NewRegions = obj.NewRegions;
            newObj.DropEntireMap = obj.DropEntireMap;
            newObj.DropTwoRegions = obj.DropTwoRegions;
        end
        
        function region = toBaseMatrixIndex(obj, index, matSize)
            %toBaseMatrixIndex computed true matrix boundaries corresponding
            %   to the block specified by index and size
            
            % first allocate the starting index
            mapStart = obj.Head + index - 1;
            mapStart = wrapIndex(obj, mapStart);
            
            if nargin == 3
                % then find the separation index in the assignment matrix
                matrixMid =  min(obj.Size-mapStart+1, matSize(1:2));
                % last find the separation index in the map matrix
                mapEnd = mapStart+matrixMid-1;
                mapWrap = matSize(1:2)-matrixMid;
                region = [mapStart; mapEnd; mapWrap; matrixMid];
            else
                region = mapStart;
            end
        end
    end
    
    methods (Access = {?matlabshared.autonomous.map.internal.InternalAccess,...
                       ?matlab.unittest.TestCase})
        
        function resetNewRegions(obj)
            %resetNewRegions clears the computed new regions
            
            obj.DropEntireMap = false;
            obj.NewRegions = zeros(1,4);
            obj.DropTwoRegions = false(1,2);
        end
        
        function [reg, minimumMatrix] = computeSetBoundaries(obj,index,matrix)
            % Reruns base matrix boundaries associated block, and
            % extracted block from specified matrix with size equal to the 
            % specified block size   
            
            indexStart = max(index, [1,1]);
            % If the row or column index of the specified lower left corner
            % is lies out grid boundaries wrap it back to be within grid
            % boundaries by using circular indexing
            if (indexStart(1)>obj.Size(1))||(indexStart(2)>obj.Size(2))
                indexStart = obj.toBaseMatrixIndex(indexStart);
            end
            sz = size(matrix, [1 2]);
            b = min(sz, obj.Size-indexStart+1);
            minimumMatrix = matrix(1:b(1), 1:b(2),:);
            reg = obj.toBaseMatrixIndex(indexStart, b);
        end
        
        function [region,blockSize] =computeGetBoundaries(obj,index1,index2)
            % Returns base matrix get boundaries
            
            indexMin = max(index1, [1,1]);
            indexMax = min(index2, obj.Size);
            blockSize = indexMax-indexMin+1;
            region = obj.toBaseMatrixIndex(indexMin, blockSize);
        end
    end
    
    methods (Access = private)
        
        function idx = wrapIndex(obj, idx)
            %wrapIndex wraps the idx to the circular buffer
            idx = mod(idx-1, obj.Size)+1;
        end
    end
    
    methods (Static, Hidden)
        function result = matlabCodegenSoftNontunableProperties(~)
        %matlabCodegenSoftNontunableProperties Mark properties as nontunable during codegen
        %
        % Marking properties as 'Nontunable' indicates to Coder that
        % the property should be made compile-time Constant.
            result = {'Size'};
        end
    end
end
