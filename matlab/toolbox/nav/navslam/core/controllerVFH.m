classdef (StrictDefaults) controllerVFH < nav.algs.internal.VectorFieldHistogramBase
%controllerVFH Avoid obstacles using vector field histogram
%   The vector field histogram (VFH) algorithm is used for obstacle
%   avoidance based on range sensor data. Given a range sensor reading
%   in terms of ranges and angles, and a target direction to drive
%   towards, the controllerVFH computes an obstacle-free steering
%   direction using the VFH+ algorithm.
%
%   VFH = controllerVFH returns a vector field histogram
%   object, VFH, that computes a steering direction using the VFH+ algorithm.
%
%   VFH = controllerVFH('PropertyName', PropertyValue, ...)
%   returns a vector field histogram object, VFH, with each specified
%   property set to the specified value.
%
%   Step method syntax:
%
%   STEERINGDIR = step(VFH, SCAN, TARGETDIR) finds an obstacle
%   free steering direction STEERINGDIR, using the VFH+ algorithm for
%   a laser scan, SCAN, as a lidarScan object and a scalar input TARGETDIR.
%   The output STEERINGDIR is in radians. The vehicle's forward direction
%   is considered zero radians.
%   The angles measured clockwise from the forward direction are negative
%   angles and angles measured counter-clockwise from the forward direction
%   are positive angles.
%
%   STEERINGDIR = step(VFH, RANGES, ANGLES, TARGETDIR) allows
%   you to pass range sensor readings as RANGES and ANGLES. The input
%   RANGES are in meters, the ANGLES and TARGETDIR are in radians.
%
%   System objects may be called directly like a function instead of using
%   the step method. For example, y = step(obj, x) and y = obj(x) are
%   equivalent.
%
%   controllerVFH methods:
%
%   step        - Compute steering direction using the range data
%   clone       - Create controllerVFH object with same property values
%   show        - Display controllerVFH information in a figure window
%   <a href="matlab:help matlab.System/reset   ">reset</a>       - Reset the internal states of controllerVFH System object
%
%   controllerVFH properties:
%
%   NumAngularSectors       - Number of angular sectors in histogram
%   DistanceLimits          - Ranges within these limits are considered
%   RobotRadius             - Radius of the circle circumscribing the vehicle
%   SafetyDistance          - Safety distance around the vehicle
%   MinTurningRadius        - Minimum turning radius at current speed
%   TargetDirectionWeight   - Weight for moving in target direction
%   CurrentDirectionWeight  - Weight for moving in current direction
%   PreviousDirectionWeight - Weight for moving in previous direction
%   HistogramThresholds     - Upper and lower thresholds for histogram
%   UseLidarScan            - Use lidarScan object instead of ranges and angles
%
%   Example:
%
%       % Create a vector field histogram object
%       vfh = controllerVFH('UseLidarScan', true);
%
%       % Example laser scan data input
%       ranges = 10*ones(1, 300);
%       ranges(1, 130:170) = 1.0;
%       angles = linspace(-pi/2, pi/2, 300);
%       scan = lidarScan(ranges, angles);
%       targetDir = 0;
%
%       % Compute obstacle-free steering direction
%       steeringDir = vfh(scan, targetDir)
%
%       % Visualize the controllerVFH computation
%       show(vfh);
%
%   See also controllerPurePursuit, mobileRobotPRM.

%   Copyright 2015-2024 The MathWorks, Inc.
%
%   References:
%
%   [1] I. Ulrich and J. Borenstein, "VFH+: reliable obstacle avoidance
%       for fast mobile robots", Proceedings of IEEE International
%       Conference on Robotics and Automation, 1998.

%#codegen

    properties (Nontunable)
        %UseLidarScan Use lidarScan object instead of ranges and angles
        %   By default, you pass ranges and angles as numeric arrays into
        %   the step function. Setting UseLidarScan to "true" allows you to
        %   pass a lidarScan object instead.
        %
        %   Default: false
        %
        %   See also: lidarScan
        UseLidarScan (1, 1) logical = false
    end

    properties(Access = {?nav.algs.internal.VectorFieldHistogramBase, ...
                         ?nav.algs.internal.InternalAccess})
        %IsShowBeforeStep Flag to prevent calls to show before step
        IsShowBeforeStep = true;
    end

    properties (Constant, Access=private)
        % Visualization parameters for show method.

        % Tiled Chart Layout tag.
        ShowTagTCL = "controllerVFH_show_tcl";
        ShowTagPODAxes = "controllerVFH_show_pod_axes";
        ShowTagMaskedAxes = "controllerVFH_show_masked_axes";

        % POD Histogram colors.
        PODHistogramSeriesIndex = 1;
        PODHistogramFaceAlpha = 0;
        PODHistogramThresholdsSeriesIndex = 2;

        % Axis limit parameters.
        PODAxesLimitMultiplier = 4;
        PODAxesLimitMinimum = 1;
        MaskedAxesLimitMargin = 1;
        
        % Masked histogram parameters.
        MaskedHistogramLengthPercentage = 0.5;
        MaskedHistogramSeriesIndex = 1;
        MaskedHistogramFaceAlpha = 0;
        
        % Direction parameters.
        DirectionLengthPercentage = 0.5;
        DirectionLineWidth = 2;
        TargetDirectionSeriesIndex = 3;
        TargetDirectionLineStyle = "--";
        SteeringDirectionSeriesIndex = 2;

        % Range parameters.
        RangesMarkerSize = 5;
        RangesSeriesIndex = 4;
        DistanceLimitsSeriesIndex = 5;

        % Constant theta data used for constant threshold plots.
        ThresholdThetaData = 0:pi/60:2*pi;
    end

    methods (Access = protected)
        function steeringDir = stepImpl(obj, varargin)
        %step Compute control commands and steering direction

            steeringDir = stepImpl@nav.algs.internal.VectorFieldHistogramBase(...
                obj, varargin{:});

            % Allow show method to be called
            obj.IsShowBeforeStep = false;
        end

        function resetImpl(obj)
        %resetImpl Reset internal states

            resetImpl@nav.algs.internal.VectorFieldHistogramBase(obj);

            % Prevent calls to show method before step
            obj.IsShowBeforeStep = true;
        end

        function [scan, target, classOfRanges] = parseAndValidateStepInputs(obj, varargin)
        %parseAndValidateStepInputs Validate inputs to step function

        % Parse and validate
            if obj.UseLidarScan
                % Only lidarScan input
                scan = robotics.internal.validation.validateLidarScan(...
                    varargin{1}, 'step', 'scan');

                target = varargin{2};
            else
                % Scan as ranges and angles
                scan = robotics.internal.validation.validateLidarScan(...
                    varargin{1}, varargin{2}, 'step', 'ranges', 'angles');

                target = varargin{3};
            end

            classOfRanges = class(scan.Ranges);

            % Validate the target direction
            validateattributes(target, {'double', 'single'}, {'nonnan', 'real', ...
                                'scalar', 'nonempty', 'finite'}, 'step', 'target direction');

            % Cache ranges and angles for "show" method.
            obj.Ranges = scan.Ranges;
            obj.Angles = scan.Angles;
        end

        function validateInputsImpl(obj, varargin)
        %validateInputsImpl Validate inputs before setupImpl is called
            [scan, target, classOfRanges] = obj.parseAndValidateStepInputs(varargin{:});

            isDataTypeEqual = isequal(classOfRanges, class(target));

            coder.internal.errorIf(~isDataTypeEqual, ...
                                   'nav:navalgs:vfh:DataTypeMismatch', ...
                                   classOfRanges, class(scan.Angles), class(target));
        end

        function num = getNumInputsImpl(obj)
        %getNumInputsImpl Get number of inputs

            if obj.UseLidarScan
                num = 2;
            else
                num = 3;
            end
        end

        function flag = isInputSizeMutableImpl(obj, index)
        %isInputSizeMutableImpl Mutable input size status
        %   This function will be called once for each input of the
        %   system block.

            if obj.UseLidarScan
                % All inputs are fixed size in this case
                flag = false;
            else
                % First two inputs, i.e. ranges and angles are variable sized
                % signals.
                if (index == 1 || index  == 2)
                    flag = true;
                else
                    flag = false;
                end
            end
        end

        function loadObjectImpl(obj, svObj, wasLocked)
        %loadObjectImpl Custom load implementation

            obj.IsShowBeforeStep = svObj.IsShowBeforeStep;
            loadObjectImpl@nav.algs.internal.VectorFieldHistogramBase(obj,svObj,wasLocked);
        end

        function s = saveObjectImpl(obj)
        %saveObjectImpl Custom save object action

            s = saveObjectImpl@nav.algs.internal.VectorFieldHistogramBase(obj);
            s.IsShowBeforeStep = obj.IsShowBeforeStep;
        end
    end

    methods
        function obj = controllerVFH(varargin)
        %controllerVFH Constructor
            setProperties(obj,nargin,varargin{:});
        end
    end

    methods
        function ax = show(obj, name, value)
        %
            
            % If step has not been called then error out.
            if obj.IsShowBeforeStep
                error(message('nav:navalgs:vfh:ShowBeforeStep'));
            end

            % Setup existing axes or create new ones.
            if nargin > 1
                validatestring(name,{'Parent'}, 'show', 'Name');
                validateattributes(value,{'matlab.graphics.axis.PolarAxes'}, ...
                                   {'numel', 2}, 'show', 'Value');
                podAxes = newplot(value(1));
                maskedAxes = newplot(value(2));
            else
                % Find POD and Masked axes in the current layout.
                tcl = matlab.graphics.internal.getCurrentLayout;
                podAxes = findall(tcl,Tag=obj.ShowTagPODAxes);
                maskedAxes = findall(tcl,Tag=obj.ShowTagMaskedAxes);
                
                % Create a layout if none exists.
                if isempty(tcl)
                    tcl = tiledlayout("flow");
                end

                % Create new axes if none exist, or prepare existing axes
                % for new plots.
                if isempty(podAxes)
                    podAxes = polaraxes(tcl,ThetaZeroLocation="top");
                    podAxes.Layout.Tile = 1;
                else
                    podAxes = newplot(podAxes);
                end
                if isempty(maskedAxes)
                    maskedAxes = polaraxes(tcl,ThetaZeroLocation="top");
                    maskedAxes.Layout.Tile = 2;
                else
                    maskedAxes = newplot(maskedAxes);
                end
                
                % Tag layout and axes.
                tcl.Tag = obj.ShowTagTCL;
                podAxes.Tag = obj.ShowTagPODAxes;
                maskedAxes.Tag = obj.ShowTagMaskedAxes;
            end

            % Plot polar obstacle density histogram.
            podplot(obj,podAxes);

            % Plot masked polar histogram and range sensor data.
            maskedplot(obj,maskedAxes);

            % Only return handle if user requested it.
            if nargout > 0
                ax = [podAxes maskedAxes];
            end
        end
    end

    methods (Access=private)
        function podplot(obj,podAxes)
        %podplot Plot polar obstacle density histogram

            % Set upper axis limit to a multiple of the upper histogram 
            % threshold or a constant minimum, whichever is larger.
            polarAxesLimit = obj.PODAxesLimitMultiplier ...
                .* max(obj.HistogramThresholds);
            polarAxesLimit = max(obj.PODAxesLimitMinimum,polarAxesLimit);
            % Only change axes limits if hold is off.
            if ~ishold(podAxes)
                podAxes.RLim = [0, polarAxesLimit];
            end
            
            % Plot the polar obstacle density.
            matlab.graphics.chart.primitive.Histogram( ...
                'Parent',podAxes, ...
                'BinEdges',thetaEdges(obj), ...
                'BinCounts',obj.PolarObstacleDensity, ...
                'FaceAlpha',obj.PODHistogramFaceAlpha, ...
                'SeriesIndex',obj.PODHistogramSeriesIndex, ...
                'EdgeColor','auto');

            % Plot histogram thresholds.
            thetaData = obj.ThresholdThetaData;
            thetaData = thetaData(:) .* [1 1];
            rData = obj.HistogramThresholds(:).' .* ones(size(thetaData));
            thetaData = [thetaData; NaN(1,2)];
            rData = [rData; NaN(1,2)];
            histThresLine = matlab.graphics.primitive.Line( ...
                'Parent',podAxes);
            set(histThresLine,'ThetaData',thetaData(:), ...
                'RData',rData(:), ...
                'SeriesIndex',obj.PODHistogramThresholdsSeriesIndex);

            % Add legend and title to the first plot
            legend(podAxes, histThresLine, message(...
                'nav:navalgs:vfh:HistThresholds').getString, ...
                   'Location','best');
            title(podAxes, ...
                  message('nav:navalgs:vfh:PODTitle').getString);
        end

        function maskedplot(obj,maskedAxes)
        %maskedplot Plot masked polar histogram and range sensor data

            % Set the upper axis limit to a margin slightly above the 
            % active region. 
            lowerDistanceLimit = obj.DistanceLimits(1);
            upperDistanceLimit = obj.DistanceLimits(2);
            maskedAxesLimit = upperDistanceLimit ...
                + obj.MaskedAxesLimitMargin;
            % Only change axes limits if hold is off.
            if ~ishold(maskedAxes)
                maskedAxes.RLim = [0, maskedAxesLimit];
            end

            % Use a percentage of the upper axis limit for the masked 
            % histogram and direction lengths.
            maskedLength = obj.MaskedHistogramLengthPercentage ...
                .* maskedAxesLimit;
            dirLength = obj.DirectionLengthPercentage .* maskedAxesLimit;

            % Plot the masked histogram.
            matlab.graphics.chart.primitive.Histogram( ...
                'Parent',maskedAxes, ...
                'BinEdges',thetaEdges(obj), ...
                'BinCounts',maskedLength .* obj.MaskedHistogram, ...
                'FaceAlpha',obj.MaskedHistogramFaceAlpha, ...
                'SeriesIndex',obj.MaskedHistogramSeriesIndex, ...
                'EdgeColor','auto');

            % Plot target and last steering direction
            targetDirLine = matlab.graphics.primitive.Line( ...
                'Parent',maskedAxes);
            set(targetDirLine,'ThetaData',[0, obj.TargetDirection], ...
                'RData',[0, dirLength], ...
                'LineWidth',obj.DirectionLineWidth, ...
                'LineStyle',obj.TargetDirectionLineStyle, ...
                'SeriesIndex',obj.TargetDirectionSeriesIndex);
            steeringDirLine = matlab.graphics.primitive.Line( ...
                'Parent',maskedAxes);
            set(steeringDirLine,'ThetaData',[0, obj.PreviousDirection], ...
                'RData',[0, dirLength], ...
                'LineWidth',obj.DirectionLineWidth, ...
                'SeriesIndex',obj.SteeringDirectionSeriesIndex);

            % Only plot range readings with distance limits.
            rangeIdx = (obj.Ranges < maskedAxesLimit) & ...
                (obj.Ranges >= lowerDistanceLimit) & ...
                (obj.Ranges <= upperDistanceLimit);

            % Plot range readings.
            rangeScatter = matlab.graphics.chart.primitive.Scatter( ...
                'Parent',maskedAxes);
            set(rangeScatter,'ThetaData',obj.Angles(rangeIdx), ...
                'RData',obj.Ranges(rangeIdx), ...
                'SizeData',obj.RangesMarkerSize, ...
                'MarkerFaceColor', 'flat', ...
                'SeriesIndex',obj.RangesSeriesIndex);

            % Plot the active region.
            thetaData = obj.ThresholdThetaData;
            thetaData = thetaData(:) .* [1 1];
            rData = [lowerDistanceLimit, upperDistanceLimit] ...
                .* ones(size(thetaData));
            thetaData = [thetaData; NaN(1,2)];
            rData = [rData; NaN(1,2)];
            distLimLine = matlab.graphics.primitive.Line( ...
                'Parent',maskedAxes);
            set(distLimLine,'ThetaData',thetaData(:), ...
                'RData',rData(:), ...
                'SeriesIndex',obj.DistanceLimitsSeriesIndex);

            % Get legend strings
            targetStr = ...
                message('nav:navalgs:vfh:TargetDir').getString;
            steerStr = ...
                message('nav:navalgs:vfh:SteeringDir').getString;
            rangeStr = ...
                message('nav:navalgs:vfh:RangeReadings').getString;
            distLimStr = ...
                message('nav:navalgs:vfh:DistanceLimits').getString;

            % Set legends and title
            hasRanges = (nnz(rangeIdx) > 0);
            lgdLoc = 'best';
            if hasRanges && ~isnan(obj.PreviousDirection)
                % All children exists
                legend(maskedAxes, ...
                    [targetDirLine, steeringDirLine, ...
                    distLimLine, rangeScatter], ...
                    targetStr,steerStr,distLimStr,rangeStr, ...
                    'Location',lgdLoc);
            elseif hasRanges && isnan(obj.PreviousDirection)
                % Previous direction is nan, so not plotted
                legend(maskedAxes, ...
                    [targetDirLine, distLimLine, rangeScatter], ...
                    targetStr,distLimStr,rangeStr,'Location',lgdLoc);
            else
                % If no laser points then previous direction cannot be nan
                legend(maskedAxes, ...
                    [targetDirLine, steeringDirLine, distLimLine], ...
                    targetStr,steerStr,distLimStr,'Location',lgdLoc);
            end

            title(maskedAxes, ...
                  message('nav:navalgs:vfh:MPHTitle').getString);
        end

        function th = thetaEdges(obj)
        %thetaEdges Theta bin edge values for polar histograms
            th = linspace(-pi,pi,obj.NumAngularSectors+1);
        end
    end
end
