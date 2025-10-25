classdef MultiResolutionGridStack < nav.algs.internal.InternalAccess
%This class is for internal use only. It may be removed in the future.

%MULTIRESOLUTIONGRIDSTACK Precomputed multi-resolution grid stack
%   Note that grids of different resolutions in a stack always have the
%   same matrix size.
%
%   Copyright 2017-2020 The MathWorks, Inc.

%#codegen

    properties
        %DetailedMatrix Grid matrix at finest resolution
        DetailedMatrix

        %MultiResMatrices Grid matrices of different resolutions
        MultiResMatrices

        %MatrixSize Size of DetailedMatrix
        MatrixSize

        %TempResultGrid Temporary result grid
        TempResultGrid

        %LowResPadded Zero Padded Low Resolution Matrix. Zeros are padded
        %   outside grid boundaries for handling out-of-bound indices.
        LowResPadded 

        %Sequence Stores indices of non-zero detailed matrix elements
        Sequence = [0 0 0]

        %SequenceSet Set to true after the computing the sequence
        SequenceSet = false
    end

    methods
        function obj = MultiResolutionGridStack(varargin)
        %MultiResolutionGridStack Constructor
        %   MultiResolutionGridStack(DETAILEDMAPSTRUCT, MAXLEVEL)
        %   DETAILEDMAPSTRUCT is a struct with necessary map-related
        %   elements, and MAXLEVEL is the number of resolution levels 
        %   minus one
        %
        %   MultiResolutionGridStack(DETAILEDMAP, MAXLEVEL)
        %   DETAILEDMAP is a nav.algs.internal.SimpleOccupancyMap object
        %   MAXLEVEL is the number of resolution levels minus one
        %
        %   MultiResolutionGridStack(DETAILEDGRIDMATRIX, MULTIRESGRIDMATRICES)
        %   DETAILEDGRIDMATRIX is a double matrix, and
        %   MULTIRESGRIDMATRICES is a cell array of double matrices

            if isstruct(varargin{1}) % syntax 1
                detailedMap = varargin{1};
                maxLevel = varargin{2};
                
                obj.MatrixSize = detailedMap.GridSize;

                % inflate scan
                radius = nav.algs.internal.MapUtils.validateInflationRadius(...
                               1, detailedMap.Resolution, true, detailedMap.GridSize, 'radius');
            
                se = nav.algs.internal.diskstrel(radius);
                inflatedDetailedMatrix = nav.algs.internal.inflate_double(detailedMap.GridMatrix, se);
                
                
                obj.MultiResMatrices = zeros([obj.MatrixSize, maxLevel]);
                obj.DetailedMatrix = inflatedDetailedMatrix;

                % set "unknown (0.5)" and "likely empty (< 0.5)" grid probability to zero
                obj.DetailedMatrix(obj.DetailedMatrix < 0.51) = 0;


                for lv = 1:maxLevel
                    obj.MultiResMatrices(:,:,lv) = obj.precompute(lv);
                end
            elseif isa(varargin{1}, 'nav.algs.internal.SimpleOccupancyMap') 
                
                detailedMap = varargin{1};
                maxLevel = varargin{2};

                se = nav.algs.internal.diskstrel(1);
                detailedMap.GridMatrix = nav.algs.internal.impl.inflate(detailedMap.GridMatrix, se);

                obj.MatrixSize = detailedMap.GridSize;
                obj.MultiResMatrices = zeros([detailedMap.GridSize,maxLevel]);
                obj.DetailedMatrix = detailedMap.occupancyMatrix();

                % set "unknown" and "likely empty" grid probability to zero
                obj.DetailedMatrix(obj.DetailedMatrix < 0.51) = 0;

                for lv = 1:maxLevel
                    obj.MultiResMatrices(:,:,lv) = obj.precompute(lv);
                end
            else
                obj.DetailedMatrix = varargin{1};
                obj.MultiResMatrices = varargin{2};
                obj.MatrixSize = size(obj.DetailedMatrix);
            end
            
            % Pad zeros around low resolution grid. This is necessary to
            % return zeros at grid indices that lie outside low resolution
            % grid. The expected indices can be away from grid boundaries
            % by a maximum of grid size when initial guess is located at
            % grid boundaries.
            obj.LowResPadded = zeros(3*obj.MatrixSize);
            obj.LowResPadded(obj.MatrixSize(1)+1:2*obj.MatrixSize(1),...
                obj.MatrixSize(2)+1:2*obj.MatrixSize(2)) = obj.MultiResMatrices(:,:,end);
        end

        function computeSequence(obj)
            %computeSequence

            if ~obj.SequenceSet
                % compute the sequence only once
                [II, JJ, VV] = find(obj.DetailedMatrix);
                sequence = [VV, II, JJ ];
            
                obj.Sequence = sortrows(sequence);
            end
        end
        
        function resultGrid = precompute(obj, lvl)
        %precompute Returns RESULTGRID, a matrix of the same size as
        %   DetailedMatrix, at the specified resolution level LV
            
            obj.computeSequence();
            sz = size(obj.DetailedMatrix);
            L = size(obj.Sequence,1);
            %expand
            wid = 2^lvl-1;
            % pad zeros around grid to handle indices that lie outside
            % grid 
            obj.TempResultGrid = zeros(sz+(2*wid));
            for k = 1:L
                ii = obj.Sequence(k,2)+wid;
                jj = obj.Sequence(k,3)+wid;

                for m = ii-wid:ii
                    for n = jj-wid:jj
                        obj.TempResultGrid(m, n) = obj.Sequence(k,1);
                    end

                end
            end
            % only return the actual grid removing the padded region
            resultGrid = obj.TempResultGrid((wid+1):(wid+sz(1)),(wid+1):(wid+sz(2)));
        end

        function value = getValue(obj, lvl, ij)
        %getValue
            sz = obj.MatrixSize;
            if (ij(1) < 1) || (ij(2) < 1)
                value = 0;
                return;
            end

            if (ij(1) > sz(1) ) || (ij(2) > sz(2) )
                value = 0;
                return;
            end

            if lvl == 0
                value = obj.DetailedMatrix(ij(1), ij(2));
            else
                value = obj.MultiResMatrices(ij(1), ij(2), lvl);
            end
        end

        function value = getValueLowResUsingLinearIdx(obj, ij)
        %getValueLowResUsingLinearIdx return value from padded low
        %   resolution martrix. Input ij is expected to be a scalar linear index.

            value = obj.LowResPadded(ij(1));
        end

        function lowestResolutionIndices = convertXYToLowResLinearIndices(obj, ...
                lowestResolutionXYCandidates)
        %convertXYToLowResLinearIndices 

            msz = obj.MatrixSize;
            sz = size(obj.LowResPadded);
            lowestResolutionIndices = (lowestResolutionXYCandidates(:,2) + ...
                msz(2) - 1)*sz(1) + lowestResolutionXYCandidates(:,1) + msz(1);
        end

        function relLinInd = lowResPaddedSubToInd(obj, xyInd)
        %lowResPaddedSubToInd converts zero-padded low resolution matrix
        %   subscripts (X,Y) to linear indices

            sz = size(obj.LowResPadded);
            relLinInd = (xyInd(:,2) - 1)*sz(1) + xyInd(:,1);
        end

    end
end
