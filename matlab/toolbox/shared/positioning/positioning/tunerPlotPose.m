function stop = tunerPlotPose(fparams, tunerValues)
%TUNERPLOTPOSE Plot filter pose estimates during tuning
%   The TUNERPLOTPOSE function plots the current pose estimate (orientation
%   and possibly position, depending on the filter) along with the ground
%   truth values. The FPARAMS input is a struct which contains the best
%   estimates of the filter parameters during the current iteration of
%   tuning using the TUNE function. The FPARAMS struct contains one field
%   for every public property of the filter and additional fields for any
%   measurement noises needed. The exact field names vary depending on
%   which filter is being tuned. The TUNERVALUES struct has
%   fields
%       Iteration - the iteration count of the tuner 
%       SensorData - the sensor data input to the TUNE function 
%       GroundTruth - the ground truth input to the TUNE function 
%       Configuration - the TUNERCONFIG object used for tuning 
%       Cost - the tuning cost at the end of the current iteration
%
%   This function always returns FALSE indicating that tuning
%   should continue on to the next iteration.
%
%   Example: 
%
%       figure; % new window for plotting
%       tc = tunerconfig('imufilter', 'OutputFcn', @tunerPlotPose)
%       ld = load('imufilterTuneData.mat');
%       tune(imufilter, ld.sensorData, ld.groundTruth, tc);
%
%   See also TUNERCONFIG

%   Copyright 2020-2023 The MathWorks, Inc.


stop = false;
cfg = tunerValues.Configuration;
cls = string(cfg.Filter);
assert(cls ~= "insEKF", message('shared_positioning:tuner:NoinsEKFPlotPose'));
% The SensorData and GroundTruth values in tunerValues are the original input tables.
% Modify them as in the normal tuner flow (rotation matrices to quaternions, etc) using
% the processSensorData and processGroundTruth static methods.
filtfcns = "fusion.internal.tuner." + cls;
sensorData = feval(filtfcns + ".processSensorData", tunerValues.SensorData);
sensorData = sensorData(:, sort(sensorData.Properties.VariableNames));
groundTruth = feval(filtfcns + ".processGroundTruth", tunerValues.GroundTruth);

% Recompute the pose estimates
fcn = cls + ".tunerfuse";
flt = feval(cfg.Filter);
[~, states] = feval(fcn, fparams, sensorData, groundTruth, cfg);
qTrue = groundTruth.Orientation;
eulTrue = eulerd(qTrue, 'ZYX', 'frame');

iter = tunerValues.Iteration;

% Do per-filter computation for time (abscissa), and error metrics.
% Orientation only filters do not have position error metrics.
% ahrs10filter only has a z-axis position error metric.
% The variables doXYPostion and doZPostion are created. All insfilters and
% ahrs10filter have doZPosition=true. Only insfilters have doXYPostion
% =true. ahrsfilter and imufilter have both = false.
switch cfg.Filter
    case {'ahrsfilter', 'imufilter'}
        doXYPosition = false;
        doZPosition = false;
        time = ((0:size(states,1)-1)./fparams.SampleRate).';
        qEst = states;
    case {'ahrs10filter'}
        doXYPosition = false;
        doZPosition = true;
        time = ((0:size(states,1)-1)./fparams.IMUSampleRate).';
        idx = flt.stateinfo(); 
        qEst = quaternion(states(:,idx.Orientation));
        pZEst = states(:,idx.Altitude);
        pZTrue = groundTruth.Altitude;
        positionErrorTuned = sqrt(sum((pZEst - pZTrue).^2, 2));
        rmsPositionErrorTuned = sqrt(mean( positionErrorTuned.^2));

    otherwise
        if strcmpi(cfg.Filter, 'insfilterAsync')
            time = groundTruth.Properties.RowTimes;
        else
            time = ((0:size(states,1)-1)./fparams.IMUSampleRate).';
        end      
        doXYPosition = true;
        doZPosition = true;
        idx = flt.stateinfo(); 
        qEst = quaternion(states(:,idx.Orientation));
        pEst = states(:,idx.Position);
        pXYEst = pEst(:,1:2);
        pZEst = pEst(:,3);
        pTrue = groundTruth.Position;
        pXYTrue = pTrue(:,1:2);
        pZTrue = pTrue(:,3);
        positionErrorTuned = sqrt(sum((pEst - pTrue).^2, 2));
        rmsPositionErrorTuned = sqrt(mean( positionErrorTuned.^2));
end

% Create an error metric string depending on what variables are in the
% pose estimate.
eulEst = eulerd(qEst, 'ZYX', 'frame');
orientationErrorTuned = rad2deg(dist(qEst, qTrue));
rmsOrientationErrorTuned = sqrt(mean(orientationErrorTuned.^2));
metricstr = msg('Iteration') + ":  " + iter + newline + ...
    msg('RMSOrient') + "  " + rmsOrientationErrorTuned;
if doZPosition
  metricstr = metricstr + newline + msg('RMSPos') + "  " + rmsPositionErrorTuned;
end


% Actual plotting. In the first iteration, setup the figure window. The
% layout varies depending on the filter. Orientation only filters just have
% Roll,Pitch,Yaw, legend and info. ahrs10filter adds Z-axis position. The
% other insfilters add on X- and Y-axis positions
if iter==1
    makeNewWindow;
    % Create the layout and do initial plotting. Create the legend after
    % the first plots since we have the handles to the lines at that point.
    [pXYax, pZax, oax, legax] = layout(cfg);
    if doXYPosition
        plotXYPos(time, pXYEst, pXYTrue, pXYax);
    end
    if doZPosition
        plotZPos(time, pZEst, pZTrue, pZax);
    end
    [trueline, qestln] = plotOrient(time, eulEst, eulTrue, oax);
    makeLegend(legax, trueline, qestln);
    updateMetric(metricstr);
    decoratePlots(cfg, pXYax, pZax, oax)
    
else
    % Iterations 2...N. Simply update the existing estimate plots
    if doXYPosition
        updateXY(pXYEst);
    end
    if doZPosition
        updateZ(pZEst);
    end
    updateOrient(eulEst);
    updateMetric(metricstr);
end

% Don't overrun the plotting. This is called by tune() in a loop.
drawnow limitrate
end

function [pXYax, pZax, oax, legax] = layout(cfg)
% Layout the figure window. 
%

pXYax = [];
pZax = [];
switch cfg.Filter
    case {'ahrsfilter', 'imufilter'}
        % For orientation filters:
        %   ----------------
        %   | roll  | info  |
        %   |---------------|
        %   | pitch | legend|
        %   |---------------|
        %   | yaw   | blank |
        %   ----------------

        o1 = subplot(3,2,1);
        o2 = subplot(3,2,3);
        o3 = subplot(3,2,5);
        prettify(o1,o2,o3);
        oax = [o1 o2 o3];
        infoax = subplot(3,2,2);
        legax = subplot(3,2,4);
    case {'ahrs10filter'}
        % For ahrs10filter filters:
        %    | ------- | ------  |
        %    | zpos    | roll    |
        %    | ------- | ------- |
        %    | info    | pitch   |
        %    | ------- | ------- |
        %    | legend  | yaw     |
        %    | ------- | ------  |

        pZax = subplot(3,2,1);
        infoax = subplot(3,2,3);
        legax = subplot(3,2,5);
        o1 = subplot(3,2,2);
        o2 = subplot(3,2,4);
        o3 = subplot(3,2,6);
        oax = [o1 o2 o3];
    otherwise
        % For insfilters filters:
        %    | ------- | ------  |
        %    | xpos    | roll    |
        %    | ------- | ------- |
        %    | ypos    | pitch   |
        %    | ------- | ------- |
        %    | zpos    | yaw     |
        %    | ------- | ------  |
        %    | info    | legend  |
        %    | ------- | ------  |

        p1 = subplot(4,2,1);
        p2 = subplot(4,2,3);
        p3 = subplot(4,2,5);
        pXYax = [p1 p2];
        pZax = p3;
        o1 = subplot(4,2,2);
        o2 = subplot(4,2,4);
        o3 = subplot(4,2,6);
        oax = [o1 o2 o3];
        infoax = subplot(4,2,7);
        legax = subplot(4,2,8);
end
% Information panel
axes(infoax);
mstr = text(0, 0.5, '');
set(mstr, 'Tag', 'mstr');
axis(infoax, 'off');
end

function makeLegend(legax, trueline, qestln)
%MAKELEGEND - create the legend in axes legax
axes(legax);
pos = get(legax, 'Position');
lgd = legend(legax, [trueline,qestln], msg('GroundTruthLeg'), msg('EstLeg'));
% Match the figure window color:
figColor = lgd.Parent.Color;
set(lgd, 'Color', figColor, 'EdgeColor', figColor);
set(lgd,  'Location', 'west');
set(lgd, 'Position', pos);
axis(legax, 'off');
end

function decoratePlots(cfg, pXYax, pZax, oax)
%DECORATEPLOTS Add titles and xlabel and ylabel

xlabel(oax(end), msg('TimeLabel'));
ylabel(oax(1),  msg('ZEulLabel'));
ylabel(oax(2), msg('YEulLabel'));
ylabel(oax(3), msg('XEulLabel'));
title(oax(1), msg('OrientationTitle'));

switch cfg.Filter
    case {'ahrsfilter', 'imufilter'}
        % Nothing. No position plots
    case {'ahrs10filter'}
        xlabel(pZax,  msg('TimeLabel'));
        ylabel(pZax,  msg('AltLabel'));
        title(pZax, msg('PositionTitle'));
    otherwise
        xlabel(pZax, msg('TimeLabel'));
        ylabel(pXYax(1), msg('XPosLabel'));
        ylabel(pXYax(2), msg('YPosLabel'));
        ylabel(pZax, msg('ZPosLabel'));
        title(pXYax(1), msg('PositionTitle'));
end


end

function plotXYPos(x, pEst, pTrue, pidx)
% PLOTXYPOS - initial plot of X and Y position estimates
%   Plot the X and Y position estimates and ground truth into
%   axes pidx(1:2). Tag the lines for finding them later.

axes(pidx(1));
lns = plot(x, pTrue(:,1), x, pEst(:,1));
estln = lns(2);
set(estln, 'Tag', 'posEstLine_x');
setYlims(pidx(1), pTrue(:,1), pEst(:,1));

axes(pidx(2));
lns = plot(x,pTrue(:,2),x,pEst(:,2));
estln = lns(2);
set(estln, 'Tag', 'posEstLine_y');
setYlims(pidx(2), pTrue(:,2), pEst(:,2));
prettify(pidx(1), pidx(2));
end

function plotZPos(x, pEst, pTrue, pidx)
% PLOTZPOS - initial plot of Z position estimate
%   Plot the Z position estimate and ground truth into
%   axes pidx. Tag the line for finding later. 
axes(pidx);
lns = plot(x, pTrue, x, pEst);
estln = lns(2);
set(estln, 'Tag', 'posEstLine_z');
setYlims(pidx(1), pTrue, pEst);
prettify(pidx);
end

function [tline, qestln] = plotOrient(x, eulEst, eulTrue, pidx)
% PLOTORIENT - initial plot of orientation estimates
%   Plot the roll, pitch, and yaw estimates and ground truth into
%   axes pidx(1:3). Tag the lines for finding them later. 

axes(pidx(1));
lns = plot(x,eulTrue(:,1), x, eulEst(:,1));
tline = lns(1);
qestln = lns(2);
set(qestln,'Tag', 'qEstLine_x');
ylim(pidx(1), [-200 200]);
ylim(pidx(1), 'manual');

axes(pidx(2));
lns = plot(x,eulTrue(:,2), x, eulEst(:,2));
qestln = lns(2);
set(qestln,'Tag', 'qEstLine_y');
ylim(pidx(2), [-100 100]);
ylim(pidx(2), 'manual');

axes(pidx(3));
lns = plot(x,eulTrue(:,3), x, eulEst(:,3));
qestln = lns(2);
set(qestln,'Tag', 'qEstLine_z');
ylim(pidx(3), [-200 200]);
ylim(pidx(3), 'manual');

prettify(pidx(1), pidx(2), pidx(3));
end

function prettify(varargin)
% PRETTIFY - Make the plots look nice 
%   Add grid lines. 
for ii=1:nargin
    varargin{ii}.XGrid = "on";
    varargin{ii}.YGrid = "on";
    varargin{ii}.YMinorGrid = "on";
end

end

function updateXY(posEst)
% UPDATEXY Update the X- and Y- position estimates. 
%   Use tags to find the right line.
f = gcf;
px = findobj(f, 'Tag', 'posEstLine_x');
py = findobj(f, 'Tag', 'posEstLine_y');
set(px, 'YData', posEst(:,1));
set(py, 'YData', posEst(:,2));
end

function updateZ(zEst)
% UPDATEZ Update the z- position estimate
%   Use tags to find the right line.
f = gcf;
pz = findobj(f, 'Tag', 'posEstLine_z');
set(pz, 'YData', zEst);
end

function updateOrient(eulEst)
% UPDATEORIENT Update the roll, pitch, and yaw estimates
%   Use tags to find the right line.
f = gcf;
qx = findobj(f, 'Tag', 'qEstLine_x');
qy = findobj(f, 'Tag', 'qEstLine_y');
qz = findobj(f, 'Tag', 'qEstLine_z');
set(qx, 'YData', eulEst(:,1));
set(qy, 'YData', eulEst(:,2));
set(qz, 'YData', eulEst(:,3));
end

function updateMetric(metricstr)
% UPDATEMETRIC Update the metric string
%   Use tags to find the text.
mstr = findobj(0, 'Tag', 'mstr');
set(mstr, 'String', metricstr);
end

function setYlims(ax, xtrue, xest)
% Set the Y limits to the total range +/- 5% of the total range on each
% end.
factor = 0.05;
maxlim = max( max(xtrue), max(xest));
minlim = min( min(xtrue), min(xest));
extraRange = factor.*abs(maxlim - minlim);
ylim(ax, [minlim - extraRange, maxlim + extraRange]);
ylim(ax, 'manual');
end

function f = makeNewWindow
np = newplot;
f = np.Parent; % figure window
clf(f);
f.NextPlot = 'replacechildren';
f.Name = 'Tuning Results';

% Make the window bigger if it is not docked
if strcmpi(f.WindowStyle, 'normal')
    f.Position([3 4]) = [690 520];
end
end

function m = msg(id)
m = string(message(['shared_positioning:tuner:' id]));
end
