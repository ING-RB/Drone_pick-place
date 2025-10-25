classdef BlockMatrix < robotics.core.internal.InternalAccess
    %This class is for internal use only. It may be removed in the future.
    
    %BLOCKMATRIX A utility class to facilitate manipulation of block matrix
    
    %   Copyright 2017-2024 The MathWorks, Inc.
    
    %#codegen
    
    properties
        %Matrix Data
        Matrix
    end
    
    properties (SetAccess = private)
        %NumBlocksPerRow Number of row blocks
        NumRowBlocks
        
        %NumBlocksPerCol Number of column blocks
        NumColBlocks
        
        %BlockSize Size of each block
        BlockSize
    end
    
    methods
        function obj = BlockMatrix(varargin)
            %BlockMatrix Constructor
            narginchk(2,3);
            if nargin == 3
                %BlockMatrix(n, m, blockSize) initializes an empty
                %   BlockMatrix object.
                %   n         - number of row blocks
                %   m         - number of column blocks 
                %   blockSize - size of each block, a 1-by-2 vector
                n = varargin{1};
                m = varargin{2};
                blkSz = varargin{3};
                obj.Matrix = zeros(n*blkSz(1), m*blkSz(2));
                obj.BlockSize = blkSz;
                obj.NumRowBlocks = n;
                obj.NumColBlocks = m;
            else
                %BlockMatrix(M, blockSize) converts an existing double
                %   matrix into a BlockMatrix object 
                %   M         - A matrix
                %   blockSize - size of each block, a 1-by-2 vector
                M = varargin{1};
                blkSz = varargin{2};
                obj.Matrix = M;
                obj.BlockSize = blkSz;
                sz = size(M);
                obj.NumRowBlocks = sz(1)/blkSz(1);
                obj.NumColBlocks = sz(2)/blkSz(2);                
            end
            
        end
        
        function replaceBlock(obj, i, j, blockij)
            %replaceBlock 
            
            % indices out of bound
            % assert( (i<=obj.NumRowBlocks) && (j <= obj.NumColBlocks) );   
            
            % For code generation rowStart and columnStart should have a 
            % fixed size of 1X1.    
            rowStart = obj.BlockSize(1)*(i(1)-1)+1;
            colStart = obj.BlockSize(2)*(j(1)-1)+1;
 
            obj.Matrix(rowStart: rowStart+obj.BlockSize(1)-1, colStart: colStart+obj.BlockSize(2)-1) = blockij;
            if coder.target('MATLAB')
                if i > obj.NumRowBlocks
                    obj.NumRowBlocks = i;
                end
                if j > obj.NumColBlocks
                    obj.NumColBlocks = j;
                end
            end
        end
        
        function B = extractBlock(obj, i, j)
            %extractBlock 
            
            %indices out of bound
            % assert( (i<=obj.NumRowBlocks) && (j <= obj.NumColBlocks)); 
            
            rowStart = obj.BlockSize(1)*(i-1)+1;
            colStart = obj.BlockSize(2)*(j-1)+1;
 
            B = obj.Matrix(rowStart : rowStart+obj.BlockSize(1)-1, colStart : colStart+obj.BlockSize(2)-1);
        end
        
        function newObj = copy(obj)
            %copy
            newObj = robotics.core.internal.BlockMatrix(obj.Matrix, obj.BlockSize);
            
        end
        
        
        % getters
        function set.NumColBlocks(obj, nc)
            validateattributes(nc, {'numeric'}, {'integer', 'positive', 'scalar'}, 'BlockMatrix', 'NumColBlocks');
            obj.NumColBlocks = nc;
        end
        
        function set.NumRowBlocks(obj, nr)
            validateattributes(nr, {'numeric'}, {'integer', 'positive', 'scalar'}, 'BlockMatrix', 'NumRowBlocks');
            obj.NumRowBlocks = nr;
        end
        
        function set.BlockSize(obj, blkSz)
            validateattributes(blkSz, {'numeric'}, {'numel', 2, 'integer', 'positive'}, 'BlockMatrix', 'BlockSize');
            obj.BlockSize = blkSz;
        end
        
        function updateBlockMatrix(obj,newObj)
            %updateBlockMatrix
            
            % Updates an existing block matrix with new properties
            obj.Matrix = newObj.Matrix;
            obj.BlockSize = newObj.BlockSize;
            obj.NumColBlocks = newObj.NumColBlocks;
            obj.NumRowBlocks = newObj.NumRowBlocks;
        end
    end
end


