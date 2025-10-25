classdef (Abstract) VectorFieldHistogramBase < matlab.System
%This class is for internal use only. It may be removed in the future.

%VectorFieldHistogramBase Base class for controllerVFH implementation in MATLAB and in Simulink
%
%   See also controllerVFH, nav.slalgs.internal.VectorFieldHistogram.

%   Copyright 2017-2024 The MathWorks, Inc.

%#codegen

    properties (Nontunable)
        %NumAngularSectors Number of angular sectors
        %   The number of angular sectors are the number of bins used to
        %   create histograms
        %
        %   Default: 180
        NumAngularSectors = 180
    end

    properties (Hidden)
        %NarrowOpeningThreshold Angular threshold in radians
        %   This is an angular threshold, specified in radians, to consider
        %   an angular region to be narrow. The algorithm selects one
        %   candidate direction for each narrow region, while it selects
        %   two candidate directions in each non-narrow region.
        %
        %   Default: 0.8
        NarrowOpeningThreshold = 0.8
    end

    properties
        %DistanceLimits Range distance limits (m)
        %   The range readings specified in the step function input are
        %   considered only if they fall within the distance limits.
        %   The lower distance limit is specified to ignore false
        %   positive data while the higher distance limit is specified
        %   to ignore obstacles that are too far from the vehicle.
        %
        %   Default: [0.05 2]
        DistanceLimits = [0.05, 2];

        %RobotRadius Vehicle radius (m)
        %   This is radius of the smallest circle that can circumscribe the
        %   vehicle geometry. The vehicle radius is used to account for vehicle
        %   size in the computation of the obstacle-free direction.
        %
        %   Default: 0.1
        RobotRadius = 0.1;

        %SafetyDistance Safety distance (m)
        %   This is a safety distance to leave around the vehicle position in
        %   addition to the RobotRadius. The vehicle radius and safety
        %   distance are used in the computation of the obstacle-free
        %   direction.
        %
        %   Default: 0.1
        SafetyDistance = 0.1;

        %MinTurningRadius Minimum turning radius (m)
        %   This is the minimum turning radius with which the vehicle can turn
        %   while moving at its current speed.
        %
        %   Default: 0.1
        MinTurningRadius = 0.1;

        %TargetDirectionWeight Target direction weight
        %   This is the cost function weight for moving towards the target
        %   direction. To follow a target direction, the
        %   TargetDirectionWeight should be higher than the sum of
        %   CurrentDirectionWeight and PreviousDirectionWeight. You can
        %   ignore the target direction cost by setting this weight to zero.
        %
        %   Default: 5
        TargetDirectionWeight = 5

        %CurrentDirectionWeight Current direction weight
        %   This is the cost function weight for moving in the current
        %   heading direction. Higher values of this weight produces
        %   efficient paths. You can ignore the current direction cost
        %   by setting this weight to zero.
        %
        %   Default: 2
        CurrentDirectionWeight = 2

        %PreviousDirectionWeight Previous direction weight
        %   This is the cost function weight for moving in the previously
        %   selected steering direction. Higher values of this weight
        %   produces smoother paths. You can ignore the previous direction
        %   cost by setting this weight to zero.
        %
        %   Default: 2
        PreviousDirectionWeight = 2

        %HistogramThresholds Histogram thresholds
        %   These thresholds are used to compute the binary histogram from
        %   the polar obstacle density. Polar obstacle density values higher
        %   than the upper threshold are considered to be occupied (1) in
        %   the binary histogram. Polar obstacle density values smaller
        %   than the lower threshold are considered to be free space (0) in
        %   the binary histogram. The values of polar obstacle density that
        %   fall between the upper and lower thresholds are determined by
        %   the previous binary histogram, with default being free space (0).
        %
        %   Default: [3 10]
        HistogramThresholds = [3 10]
    end

    properties(Access = {?nav.algs.internal.VectorFieldHistogramBase, ...
                         ?matlab.unittest.TestCase})
        %PolarObstacleDensity Polar obstacle density histogram
        PolarObstacleDensity

        %BinaryHistogram Binary polar histogram
        BinaryHistogram

        %MaskedHistogram Masked polar histogram
        MaskedHistogram

        %PreviousDirection Steering direction output of the last step call
        %
        %   Default: 0
        PreviousDirection

        %TargetDirection Target direction specified in the last step call
        %
        %   Default: 0
        TargetDirection

        %AngularSectorMidPoints Angular sectors in radians
        %   These are the angular sectors determined based on the angular
        %   limits and the number of angular sectors.
        AngularSectorMidPoints

        %AngularDifference Size of each angular sector
        AngularDifference

        %AngularSectorStartPoints Start points of angular sectors
        AngularSectorStartPoints

        %AngularSectorEndPoints Start and end points for angular sectors
        AngularSectorEndPoints
    end

    properties (Access = protected)
        %Ranges Range sensor reading from the last step call
        Ranges

        %Angles Angles corresponding to ranges from the last step call
        Angles

        %AngularLimits Minimum and maximum angular limits in radians
        %   A vector [MIN MAX] representing the angular limits to consider
        %   as candidate directions. This is usually the angular limits of
        %   the range sensor. If an empty value is assigned, the angular
        %   limits will be computed from the input angles in the step
        %   function.
        %
        %   Default: [-pi, pi]
        AngularLimits = [-pi, pi];
    end


    methods (Access = protected)
        function loadObjectImpl(obj, svObj, wasLocked)
        %loadObjectImpl Custom load implementation

            mco = ?nav.algs.internal.VectorFieldHistogramBase;
            propList = mco.PropertyList;

            % Re-load all protected properties
            for i = 1:length(propList)
                propName = mco.PropertyList(i).Name;
                if robotics.internal.isProtectedProperty(mco, propList(i)) && ...
                        isfield(svObj, propName)
                    obj.(propName) = svObj.(propName);
                end
            end

            % Call base class method
            loadObjectImpl@matlab.System(obj,svObj,wasLocked);
        end


        function s = saveObjectImpl(obj)
        %saveObjectImpl Custom save implementation
            s = saveObjectImpl@matlab.System(obj);

            % Save all protected properties
            mco = ?nav.algs.internal.VectorFieldHistogramBase;
            propList = mco.PropertyList;

            for i = 1:length(propList)
                propName = mco.PropertyList(i).Name;
                if robotics.internal.isProtectedProperty(mco, propList(i))
                    s.(propName) = obj.(propName);
                end
            end
        end

        function outFixedSize = isOutputFixedSizeImpl(~)
        %isOutputFixedSizeImpl Return true for each output port with fixed size

        % Steering direction is fixed size
            outFixedSize = true;
        end

        function resetImpl(obj)
        %resetImpl Reset internal states

            obj.BinaryHistogram = false(1, obj.NumAngularSectors);
            obj.PreviousDirection = 0*obj.PreviousDirection;
        end

        function num = getNumOutputsImpl(~)
        %getNumOutputsImpl Define number of outputs for system with optional outputs
            num = 1;
        end

    end

    methods
        function set.DistanceLimits(obj, val)
            validateNonnegativeArray(val, 'DistanceLimits');
            obj.DistanceLimits = [min(val) max(val)];
        end

        function set.NarrowOpeningThreshold(obj, val)
            validateattributes(val, {'double'}, {'nonnan', 'real', ...
                                'scalar', 'positive', 'finite'}, 'controllerVFH',...
                               'NarrowOpeningThreshold');
            obj.NarrowOpeningThreshold = val;
        end

        function set.RobotRadius(obj, val)
            validateNonnegativeScalar(val, 'RobotRadius');
            obj.RobotRadius = val;
        end

        function set.SafetyDistance(obj, val)
            validateNonnegativeScalar(val, 'SafetyDistance');
            obj.SafetyDistance = val;
        end

        function set.MinTurningRadius(obj, val)
            validateNonnegativeScalar(val, 'MinTurningRadius');
            obj.MinTurningRadius = val;
        end

        function set.TargetDirectionWeight(obj, val)
            validateNonnegativeScalar(val, 'TargetDirectionWeight');
            obj.TargetDirectionWeight = val;
        end

        function set.CurrentDirectionWeight(obj, val)
            validateNonnegativeScalar(val, 'CurrentDirectionWeight');
            obj.CurrentDirectionWeight = val;
        end

        function set.PreviousDirectionWeight(obj, val)
            validateNonnegativeScalar(val, 'PreviousDirectionWeight');
            obj.PreviousDirectionWeight = val;
        end

        function set.HistogramThresholds(obj, val)
            validateNonnegativeArray(val, 'HistogramThresholds');
            obj.HistogramThresholds = [min(val) max(val)];
        end

        function set.NumAngularSectors(obj, val)
            validateattributes(val, {'double', 'single'}, {'nonnan', 'integer', ...
                                'scalar', 'positive', 'finite'}, 'controllerVFH', ...
                               'NumAngularSectors');
            obj.NumAngularSectors = val;
        end

        function val = get.NumAngularSectors(obj)
            val = obj.NumAngularSectors;
        end
    end

    % Abstract methods that should be implemented by all derived
    % classes.
    methods (Abstract, Access = protected)
        [scan, target, classOfRanges] = parseAndValidateStepInputs(varargin);
    end

    methods (Access = protected)
        function setupImpl(obj, varargin)
        %setupImpl Setup for the system object

            [~, ~, classOfRanges] = obj.parseAndValidateStepInputs(varargin{:});

            obj.PreviousDirection = cast(0, classOfRanges);
            angularLimits = cast(obj.AngularLimits, classOfRanges);
            numAngularSectors = cast(obj.NumAngularSectors, classOfRanges);

            % Create angular sectors
            obj.AngularSectorMidPoints = linspace(angularLimits(1,1)+...
                                                  pi/numAngularSectors, angularLimits(1,2)-...
                                                  pi/numAngularSectors, numAngularSectors);

            if numAngularSectors > 1
                obj.AngularDifference = abs(robotics.internal.angdiff(...
                    obj.AngularSectorMidPoints(1,1), ...
                    obj.AngularSectorMidPoints(1,2)));
            else
                obj.AngularDifference = cast(2*pi, classOfRanges);
            end

            obj.AngularSectorStartPoints = obj.AngularSectorMidPoints - ...
                obj.AngularDifference/2;
            sectorEndPoints = obj.AngularSectorMidPoints + ...
                obj.AngularDifference/2;
            sectorPoints = [obj.AngularSectorStartPoints; ...
                            sectorEndPoints];
            obj.AngularSectorEndPoints = sectorPoints(:)';

            % Pre-allocate the histogram
            obj.BinaryHistogram = false(1, obj.NumAngularSectors);
        end

        function steeringDir = stepImpl(obj, varargin)
        %step Compute control commands and steering direction
        %   STEERINGDIR = step(VFH, RANGES, ANGLES, TARGETDIR) finds an obstacle
        %   free steering direction STEERINGDIR, using the VFH+ algorithm for
        %   input vectors RANGES and ANGLES of the same number of elements, and
        %   scalar input TARGETDIR. The input RANGES are in meters, the
        %   ANGLES and TARGETDIR are in radians. The output STEERINGDIR is in
        %   radians. The vehicle's forward direction is considered zero radians.
        %   The angles measured clockwise from the forward direction are negative
        %   angles and angles measured counter-clockwise from the forward direction
        %   are positive angles.
        %
        %   Supported syntax
        %   vfh(ranges, angles, target)
        %   vfh(lidarscanObj, target)

            [scan, target, classOfRanges] = obj.parseAndValidateStepInputs(varargin{:});

            if abs(target) > pi
                target = robotics.internal.wrapToPi(target);
            end

            % Compute theta steer
            obj.buildPolarObstacleDensity(scan, classOfRanges);
            obj.buildBinaryHistogram;
            obj.buildMaskedPolarHistogram(scan, classOfRanges);
            steeringDir = obj.selectHeadingDirection(target);
        end

    end

    methods (Access = protected)
        function buildPolarObstacleDensity(obj, scan, classRanges)
        %buildPolarObstacleDensity Create polar obstacle density
        %   This function creates a polar obstacle density histogram
        %   from the range readings taking into account the vehicle
        %   radius and safety distance.

            validScan = removeInvalidData(scan, 'RangeLimits', ...
                                          cast([obj.DistanceLimits(1) obj.DistanceLimits(2)], 'like', scan.Ranges));

            % Constants A and B used in Reference [1]
            constB = cast(1, classRanges);
            constA = cast(obj.DistanceLimits(2), classRanges);

            % Weighted ranges
            weightedRanges = constA - constB*validScan.Ranges;


            % If empty space in front of the vehicle
            if isequal(validScan, scan)
                obj.PolarObstacleDensity = zeros(1, obj.NumAngularSectors, classRanges);
                return;
            end

            % Special case of one sector
            if obj.NumAngularSectors == 1
                validWeights = ones(1, numel(validScan.Ranges), classRanges);
                obj.PolarObstacleDensity = (validWeights * weightedRanges)';
                return;
            end

            % If vehicle radius and safety distance both are zero, then use
            % primary histogram
            if obj.RobotRadius + obj.SafetyDistance == 0
                [~,bin] = histc(validScan.Angles, obj.AngularSectorMidPoints); %#ok<HISTC>
                obstacleDensity = zeros(1, obj.NumAngularSectors, classRanges);
                for i =1:length(bin)
                    obstacleDensity(1, bin(i)) = ...
                        obstacleDensity(1, bin(i)) + weightedRanges(i);
                end
                obj.PolarObstacleDensity = obstacleDensity;
                return;
            end

            % Equation (4) in Reference [1]
            % If the vehicle radius + safety distance is larger than the
            % Ranges, then "ASIN" will give complex values.

            % Using pi/2 as enlargement angle for ranges that are below
            % RobotRadius+SafetyDistance. In the original VFH algorithm
            % this case is not handled.
            sinOfEnlargement = cast(obj.RobotRadius + ...
                                    obj.SafetyDistance, classRanges)./validScan.Ranges;

            % Using 1 - eps, which results in enlargement angles approximately
            % sqrt(eps) smaller than pi/2. This is required because floating point
            % errors can cause nondeterministic behavior in the downstream
            % computation at enlargement angle of pi/2.
            sinOfEnlargement(sinOfEnlargement >= 1) = 1 - eps(classRanges);

            enlargementAngle = asin(sinOfEnlargement);

            % Polar obstacle density computation
            % Equation (5)-(6) in Reference [1]
            higherAng = validScan.Angles + enlargementAngle;
            lowerAng  = validScan.Angles - enlargementAngle;

            % Compute if a sector is within enlarged angle of a range
            % reading
            % If A X B, A X N and N X B have the same sign for Z-dimension,
            % then vector N is in between vectors A and B.

            % Create vectors for cross product computation
            lowerVec = [cos(lowerAng), sin(lowerAng), ...
                        zeros(size(lowerAng, 1), 1, classRanges)];
            higherVec = [cos(higherAng), sin(higherAng), ...
                         zeros(size(higherAng, 1), 1, classRanges)];
            validWeights = true(obj.NumAngularSectors, size(lowerVec,1));
            lh = cross(lowerVec, higherVec);
            kalpha = [cos(obj.AngularSectorMidPoints); ...
                      sin(obj.AngularSectorMidPoints);...
                      zeros(1,obj.NumAngularSectors, classRanges)]';
            for i=1:obj.NumAngularSectors
                kalphaVec = repmat(kalpha(i,:), size(lowerVec,1), 1);
                lk = cross(lowerVec, kalphaVec);
                kh = cross(kalphaVec, higherVec);
                validWeights(i, :) = (abs(sign(lk(:,3))+sign(kh(:,3)) + ...
                                          sign(lh(:,3))) > 1);
            end

            obj.PolarObstacleDensity = (validWeights * weightedRanges)';
        end

        function buildBinaryHistogram(obj)
        %buildBinaryHistogram Create binary histogram
        %   This function creates a binary polar histogram using the
        %   polar obstacle density. The function uses two threshold
        %   values to determine the binary values. The values falling
        %   in between the two threshold are chosen from binary
        %   histogram from the previous step.

        % Using thresholds, determine binary histogram
        % Equation (7) in Reference [1]
        % True means occupied sector
            obj.BinaryHistogram(obj.PolarObstacleDensity > ...
                                obj.HistogramThresholds(1,2)) = true;
            obj.BinaryHistogram(obj.PolarObstacleDensity < ...
                                obj.HistogramThresholds(1,1)) = false;
        end

        function buildMaskedPolarHistogram(obj, scan, classRanges)
        %buildMaskedPolarHistogram Create masked histogram
        %   This function creates the masked polar histogram from the
        %   binary histogram. It considers the vehicle's turning radius
        %   and evaluates if the obstacles are too close restricting
        %   the vehicle movement towards certain direction.


        % Angle ahead =  0    rad
        % Angle left  =  pi/2 rad
        % Angle right = -pi/2 rad

        % Equation (8) in Reference [1]
            DXr = cast(0, classRanges);
            DYr = cast(-obj.MinTurningRadius, classRanges);
            DYl = cast(obj.MinTurningRadius, classRanges);
            DXl = cast(0, classRanges);

            % Only consider indices in active region
            % find function always returns double output, hence it is
            % required to cast it.
            validScan = removeInvalidData(scan, 'RangeLimits', ...
                                          cast([obj.DistanceLimits(1) obj.DistanceLimits(2)], 'like', scan.Ranges));

            % Equation (9) in Reference [1]
            DXj = (validScan.Ranges).*cos(validScan.Angles);
            DYj = (validScan.Ranges).*sin(validScan.Angles);

            distR = sqrt((DXr - DXj).^2 + (DYr - DYj).^2);
            distL = sqrt((DXl - DXj).^2 + (DYl - DYj).^2);

            % Equation (10a)-(10b) in Reference [1]
            blockedR = distR < (obj.MinTurningRadius + obj.RobotRadius + ...
                                obj.SafetyDistance) & (validScan.Angles <= 0);
            blockedL = distL < (obj.MinTurningRadius + obj.RobotRadius + ...
                                obj.SafetyDistance) & (validScan.Angles >= 0);

            % Compute limit angles
            phiR = validScan.Angles(find(blockedR, 1, 'last'));
            phiL = validScan.Angles(find(blockedL, 1 , 'first'));

            if isempty(phiR)
                phiR = obj.AngularSectorMidPoints(1, 1);
            elseif phiR(1,1) <= obj.AngularSectorMidPoints(1, 1)
                % Account for point inside first sector
                phiR = obj.AngularSectorMidPoints(1, 2);
            end

            if isempty(phiL)
                phiL = obj.AngularSectorMidPoints(1, end);
            elseif phiL(1,1) >= obj.AngularSectorMidPoints(1, end)
                % Account for point inside last sector
                phiL = obj.AngularSectorMidPoints(1, end-1);
            end

            % Equation (11) in Reference [1]
            occupiedAngularSectors = (obj.AngularSectorMidPoints < ...
                                      phiR(1,1)*ones(size(obj.AngularSectorMidPoints), classRanges) | ...
                                      obj.AngularSectorMidPoints > ...
                                      phiL(1,1)*ones(size(obj.AngularSectorMidPoints), classRanges));
            obj.MaskedHistogram = (obj.BinaryHistogram | occupiedAngularSectors);
        end

        function thetaSteer = selectHeadingDirection(obj, targetDir)
        %selectHeadingDirection Select heading direction
        %   This function selects the heading direction based on a
        %   target direction using a cost function. It first computes
        %   the candidate directions based on the empty sectors in the
        %   masked histogram and then selects one or two candidate
        %   directions for each sector.

        % Find open sectors
            changes = cast(diff([0 ~obj.MaskedHistogram 0]), 'like', targetDir);

            % Skip everything if there are no open sectors
            if ~any(changes)
                thetaSteer = cast(nan, 'like', targetDir);
                obj.PreviousDirection = thetaSteer;
                return;
            end

            foundSectors = cast(find(changes), 'like', targetDir);

            % Because masked histogram is binary, the foundSectors will
            % always have even elements.
            sectors = reshape(foundSectors, 2, []);
            sectors(2,1:end) = sectors(2,1:end) - ones(1, size(sectors, 2), 'like', targetDir);

            % Get size of different sectors
            angles = zeros(size(sectors), 'like', targetDir);
            angles(1, 1:end) = obj.AngularSectorMidPoints(sectors(1, 1:end));
            angles(2, 1:end) = obj.AngularSectorMidPoints(sectors(2, 1:end));

            sectorAngles = reshape(angles, 2, []);
            sectorSizes = cast(obj.AngularDifference.*diff(sectors, 1, 1), 'like', targetDir);

            % Compute one candidate direction for each narrow sector
            % Equation (12) in Reference [1]
            narrowIdx = sectorSizes < ...
                obj.NarrowOpeningThreshold*ones(size(sectorSizes), 'like', targetDir);
            narrowDirs = nav.algs.internal.bisectAngles(...
                sectorAngles(1, narrowIdx), sectorAngles(2,narrowIdx));

            % Compute two candidates for each non-narrow sector
            % Equation (13) in Reference [1]
            nonNarrowDirs = [sectorAngles(1,~narrowIdx) + ...
                             ones(size(sectorAngles(1,~narrowIdx)), 'like', targetDir)*...
                             obj.NarrowOpeningThreshold/cast(2, 'like', targetDir), ...
                             sectorAngles(2,~narrowIdx) - ...
                             ones(size(sectorAngles(1,~narrowIdx)), 'like', targetDir)*...
                             obj.NarrowOpeningThreshold/cast(2, 'like', targetDir)];

            % Add target, current and previous directions as candidates
            obj.TargetDirection = targetDir;
            currDir = cast(0, 'like', targetDir);
            if isnan(obj.PreviousDirection)
                obj.PreviousDirection = currDir;
            end

            % Final list of candidate directions
            % Equation (14) in Reference [1]
            candidateDirs = [nonNarrowDirs(1,:), ...
                             narrowDirs(1,:), targetDir(1,1), currDir(1,1), ...
                             obj.PreviousDirection(1,1)];

            % Remove occupied directions
            % If the candidate direction falls at the center of two bins
            % then check both the bins for occupancy
            tolerance = sqrt(eps(class(targetDir)));
            candToSectDiff = abs(bsxfun(@robotics.internal.angdiff, ...
                                        obj.AngularSectorMidPoints,candidateDirs.'));
            tempDiff = bsxfun(@minus, candToSectDiff, min(candToSectDiff,[],2));
            nearIdx = tempDiff < tolerance;

            freeDirs = true(1, size(nearIdx, 1));

            for i=1:length(freeDirs)
                freeDirs(i) = ~any(obj.MaskedHistogram(nearIdx(i,:)));
            end

            candidateDirections = candidateDirs(freeDirs);

            % Compute cost for each candidate direction
            % Equation (15) in Reference [1]
            costValues = obj.computeCost(candidateDirections, ...
                                         targetDir, currDir, obj.PreviousDirection);

            % Decide best direction to steer
            cVal = min(costValues);

            % Consider all costs that have very small difference to min
            % value
            cDiff = costValues - cVal;
            minCostIdx = cDiff < tolerance;

            thetaSteer = min(candidateDirections(minCostIdx));

            if isempty(thetaSteer)
                thetaSteer = cast(nan, 'like', targetDir);
            end
            obj.PreviousDirection = thetaSteer;
        end

        function cost = computeCost(obj, c, targetDir, currDir, prevDir)
        %computeCost Compute total cost using all cost components

            tdWeight = cast(obj.TargetDirectionWeight, 'like', targetDir);
            cdWeight = cast(obj.CurrentDirectionWeight, 'like', targetDir);
            pdWeight = cast(obj.PreviousDirectionWeight, 'like', targetDir);
            totalWeight = tdWeight + cdWeight + pdWeight;

            targetDir = targetDir*ones(1, numel(c), 'like', targetDir);
            currDir = currDir*ones(1, numel(c), 'like', targetDir);
            prevDir = prevDir*ones(1, numel(c), 'like', targetDir);

            cost =  (tdWeight*obj.localCost(c, targetDir) + ...
                     cdWeight*obj.localCost(c, currDir) + ...
                     pdWeight*obj.localCost(c, prevDir))./...
                    3*totalWeight;
        end

        function cost = localCost(~, candidateDir, selectDir)
        %localCost Compute cost for each cost component

        % Cost computation for valid candidate indices
            cost = abs(robotics.internal.angdiff(candidateDir, selectDir));
        end

    end
end


function validateNonnegativeScalar(val, name)
%validateNonnegativeScalar Validate non-negative real scalar
    validateattributes(val, {'double', 'single'}, {'nonnan', 'real', ...
                        'scalar', 'nonnegative', 'finite'}, 'controllerVFH', name);
end

function validateNonnegativeArray(val, name)
%validateNonnegativeArray Validate non-negative two element array
    validateattributes(val, {'double', 'single'}, {'nonnan', 'real', ...
                        'numel', 2, 'finite', 'nonnegative'}, 'controllerVFH', name);
end
