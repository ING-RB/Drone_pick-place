function varargout = sensordet(targets, varargin)
%SENSORDET Sensor detection generator
%   D = SENSORDET(TGTPOS) simulates M sensor detections for a scenario with
%   N targets. TGTPOS is a 7-by-N matrix whose columns contain the
%   following tuple:
%     targetID - unique integer
%            x - target position on x-axis
%            y - target position on y-axis 
%            z - target position on z-axis
%           vx - target velocity on x-axis
%           vy - target velocity on y-axis
%           vz - target velocity on z-axis
%
%   D is a 8-by-M matrix whose columns contain the following tuple:
%               targetID - unique integer. Negative for false detections
%                azimuth - angle in degrees
%              elevation - angle in degrees
%                  range - distance from sensor in meters
%              rangerate - rate at which the range increases in m/s
%     azimuth resolution - angle in degrees
%   elevation resolution - angle in degrees
%       range resolution - in meters
%
%   By default, the function simulates a perfect stationary sensor located
%   at the origin of the coordinate system, i.e., one that detects all
%   targets (within the sensor resolution) without any false alarms, and
%   provides complete detection information.
%  
%   D = SENSORDET(..., 'Position', POS) specifies the 3 by 1 POS vector
%   whose values correspond to the x, y and z position components of the
%   sensor. POS defaults to [0; 0; 0].
%
%   D = SENSORDET(..., 'Velocity', VEL) specifies the 3 by 1 VEL vector
%   whose values correspond to the vx, vy and vz velocity components of the
%   sensor. VEL defaults to [0; 0; 0].
%
%   D = SENSORDET(..., 'Pd', PD) specifies the probability of detection,
%   PD, of the sensor. PD can be a scalar or N-element vector with values
%   between 0 and 1. PD defaults to 1.
% 
%   D = SENSORDET(..., 'Pfa', PFA) specifies the probability of false
%   alarm, PFA, of the sensor. PFA is a scalar with values between 0 and 1.
%   PFA defaults to 0.
%       
%   D = SENSORDET(..., 'RangeResolution', RR) specifies the range
%   resolution, RR, of the sensor in meters. RR defaults to 1.
%
%   D = SENSORDET(..., 'AzimuthResolution', AZR) specifies the azimuth
%   resolution, AZR, of the sensor in degrees. AZR defaults to 1.
%
%   D = SENSORDET(..., 'ElevationResolution', ELR) specifies the elevation
%   resolution, ELR, of the sensor in degrees. ELR defaults to 1.
%
%   D = SENSORDET(..., 'RangeRateResolution', RRR) specifies the range rate
%   resolution, RRR, of the sensor in m/s. RRR defaults to 1.
%
%   D = SENSORDET(..., 'MaxRange', MAXR) specifies maximum range MAXR in
%   which the sensor operates. The default value of MAXR corresponds to the
%   range of the most distant target.
%
%   D = SENSORDET(..., 'AzimuthSpan', ASPAN) specifies the 2-element vector
%   ASPAN that defines the range of azimuth angles covered by the sensor,
%   in degrees. The default value of ASPAN is [-180 180].
%
%   D = SENSORDET(..., 'ElevationSpan', ESPAN) specifies the 2-element
%   vector ESPAN that defines the range of elevation angles covered by the
%   sensor, in degrees. The default value of ESPAN is [-90 90].
% 
%   D = SENSORDET(..., NAME, false) specifies additional parameter names to
%   simulate incomplete information returned by the sensor by replacing
%   some rows of D with NaNs. NAME can be one of the following:
%   'HasTargetID' | 'HasAzimuth' | 'HasElevation' | 'HasRange' |
%   'HasRangeRate' | 'HasAzimuthResolution' | 'HasElevationResolution' |
%   'HasRangeResolution'. By default, the values of these parameters is
%   true.
%
%   SENSORDET(...) plots the targets, the detections and the sensor
%   coverage.
%
%   [D, DTABLE] = SENSORDET(...) provides the detections in an easy-to-read
%   table format, DTABLE, in addition to the matrix D.
%
%   Example:
%   targets = [...
%       1.0000   2.0000    3.0000    4.0000     5.0000    6.0000    7.0000    8.0000    9.0000   10.0000; ... 
%     307.3825 155.5796  277.2971   40.5487   -58.8038 -140.7397 -205.2381 -252.2770 -161.8343 -293.8874; ...
%      54.5299  63.9909    2.9160   29.5140    56.1228   82.7425  109.3734  136.0157  162.6693  189.3345; ...
%       0        0         0         0          0         0         0         0         0         0; ...
%   -51.8768   -56.0789   92.2494   79.5412   66.7183   53.7973   40.7954   27.7304   14.6206    1.4846; ...
%   446.9998   516.9673 -592.8660 -594.7043 -596.2790 -597.5833 -598.6115 -599.3588 -599.8218 -599.9982; ...
%          0         0         0         0         0         0         0         0         0         0];
%
%   % Depict detections of these targets
%   matlabshared.tracking.internal.sensordet(targets) 
%   % Depict detections with a lower PD
%   matlabshared.tracking.internal.sensordet(targets, 'PD', 0.9) 
%   % Depict with additional false alarms.
%   matlabshared.tracking.internal.sensordet(targets, 'PFA', 1e-6)
%   % To return the detections, call the function with an output:
%   detections = matlabshared.tracking.internal.sensordet(targets, 'PD', 0.9) 
%   % To return detections without RangeRate information:
%   detections = matlabshared.tracking.internal.sensordet(targets, 'HasRangeRate', false) 

%   Copyright 2016 The MathWorks, Inc.

%#codegen
    
    cond = (nargin == 0 || isempty(targets));

    coder.internal.errorIf(cond, ...
        'shared_tracking:sensordet:noInputs');    
    if coder.target('MATLAB')    
        [tgts, params] = parseInputs(targets, varargin{:});
    else
        [tgts, params] = parseInputsCodegen(targets, varargin{:});
    end
    realdetections = generateTrueDetections(tgts, params);
    falsealarms = generateFalseAlarms(params); 
    detections = [realdetections,falsealarms];
    % Eliminate detections that fall into the same resolution bin
    [~, UniqueDets, ~] = unique(detections(2:4, :)', 'rows');
    detections = detections(:, UniqueDets);    
    if ~nargout
        visualizeDetections(targets, detections, params);        
    else
        % Replace detection parameters with NaN if params.HasX if false
        detections = zero2nan(detections, params);
        varargout = {detections};
        if coder.target('MATLAB') && nargout == 2
            TargetID = detections(1,:)';
            Azimuth  = detections(2,:)'; 
            Elevation = detections(3,:)';
            Range = detections(4,:)';
            RangeRate = detections(5,:)';
            AzimuthResolution = detections(6,:)';
            ElevationResolution  = detections(7,:)';
            RangeResolution  = detections(8,:)';
            varargout(2) = {table(TargetID, Azimuth, Elevation, Range,...
                RangeRate, AzimuthResolution, ElevationResolution, ...
                RangeResolution)};
        end
    end
    
end

function detections = generateTrueDetections(targets, params)
%GENERATETRUEDETECTIONS generates detections for simulated targets
%based on the simulated sensor PARAMS.
    numTgts = size(targets, 2);
    detections = zeros(8, numTgts); % 8 parameters per target detection
    k = 0;
    rad2deg = 180/pi;
    for i = 1:numTgts
        if rand <= params.PD(i) %generate detection
            relpos = targets(2:4, i) - params.Position;
            [az, el, r] = cart2sph(relpos(1), relpos(2), relpos(3));
            az = az * rad2deg;
            el = el * rad2deg;
            %Calculate range rate:
            relvel = targets(5:7, i) - params.Velocity;
            rr = relpos' * relvel / max(r, eps('double'));
            if r <= params.MaxRange && ... %within range
                    el >= params.ElevationSpan(1) && el <= params.ElevationSpan(2) && ... %within elevation angles
                    az >= params.AzimuthSpan(1) && az <= params.AzimuthSpan(2) && ... %within azimuth angles
                    rr <= params.MaxRangeRate %within range rate limits
                k = k + 1; %create detection
                detections(1, k) = targets(1, i) * params.HasTargetID;                
                detections(2, k) = roundMeasurement(az, params.AzimuthResolution) * params.HasAzimuth;
                detections(3, k) = roundMeasurement(el, params.ElevationResolution) * params.HasElevation;
                detections(4, k) = roundMeasurement(r, params.RangeResolution) * params.HasRange;
                detections(5, k) = roundMeasurement(rr, params.RangeRateResolution) * params.HasRangeRate;                
                detections(6, k) = params.AzimuthResolution * params.HasAzimuthResolution;
                detections(7, k) = params.ElevationResolution * params.HasElevationResolution;
                detections(8, k) = params.RangeResolution * params.HasRangeResolution;
            end
        end            
    end
    detections = detections(: ,1:k);
end

function detections = generateFalseAlarms(params)
%GENERATEFALSEDETECTIONS generates false alarms, i.e., detections that
%are of nonexistent targets.
    if params.PFA
        numRCells = round(params.FDrange / params.RangeResolution);
        numAzCells = round((params.AzimuthSpan(2) - params.AzimuthSpan(1)) ...
            / params.AzimuthResolution);
        % To avoid false detections at elevation angles of +90 or -90,
        % modify the range to [-89.9 89.9]. These detections cause a
        % singularity in the covariance matrix
        params.ElevationSpan(1) = max(params.ElevationSpan(1) + params.ElevationResolution, params.ElevationSpan(1));
        params.ElevationSpan(2) = min(params.ElevationSpan(2) - params.ElevationResolution, params.ElevationSpan(2));
        
        numElCells = round((params.ElevationSpan(2) - params.ElevationSpan(1)) ...
            / params.ElevationResolution);
        numCells =  numRCells * numAzCells * numElCells;
        numFalses = round(params.PFA * numCells);
        if numFalses == 0 % So, there should be less than 1 false alarms
            if rand < params.PFA * numCells
                numFalses = 1;
            end
        end
        detections = zeros(8, numFalses);
        for i = 1:numFalses            
            detections(1, i) = -i * params.HasTargetID;
            rangecell = round(numRCells * rand);
            azcell = round(numAzCells * rand);
            elcell = round(numElCells * rand);            
            detections(2, i) = (params.AzimuthSpan(1) + azcell * params.AzimuthResolution) * params.HasAzimuth;
            detections(3, i) = (params.ElevationSpan(1) + elcell * params.ElevationResolution) * params.HasElevation;
            detections(4, i) = rangecell * params.RangeResolution * params.HasRange;
            detections(5, i) = 2 * (rand-0.5) * params.MaxRangeRate * params.HasRangeRate;            
            detections(6, i) = params.AzimuthResolution * params.HasAzimuthResolution;
            detections(7, i) = params.ElevationResolution * params.HasElevationResolution;
            detections(8, i) = params.RangeResolution * params.HasRangeResolution;
        end
    else
        detections = zeros(8, 0);        
    end
end

function meas = roundMeasurement(measurement, measurementresolution)
%ROUNDMEASUREMENT rounds the measurement to the nearest measurement
%resolution bin.
    meas = round(measurement / measurementresolution) * measurementresolution;
end

function handles = visualizeDetections(targets, detections, params)
%VISUALIZEDETECTIONS plots the detections on a 2D or 3D grid
    hfig = figure;
    set(hfig, 'Position', [100 100 600 400]);
    targetColor = [0.85, 0.325, 0.098];
    detectionColor = [0.494, 0.184, 0.556];
    sensorColor = [0, 0, 1];
    numTargets = size(targets, 2);
    numDetections = size(detections, 2);
    position = params.Position;
    handles = gobjects(2 + numTargets + 3 * numDetections, 1)';
    maxXY = max([max(targets(2, :)) - min(targets(2, :)), max(targets(3, :)) - min(targets(3,:))]);
        
    % Some values are easier to work with in radians:
    deg2rad = pi/180;
    detections(2, :) = detections(2, :) * deg2rad;
    detections(3, :) = detections(3, :) * deg2rad;
    azRes = params.AzimuthResolution * deg2rad;
    elRes = params.ElevationResolution * deg2rad;
 
    %Making sure that we don't wait too much for the plot.
    maxNumDetections = 250; %This corresponds to about 5 seconds     
    cond = numDetections > maxNumDetections;
    coder.internal.warningIf(cond, ...
        'shared_tracking:sensordet:TooManyToPlot', maxNumDetections);
    if cond
        numDetections = maxNumDetections;
    end
    if abs(max(targets(4,:)) - min(targets(4,:)))/maxXY < 1e-5 %mostly 2-D problem
        handles(1) = plot(position(1), position(2), 'd', 'color', sensorColor);
        hold on;
        text(position(1), position(2)+3, 'Sensor', 'Clipping', 'on')
        handles(2) = matlabshared.tracking.internal.fillSector(position(1:2), ...
            params.MaxRange, params.AzimuthSpan * deg2rad,...
            sensorColor, sensorColor, 0.1);        
        for i = 1:numTargets
            handles(i + 2) = plot(targets(2, i), targets(3, i), 's', 'color', targetColor);
            text(targets(2, i), targets(3, i)+3, ['Tgt ',num2str(targets(1, i))],...
                'Clipping', 'on')
        end
        [x, y, ~] = sph2cart(detections(2, :) , detections(3, :), detections(4, :));
        x = x + params.Position(1);
        y = y + params.Position(2);
        for i = 1:numDetections        
            handles(i + 2 + numTargets) = plot(x(i), y(i), '+', 'color', detectionColor);
            handles(i + 2 + numTargets + numDetections) = plot([position(1), x(i)],...
                [position(2), y(i)], ':', 'color', detectionColor);
            % If R=0, the covariance rotation produces covariance matrices
            % that cause a warning. To eliminate that, use R>0.
            R = max(detections(4, i), 100 * sqrt(eps(class(detections(4, i)))));
            U = matlabshared.tracking.internal.sph2cartcovrot(detections(2, i), detections(3, i), R);
            C = U * diag([azRes^2, elRes^2, params.RangeResolution^2]) * U';
            handles(i + 2 + numTargets + 2 * numDetections) = ...
                matlabshared.tracking.internal.plot_gaussian_ellipsoid([x(i); y(i)], C(1:2,1:2), 1);
            set(handles(i + 2 + numTargets + 2 * numDetections), 'color', detectionColor);
        end
        set(gca, 'Units', 'normalized', 'Position', [.53 .16 .42 .83])
        xlabel('x'); ylabel('y')
        legendHandles = [handles(1), handles(3), handles(3 + numTargets)];
        legend(legendHandles, 'Sensor', 'Targets', 'Detections', 'Location', 'Best')
    else
        handles(1) = plot3(position(1), position(2), position(3), 'bd');
        text(position(1), position(2)+3, position(3), 'Sensor', 'Clipping', 'on')
        hold on;
        for i = 1:numTargets
            handles(i + 1) = plot3(targets(2, i), targets(3, i), targets(4, i), 's', 'color', targetColor);
            text(targets(2, i), targets(3, i)+3, targets(4, i),...
                ['Tgt ',num2str(targets(1, i))], 'Clipping', 'on')
        end
        [x, y, z] = sph2cart(detections(2, :), detections(3, :), detections(4, :));
        x = x + params.Position(1);
        y = y + params.Position(2);
        z = z + params.Position(3);
        for i = 1:numDetections        
            handles(i + 1 + numTargets) = plot3(x(i), y(i), z(i), '+', 'color', detectionColor);
            handles(i + 1 + numTargets + numDetections) = plot3([position(1), x(i)],...
                [position(2), y(i)], [position(3), z(i)], ':', 'color', detectionColor);
            R = max(detections(4, i), 100 * sqrt(eps(class(detections(4, i)))));
            U = matlabshared.tracking.internal.sph2cartcovrot(detections(2, i), detections(3, i), R);
            C = U * diag([azRes^2, elRes^2, params.RangeResolution^2]) * U';
            handles(i + 1 + numTargets + 2 * numDetections) = ...
                matlabshared.tracking.internal.plot_gaussian_ellipsoid([x(i); y(i); z(i)], C, 1);
            set(handles(i + 1 + numTargets + 2 * numDetections), 'facealpha', 0, 'EdgeColor', detectionColor);
        end
        xlabel('x'); ylabel('y'); zlabel('z') 
        set(gca, 'Units', 'normalized', 'Position', [.52 .16 .43 .83])
        cameratoolbar('show');
        legendHandles = [handles(1), handles(3), handles(3 + numTargets)];
        legend(legendHandles, 'Sensor', 'Targets', 'Detections', 'Location', 'Best')
    end
    grid on; axis equal; axis tight;
    displaySensorProperties(hfig, params)
end

function displaySensorProperties(h, params)
%DISPLAYSENSORPROPERTIES displays a text list of selected sensor properties
selectedProps = [17, 21, 2, 4, 13, 1, 3, 18, 19, 15, 16, 5:12];
propNames = fields(params);
propNames = propNames(selectedProps);
p = 0;
for i=1:numel(propNames)
    p = p + 1;
    propN{p} = propNames{i};
    % Convert to all the angle properties to degrees
    if selectedProps(i) < 5 
        params.(propNames{i}) = params.(propNames{i});
    end
    
    %Scalars should be displayed as scalars
    if isscalar(params.(propNames{i}))
        %Display numeric values as numbers
        if isnumeric(params.(propNames{i}))
            propValues{p} = num2str(params.(propNames{i}));
        %Display logical values as true/false
        elseif islogical(params.(propNames{i}))
            if params.(propNames{i})
                propValues{p} = 'true';
            else
                propValues{p} = 'false';
            end
        end
    %Vectors should be displayed as vectors
    else
        % PD may be very long. Only display a number if PD is the same for
        % all targets and write 'varies' otherwise.
        if strcmp(propNames{i}(1:2), 'PD')
            if ~any(params.(propNames{i}) - params.(propNames{i})(1))
                propValues{p} = params.(propNames{i})(1);
            else
                propValues{p} = 'varies';
            end
        elseif strcmp(propNames{i}(1:2), 'Po') || strcmp(propNames{i}(1:2), 'Ve')
            propValues{p} = ['[', num2str(params.(propNames{i})'), ']'];
        else
            %All the other vectors are short enough to display as is
            propValues{p} = ['[', num2str(params.(propNames{i})), ']'];
        end
    end
    separator{p} = ':';
end
addTextInfo(h, propN, propValues, separator);
end

function [txt1, txt2, txt3] = addTextInfo(handle, textBlock1, textBlock2, separator)
%ADDTEXTINFO  Adds text to the figure specified by HANDLE
%   The texts are added as three UIcontrol blocks: textBlock1, textBlock2
%   and a separator. The text blocks will be added to the top-left corner
%   of the figure.
    figure(handle);
    l1 = length(textBlock1);
    w1 = 0;
    for i = 1:l1        
        w1 = max(w1, length(textBlock1{i}));
    end
    
    w2 = 0;
    l2 = length(textBlock2);
    for i = 1:l2       
        w2 = max(w2, length(textBlock2{i}));
    end
    verticalShift = 22;
    txt1 = uicontrol('Style', 'text', 'Units', 'characters',...
        'Position', [1 verticalShift-l1 w1+1 l1+2], 'HorizontalAlignment', 'right',...
        'FontSize', 8, ...
        'String', textBlock1);
    txt2 = uicontrol('Style', 'text', 'Units', 'characters',...
        'Position', [w1+3.2 verticalShift-l2 w2 l2+2], 'HorizontalAlignment', 'left',...
        'FontSize', 8, ...
        'String', textBlock2);
    txt3 = uicontrol('Style', 'text', 'Units', 'characters',...
        'Position', [w1+2.1 verticalShift-l1 1.1 l1+2], 'HorizontalAlignment', 'center',...
        'FontSize', 8, ...
        'String', separator);
end

function [tgts, res] = parseInputs(targets, varargin)
%PARSEINPUT parses the input when not in codegen
    % Prepare parser
    parser = inputParser;
    parser.addRequired('targets', @validateTargets);
    parser.addParameter('PD', 1.0, @validatePD);
    parser.addParameter('PFA', 0.0, @validatePFA);
    parser.addParameter('RangeResolution', 1, @validateRangeRes);
    parser.addParameter('RangeRateResolution', 1, @validateRangeRateResolution);
    parser.addParameter('MaxRangeRate', 1000, @validateMaxRangeRate);
    parser.addParameter('AzimuthResolution', 1, @validateAngRes);
    parser.addParameter('ElevationResolution', 1, @validateAngRes);
    parser.addParameter('MaxRange', 0, @validateRange);
    parser.addParameter('AzimuthSpan', [-180 180], @validateAzRange);
    parser.addParameter('ElevationSpan', [-90 90], @validateElRange);
    parser.addParameter('Position', [0;0;0], @validatePosVel); 
    parser.addParameter('Velocity', [0;0;0], @validatePosVel); 
    parser.addParameter('HasTargetID', true, @validateFlag);
    parser.addParameter('HasRange', true, @validateFlag);
    parser.addParameter('HasAzimuth', true, @validateFlag);
    parser.addParameter('HasElevation', true, @validateFlag);
    parser.addParameter('HasRangeRate', true, @validateFlag);
    parser.addParameter('HasRangeResolution', true, @validateFlag);
    parser.addParameter('HasAzimuthResolution', true, @validateFlag);
    parser.addParameter('HasElevationResolution', true, @validateFlag);
        
    % Parse
    if isempty(varargin)
       parser.parse(targets);
    else
       parser.parse(targets, varargin{:});
    end
    res = parser.Results;
    tgts = res.targets;    
    
    % Make additional input processing  
    if isscalar(res.PD)
        res.PD = res.PD * ones(1, size(targets,2));
    end
    res = inputProcessing(res, tgts);

end

function [targets, res] = parseInputsCodegen(targets, varargin)
%PARSEINPUTCODEGEN parses the input when in codegen. 
  validateTargets(targets);
  firstNVIndex = matlabshared.tracking.internal.findFirstNVPair(varargin{:});

  parms = struct( ...
    'PD',                   uint32(0), ...
    'PFA',                  uint32(0), ...
    'RangeResolution',      uint32(0), ...
    'RangeRateResolution',  uint32(0), ...
    'MaxRangeRate',         uint32(0), ...
    'AzimuthResolution',    uint32(0), ...
    'ElevationResolution',  uint32(0), ...
    'MaxRange',             uint32(0), ...
    'AzimuthSpan',          uint32(0), ...
    'ElevationSpan',        uint32(0), ...
    'Position',             uint32(0), ...
    'Velocity',             uint32(0), ...
    'HasTargetID',          uint32(0), ...
    'HasRange',             uint32(0), ...
    'HasAzimuth',           uint32(0), ...
    'HasElevation',         uint32(0), ...
    'HasRangeRate',         uint32(0), ...
    'HasRangeResolution',   uint32(0), ...
    'HasAzimuthResolution', uint32(0), ...
    'HasElevationResolution', uint32(0) ...
    );

  popt = struct( ...
    'CaseSensitivity', false, ...
    'StructExpand',    true, ...
    'PartialMatching', false);

  optarg           = eml_parse_parameter_inputs(parms, popt, ...
    varargin{firstNVIndex:end});
  PD  =                         eml_get_parameter_value...
      (optarg.PD, 1, varargin{firstNVIndex:end});
  validatePD(PD);
  PFA  =                        eml_get_parameter_value...
      (optarg.PFA, 0, varargin{firstNVIndex:end});
  validatePFA(PFA);
  RangeResolution  =            eml_get_parameter_value...
      (optarg.RangeResolution, 1, varargin{firstNVIndex:end});
  validateRangeRes(RangeResolution);
  RangeRateResolution  =        eml_get_parameter_value...
      (optarg.RangeRateResolution, 1, varargin{firstNVIndex:end});
  validateRangeRateResolution(RangeRateResolution);
  MaxRangeRate  =               eml_get_parameter_value...
      (optarg.MaxRangeRate, 1000, varargin{firstNVIndex:end});
  validateMaxRangeRate(MaxRangeRate);
  AzimuthResolution  =          eml_get_parameter_value...
      (optarg.AzimuthResolution, 1, varargin{firstNVIndex:end});
  validateAngRes(AzimuthResolution);
  ElevationResolution  =          eml_get_parameter_value...
      (optarg.ElevationResolution, 1, varargin{firstNVIndex:end});
  validateAngRes(ElevationResolution);
  MaxRange  =                      eml_get_parameter_value...
      (optarg.MaxRange, 0, varargin{firstNVIndex:end});
  validateRange(MaxRange);
  AzimuthSpan  =               eml_get_parameter_value...
      (optarg.AzimuthSpan, [-180 180], varargin{firstNVIndex:end});
  validateAzRange(AzimuthSpan);
  ElevationSpan  =             eml_get_parameter_value...
      (optarg.ElevationSpan, [-90 90], varargin{firstNVIndex:end});
  validateElRange(ElevationSpan);
  Position  =                   eml_get_parameter_value...
      (optarg.Position, [0; 0; 0], varargin{firstNVIndex:end});
  validatePosVel(Position);
  Velocity  =                   eml_get_parameter_value...
      (optarg.Velocity, [0; 0; 0], varargin{firstNVIndex:end});
  validatePosVel(Velocity);
  HasTargetID  =                eml_get_parameter_value...
      (optarg.HasTargetID, 1, varargin{firstNVIndex:end});
  validateFlag(HasTargetID);
  HasRange  =                   eml_get_parameter_value...
      (optarg.HasRange, 1, varargin{firstNVIndex:end});
  validateFlag(HasRange);
  HasAzimuth  =                 eml_get_parameter_value...
      (optarg.HasAzimuth, 1, varargin{firstNVIndex:end});
  validateFlag(HasAzimuth);
  HasElevation  =               eml_get_parameter_value...
      (optarg.HasElevation, 1, varargin{firstNVIndex:end});
  validateFlag(HasElevation);
  HasRangeRate  =               eml_get_parameter_value...
      (optarg.HasRangeRate, 1, varargin{firstNVIndex:end});
  validateFlag(HasRangeRate);
  HasRangeResolution  =         eml_get_parameter_value...
      (optarg.HasRangeResolution, 1, varargin{firstNVIndex:end});
  validateFlag(HasRangeResolution);
  HasAzimuthResolution  =    eml_get_parameter_value...
      (optarg.HasAzimuthResolution, 1, varargin{firstNVIndex:end});
  validateFlag(HasAzimuthResolution);
  HasElevationResolution  =    eml_get_parameter_value...
      (optarg.HasElevationResolution, 1, varargin{firstNVIndex:end});
  validateFlag(HasElevationResolution);

  if isscalar(PD)
      PDcol = PD * ones(1, size(targets,2));
  else
      PDcol = PD;
  end
  
  res = struct( ...
    'PD',                       PDcol, ...
    'PFA',                      PFA, ...
    'RangeResolution',          RangeResolution, ...
    'RangeRateResolution',      RangeRateResolution, ...
    'MaxRangeRate',             MaxRangeRate, ...
    'AzimuthResolution',        AzimuthResolution, ...
    'ElevationResolution',      ElevationResolution, ...
    'MaxRange',                 MaxRange, ...
    'AzimuthSpan',              AzimuthSpan, ...
    'ElevationSpan',            ElevationSpan, ...
    'Position',                 Position, ...
    'Velocity',                 Velocity, ...
    'HasTargetID',              HasTargetID, ...
    'HasRange',                 HasRange, ...
    'HasAzimuth',               HasAzimuth, ...
    'HasElevation',             HasElevation, ...
    'HasRangeRate',             HasRangeRate, ...
    'HasRangeResolution',       HasRangeResolution, ...
    'HasAzimuthResolution',     HasAzimuthResolution, ...
    'HasElevationResolution',   HasElevationResolution, ...
    'FDrange',                  MaxRange ...
    );

    % Make additional input processing    
    res = inputProcessing(res, targets);

end

function res = inputProcessing(res, tgts)
%INPUTPROCESSING prepares additional sensor parameters after parsing.
    % Expand PD to all targets
    numTgts = size(tgts, 2);
    coder.internal.errorIf(numel(res.PD) ~= numTgts, 'shared_tracking:sensordet:invalidPD', 'PD');    
    
        % Input processing:
    res.AzimuthSpan = res.AzimuthSpan(:)'; %row, radians
    res.ElevationSpan = res.ElevationSpan(:)'; %row, radians
    res.AzimuthResolution = res.AzimuthResolution; %radians    
    res.ElevationResolution = res.ElevationResolution; %radians    
    res.Position = res.Position(:);
    res.Velocity = res.Velocity(:);
    
    % Calculate  the range to the farthest target    
    if res.PFA > 0 && res.MaxRange
        res.FDrange = res.MaxRange;
    elseif res.PFA > 0 || res.MaxRange == 0
        distances = bsxfun(@minus, tgts(2:4, :), res.Position);        
        r = zeros(numTgts, 1);
        for i = 1: numTgts
            r(i) = norm(distances(:,i));
        end
        res.FDrange = max(r) + 1; %slightly longer than all targets
        if res.MaxRange == 0
            res.MaxRange = res.FDrange;
        end
    end
end

function detections = zero2nan(detections, params)
%ZERO2NAN turns all the detection parameters that should not be provided
%with the detection to NaN
    if ~params.HasTargetID
        detections(1, :) = NaN;
    end
    if ~params.HasAzimuth
        detections(2, :) = NaN;
    end
    if ~params.HasElevation
        detections(3, :) = NaN;
    end
    if ~params.HasRange
        detections(4, :) = NaN;
    end
    if ~params.HasRangeRate
        detections(5, :) = NaN;
    end
    if ~params.HasAzimuthResolution
        detections(6, :) = NaN;
    end
    if ~params.HasElevationResolution
        detections(7, :) = NaN;
    end
    if ~params.HasRangeResolution
        detections(8, :) = NaN;
    end
end

function validateTargets(targets)
%VALIDATETARGETS validates that targets is a valid input.
    validateattributes(targets, {'single', 'double'}, {'real', 'finite'}, ...
        'sensordet', 'targets');
    coder.internal.errorIf(size(targets, 1) < 7, ...
        'shared_tracking:sensordet:insufficientTargetInformation');    
end

function validatePD(PD)
%VALIDATEPD validates that PD is a valid input.
    validateattributes(PD, {'single', 'double'}, {'real', 'nonnegative', ...
        'finite', 'vector', '<=', 1}, 'sensordet', 'PD');
end

function validatePFA(PFA)
%VALIDATEFD validates that FD is a valid input.
    validateattributes(PFA, {'single', 'double'}, {'real', 'nonnegative', ...
        'finite', 'scalar', '<=', 1}, 'sensordet', 'PFA');
end

function validateRangeRes(RR)
%validateRangeRes validates that RangeResolution(RR) is a valid input.
    validateattributes(RR, {'numeric'}, {'real', 'positive', ...
        'scalar', 'finite'}, 'sensordet', 'RangeResolution');
end

function validateRange(MaxRange)
%validateRangeRes validates that MaxRange is a valid input.
    validateattributes(MaxRange, {'numeric'}, {'real', 'nonnegative', ...
        'scalar', 'finite'}, 'sensordet', 'MaxRange');
end

function validateAngRes(AngularRes)
%validateRangeRes validates that AzimuthResolution and ElevationResolution
%are valid inputs.
    validateattributes(AngularRes, {'numeric'}, {'real', 'positive', ...
        'scalar', 'finite', '<=', 360}, 'sensordet', ...
        'AzimuthResolution or ElevationResolution');
end

function validateAzRange(AzRange)
%validateAzRange validates that AzimuthSpan is a valid input.
    validateattributes(AzRange, {'numeric'}, {'real', 'numel', 2, ...
        'finite', '>=', -180, '<=', 180}, 'sensordet', 'AzimuthSpan');
end

function validateRangeRateResolution(RRRes)
%validateRangeRateResolution validates that RangeRateResolution is a valid input.
    validateattributes(RRRes, {'numeric'}, {'real', 'positive', ...
        'scalar', 'finite'}, 'sensordet', 'RangeRateResolution');
end

function validateMaxRangeRate(MaxRR)
%validateAzRange validates that MaxRangeRate is a valid input.
    validateattributes(MaxRR, {'numeric'}, {'real', 'positive', ...
        'scalar', 'finite'}, 'sensordet', 'MaxRangeRate');
end

function validateElRange(ElRange)
%validateElRange validates that ElevationSpan is a valid input.
    validateattributes(ElRange, {'numeric'}, {'real', 'vector', ...
        'finite', 'numel', 2, '<=', 90, '>=', -90}, 'sensordet', 'ElevationSpan');
end

function validatePosVel(vec)
%validateRangeRes validates that Position or Velocity are valid inputs.
    validateattributes(vec, {'numeric'}, {'real', 'vector', 'numel', 3, ...
        'finite'}, 'sensordet', 'Position or Velocity');
end

function validateFlag(flag)
%validateFlag validates that all the flags are valid inputs.
    validateattributes(flag, {'numeric', 'logical'}, {'real', 'scalar', ...
        'binary'}, 'sensordet', 'Flag');
end