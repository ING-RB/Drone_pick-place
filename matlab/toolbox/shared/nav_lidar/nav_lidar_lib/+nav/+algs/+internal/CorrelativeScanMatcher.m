classdef CorrelativeScanMatcher < nav.algs.internal.InternalAccess & ...
        robotics.core.internal.InternalAccess
    %This class is for internal use only. It may be removed in the future.

    %CORRELATIVESCANMATCHER Correlative scan matcher

    %   Copyright 2017-2022 The MathWorks, Inc.

    %#codegen

    properties
        % properties related to reference map

        %MapRef Reference map, a occupancyMap object
        MapRef

        %MaxRange
        MaxRange

        %Resolution Resolution of MapRef (cell per meter)
        Resolution

        %CellSize Side length of each (square) cell, i.e. the inverse of resolution
        CellSize

        %GridLocInWorld Grid origin location in world coordinates
        GridLocInWorld

        %GridSize Size of MapRef
        %   A vector [ROWS COLS] indicating the size of MapRef as number of
        %   rows and columns.
        GridSize
        
        %InvSensorModel
        InvSensorModel
        
        %ProbSaturation
        ProbSaturation

        %MaxLevel Number of resolution levels
        MaxLevel

        %PrecomputedGridStack A stack of grid maps at different resolutions
        PrecomputedGridStack

        %CenterOffset The location of map center relative to the upper left
        %   corner of the occupancy grid as counts of finest resolution
        %   grid cells. This is a 2-vector
        CenterOffset
    end

    properties
        % properties related to matching

        %DeltaTheta Angle sweeping resolution
        DeltaTheta

        %LowestResolutionCandidates Relative pose candidates at lowest
        %   resolution grid. This property is an N-by-5 matrix, where N is
        %   the number of lowest resolution candidates.
        %   A candidate is a 5-vector like below
        %   [score, angleID, gridIDx, gridIDy, resolutionLevel]
        LowestResolutionCandidates

        %LowestResolutionIndices linear indices of lowest resolution
        %   candidates
        LowestResolutionIndices

        %NumLowestResolutionCandidates Number of lowest resolution
        %   candidates
        NumLowestResolutionCandidates

        %AllAngles All possible theta values, based on DeltaTheta
        AllAngles

        %NumAllAngles Number of all possible theta values
        NumAllAngles

        %AngleCandidates Angle candidate IDs
        AngleCandidates

        %XYSearchWindow XY search window in grid space as counts of lowest
        %   resolution grids. This is a 2-vector.
        XYSearchWindow

        %ThetaSearchWindow Theta search window as count of discretized
        %   search angles
        ThetaSearchWindow

        %DiscreteScans Scan points expressed as counts of grid cells in
        %   MapRef
        DiscreteScans

    end
    
    properties
        %ComputeCovariance
        ComputeCovariance
    end

    methods
        function obj = CorrelativeScanMatcher(source, maxRange, resolution, maxLevel, linearSearchWindowSize, angularSearchWindowSize)
        %CORRELATIVESCANMATCHER Constructor
            
            if isa(source, 'nav.algs.internal.Submap')
                % source is a grid matrix (at the finest resolution
                submapRef = source;
                obj.GridLocInWorld = [-submapRef.MaxRange, -submapRef.MaxRange];
                obj.GridSize = ceil([2*submapRef.MaxRange, 2*submapRef.MaxRange]*submapRef.Resolution);

                obj.MaxRange = submapRef.MaxRange;
                obj.Resolution = submapRef.Resolution;
                obj.CellSize = 1/obj.Resolution;
                obj.MaxLevel = submapRef.MaxLevel;
                obj.PrecomputedGridStack = nav.algs.internal.MultiResolutionGridStack(submapRef.DetailedGridMatrix, submapRef.MultiResGridMatrices);
            else
                % source is a lidarScan object
                obj.MaxRange = maxRange;
                obj.CellSize = 1/resolution;
                obj.Resolution = resolution;
                obj.GridLocInWorld = [-maxRange, -maxRange];
                
                height = 2*maxRange;
                width = height;
                rows = ceil(height*resolution);
                cols = ceil(width*resolution);
                obj.GridSize = [rows,cols];
                obj.InvSensorModel = [0.4, 0.7];
                obj.ProbSaturation = [0.001 0.999];

                scanRef = source;
                scanRef = scanRef.removeInvalidData('RangeLimits', [obj.CellSize, maxRange]);
                detailedMatrix = obj.scanToGridMap(scanRef);
                detailedMap = struct('Resolution', obj.Resolution, 'GridSize', obj.GridSize, 'GridMatrix', detailedMatrix);

                obj.MaxLevel = maxLevel;
                obj.PrecomputedGridStack = nav.algs.internal.MultiResolutionGridStack(detailedMap, obj.MaxLevel);
            end


            obj.CenterOffset = ceil(obj.GridSize/2);

            obj.preallocateLowestResolutionCandidates;

            % search windows, used when an initial guess is provided
            obj.XYSearchWindow = ceil(linearSearchWindowSize/(obj.CellSize * 2^obj.MaxLevel));
            obj.ThetaSearchWindow = ceil(angularSearchWindowSize/obj.DeltaTheta);

            obj.ComputeCovariance = false;
        end


        function preallocateLowestResolutionCandidates(obj)
        %preallocateLowestResolutionCandidates Pre-allocate the memory
        %   space for lowest resolution candidates, and initialize some
        %   search related properties

            obj.DeltaTheta = acos(1 - (obj.CellSize*obj.CellSize)/(2*obj.MaxRange*obj.MaxRange));
            m = ceil(2*pi/obj.DeltaTheta);
            obj.NumAllAngles = m - 1;
            angles = linspace(0, 2*pi, m);
            obj.AllAngles = angles(1:obj.NumAllAngles);

            maxNumAngles = obj.NumAllAngles;
            maxNumRows = length(1:2^obj.MaxLevel:obj.GridSize(1));
            maxNumCols = length(1:2^obj.MaxLevel:obj.GridSize(2));

            obj.LowestResolutionCandidates = zeros(maxNumRows * maxNumCols * maxNumAngles, 5);
            obj.LowestResolutionIndices = zeros(maxNumRows * maxNumCols * maxNumAngles, 1);
        end


        function initializeLowestResolutionCandidates(obj, initialGuess)
        %initializeLowestResolutionCandidates

        %clear previous LowestResolutionCandidates
            obj.LowestResolutionCandidates = zeros(size(obj.LowestResolutionCandidates));
            obj.NumLowestResolutionCandidates = 0;

            if nargin > 1
                % if the initial guess is given

                x0 = initialGuess(1) - obj.GridLocInWorld(1);
                y0 = initialGuess(2) - obj.GridLocInWorld(2);
                theta0 = initialGuess(3);

                % populate lowest resolution candidates around the initial
                % guess
                n = 2^obj.MaxLevel;
                d = obj.CellSize*n;

                % snap initial guess to pre-allocated grids
                rowNum0 = obj.GridSize(1) - n*ceil(y0/d) + 1;
                colNum0 = n*floor(x0/d) + 1;
                thetaNum0 = floor(theta0/obj.DeltaTheta) + 1;

                % extract the rows and columns that intersect with the grid
                % from the considered search window
                rowNums = max(-n*obj.XYSearchWindow(1) + rowNum0,1): n : min(n*obj.XYSearchWindow(1) + rowNum0,obj.GridSize(1));
                colNums = max(-n*obj.XYSearchWindow(2) + colNum0,1): n : min(n*obj.XYSearchWindow(2) + colNum0,obj.GridSize(2));

                thetaNums = obj.specialMod(thetaNum0 - obj.ThetaSearchWindow:thetaNum0 + obj.ThetaSearchWindow);

            else
                % if initial guess in not given, encode the entire
                % possible search space
                rowNums = 1:2^obj.MaxLevel:obj.GridSize(1);
                colNums = 1:2^obj.MaxLevel:obj.GridSize(2);
                thetaNums = 1:obj.NumAllAngles;

            end

            [II,JJ] = meshgrid(rowNums, colNums);
            L = length(rowNums)*length(colNums);
            lowestResolutionXYCandidates = [II(:), JJ(:)] - repmat(obj.CenterOffset - [1, 1] , L, 1);
            msz = obj.PrecomputedGridStack.MatrixSize;
            sz = size(obj.PrecomputedGridStack.LowResPadded);
            lowestResolutionIndices = (lowestResolutionXYCandidates(:,2) + ...
                msz(2) - 1)*sz(1) + lowestResolutionXYCandidates(:,1) + msz(1);

            N = length(thetaNums)*L;
            allLowesetResolutionCandidates = [zeros(N, 2), repmat(lowestResolutionXYCandidates,...
                length(thetaNums), 1), repmat(obj.MaxLevel, N, 1)];
            allLowestResolutionIndices = repmat(lowestResolutionIndices, length(thetaNums), 1);
            if N > size(lowestResolutionXYCandidates,1)
                % replace the low resolution matrices if the pre-allocation is not enough
                obj.LowestResolutionCandidates = allLowesetResolutionCandidates(:,1:5);
                obj.LowestResolutionIndices = allLowestResolutionIndices(:,1);
            else
                obj.LowestResolutionCandidates(1:N, 1:5) = allLowesetResolutionCandidates(:,1:5);
                obj.LowestResolutionIndices(1:N,1) = allLowestResolutionIndices(:,1);
            end
            obj.NumLowestResolutionCandidates = N;
            obj.DiscreteScans = coder.nullcopy(cell(1, obj.NumAllAngles));

            for i = 1:length(thetaNums)
                obj.LowestResolutionCandidates((i-1)*L+1:i*L,2) = repmat(thetaNums(i), L, 1);
                obj.DiscreteScans{thetaNums(i)} = [0 0];
            end

            obj.AngleCandidates = {thetaNums};
        end

        function angleNumsMod = specialMod(obj, angleNums)
        %specialMod Similar to regular mod, but this one is 1-based
        %   indexing
            angleNumsMod = mod(angleNums, obj.NumAllAngles);
            angleNumsMod(angleNumsMod == 0) = obj.NumAllAngles;
        end



        function idxBinary = rasterizeScan(obj, scanPoints)
        %RASTERIZESCAN Discretize scan at finest grid level

        % inserted at (0, 0, 0)
            x = scanPoints(:,1);
            y = scanPoints(:,2);

            x0 = obj.GridLocInWorld(1);
            y0 = obj.GridLocInWorld(2);

            idxBinary = [obj.GridSize(1) - floor((y - y0)*obj.Resolution),   ceil((x - x0)*obj.Resolution) ];

        end
        
        function [idxBinaryEndPts, idxBinaryMiddlePts] = rasterizeScanWithMiddlePoints(obj, scanPoints)
            %rasterizeScanWithMiddlePoints Discretize scan considering raycasting 
            rows = obj.GridSize(1);
            cols = obj.GridSize(2);
            [~,~, idxBinaryEndPts, idxBinaryMiddlePts] = nav.algs.internal.impl.raycastInternal([0, 0], scanPoints, rows, cols, obj.Resolution, obj.GridLocInWorld);
        end
        
        function mat = scanToGridMap(obj, scan)
            %scanToGridMap
            %   This operation is equivalent to insertRay with a lidar scan 
            %   at [0, 0, 0] on a clean slate, but ignoring middle points
            
            [idxBinaryEP, idxBinaryMP] = rasterizeScanWithMiddlePoints(obj, scan.Cartesian);
            
            idxUnaryEP = idxBinaryEP(:, 1) + obj.GridSize(1) * (idxBinaryEP(:, 2) - 1);
            [numRepeatsEP, idxEP] = hist(idxUnaryEP, unique(idxUnaryEP)); %#ok<HIST>
            
            idxUnaryMP = idxBinaryMP(:, 1) + obj.GridSize(1) * (idxBinaryMP(:, 2) - 1);
            [numRepeatsMP, idxMP] = hist(idxUnaryMP, unique(idxUnaryMP)); %#ok<HIST>
            
            mat = obj.createGridMatrix(idxEP, numRepeatsEP, idxMP, numRepeatsMP);
        end
        
        function mat = createGridMatrix(obj, indicesHit, repeatsHit, indicesMiss, repeatsMiss)
            %createGridMatrix Update a default grid map at specified grids
            
            p1 = obj.InvSensorModel(2); % prob. that the grid is occupied if the ovservation is hit
            p2 = obj.InvSensorModel(1); % prob. that the grid is unoccupied if the ovservation is miss
            
            logoddsHitDelta = log(p1/(1-p1));
            logoddsMissDelta = log(p2/(1-p2));
            mat = 0.5*ones(obj.GridSize(1), obj.GridSize(2));
            
            [~, loc] = ismember(indicesHit, indicesMiss);
            
            for i = 1:size(indicesHit, 1)
                if loc(i) > 0
                    m = loc(i);
                    logodds = repeatsHit(i)*logoddsHitDelta + repeatsMiss(m)*logoddsMissDelta;
                else
                    logodds = repeatsHit(i)*logoddsHitDelta;
                end
                
                p = 1 - 1/(1 + exp(logodds)); % logodds to prob
                if p > obj.ProbSaturation(2)
                    p = obj.ProbSaturation(2);
                end
                if p < obj.ProbSaturation(1)
                    p = obj.ProbSaturation(1);
                end
                mat(indicesHit(i)) = p;
            end

        end


        function scoreAndRankLowestResolutionCandidates(obj)
        %scoreAndRankLowestResolutionCandidates

            N = obj.NumLowestResolutionCandidates;
            evaluateLowestResolutionCandidates(obj);

            lowResCandidates = obj.LowestResolutionCandidates(1:N, :);
            [~,ind] = sort(lowResCandidates(:,1));
            obj.LowestResolutionCandidates(1:N, :) = lowResCandidates(ind,:);

        end

        function evaluateLowestResolutionCandidates(obj)
        %evaluateLowestResolutionCandidates
            
            angleNums = [obj.AngleCandidates{:}];
            numA = numel(angleNums);
            N = obj.NumLowestResolutionCandidates;
            % L is the total number of xy-shifted discrete scans rotated by angle, a.
            L = N/numA;
            for a = 1:numA
                scanIdx =angleNums(a);
                relativeIdx = obj.DiscreteScans{scanIdx};
                % Each discrete scan index is used "L" times, where L is is
                % the total number of xy-shifted discrete scans rotated by
                % angle, a. Indexing with subscripts (i,j) is converted to
                % linear index in generated code. The computed linear
                % indices for a descrete scan can be reused L times, which
                % improves the efficiency as it reduces the required number
                % of additions and multiplications needed for sub2idx
                % conversion
                relativeLinearIdx = obj.PrecomputedGridStack.lowResPaddedSubToInd(relativeIdx);
                for l = 1:L
                    sum = 0;
                    % compute low resolution candidate linear index. Each
                    % candidate represents some expected rotation and
                    % transltion.
                    cid = (a-1)*L + l;
                    for k = 1:length(relativeLinearIdx)
                        sum = sum + obj.PrecomputedGridStack.getValueLowResUsingLinearIdx(obj.LowestResolutionIndices(cid,1) ...
                            + relativeLinearIdx(k,1));
                    end
                    obj.LowestResolutionCandidates(cid, 1) = sum;
                end
            end
        end
        
        function covariance = estimateCovariance(obj, bestCandidate)
            %estimateCovariance Estimate the covariance around the best candidate
            %   The basic idea is to first sample around the best candidate
            %   to get a collection of correlation values, then try to 
            %   fit a multivariate normal distribution using the sampled data.

            baseA = bestCandidate(2);
            baseIJ = bestCandidate(3:4);
            bestScore = bestCandidate(1);
            bestX = extractRelPoseFromCandidate(obj, bestCandidate);
            
            % set the window around the best candidate for sampling
            d = 10;
            [dI,dJ] = meshgrid(-d:d, -d:d);
            deltaIJ = [dI(:), dJ(:)];
            deltaA_ = 5*(-d:d); % larger step for theta
            
            % codegen safeguard. Ideally, the max angle perturbation should
            % be small (i.e. abs(deltaA_) < 0.1*l ). If it turns out to be
            % bigger than that due to inappropriate resolution and range
            % input, then the covariance output will be vastly inaccurate.
            % Here, the bound l/2 only makes sure the generated mex does not
            % crash MATLAB, but does not guarantee the quality of the
            % estimated covariance.
            l = length(obj.DiscreteScans);
            mask = deltaA_ < l/2 & deltaA_ > -l/2;
            deltaA = deltaA_(mask);
            
            N = length(deltaA);
            M = size(deltaIJ ,1);

            % scores for each sample, roughly representing the conditional probability
            % of getting this scan given the current robot pose and the map.
            P = cell(N,1);
            for n = 1:N
                scanId = baseA + deltaA(n);
                if scanId < 1
                    scanId = obj.NumAllAngles + scanId;
                elseif scanId > obj.NumAllAngles
                    scanId = scanId - obj.NumAllAngles;
                end

                relevantIndices = obj.DiscreteScans{scanId};
                PIJ = zeros(size(deltaIJ,1),1);
                for m = 1:M
                    s = 0;
                    for k = 1:size(relevantIndices,1)
                        s = s + obj.PrecomputedGridStack.getValue(0, deltaIJ(m,:) + baseIJ + relevantIndices(k,:) );
                    end
                    PIJ(m) = s;
                end
                P{n} = PIJ;
            end

            sampleSets = cell(N,1);
            sampleIndices = zeros(N,2); % start and end indices for each set
            for n = 1:N
                PIJ = P{n};
                angleId = baseA + deltaA(n);
                if angleId < 1
                    angleId = obj.NumAllAngles + angleId;
                elseif angleId > obj.NumAllAngles
                    angleId = angleId - obj.NumAllAngles;
                end
                samples = zeros(M, 3 + 1); % sample and its corresponding probability
                
                k = 1;
                for m = 1:M
                    x = extractRelPoseFromCandidate(obj, [0, angleId, baseIJ + deltaIJ(m,:), 0]);
                    dx = x - bestX;

                    % if the score is lower than a threshold, just ignore the sample.
                    % This tends to produce a more accurate covariance estimation.
                    % 60% of the best score is an empirical value.
                    if PIJ(m) > 0.6*bestScore 
                        samples(k, 1:3) = dx;
                        samples(k, 4) = PIJ(m);
                        k = k + 1;
                    end
                end
                
                if n == 1
                    kStart = 1;
                else
                    kStart = sampleIndices(n-1, 2) + 1;
                end
                % k is next sample index. When k is 1 all samples are
                % ignored and dummy zero probability sample is stored in
                % sampleSets for codegen purpose.
                k = max(k-1,1);
                sampleSets{n} = samples(1:k, :);
                sampleIndices(n,1:2) = [kStart, kStart+k-1];
            end
            
            if N > 0
                A = zeros(sampleIndices(N,2), 4);
                for i = 1:N
                    A(sampleIndices(i,1):sampleIndices(i,2), :) = sampleSets{i};
                end
            else
                A = zeros(0, 4); % for codegen robustness, in this case covarince will be all Nans
            end
            

            %
            % the formula
            K = zeros(3);
            u = zeros(3,1);
            s = 0;
            
            for i = 1:size(A,1)

                dx = A(i, 1:3);
                p = A(i, 4);
                
                K = K + dx'*dx*p;
                u = u + dx'*p;
                s = s + p;
                
            end
            covariance = (1/s)*K - (1/(s*s))*(u*u');
        end


        function subtreeCandidates = evaluateSubtreeCandidates(obj, candidate)
        %evaluateSubtreeCandidates Evaluate all candidates in the
        %   subtree

        % each candidate is a 5-vector
        % [score, angleID, gridIDx, gridIDy, resolutionLevel]
            lvl = candidate(5);
            newLvl = lvl -1 ;
            deltaIJ = candidate(3:4);
            angleId = candidate(2);
            indexOffset = bitshift(1, newLvl);
            deltaIJs = [deltaIJ;
                        deltaIJ + [indexOffset, 0];
                        deltaIJ + [0, indexOffset];
                        deltaIJ + [indexOffset, indexOffset]];

            subtreeCandidates = [zeros(4,1), repmat(angleId, 4,1), deltaIJs, repmat(newLvl, 4,1)];

            relevantIndices = obj.DiscreteScans{angleId};
            for i = 1:4
                sum = 0;
                for k = 1:size(relevantIndices,1)
                    sum = sum + obj.PrecomputedGridStack.getValue(newLvl, deltaIJs(i,:) + relevantIndices(k,:) );
                end
                subtreeCandidates(i,1) = sum;
            end
            subtreeCandidates = sortrows(subtreeCandidates);
        end


        function [p, score, covariance] = match(obj, scanCurr, initialPose)
        %match
            coder.inline('never');
            if nargin > 2
                obj.initializeLowestResolutionCandidates(initialPose);
            else
                obj.initializeLowestResolutionCandidates;
            end

            scanCurr = scanCurr.removeInvalidData('RangeLimits', [obj.CellSize, obj.MaxRange]);
            scanPointsCurr = scanCurr.Cartesian;

            angleNums = [obj.AngleCandidates{:}];

            for i = 1:numel(angleNums)
                sc = transformScanPoints(scanPointsCurr, [0 0 obj.AllAngles(angleNums(i))]);
                obj.DiscreteScans{angleNums(i)} = obj.rasterizeScan(sc);
            end

            obj.scoreAndRankLowestResolutionCandidates();

            % branch and bound
            L = obj.NumLowestResolutionCandidates;
            ss = robotics.core.internal.Stack(zeros(1,5), ceil(1.2*L), false);
            ss.Data(1:L,1:5) = obj.LowestResolutionCandidates(1:L,:); % quick fill stack
            ss.Depth = L;

            bestScore = 0;
            bestCandidate = zeros(1,5);
            while(ss.Depth > 0)
                candidate = ss.pop();
                if candidate(5) == 0 % only accept best score at finest resolution level (level 0)
                    if candidate(1) > bestScore % score
                        bestScore = candidate(1);
                        bestCandidate = candidate;
                    end

                elseif bestScore <= candidate(1) % if not at the finest resolution level, and the score is better than the best score, branch
                    subtreeCandidates = obj.evaluateSubtreeCandidates(candidate);
                    for h = 1:4
                        ss.push(subtreeCandidates(h,:));
                    end
                end
            end

            [p, score] = obj.extractRelPoseFromCandidate(bestCandidate);

            if obj.ComputeCovariance
                covariance = estimateCovariance(obj, bestCandidate);
            else
                covariance = zeros(3);
            end
        end

        function [relPose, score] = extractRelPoseFromCandidate(obj, candidate)
        %extractRelPoseFromCandidate
            i = candidate(3);
            j = candidate(4);
            angleNum = candidate(2);

            loc = obj.GridLocInWorld;

            i = obj.CenterOffset(1) + i;
            j = obj.CenterOffset(2) + j;
            xy = [loc(1)+ j*obj.CellSize, loc(2) + (obj.GridSize(1)-i)*obj.CellSize];

            angle = robotics.internal.wrapToPi( (angleNum/obj.NumAllAngles)*2*pi);
            relPose = [xy, angle];

            score = candidate(1);
        end

    end
end

function scanT = transformScanPoints(scan, pose)
%TRANSFORMSCANPOINTS

% Create rotation matrix
    theta = pose(3);
    ctheta = cos(theta);
    stheta = sin(theta);
    x = pose(1);
    y = pose(2);

    scanT = [scan(:,1)*ctheta - scan(:,2)*stheta + x, ...
             scan(:,1)*stheta + scan(:,2)*ctheta + y];

end
