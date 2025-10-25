classdef Submap
    %This function is for internal use only. It may be removed in the future.
    
    %SUBMAP Create submap from a few neighboring scans
    
    %#codegen
    
    %   Copyright 2017-2020 The MathWorks, Inc.
    
    properties
        %DetailedMatrix
        DetailedGridMatrix
        
        %MultiResGridMatrices
        MultiResGridMatrices
        
        %Center Center of the submap in global coordinates
        Center
        
        %AnchorScanIndex
        AnchorScanIndex
    end
    
    properties
        % information to pass to nav.algs.internal.CorrelativeScanMatcher
        
        %MaxRange
        MaxRange
        
        %Resolution
        Resolution
        
        %MaxLevel
        MaxLevel
    end
    
    methods
        function obj = Submap(scans, scanIndices, poses, anchorId, resolution, maxRange, maxLevel)
            %SUBMAP Constructor
            
            if nargin > 0
                gridSize = ceil([2*maxRange, 2*maxRange]*resolution);
                mapRef = nav.algs.internal.SimpleOccupancyMap(gridSize, resolution);
                mapRef.GridLocationInWorld = [-maxRange, -maxRange];
                
                numScans = length(scanIndices);
                
                rp0 = robotics.core.internal.SEHelpers.poseInvSE2(poses(anchorId, :));
                posesNew = zeros(numScans, 3);
                for i = 1:numScans
                    posesNew(i,:) = robotics.core.internal.SEHelpers.accumulatePoseSE2(rp0, poses(i,:)); % note the sequence
                end
                
                % this for loop accounts for the majority of the runtime of this method (in mex'ed code)
                for i = 1:numScans
                    sc = scans{scanIndices(i)};
                    sc = sc.removeInvalidData('RangeLimits', [0.05, maxRange]);
                    mapRef.insertRay(posesNew(i,:), sc, maxRange);
                end
                
                %             if true
                %                 figure
                %                 mapRef.show
                %                 hold on
                %                 plot(poses(:,1), poses(:,2), 'rs-')
                %                 plot(posesNew(:,1), posesNew(:,2), 'bo-')
                %             end
                
                % inflate by 1 grid
                se = nav.algs.internal.diskstrel(1);
                mapRef.GridMatrix = nav.algs.internal.impl.inflate(mapRef.GridMatrix, se);
                
                
                M = mapRef.occupancyMatrix;
                M(M<0.51) = 0;
                
                obj.DetailedGridMatrix = M;
                
                if maxLevel >= 1
                    gridStack = nav.algs.internal.MultiResolutionGridStack(mapRef, maxLevel);
                    obj.MultiResGridMatrices = gridStack.MultiResMatrices;
                else
                    obj.MultiResGridMatrices = zeros(1,1,1); % for quick testing
                end
                
                obj.Center = poses(anchorId,1:2);
                
                obj.Resolution = resolution;
                obj.MaxRange = maxRange;
                obj.MaxLevel = maxLevel;
                
                obj.AnchorScanIndex = scanIndices(anchorId);
                
            else
                % Empty map creation. This is required for efficient
                % pre-allocation for codegen. While creating a dummy submap
                % just for preallocation its not very efficient to store
                % real multi resolution matrices. These will be computed at
                % runtime. So instead of saving real multi resolution
                % matrices and detailed grid matrix storing dummy zero
                % values.
                coder.varsize('mat', [inf, inf], [1, 1]);
                coder.varsize('multiResMat', [inf, inf, inf], [1, 1, 1]);
                mat = 0;
                multiResMat = zeros(1,1,1);
                obj.DetailedGridMatrix = mat;
                obj.MultiResGridMatrices = multiResMat;
                obj.Center = zeros(1,2);
                obj.Resolution = 0;
                obj.MaxRange = 0;
                obj.MaxLevel = 0;
                obj.AnchorScanIndex = 0;
            end
        end
        
    end
end
