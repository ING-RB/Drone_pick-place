classdef MapUtils < nav.algs.internal.InternalAccess & ...
        matlabshared.autonomous.map.internal.InternalAccess
%This class is for internal use only. It may be removed in the future.

%This file replaces nav.algs.internal.OccupancyGridBase, and MapUtils acts...
% as a helper class, containing functionality shared by occupancy map classes
% derived from matlabshared.autonomous.internal.MapLayer:
%   binaryOccupancyMap
%   occupancyMap

%   Copyright 2014-2025 The MathWorks, Inc.

%#codegen
    
    properties (Hidden, Constant)
        %Properties containing message catalog strings
        ColLabel = message('nav:navalgs:occgridcommon:FigureColLabel').getString
        RowLabel = message('nav:navalgs:occgridcommon:FigureRowLabel').getString
        XLabel   = message('nav:navalgs:occgridcommon:FigureXLabel').getString
        YLabel   = message('nav:navalgs:occgridcommon:FigureYLabel').getString
    end
    
    methods (Static)
        function [startPt, endPt, inverseModelLogodds, maxRange, rangeIsMax] = parseInsertRayInputs(map, defaultInverseModelLogodds, varargin)
            %parseInsertRayInputs Parse the various syntaxes of the insertRay function
            %   This function returns 3 different outputs:
            %   - startPt are the Cartesian start points for the line
            %     segments corresponding to the laser scan rays.
            %   - endPt are the Cartesian end points for the line
            %     segments corresponding to the laser scan rays.
            %   - updateValues are the values used to update the occupancy of
            %     the map. Free spaces are updated with updateValues(1),
            %     occupied spaces are updated with updateValues(2)
            %   - rangeIsMax is a logical vector with the same length as
            %     startPt. Each element of rangeIsMax indicates if the
            %     laser scan range for that line segment was saturated to
            %     the maximum range.
            %
            %   Supported syntax variants:
            %    insertRay(map, robotpose, ranges, angles, maxRange) -> 5
            %    insertRay(map, robotpose, ranges, angles, maxRange, inverseModel) -> 6
            %
            %    insertRay(map, robotpose, lidarScan, maxRange) -> 4
            %    insertRay(map, robotpose, lidarScan, maxRange, inverseModel) -> 5
            %
            %    insertRay(map, startPoint, endPoints) -> 3
            %    insertRay(map, startPoint, endPoints, inverseModel) -> 4
            
            narginchk(4, 7);
            
            if nargin == 4
                % Syntax: insertRay(ogmap, startPoint, endPoints)

                % Cartesian / line segment input
                [startPt, endPt] = nav.algs.internal.MapUtils.validateLineSegment(map,varargin{1}, varargin{2});
                inverseModelLogodds = defaultInverseModelLogodds;
                rangeIsMax = logical([]);
                maxRange = max(abs([endPt(:,1)-startPt(1); endPt(:,2)-startPt(2)]));
            else
                xlim = map.SharedProperties.XWorldLimits;
                ylim = map.SharedProperties.YWorldLimits;
                if nargin == 5
                    % Possible Syntaxes:
                    %    insertRay(ogmap, startPoint, endPoints, inverseModel)
                    %    insertRay(ogmap, robotpose, lidarScan, maxRange)
                    
                    if isa(varargin{2}, 'lidarScan')
                        % Syntax: insertRay(ogmap, robotpose, lidarScan, maxRange)
                        
                        pose = nav.algs.internal.MapUtils.validatePose(varargin{1}, xlim, ...
                            ylim, 'insertRay', 'pose');
                        
                        maxRange = varargin{3};
                        nav.algs.internal.MapUtils.validateMaxRange(maxRange);
                        
                        scan = robotics.internal.validation.validateLidarScan(varargin{2}, 'insertRay', 'scan');
                        [saturatedRanges, saturatedAngles] = nav.algs.internal.MapUtils.validateRangesAngles(scan.Ranges, scan.Angles, maxRange);
                        [startPt, endPt] = nav.algs.internal.MapUtils.calculateLineSegmentsFromScan(pose, saturatedRanges, saturatedAngles);
                        rangeIsMax = (saturatedRanges == maxRange);
                        
                        inverseModelLogodds = defaultInverseModelLogodds;
                    else
                        % Syntax: insertRay(ogmap, startPoint, endPoints, inverseModel)
                        
                        [startPt, endPt] = nav.algs.internal.MapUtils.validateLineSegment(map,varargin{1}, varargin{2});
                        inverseModelLogodds = map.validateInverseModel(varargin{3});
                        rangeIsMax = logical([]);
                        maxRange = max(abs([endPt(:,1)-startPt(1); endPt(:,2)-startPt(2)]));
                    end
                    
                elseif nargin == 6
                    % Possible Syntaxes:
                    %    insertRay(ogmap, robotpose, lidarScan, maxRange, inverseModel)
                    %    insertRay(ogmap, robotpose, ranges, angles, maxRange)
                    
                    if isa(varargin{2}, 'lidarScan')
                        % Syntax: insertRay(ogmap, robotpose, lidarScan, maxRange, inverseModel)
                        
                        pose = nav.algs.internal.MapUtils.validatePose(varargin{1}, xlim, ...
                            ylim, 'insertRay', 'pose');
                        
                        maxRange = varargin{3};
                        nav.algs.internal.MapUtils.validateMaxRange(maxRange);
                        
                        scan = robotics.internal.validation.validateLidarScan(varargin{2}, 'insertRay', 'scan');
                        [saturatedRanges, saturatedAngles] = nav.algs.internal.MapUtils.validateRangesAngles(scan.Ranges, scan.Angles, maxRange);
                        
                        inverseModelLogodds = map.validateInverseModel(varargin{4});
                    else
                        % Syntax: insertRay(ogmap, robotpose, ranges, angles, maxRange)
                        
                        pose = nav.algs.internal.MapUtils.validatePose(varargin{1}, xlim, ...
                            ylim, 'insertRay', 'pose');
                        
                        maxRange = varargin{4};
                        nav.algs.internal.MapUtils.validateMaxRange(maxRange);
                        
                        [saturatedRanges, saturatedAngles] = nav.algs.internal.MapUtils.validateRangesAngles(varargin{2}, varargin{3}, maxRange);
                        
                        inverseModelLogodds = defaultInverseModelLogodds;
                    end
                    
                    [startPt, endPt] = nav.algs.internal.MapUtils.calculateLineSegmentsFromScan(pose, saturatedRanges, saturatedAngles);
                    rangeIsMax = (saturatedRanges == maxRange);
                    
                else
                    % Syntax: insertRay(ogmap, robotpose, ranges, angles, maxRange, inverseModel)
                    
                    pose = nav.algs.internal.MapUtils.validatePose(varargin{1}, xlim, ...
                        ylim, 'insertRay', 'pose');
                    
                    maxRange = varargin{4};
                    nav.algs.internal.MapUtils.validateMaxRange(maxRange);
                    
                    [saturatedRanges, saturatedAngles] = nav.algs.internal.MapUtils.validateRangesAngles(varargin{2}, varargin{3}, maxRange);
                    [startPt, endPt] = nav.algs.internal.MapUtils.calculateLineSegmentsFromScan(pose, saturatedRanges, saturatedAngles);
                    rangeIsMax = (saturatedRanges == maxRange);
                    
                    inverseModelLogodds = map.validateInverseModel(varargin{5});
                end
            end
        end
        
        function [nvPairs, useGridSizeInit, rows, cols, sz, depth] = parseGridVsMatrix(className, parseFcn, varargin)
        %parseGridVsMatrix Parser for dimension vs matrix construction
            depth = 1;
            if numel(varargin) >= 3 && isnumeric(varargin{1}) && isnumeric(varargin{2}) && isnumeric(varargin{3})
            %Syntax: occupancyMap(W,H,RES,___)
                validateattributes(varargin{1}, {'numeric','logical'}, { 'real', ...
                    'scalar','nonnan', 'finite','positive'}, className, 'MapWidth');
                validateattributes(varargin{2}, {'numeric'}, {'scalar', 'real', ...
                    'nonnan', 'finite','positive'}, className, 'MapHeight');
                [frame, nvPairsInit, userSupplied] = matlabshared.autonomous.internal.MapLayer.parseGridInitialization(className, parseFcn, varargin{4:end});
                nvPairs = matlabshared.autonomous.internal.MapInterface.updateParsedResolution(className,nvPairsInit,userSupplied,varargin{3});
                [useGridSizeInit, rows, cols] = matlabshared.autonomous.internal.MapLayer.calculateMapDimensions(nvPairs.Resolution,frame,varargin{1},varargin{2});
            elseif numel(varargin) >= 2 && isscalar(varargin{1}) && isnumeric(varargin{1}) && coder.internal.isConst(size(varargin{1}))
            %Syntax: occupancyMap(W/R,H/C,___)
                validateattributes(varargin{1}, {'numeric','logical'}, { 'real', ...
                    'scalar','nonnan', 'finite','positive'}, className, 'MapWidth');
                validateattributes(varargin{2}, {'numeric'}, {'scalar', 'real', ...
                    'nonnan', 'finite','positive'}, className, 'MapHeight');
                [frame, nvPairs] = matlabshared.autonomous.internal.MapLayer.parseGridInitialization(className, parseFcn, varargin{3:end});
                [useGridSizeInit, rows, cols] = matlabshared.autonomous.internal.MapLayer.calculateMapDimensions(nvPairs.Resolution,frame,varargin{1},varargin{2});
            else
            %Syntax: occupancyMap(P,___)
                matlabshared.autonomous.internal.MapInterface.validateMatrixInput(varargin{1}, className, className);
                
                if mod(numel(varargin),2) == 0
                %Syntax: occupancyMap(P,RES,nvPairs)
                    [nvPairsInit, userSupplied] = parseFcn(varargin{3:end});
                    nvPairs = matlabshared.autonomous.internal.MapInterface.updateParsedResolution(className,nvPairsInit,userSupplied,varargin{2});
                else
                %Syntax: occupancyMap(P,nvPairs)
                    nvPairs = parseFcn(varargin{2:end});
                end
                matSz = size(varargin{1});
                coder.internal.prefer_const(matSz);
                [useGridSizeInit, rows, cols] = matlabshared.autonomous.internal.MapLayer.calculateMapDimensions(nvPairs.Resolution,'grid',matSz(1),matSz(2));
            end
            sz = [rows cols];
        end
        
        function [endPts, middlePts] = raycast(map, varargin)
            %RAYCAST Compute cell indices along a ray
            %   [ENDPTS, MIDPTS] = RAYCAST(MAP, POSE, RANGE, ANGLE) returns
            %   cell indices of all cells traversed by a ray emanating from
            %   POSE at an angle ANGLE with length equal to RANGE. POSE is
            %   a 3-element vector representing robot pose [X, Y, THETA] in
            %   the world coordinate frame. ANGLE and RANGE are scalars.
            %   The ENDPTS are indices of cells touched by the
            %   end point of the ray. MIDPTS are all the cells touched by
            %   the ray excluding the ENDPTS.
            %
            %   [ENDPTS, MIDPTS] = RAYCAST(MAP, P1, P2) returns
            %   the cell indices of all cells between the line segment
            %   P1=[X1,Y1] to P2=[X2,Y2] in the world coordinate frame.
            %
            %   For faster insertion of range sensor data, use the insertRay
            %   method with an array of ranges or an array of end points.
            
            narginchk(3,4);
            xlim      = map.SharedProperties.XWorldLimits;
            ylim      = map.SharedProperties.YWorldLimits;
            gSize     = map.SharedProperties.GridSize;
            res       = map.SharedProperties.Resolution;

            if nargin == 4
                
                pose = nav.algs.internal.MapUtils.validatePose(varargin{1}, xlim, ...
                    ylim, 'raycast', 'pose');
                
                validateattributes(varargin{2}, {'numeric'}, ...
                    {'real', 'nonnan', 'finite', 'scalar', 'nonnegative'}, 'raycast', 'range');
                validateattributes(varargin{3}, {'numeric'}, ...
                    {'real', 'nonnan', 'finite', 'scalar'}, 'raycast', 'angle');
                range = double(varargin{2});
                angle = double(varargin{3}) + pose(3);
                
                startPoint = pose(1:2);
                endPoint = [pose(1) + range*cos(angle), ...
                    pose(2) + range*sin(angle)];
            else
                validateattributes(varargin{1}, {'numeric'}, {'nonnan', 'finite', 'numel', 2}, 'raycast', 'p1');
                [startPoint, startValid] = matlabshared.autonomous.internal.MapInterface.validatePosition(varargin{1}, xlim, ...
                    ylim, 'raycast', 'StartPoint', 2);
                
                validateattributes(varargin{2}, {'numeric'}, {'nonnan', 'finite', 'numel', 2}, 'raycast', 'p2');
                [endPoint, endValid] = matlabshared.autonomous.internal.MapInterface.validatePosition(varargin{2}, xlim, ...
                    ylim, 'raycast', 'EndPoint', 3);
                
                if ~startValid || ~endValid
                    coder.internal.error('nav:navalgs:occgridcommon:CoordinateOutside', ...
                        coder.internal.num2str(xlim(1)), coder.internal.num2str(xlim(2)), ...
                        coder.internal.num2str(ylim(1)), coder.internal.num2str(ylim(2)));
                end
            end
            
            [endPts, middlePts] = nav.algs.internal.raycastCells(startPoint, endPoint, ...
                gSize(1), gSize(2), res, map.SharedProperties.GridLocationInWorld);
        end
        
        function collisionPt = rayIntersection(map, grid, pose, angles, maxRange)
            %rayIntersection Calculates the collision points for a set of rays
            vPose = nav.algs.internal.MapUtils.validatePose(pose, map.SharedProperties.XWorldLimits, map.SharedProperties.YWorldLimits, 'rayIntersection', 'pose');
            vAngles = nav.algs.internal.MapUtils.validateAngles(angles, 'rayIntersection', 'angles');
            
            validateattributes(maxRange, {'numeric'}, ...
                {'real', 'nonnan', 'finite', 'scalar', 'positive'}, 'rayIntersection', 'maxrange');
            
            [ranges, endPt] = nav.algs.internal.calculateRanges(vPose, vAngles, double(maxRange), ...
                grid, map.SharedProperties.GridSize, map.SharedProperties.Resolution, map.SharedProperties.GridLocationInWorld);
            collisionPt = endPt;
            collisionPt(isnan(ranges), :) = nan;
        end
        
        function [newMat, success] = resampleMatrix(mat, xyOffset, oldRes, newRes, defaultValue)
            %resampleMatrix Resample a matrix with shifted location and/or resolution
            % mat: NxM matrix to be resampled
            % xyOffset: Difference in location between input and output matrices
            %     Offset must be less than 1 cell
            % oldRes: Resolution of original matrix
            % newRes: Resolution of resampled matrix
            % defaultValue: Value used for cells that lie outside the bounds of mat
            gridRatio = newRes/oldRes;
            dims = size(mat);
            
            success = 1;
            if (gridRatio == 1)
                % If grid-resolutions match, we can optimize the copy
                % operations
                ijOffset = flip(xyOffset).*[-1 1];
                if (all(xyOffset == 0))
                    % Maps are in identical positions -> Simple copy operation
                    newMat = mat;
                else
                    % If resolutions match, but their grids are not aligned,
                    % we can still do vectorized operations by upsampling then
                    % downsampling a shifted matrix
                    %
                    % Map grids are not perfectly aligned -> Resample
                    % using 'Max' policy
                    
                    % Upsample to augmented matrix
                    % e.g. For 2x upsample
                    %      mat = [1 2 3;   ->  augMat = [1 1 2 2 3 3;
                    %             4 5 6]                 1 1 2 2 3 3;
                    %                                    4 4 5 5 6 6;
                    %                                    4 4 5 5 6 6]
                    augMat = reshape(repmat(reshape(...
                        repmat(reshape(mat,[],1)',2,1), ...
                        [], dims(2)),2,1),dims(1)*2,[]);
                    
                    % Shift according to grid offset and fill in out-of-bounds
                    % cells if we moved in that direction
                    % e.g. For xyShift = [1 1]
                    %  augMat = [1 1 2 2 3 3; -> augMat = [x x x x x x;
                    %            1 1 2 2 3 3;              1 1 2 2 3 x;
                    %            4 4 5 5 6 6;              4 4 5 5 6 x;
                    %            4 4 5 5 6 6]              4 4 5 5 6 x]
                    % e.g. For xyShift = [-1 -1]
                    %  augMat = [3 1 1 2 2 3; -> augMat = [x 1 1 2 2 3;
                    %            6 4 4 5 5 6;              x 4 4 5 5 6;
                    %            6 4 4 5 5 6;              x 4 4 5 5 6;
                    %            3 1 1 2 2 3]              x x x x x x]
                    augMat = circshift(augMat,-double(sign(ijOffset)));
                    if (ijOffset(1) ~= 0)
                        % y-direction
                        augMat(mod(-sign(ijOffset(1)),size(augMat,1)+1),:) = defaultValue;
                    end
                    if (ijOffset(2) ~= 0)
                        % x-direction
                        augMat(:,mod(-sign(ijOffset(2)),size(augMat,2)+1)) = defaultValue;
                    end
                    
                    % Downsample using 'Max' policy
                    % e.g. for 2x upsample, xyShift = [-1 -1]
                    % augMat = [x 1 1 2 2 3;    ->   newMat = [4 5 6;
                    %           x 4 4 5 5 6;                   4 5 6]
                    %           x 4 4 5 5 6;
                    %           x x x x x x]
                    newMat = reshape(max(reshape(reshape(max(reshape(...
                        augMat,2,[])),dims(1),[])',2,[])),dims(2),[])';
                end
            elseif (gridRatio > 1 && floor(newRes/oldRes) == newRes/oldRes &&...
                    all(xyOffset == 0))
                % If the old resolution is a divisor of the new
                % resolution, and no shifting occurs, we can efficiently
                % upsample
                
                % Upsample the matrix using 'nearest' policy
                newMat = reshape(repmat(reshape(...
                    repmat(mat,gridRatio,1),1,[]), gridRatio,1),gridRatio*dims(1),[]);
            elseif (gridRatio < 1 && floor(oldRes/newRes) == oldRes/newRes &&...
                    all(floor(gridRatio*size(mat)) == gridRatio*size(mat)) &&...
                    all(xyOffset == 0))
                % If the new resolution is a divisor of the old
                % resolution, and no shifting occurs, we can efficiently
                % downsample
                
                % Downsampling using 'Max' policy
                newMat = reshape(max(reshape(reshape(max(reshape(mat,1/gridRatio,[])),...
                    dims(1)*gridRatio,[])',1/gridRatio,[])),dims(2)*gridRatio,[])';
            else
                % In any case where the resolutions are not divisors, or if
                % they are divisors but the grids are not aligned, we
                % resort to a copy using loops
                newMat = repmat(defaultValue,ceil(size(mat)*newRes/oldRes));
                success = 0;
            end
        end
        
        function [startPt, endPt] = calculateLineSegmentsFromScan(pose, ranges, angles)
            %calculateLineSegmentsFromScan Calculate line segments (start and end points) for range readings
            
            startPt = [pose(1) pose(2)];
            endPt = [pose(1) + ranges.*cos(pose(3)+angles), ...
                pose(2) + ranges.*sin(pose(3)+angles)];
        end
        
        function validateOccupancyValues(values, len, fcnName, argname, argNum)
            %validateOccupancyValues Validate occupancy value vector
            
            % check that the values are numbers in [0,1]
            if islogical(values)
                validateattributes(values, {'logical'}, ...
                    {'vector', 'nonempty'}, fcnName, argname, argNum);
            else
                validateattributes(values, {'numeric'}, ...
                    {'real','vector', 'nonnan', 'nonempty'}, fcnName, argname, argNum);
            end
            if length(values) ~= 1 && length(values) ~= len
                coder.internal.error('nav:navalgs:occgridcommon:InputSizeMismatch');
            end
        end
        
        function loc = validateGridLocationInput(loc, argName)
            % Validate the input format and type
            validateattributes(loc,{'numeric', 'logical'}, ...
                {'real', 'nonnan', 'finite', 'size', [1 2]}, ...
                'validateGridLocationInput', argName)
            loc = double(loc);
        end
        
        function [frameValid, frame] = validateCoordFrames(cframe)
            %validateCoordFrames Validates the coordinate frame
            validCoordFrames = {'grid','world','local'};
            frame = validatestring(cframe,validCoordFrames,'validateCoordFrames');
            frameValid = any(frame);
        end
        
        function res = validateResolution(res, fcnName, argNum)
            %validateResolution Validates the resolution input
            if isnan(argNum)
            % Name-value pair
                validateattributes(res, ...
                    {'numeric', 'logical'}, ...
                    {'scalar', 'positive','nonnan','finite'},...
                    fcnName,'RES');
            else
            % Optional argument
                validateattributes(res, ...
                {'numeric', 'logical'}, ...
                {'scalar', 'positive','nonnan','finite'},...
                fcnName,'RES',argNum);
            end
            res = double(res);
        end
        
        function radius = validateInflationRadius(inflationRad, ...
                resolution, isgrid, gridsize, argName)
            %validateInflationRadius Validate inflation radius
            
            % Validate that the input is double
            validateattributes(inflationRad, {'double'}, {'scalar','positive','nonnan', 'finite'}, 'inflate', argName);
            
            % Convert radius from meters to number of cells
            if isgrid
                radius = inflationRad;
            else
                radius = ceil(inflationRad*resolution);
            end
            
            % Validate if the radius is integer and not excessively large
            validateattributes(radius,{'double'},{'integer', '<=', max(gridsize)}, ...
                'inflate', argName);
        end
        
        function outPose = validatePose(inPose, xLimits, yLimits, fcnName, argName)
            %validatePose Validate robot pose
            
            validateattributes(inPose, {'numeric'}, {'real', 'nonnan', 'finite', 'vector', 'numel', 3}, fcnName, argName);
            outPose = double(inPose(:).');
            
            % Verify that pose is within the boundaries of the map
            boundCheck = outPose(1) < xLimits(1) || outPose(1) > xLimits(2) || ...
                         outPose(2) < yLimits(1) || outPose(2) > yLimits(2);
            
            if boundCheck
                coder.internal.error("nav:navalgs:occgridcommon:XYPoseOutside",...
                string(xLimits(1)),string(xLimits(2)),string(yLimits(1)),string(yLimits(2)));
            end
            
            outPose(3) = robotics.internal.wrapToPi(outPose(3));
        end
        
        function outAngles = validateAngles(inAngles, fcnName, argName)
            %validateAngles Validate laser angles
            
            validateattributes(inAngles, {'numeric'}, {'real', 'nonnan', 'finite', 'vector'}, fcnName, argName);
            outAngles = double(inAngles(:));
        end
        
        function outRanges = validateRanges(inRanges, fcnName, argName)
            %validateRanges Validate laser ranges
            %   NaN values are allowed, the method has to decide on what to
            %   do with NaN ranges.
            
            validateattributes(inRanges, {'numeric'}, {'real', 'vector', 'nonnegative'}, fcnName, argName);
            outRanges = double(inRanges(:));
        end
        
        function validateMaxRange(maxRange)
            %validateMaxRange Validate maximum range input
            
            validateattributes(maxRange, {'numeric'}, ...
                {'real', 'nonnan', 'finite', 'scalar', 'positive'}, 'insertRay', 'maxRange');
        end
        
        function [validRanges, validAngles] = validateRangesAngles(rangesIn, anglesIn, maxRange)
            %validateRangesAngles Validate raw ranges / angles inputs
            
            ranges = nav.algs.internal.MapUtils.validateRanges(rangesIn, 'insertRay', 'ranges');
            angles = nav.algs.internal.MapUtils.validateAngles(anglesIn, 'insertRay', 'angles');
            
            if numel(ranges) ~= numel(angles)
                coder.internal.error('nav:navalgs:occgridcommon:RangeAngleMismatch', 'ranges', 'angles');
            end
            
            validRanges = ranges(~isnan(ranges(:)));
            validAngles = angles(~isnan(ranges(:)));
            validRanges = min(maxRange, validRanges);
        end
        
        function [validStartPt, validEndPt] = validateLineSegment(map, startPt, endPt)
            %validateLineSegment Validate line segment (start point, end point) inputs
            
            validateattributes(startPt, {'numeric'}, {'nonnan', 'finite', 'numel', 2}, 'insertRay', 'startpt');
            validateattributes(endPt,   {'numeric'}, {'nonnan', 'finite'}, 'insertRay', 'endpt');
            xlimits = map.SharedProperties.XWorldLimits;
            ylimits = map.SharedProperties.YWorldLimits;
            [validStartPt, startIsValid] = matlabshared.autonomous.internal.MapInterface.validatePosition([startPt(1) startPt(2)], xlimits, ...
                ylimits, 'insertRay', 'StartPoint', 2);
            
            [validEndPt, endIsValid] = matlabshared.autonomous.internal.MapInterface.validatePosition(endPt, xlimits, ...
                ylimits, 'insertRay', 'endpts', 3);
            
            if ~startIsValid || ~any(endIsValid)
                if coder.target('MATLAB')
                    coder.internal.error('nav:navalgs:occgridcommon:CoordinateOutside', ...
                        sprintf('%0.1f',xlimits(1)), sprintf('%0.1f',xlimits(2)), ...
                        sprintf('%0.1f',ylimits(1)), sprintf('%0.1f',ylimits(2)));
                else
                    coder.internal.error('nav:navalgs:occgridcommon:CoordinateOutside', ...
                        coder.internal.num2str(xlimits(1)), coder.internal.num2str(xlimits(2)), ...
                        coder.internal.num2str(ylimits(1)), coder.internal.num2str(ylimits(2)));
                end
            end
        end
        
        function grid = inflateGrid(obj, grid, inflationRad, frame)
            %inflate Inflate the occupied positions by a given amount
            %   Internal function to inflate grid.
            
            isGrid = false;
            % If optional argument present then parse it separately
            if nargin > 3
                isGrid = matlabshared.autonomous.internal.MapInterface.parseOptionalFrameInput(frame, 'inflate');
            end
            
            % Validate inflation radius and conversion to grid
            radius = nav.algs.internal.MapUtils.validateInflationRadius(...
                inflationRad, obj.SharedProperties.Resolution, isGrid, obj.SharedProperties.GridSize, 'R');
            
            se = nav.algs.internal.diskstrel(radius);
            grid = nav.algs.internal.inflate(grid, se);
        end
        
        function [axHandle,isGrid,isLocal,fastUpdate] = showInputParser(varargin)
            %showInputParser Input parser for show function
            
            if ~coder.target('MATLAB')
                % Always throw error when calling show in
                % generated code
                coder.internal.error('nav:navalgs:occgridcommon:GraphicsSupportCodegen','show');
            end
            
            narginchk(0,5);
            
            isGrid = 0;
            isLocal = 0;
            fastUpdate = 0;
            axHandle = [];
            
            if nargin == 0
                % Show displays the world frame by default
                return;
            elseif mod(nargin,2) == 1
                % Optional frame input provided
                [isGrid, isLocal] =  matlabshared.autonomous.internal.MapInterface.parseOptionalFrameInput(varargin{1}, 'validateCoordFrames');
                
                if nargin > 1
                    % Axes provided as well
                    p = inputParser;
                    addParameter(p, 'Parent', [], @robotics.internal.validation.validateAxesUIAxesHandle);
                    addParameter(p, 'FastUpdate', 0, @(x)isnumeric(x)||islogical(x));
                    parse(p, varargin{2:end});
                    res = p.Results;
                    axHandle = res.Parent;
                    fastUpdate = res.FastUpdate;
                end
            else
                % nargin is even, check for axes
                p = inputParser;
                addParameter(p, 'Parent', [], @robotics.internal.validation.validateAxesUIAxesHandle);
                addParameter(p, 'FastUpdate', 0, @(x)isnumeric(x)||islogical(x));
                parse(p, varargin{:});
                res = p.Results;
                axHandle = res.Parent;
                fastUpdate = res.FastUpdate;
            end
        end
        
        function [axHandle, imageHandle, fastUpdate] = showEmptyGrid(map, axHandle, isGrid, isLocal, fastUpdate)
        %showGrid Display the empty grid in a figure to which we
        %overlay the occupancy or custom data        
        %   [AH, IH] = showGrid(OBJ, MAP, AXHANDLE, ISGRID, ISLOCAL) plots the
        %   empty grid MAP using imshow function on the provided axes AXHANDLE
        %   and returns the axes handle AH and image handle IH. ISGRID and
        %   ISLOCAL are used to indicate if the axes label need to be in 
        %   world, local, or grid indices. If FASTUPDATE is true, showGrid
        %   will only update the CData of the plot if a map has already
        %   been shown on the current axes.
        %
        %   Example:
        %      % Create empty grid map with axis
        %      [axHandle, imageHandle, fastUpdate] = nav.algs.internal.MapUtils.showEmptyGrid(map,
        %                                            axHandle, isGrid, isLocal, fastUpdate);
        %      % Overlay occupancy or custom data stored in mapData
        %      nav.algs.internal.MapUtils.updateImageAndColorBar(mapData,
        %               axHandle, imageHandle, colorbar, clims, imageTag)
        
        % If axes not given, create an axes
        % The newplot function does the right thing
            if fastUpdate
                if isempty(axHandle)
                    % Get the current axes if none is provided, or create
                    % one if none exist
                    axHandle = gca;
                end
            else
                if isempty(axHandle)
                    % Retrieve the current axes or create one. If hold
                    % all/on is applied, this will not clear the axes
                    % children
                    axHandle = newplot;
                end
            end

            % Get all children of the axes
            imageHandle = findobj(axHandle,'Type','image');

            if ~isempty(imageHandle) && fastUpdate
                % Check if the axes is already being used to display the map
                if ~isscalar(imageHandle)
                    % Get the handle to the image used to display a map most
                    % recently
                    imageHandle = imageHandle(contains({imageHandle(:).Tag},map.ImageTag));
                    imageHandle = imageHandle(1);
                end

                if (isGrid && imageHandle.Tag(end) ~= 'G') || (~isGrid && imageHandle.Tag(end) == 'G')
                    % Plotted frame is different from previous call to show,
                    % update labels
                    fastUpdate = 0;
                else
                    % Last call to show uses the same x/y labels, skip
                    % updating them
                end
                axHandle.Visible = 'off';
                imageHandle.Visible = 'off';
            else
                % No longer fast-update eligible
                fastUpdate = 0;

                % Create image handle for map
                imageHandle = imagesc([],'Parent',axHandle,[0 1]);

                % Make axes invisible before plotting
                axHandle.Visible = 'off';
                imageHandle.Visible = 'off';
                
                axHandle.DataAspectRatio = [1 1 1];
            end

            gSize = map.SharedProperties.GridSize;
            res   = map.SharedProperties.Resolution;
            
            % Change the axes limits, X data and Y data to show world
            % coordinates or grid indices on the figure
            if isGrid
                if ~fastUpdate
                    % Skip the slow elements that don't need to be updated

                    % Set the axes
                    axHandle.XLabel.String = nav.algs.internal.MapUtils.ColLabel;
                    axHandle.YLabel.String = nav.algs.internal.MapUtils.RowLabel;
                    set(axHandle, 'YDir', 'reverse');
                    imageHandle.Tag = [map.ImageTag 'G'];
                end
                % Get the grid size
                xdata = [1, gSize(2)];
                ydata = [1, gSize(1)];

                % Compute the grid limits
                xlimits = [0.5, gSize(2)+0.5];
                ylimits = [0.5, gSize(1)+0.5];
            else
                if ~fastUpdate
                    % Skip the slow elements that don't need to be updated

                    % Set the axes
                    axHandle.XLabel.String = nav.algs.internal.MapUtils.XLabel;
                    axHandle.YLabel.String = nav.algs.internal.MapUtils.YLabel;
                    set(axHandle, 'YDir', 'normal');
                end

                % Get the proper limits
                if (isLocal)
                    imageHandle.Tag = [map.ImageTag 'L'];
                    xlimits = map.SharedProperties.XLocalLimits;
                    ylimits = map.SharedProperties.YLocalLimits;
                else
                    imageHandle.Tag = [map.ImageTag 'W'];
                    xlimits = map.SharedProperties.XWorldLimits;
                    ylimits = map.SharedProperties.YWorldLimits;
                end

                % Adjust map axes by the internal grid offset
                topLeftLoc = [xlimits(1) ylimits(1)] + 1/(2*res);

                botRightLoc = [xlimits(2) ylimits(2)] - 1/(2*res);

                % Set XData and YData
                if (abs(xlimits(1)-xlimits(2)+1/res) < eps)
                    % Special case when there is only one cell
                    xdata = [xlimits(1), xlimits(2)];
                else
                    xdata = [topLeftLoc(1), botRightLoc(1)];
                end

                if (abs(ylimits(1)-ylimits(2)+1/res) < eps)
                    ydata = [ylimits(2), ylimits(1)];
                else
                    ydata = flip([topLeftLoc(2), botRightLoc(2)]);
                end
            end

            % Set new image data
            imageHandle.XData = xdata;
            imageHandle.YData = ydata;
            axHandle.XLim = xlimits;
            axHandle.YLim = ylimits;
        end


        function [axHandle, imageHandle, fastUpdate] = showGrid(map, axHandle, isGrid, isLocal, fastUpdate)
            %showGrid Display the occupancy grid in a figure
            %   [AH, IH] = showGrid(OBJ, MAT, AXHANDLE, ISGRID, ISLOCAL) plots the
            %   matrix MAT using imshow function on the provided axes AXHANDLE
            %   and returns the axes handle AH and image handle IH. ISGRID and
            %   ISLOCAL are used to indicate if the axes label need to be in 
            %   world, local, or grid indice. If FASTUPDATE is true, showGrid
            %   will only update the CData of the plot if a map has already
            %   been shown on the current axes.
            %
            %   Calling sequence for derived class
            %   [axHandle, isGrid] = obj.showInputParser(varargin{:});
            %   imageHandle = showGrid(obj, grid, axHandle, isGrid)
            %   title(axHandle, message('nav:navalgs:occgrid:FigureTitle').getString);

            % Convert occupancy data to 3-channel grayscale image
            imgData = repmat(1-map.getMapData,1,1,3);

            % Show empty grid on top of which will overlay the occupancy
            % data
            [axHandle, imageHandle, fastUpdate] = nav.algs.internal.MapUtils.showEmptyGrid(...
                map, axHandle, isGrid, isLocal, fastUpdate);

            % react to theme change after plotting
            themeContainer = ancestor(axHandle,'figure');
            % Remove old listener
            delete(map.ThemeListener);
            % Add new listener
            map.ThemeListener = addlistener(themeContainer,'ThemeChanged',...
                @(src,event)nav.algs.internal.MapUtils.occupancyMapThemeChangeCallback(src,event,imageHandle,imgData));
            
            % default to light theme
            cdata = imgData;
            if ~isempty(themeContainer)
                if isa(themeContainer.Theme,'matlab.graphics.theme.GraphicsTheme')
                    currentTheme = themeContainer.Theme;
                    if strcmp(currentTheme.BaseColorStyle,'dark')
                        cdata = 1-imgData;
                    else
                        cdata = imgData;
                    end
                end
            end
            imageHandle.CData = cdata;
            
            axHandle.Visible = 'on';
            imageHandle.Visible = 'on';
        end

        function occupancyMapThemeChangeCallback(~,event,imageHandle,imgData)
        %occupancyMapThemeChangeCallback updates the occupancy map plot in
        %   response to theme change.

            % Assume empty theme also as default theme
            if strcmp(event.Theme.BaseColorStyle,'dark')
                cdataToggle = 1 - imgData;
                imageHandle.CData = cdataToggle;
            else
                imageHandle.CData = imgData;
            end
        end

        function updateImageAndColorBar(mapData, axHandle, imgHandle, colorBarState, limits, imageTag)
            % updateImageAndColorBar Display the map as a colormap
            %
            % Inputs:
            %       MAPDATA : Map data (e.g., traversabilityMap.cost, signedDistanceMap.distance)
            %      AXHANDLE : Axes handle object
            %     IMGHANDLE : Image handle object that displays the map
            % COLORBARSTATE : Visible status of colorbar
            %        LIMITS : Limits for which we define colorbar

            arguments
                mapData (:,:) double
                axHandle matlab.graphics.axis.Axes
                imgHandle matlab.graphics.primitive.Image
                colorBarState (1,:) matlab.lang.OnOffSwitchState
                limits (1,2) = [0,1]
                imageTag = ''
            end

            axHandle.Visible = 'on';
            imgHandle.Visible = 'on';

            % Map data intervals that correspond to each color in the
            % colormap
            cMap = axHandle.Colormap;
            nBin = size(cMap,1);
            dataIntervals = linspace(limits(1), limits(2), nBin);

            %Find the nearest color in the data intervals to the map data
            %and assign the corresponding color to the respective grid
            %cells
            cIdx = discretize(mapData, dataIntervals);            
            cData = ind2rgb(cIdx, cMap);
            imgHandle.CData = cData;

            % Delete any pre-existing colorbar
            delete(findobj(axHandle.Parent, Type='colorbar', Tag=[imageTag '_Colorbar']));

            % Add colorbar (we assume the map data is range is between 0 and 1)
            ticks = linspace(limits(1),limits(2),11); % increment of 0.1 for rescaled data
            tickLabels = linspace(limits(1),limits(2),11); % same for ticks
            colorBar = colorbar(axHandle, Ticks=ticks, TickLabels=tickLabels,...
                Tag=[imageTag '_Colorbar'], Colormap=cMap, ColormapMode='manual');
            if isequal(colorBarState, matlab.lang.OnOffSwitchState.off)
                colorBar.Visible = "off";
            end
        end
    end
end
