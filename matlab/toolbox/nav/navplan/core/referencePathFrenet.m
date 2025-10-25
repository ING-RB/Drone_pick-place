classdef referencePathFrenet < nav.algs.internal.FrenetReferencePath
%

%   Copyright 2020-2023 The MathWorks, Inc.

%#codegen

    properties (Dependent)
        PathLength

        SegmentParameters
    end

    methods
        function obj = referencePathFrenet(waypoints, varargin)
        %

            narginchk(1,5);
            obj = obj@nav.algs.internal.FrenetReferencePath(waypoints, varargin{:});
        end

        function cObj = copy(obj)
        %
            if isa(obj.PathManager,'nav.algs.internal.PathManagerFixed')
                maxSize = {'MaxNumWaypoints',obj.MaxNumWaypoints};
            else
                maxSize = {};
            end
            cObj = referencePathFrenet(obj.Waypoints, ...
                                       'DiscretizationDistance', obj.DiscretizationDistance, ...
                                       maxSize{:});
        end

        function [pathPoints, inWindow] = closestPoint(obj, points, searchWindow)
        %

        % Validate inputs
            narginchk(2,3);
            xy = obj.validateXYPoints(points,'closestPoint','points');

            if nargin == 2
                % Find closest points
                pathPoints = closestPoint@nav.algs.internal.FrenetReferencePath(obj,xy);
                clippedWindow = [0 obj.Length];
            else
                clippedWindow = obj.validateSearchWindow(searchWindow,'closestPoint','searchWindow');

                pathPoints = obj.searchInWindow(xy,clippedWindow,false);
            end

            if nargout == 2
                inWindow = obj.verifyInWindow(xy,pathPoints,clippedWindow);
            end
        end

        function [pathPoints, inWindow] = closestPointsToSequence(obj, points, initialWindow)
        %

        % Validate inputs
            narginchk(3,3);
            xy = obj.validateXYPoints(points,'closestPointsToSequence','points');
            clippedWindow = obj.validateSearchWindow(initialWindow,'closestPointsToSequence','initialWindow');
            halfSpan = (initialWindow(2)-initialWindow(1))/2;

            % Allocate output
            n = size(xy,1);
            pathPoints = zeros(n,6);

            if nargout == 2
                inWindow = false(n,1);
            end

            arclimits = [0 obj.PathLength];

            for i = 1:size(xy,1)
                % Search in window
                if nargout == 2
                    [pathPoints(i,:), ~, inWindow(i)] = obj.searchInWindow(xy(i,:),clippedWindow,false);
                else
                    pathPoints(i,:) = obj.searchInWindow(xy(i,:),clippedWindow,false);
                end
                clippedWindow = obj.clipWindow(arclimits, pathPoints(i,end)+[-halfSpan halfSpan]);
            end
        end

        function [arclengths,distances,projPoints] = closestProjections(obj, points, varargin)
        %

        % Parse and validate inputs
            narginchk(2,4);
            coder.internal.prefer_const(varargin);
            [xy, clippedIntervals, maxNumProj] = obj.parseClosestProjection(points, varargin{:});

            numPts = size(xy,1);
            projPoints_tmp  = repmat({zeros(maxNumProj,6)},numPts,1);
            S_tmp           = repmat({zeros(maxNumProj,1)},numPts,1);
            D_tmp           = repmat({zeros(maxNumProj,1)},numPts,1);
            dMax            = inf(numPts,1);
            curNumProj      = repmat({0},numPts,1);

            % Find nearest point within each section
            for seg = 1:size(clippedIntervals,1)
                sWindow = clippedIntervals(seg,:);
                [pp, dist, inRange] = obj.searchInWindow(xy,sWindow,true);

                for i = 1:numPts
                    % Update list of best projections for each point
                    if inRange(i)
                        [S_tmp{i},D_tmp{i},projPoints_tmp{i},curNumProj{i},dMax(i)] = obj.updateRecords(...
                            S_tmp{i}, D_tmp{i}, projPoints_tmp{i}, dMax(i), curNumProj{i}, dist(i), pp(i,:), maxNumProj);
                    end
                end
            end

            % Only return the valid projections
            arclengths = cell(numPts,1);
            distances = cell(numPts,1);
            projPoints = cell(numPts,1);

            for i = 1:numPts
                arclengths{i} = S_tmp{i}(1:curNumProj{i},1);
                distances{i} = D_tmp{i}(1:curNumProj{i},1);
                projPoints{i} = projPoints_tmp{i}(1:curNumProj{i},:);
            end
        end

        function pathPoint = interpolate(obj, arcLength)
        %

        % Validate number of input arguments
            narginchk(2,2);
            validateattributes(arcLength,{'numeric'},{'nonempty','nonnan','finite','vector'},'interpolate','arcLength');
            pathPoint = obj.interpolate@nav.algs.internal.FrenetReferencePath(arcLength(:));
        end

        function xy = position(obj,s)
        %
            narginchk(2,2)
            idx = validateAndDiscretizeArclengths(obj, s, 'position');
            segStarts = obj.PathManager.SegStarts;
            xy = zeros(numel(s),2);
            for n = 1:numel(idx)
                i = idx(n);
                ds = s(n)-segStarts(i,end);
                [xy(n,1),xy(n,2)] = obj.clothoid(segStarts(i,1),segStarts(i,2),...
                                                 segStarts(i,3),segStarts(i,4),segStarts(i,5),ds);
            end
        end

        function theta = tangentAngle(obj,s)
        %
            narginchk(2,2)
            idx = validateAndDiscretizeArclengths(obj, s, 'tangentAngle');
            TH0 = obj.PathManager.SegStarts(idx,3);
            K0 = obj.PathManager.SegStarts(idx,4);
            DK0 = obj.PathManager.SegStarts(idx,5);
            S0 = obj.PathManager.SegStarts(idx,6);
            n = numel(s);
            theta = zeros(n,1);

            for i = 1:n
                th0 = TH0(i);
                k0 = K0(i);
                dk = DK0(i);
                s0 = S0(i);
                L = s(i)-s0;
                theta(i) = dk/2*L*L + k0*L + th0;
            end
            theta = robotics.internal.wrapToPi(theta);
        end

        function k = curvature(obj,s)
        %
            narginchk(2,2)
            idx = validateAndDiscretizeArclengths(obj, s, 'curvature');
            k0 = obj.PathManager.SegStarts(idx,4);
            dk = obj.PathManager.SegStarts(idx,5);
            s0 = obj.PathManager.SegStarts(idx,6);
            n = numel(s);
            k = zeros(n,1);
            for i = 1:n
                k(i) = k0(i)+dk(i).*(s(i)-s0(i));
            end
        end

        function dk = changeInCurvature(obj,s)
        %
            narginchk(2,2)
            idx = validateAndDiscretizeArclengths(obj, s, 'changeInCurvature');
            dk = obj.PathManager.SegStarts(idx,5);
        end

        function S = get.PathLength(obj)
        %
            S = obj.Length;
        end

        function cParams = get.SegmentParameters(obj)
        %
            cParams = obj.PathManager.SegStarts(1:end-1,:);
        end

        function globalState = frenet2global(obj, varargin)
        %

        % Validate number/type of input arguments
            narginchk(2,3);

            % Validate frenet states
            validateattributes(varargin{1},{'numeric'},{'nonnan','nonempty','finite','size',[nan 6]},'frenet2global','frenetState');

            if nargin == 3
                % Validate lateral time derivatives and heading invert
                validateattributes(varargin{2},{'numeric'},{'nonnan','finite','nonempty','size',[size(varargin{1},1) 3]},'frenet2global','latTimeDerivs');
                validateattributes(varargin{2}(:,3),{'numeric'},{'binary'},'frenet2global','invertHeadingTF');
            end

            % Convert frenet states to global coordinate frame
            globalState = obj.frenet2global@nav.algs.internal.FrenetReferencePath(varargin{:});
        end

        function [frenetState, lateralTimeDerivatives] = global2frenet(obj, varargin)
        %

        % Validate number/type of input arguments
            narginchk(2,3);

            % Validate globalState
            validateattributes(varargin{1},{'numeric'},{'nonnan','nonempty','finite','size',[nan 6]},'global2frenet','globalPoint');

            if nargin == 3
                % Validate arclengths at which the Frenet frame will be
                % placed.
                validateattributes(varargin{2},{'numeric'},{'nonnan','finite','nonnegative','vector','numel',size(varargin{1},1)},'global2frenet','sFrame');
            end

            % Convert global states to frenet coordinate frame
            if nargout == 2
                [frenetState, lateralTimeDerivatives] = obj.global2frenet@nav.algs.internal.FrenetReferencePath(varargin{:});
            else
                frenetState = obj.global2frenet@nav.algs.internal.FrenetReferencePath(varargin{:});
            end
        end
    end

    methods (Access = protected)
        function [pathPoints, dist, INWINDOW] = searchInWindow(obj, xy, searchWindow, mustBeProjection)
        %

        %searchInWindow Find closest point or projection within search window

        % Determine initial and final indices
            i0 = discretize(searchWindow(:,1),[-inf;obj.PathManager.SegStarts(2:end-1,end);inf],'IncludedEdge','left');
            i1 = discretize(searchWindow(:,2),[-inf;obj.PathManager.SegStarts(2:end-1,end);inf],'IncludedEdge','left');

            % Grab path info for region of interest
            ss = obj.PathManager.SegStarts(i0:i1,:);
            bboxes = obj.PathManager.BoundingBoxes(:,i0:i1);

            % Recalculate lower bound
            [ss(1,1),ss(1,2),ss(1,3),ss(1,4)] = ...
                obj.clothoid(ss(1,1),ss(1,2),ss(1,3),ss(1,4),ss(1,5),...
                             searchWindow(1)-ss(1,end));
            ss(1,end) = searchWindow(1);

            % Search within bounds
            if coder.target('MATLAB')
                [pathPoints,dist,~,~] = nav.algs.internal.mex.nearestPointIterative(...
                    xy, ss, bboxes, searchWindow(2), mustBeProjection);
            else
                [pathPoints,dist,~,~] = nav.algs.internal.impl.nearestPointIterative(...
                    xy, ss, bboxes, searchWindow(2), mustBeProjection);
            end

            if nargout == 3
                if mustBeProjection
                    % Any points returned by nearestPointIterative when
                    % mustBeProjection is true qualify as valid projections
                    INWINDOW = ~isnan(pathPoints(:,end));
                else
                    % Verify non-projection points
                    INWINDOW = verifyInWindow(obj,xy,pathPoints,searchWindow);
                end
            end
        end

        function INWINDOW = verifyInWindow(~,xy,pathPoints,searchWindow)
        %

        %verifyInWindow Verifies whether closest points returned also qualify as projections
        %
        %   First checks whether any points lie on the interval boundary.
        %   Any points close to the boundary are checked for orthogonality.

        % Point lies within bound
            INWINDOW = all(pathPoints(:,end) >= (searchWindow(1)+sqrt(eps)) & pathPoints(:,end) <= (searchWindow(2)-sqrt(eps)),2);
            if any(~INWINDOW)
                % Check perpendicularity
                pp = pathPoints(~INWINDOW,:);
                v = xy(~INWINDOW,:)-pp(:,1:2);
                t = [cos(pp(:,3)) sin(pp(:,3))];
                INWINDOW(~INWINDOW) = abs(dot(t,v./vecnorm(v,2,2),2)) > (1-sqrt(eps));
            end
        end

        function idx = validateAndDiscretizeArclengths(obj, s, methodName)
        %

        %validateAndDiscretizeArclengths Validate arclengths and identify the segment to which they belong
            validateattributes(s,{'numeric'},{'column','nonnan','finite'},methodName,'s');
            idx = discretize(s,obj.PathManager.SegStarts(:,end),'IncludedEdge','left');
        end

        function [S,D,PTS,curNumProj,dMax] = updateRecords(~, S, D, PTS, dMax, curNumProj, d, pp, maxNumProj)
        %

        %updateRecords Add new projection to list or replace worst if list is full

            if curNumProj < maxNumProj
                % Add projection to results
                curNumProj = curNumProj+1;
                S(curNumProj,1) = pp(end);
                D(curNumProj,1) = d;
                PTS(curNumProj,:) = pp;
                if curNumProj == maxNumProj
                    dMax = max(D);
                end
            else
                if d < dMax
                    % Find current max point and replace entry
                    [~,idx] = max(D);
                    D(idx,1) = d;
                    S(idx,1) = pp(end);
                    PTS(idx,:) = pp;
                end
                dMax = max(D);
            end
        end

        function xy = validateXYPoints(~,points,fcnName,varName)
        %

        %validateXYPoints Validate incoming points
            validateattributes(points, {'numeric'}, {'nonnan','finite','nonempty','2d'},fcnName,varName);
            sz = size(points,2);
            coder.internal.assert(sz>=2, 'nav:navalgs:referencepathfrenet:XYNumCol');

            if sz == 2
                xy = points;
            else
                xy = points(:,1:2);
            end
        end

        function searchWindow = validateSearchWindow(obj, searchWindow, fcnName, varName, numWindows)
        %

        %validateSearchWindow Verify searchWindow attributes and clip window to path limits
            if nargin == 4
                validateattributes(searchWindow, {'numeric'}, ...
                                   {'row','numel',2,'finite','increasing'}, ...
                                   fcnName,varName);
            else
                validateattributes(searchWindow, {'numeric'}, ...
                                   {'size',[numWindows 2],'finite'}, ...
                                   fcnName,varName);
                coder.internal.assert(all(diff(searchWindow,[],2)>=0),...
                                      'nav:navalgs:referencepathfrenet:NonDecreasingIntervals');
            end
            searchWindow = obj.clipWindow([0 obj.PathLength],searchWindow);
        end

        function [xy, clippedIntervals, maxNumProj, defaultIntervals] = parseClosestProjection(obj, points, varargin)
            xy = obj.validateXYPoints(points,'closestProjections','points');

            switch nargin
              case 2
                breaks = obj.PathManager.SegStarts(:,end);
                intervals = [breaks(1:end-1) breaks(2:end)];
                maxNumProj = size(intervals,1); % Subtract one due to extra line in segstarts
                defaultIntervals = true;
              case 3
                if coder.internal.isConstTrue(isscalar(varargin{1}))
                    % Treat 3rd input as number of possible distances
                    % returned
                    breaks = obj.PathManager.SegStarts(:,end);
                    intervals = [breaks(1:end-1) breaks(2:end)];
                    maxNumProj = varargin{1};
                    defaultIntervals = true;
                else
                    intervals = varargin{1};
                    maxNumProj = size(intervals,1);
                    defaultIntervals = false;
                end
              case 4
                intervals = varargin{1};
                maxNumProj = varargin{2};
                defaultIntervals = false;
            end

            % Validate intervals
            clippedIntervals = obj.validateSearchWindow(intervals,'closestProjections','intervals',size(intervals,1));

            % Validate number of requested projections
            validateattributes(maxNumProj,{'numeric'},{'integer','positive','<=',size(intervals,1)},'closestProjections','N');
        end
    end

    methods (Static, Hidden)
        function searchWindow = clipWindow(arclimits,searchWindow)
        %clipWindow Constrain window to path limits
            searchWindow(searchWindow < arclimits(1)) = arclimits(1);
            searchWindow(searchWindow > arclimits(2)) = arclimits(2);
        end
    end
end
