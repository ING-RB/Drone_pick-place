classdef cameraIMUParameters
%

%   Copyright 2023-2024 The MathWorks, Inc.

    properties (SetAccess={?nav.algs.internal.InternalAccess})
        Transform

        ReprojectionErrors

        TranslationErrors

        RotationErrors

        CameraPoses

        ImagesUsed

        GravityRotation

        AccelerometerBias

        GyroscopeBias

        Velocity

        SolutionInfo
    end

    properties (Access={?nav.algs.internal.InternalAccess})
        %CameraIntrinsics - Camera intrinsic parameters
        CameraIntrinsics

        %IMUParameters - IMU noise parameters
        IMUParameters

        %ImageData -Input image time stamps
        ImageTimeStamps
    end

    methods (Access={?nav.algs.internal.InternalAccess})
        function obj = cameraIMUParameters(tform, errors, estimates, info, ...
                                      imageTimeStamps, intrinsics, imuParams) 

            obj.Transform = tform;
            obj.ImageTimeStamps = imageTimeStamps;
            obj.CameraIntrinsics = intrinsics;
            obj.AccelerometerBias = estimates.IMUBias(:,4:6);
            obj.GyroscopeBias = estimates.IMUBias(:,1:3);
            obj.Velocity = estimates.IMUVelocity;
            obj.GravityRotation = estimates.GravityRotation;
            obj.CameraPoses = se3(estimates.CameraPoses.AbsolutePose,"xyzquat");
            obj.ImagesUsed = estimates.CameraPoses.ImageIndex;
            obj.TranslationErrors = errors.TranslationError;
            obj.RotationErrors = errors.RotationError;
            obj.ReprojectionErrors = errors.ReprojectionError;
            obj.IMUParameters = imuParams;
            obj.SolutionInfo = info;
        end
    end

    methods (Hidden, Static)
        function obj = constructObject(varargin)
            obj = cameraIMUParameters(varargin{:});
        end
    end

    methods
        function ax = showReprojectionErrors(obj, options)
            %
            
            % visualize re-projection errors of pattern points

            % input name=value arguments
            arguments
                obj
                options.Threshold double {mustBeReal, mustBeNonNan, mustBeFinite, mustBePositive, mustBeScalarOrEmpty} = []
                options.Parent (1,1) {validateAxesHandleVector} = axes(figure("Tag","CameraIMUCalibration_ReprojectionErrors"))
            end
            % threshold line value
            th = options.Threshold;
            ax = options.Parent;

            % compute mean error per image
            errors = computeMeanReprojectionErrorPerImage(obj.ReprojectionErrors);
            plotBarGraphWithMeanAndThreshold(ax, errors, th, 'ReprojectionBarGraphLabelX', ...
                'ReprojectionBarGraphLabelY', 'ReprojectionBarGraphTitle', ...
                'ReprojectionBarGraphLegendMean', 'ReprojectionBarGraphLegendThreshold');
        end

        function ax = showIMUPredictionErrors(obj, options)
            %

            % visualize IMU prediction errors.

            % validate input options
            arguments
                obj
                options.Mode (1,1) string {mustBeMember(options.Mode, {'absolute', 'percentage'})} = 'absolute' 
                options.Threshold  {mustBeReal, mustBeNonNan, mustBeFinite, mustBePositive} = []
                options.Parent (1,6) {validateAxesHandleVector} = createTwoTabsWithSixAxes('TranslationErrors','RotationErrors','CameraIMUCalibration_PredictionErrors')
            end

            % parse input options
            th = validateIMUPredictionThreshold(options.Threshold,true);
            mode = options.Mode;
            ax = options.Parent;

            translationErrors = obj.TranslationErrors;
            rotationErrors = obj.RotationErrors;

            if strcmp(mode,'absolute')
                % plot absolute translation error along x axis
                plotBarGraphWithMeanAndThreshold(ax(1), translationErrors(:,1), ...
                    th(1:min(1,length(th))), 'IMUPredictionBarGraphLabelX', ...
                'IMUPredictionBarGraphLabelTY', 'IMUPredictionBarGraphTitleTX', ...
                'IMUPredictionBarGraphLegendMeanM', 'IMUPredictionBarGraphLegendThresholdM');
                 % plot absolute translation error along y axis
                plotBarGraphWithMeanAndThreshold(ax(2), translationErrors(:,2), ...
                    th(2:min(2,length(th))), 'IMUPredictionBarGraphLabelX', ...
                'IMUPredictionBarGraphLabelTY', 'IMUPredictionBarGraphTitleTY', ...
                'IMUPredictionBarGraphLegendMeanM', 'IMUPredictionBarGraphLegendThresholdM');
                 % plot absolute translation error along z axis
                plotBarGraphWithMeanAndThreshold(ax(3), translationErrors(:,3), ...
                    th(3:min(3,length(th))), 'IMUPredictionBarGraphLabelX', ...
                'IMUPredictionBarGraphLabelTY', 'IMUPredictionBarGraphTitleTZ', ...
                'IMUPredictionBarGraphLegendMeanM', 'IMUPredictionBarGraphLegendThresholdM');
                 % plot absolute rotation error along x axis
                plotBarGraphWithMeanAndThreshold(ax(4), rotationErrors(:,1), ...
                    th(4:min(4,length(th))), 'IMUPredictionBarGraphLabelX', ...
                'IMUPredictionBarGraphLabelRY', 'IMUPredictionBarGraphTitleRX', ...
                'IMUPredictionBarGraphLegendMeanRad', 'IMUPredictionBarGraphLegendThresholdRad');
                % plot absolute rotation error along y axis
                plotBarGraphWithMeanAndThreshold(ax(5), rotationErrors(:,2), ...
                    th(5:min(5,length(th))), 'IMUPredictionBarGraphLabelX', ...
                'IMUPredictionBarGraphLabelRY', 'IMUPredictionBarGraphTitleRY', ...
                'IMUPredictionBarGraphLegendMeanRad', 'IMUPredictionBarGraphLegendThresholdRad');
                % plot absolute rotation error along z axis
                plotBarGraphWithMeanAndThreshold(ax(6), rotationErrors(:,3), ...
                    th(6:min(6,length(th))), 'IMUPredictionBarGraphLabelX', ...
                'IMUPredictionBarGraphLabelRY', 'IMUPredictionBarGraphTitleRZ', ...
                'IMUPredictionBarGraphLegendMeanRad', 'IMUPredictionBarGraphLegendThresholdRad');
            else
                camPoses = obj.CameraPoses;
                relPoses = camPoses(2:end).*inv(camPoses(1:(end-1)));
                translationalMotion = abs(trvec(obj.CameraPoses(2:end))-trvec(obj.CameraPoses(1:(end-1))));
                rotationalMotion = abs(eul(relPoses,"ZYX"));
                rotationalMotion = rotationalMotion(:,[3,2,1]);
                errorPercentages = ([translationErrors,rotationErrors]./[translationalMotion,rotationalMotion])*100;
                % plot translation error percentage along x axis
                plotBarGraphWithMeanAndThreshold(ax(1), errorPercentages(:,1), ...
                    th(1:min(1,length(th))), 'IMUPredictionBarGraphLabelX', ...
                'IMUPredictionBarGraphLabelPY', 'IMUPredictionBarGraphTitleTX', ...
                'IMUPredictionBarGraphLegendMeanP', 'IMUPredictionBarGraphLegendThresholdP');
                 % plot translation error percentage along y axis
                plotBarGraphWithMeanAndThreshold(ax(2), errorPercentages(:,2), ...
                    th(2:min(2,length(th))), 'IMUPredictionBarGraphLabelX', ...
                'IMUPredictionBarGraphLabelPY', 'IMUPredictionBarGraphTitleTY', ...
                'IMUPredictionBarGraphLegendMeanP', 'IMUPredictionBarGraphLegendThresholdP');
                 % plot translation error percentage along z axis
                plotBarGraphWithMeanAndThreshold(ax(3), errorPercentages(:,3), ...
                    th(3:min(3,length(th))), 'IMUPredictionBarGraphLabelX', ...
                'IMUPredictionBarGraphLabelPY', 'IMUPredictionBarGraphTitleTZ', ...
                'IMUPredictionBarGraphLegendMeanP', 'IMUPredictionBarGraphLegendThresholdP');
                 % plot rotation error percentage along x axis
                plotBarGraphWithMeanAndThreshold(ax(4), errorPercentages(:,4), ...
                    th(4:min(4,length(th))), 'IMUPredictionBarGraphLabelX', ...
                'IMUPredictionBarGraphLabelPY', 'IMUPredictionBarGraphTitleRX', ...
                'IMUPredictionBarGraphLegendMeanP', 'IMUPredictionBarGraphLegendThresholdP');
                % plot rotation error percentage along y axis
                plotBarGraphWithMeanAndThreshold(ax(5), errorPercentages(:,5), ...
                    th(5:min(5,length(th))), 'IMUPredictionBarGraphLabelX', ...
                'IMUPredictionBarGraphLabelPY', 'IMUPredictionBarGraphTitleRY', ...
                'IMUPredictionBarGraphLegendMeanP', 'IMUPredictionBarGraphLegendThresholdP');
                % plot absolute rotation error along z axis
                plotBarGraphWithMeanAndThreshold(ax(6), errorPercentages(:,6), ...
                    th(6:min(6,length(th))), 'IMUPredictionBarGraphLabelX', ...
                'IMUPredictionBarGraphLabelPY', 'IMUPredictionBarGraphTitleRZ', ...
                'IMUPredictionBarGraphLegendMeanP', 'IMUPredictionBarGraphLegendThresholdP');
            end
        end
        
        function ax = showIMUBiasEstimates(obj,options)
            %
            
            % visualize accelerometer and gyroscope bias estimates

            arguments
                obj
                options.Parent (1,6) {validateAxesHandleVector} = createTwoTabsWithSixAxes('AccelerometerBias', 'GyroscopeBias', 'CameraIMUCalibration_Bias')
            end
            ax = options.Parent;

            time = obj.ImageTimeStamps(obj.ImagesUsed);
            accelBias = obj.AccelerometerBias;
            gyroBias = obj.GyroscopeBias;
            imuParams = obj.IMUParameters;
            t = convertTo(time,"posixtime");
            t = t - t(1);
            accelBiasStandardDeviation = sqrt(diag(imuParams.AccelerometerBiasNoise))';
            gyroBiasStandardDeviation = sqrt(diag(imuParams.GyroscopeBiasNoise))';
            aB1 = accelBias(1,1:3) + 3*(accelBiasStandardDeviation).*sqrt(t);
            aB2 = accelBias(1,1:3) - 3*(accelBiasStandardDeviation).*sqrt(t);
            gB1 = gyroBias(1,1:3) + 3*(gyroBiasStandardDeviation).*sqrt(t);
            gB2 = gyroBias(1,1:3) - 3*(gyroBiasStandardDeviation).*sqrt(t);

            % plot accelerometer bias along X
            plotValueAlongWithBounds(ax(1),t,accelBias(:,1),[aB1(:,1),aB2(:,1)], ...
                'IMUBiasLabelX','AccelerometerBiasLabelY','IMUBiasTitleTX', ...
                'IMUBiasLegend','IMUBiasBoundLegend');
            % plot accelerometer bias along Y
            plotValueAlongWithBounds(ax(2),t,accelBias(:,2),[aB1(:,2),aB2(:,2)], ...
                'IMUBiasLabelX','AccelerometerBiasLabelY','IMUBiasTitleTY', ...
                'IMUBiasLegend','IMUBiasBoundLegend');
            % plot accelerometer bias along Z
            plotValueAlongWithBounds(ax(3),t,accelBias(:,3),[aB1(:,3),aB2(:,3)], ...
                'IMUBiasLabelX','AccelerometerBiasLabelY','IMUBiasTitleTZ', ...
                'IMUBiasLegend','IMUBiasBoundLegend');
            % plot gyroscope bias along X
            plotValueAlongWithBounds(ax(4),t,gyroBias(:,1),[gB1(:,1),gB2(:,1)], ...
                'IMUBiasLabelX','GyroscopeBiasLabelY','IMUBiasTitleRX', ...
                'IMUBiasLegend','IMUBiasBoundLegend');
            % plot gyroscope bias along Y
            plotValueAlongWithBounds(ax(5),t,gyroBias(:,2),[gB1(:,2),gB2(:,2)], ...
                'IMUBiasLabelX','GyroscopeBiasLabelY','IMUBiasTitleRY', ...
                'IMUBiasLegend','IMUBiasBoundLegend');
            % plot gyroscope bias along Z
            plotValueAlongWithBounds(ax(6),t,gyroBias(:,3),[gB1(:,3),gB2(:,3)], ...
                'IMUBiasLabelX','GyroscopeBiasLabelY','IMUBiasTitleRZ', ...
                'IMUBiasLegend','IMUBiasBoundLegend');
        end

        function ax = showTransform(obj,options)
            %

            % visualize estimated transformation from camera to IMU.

            arguments
                obj
                options.ScaleFactor (1,1) double {mustBeReal,mustBeNonNan,mustBeFinite,mustBePositive} = 0.1
                options.Parent (1,1) {validateAxesHandleVector} = axes(figure("Tag","CameraIMUCalibration_Transform"))
            end
            ax = options.Parent;
            s = options.ScaleFactor;

            if isa(obj.Transform,"se3")
                camIMUTform = obj.Transform;
            else
                camIMUTform = se3(obj.Transform.A);
            end
            
            % get hold state
            holdState = get(ax,'NextPlot');

            % plot IMU at origin
            poseplot('ENU','ScaleFactor',s,'Parent',ax);
            tr = camIMUTform.trvec;
            % hold state on
            set(ax,'NextPlot','add');
            % plot the estimated transform which specifies camera pose relative to IMU
            plotCamera('AbsolutePose',rigidtform3d(camIMUTform.tform),'Size',s,'Parent',ax,'AxesVisible',true);
            plot3(ax,[0;tr(1)],[0;tr(2)],[0;tr(3)], 'SeriesIndex',1);
            % reset hold state
            set(ax,'NextPlot', holdState);
            % add title
            title(ax, getString(message('nav:navalgs:camimucalibration:TransformTitle')));
            legend1 = getString(message('nav:navalgs:camimucalibration:TransformLegend'));
            legend(ax,legend1);
            % add axis label
            xlabel(ax,getString(message('nav:navalgs:camimucalibration:AxisX')));
            ylabel(ax,getString(message('nav:navalgs:camimucalibration:AxisY')));
            zlabel(ax,getString(message('nav:navalgs:camimucalibration:AxisZ')));
        end
        
        function [status,info] = validate(obj, reprojectionThreshold, predictionThreshold, options)
            %

            % validate calibration.

            % input validation
            arguments
                obj
                reprojectionThreshold (1,1) double {mustBeReal,mustBeNonNan,mustBeFinite,mustBePositive}
                predictionThreshold double {mustBeReal,mustBeNonNan,mustBeFinite,mustBeVector,mustBePositive}
                options.ReprojectionErrorMode (1,1) string {mustBeMember(options.ReprojectionErrorMode, {'all', 'mean'})} = 'mean'
                options.IMUPredictionErrorMode (1,1) string {mustBeMember(options.IMUPredictionErrorMode,{'absolute','percentage'})} = 'absolute'
            end
            
            % input parsing
            rTh = reprojectionThreshold;
            pTh = validateIMUPredictionThreshold(predictionThreshold, false);

            % verify if the re-projection error is below specified threshold
            if strcmp(options.ReprojectionErrorMode,'mean')
                meanErr = computeMeanReprojectionErrorPerImage(obj.ReprojectionErrors);
                rpeCheckFailed = any(meanErr > rTh);
            else
                valid = ~isnan(obj.ReprojectionErrors);
                rpeCheckFailed = any(obj.ReprojectionErrors(valid)>rTh);
            end

            % verify if the IMU pose prediction error is below specified
            % threshold
            translationErrors = obj.TranslationErrors;
            rotationErrors = obj.RotationErrors;
            if strcmp(options.IMUPredictionErrorMode,'absolute')
                predCheckFailed = any(translationErrors(:,1) > pTh(1)) || ...
                any(translationErrors(:,2) > pTh(2)) || any(translationErrors(:,3) > pTh(3)) || ...
                any(rotationErrors(:,1) > pTh(4)) || any(rotationErrors(:,2) > pTh(5)) || ...
                any(rotationErrors(:,3) > pTh(6));
            else
                camPoses = obj.CameraPoses;
                relPoses = (camPoses(2:end).inv()).*camPoses(1:(end-1));
                translationalMotion = abs(trvec(camPoses(2:end))-trvec(camPoses(1:(end-1))));
                rotationalMotion = eul(relPoses,"ZYX");
                percentageErrors = ([translationErrors,rotationErrors]./[translationalMotion,rotationalMotion(:,[3,2,1])])*100;
                predCheckFailed = any(percentageErrors(:,1) > pTh(1)) || ...
                any(percentageErrors(:,2) > pTh(2)) || any(percentageErrors(:,3) > pTh(3)) || ...
                any(percentageErrors(:,4) > pTh(4)) || any(percentageErrors(:,5) > pTh(5)) || ...
                any(percentageErrors(:,6) > pTh(6));
            end

            % compute IMU bias bounds
            time = obj.ImageTimeStamps(obj.ImagesUsed);
            accelBias = obj.AccelerometerBias;
            gyroBias = obj.GyroscopeBias;
            imuParams = obj.IMUParameters;
            t = convertTo(time,"posixtime");
            t = t - t(1);
            accelBiasStandardDeviation = sqrt(diag(imuParams.AccelerometerBiasNoise))';
            gyroBiasStandardDeviation = sqrt(diag(imuParams.GyroscopeBiasNoise))';
            aB1 = accelBias(1,1:3) + 3*(accelBiasStandardDeviation).*sqrt(t);
            aB2 = accelBias(1,1:3) - 3*(accelBiasStandardDeviation).*sqrt(t);
            gB1 = gyroBias(1,1:3) + 3*(gyroBiasStandardDeviation).*sqrt(t);
            gB2 = gyroBias(1,1:3) - 3*(gyroBiasStandardDeviation).*sqrt(t);

            % verify if the estimated bias is within expected bounds
            biasCheckFailed = any(accelBias(:,1) > aB1(:,1) | accelBias(:,1) < aB2(:,1) | ...
                                  accelBias(:,2) > aB1(:,2) | accelBias(:,2) < aB2(:,2) | ...
                                  accelBias(:,3) > aB1(:,3) | accelBias(:,3) < aB2(:,3) | ... 
                                  gyroBias(:,1) > gB1(:,1) | gyroBias(:,1) < gB2(:,1) | ...
                                  gyroBias(:,2) > gB1(:,2) | gyroBias(:,2) < gB2(:,2) | ...
                                  gyroBias(:,3) > gB1(:,3) | gyroBias(:,3) < gB2(:,3));

            % verify if the calibration optimization converged
            solutionConvergenseFailed = obj.SolutionInfo.TerminationType ~= 0;

            % verify if the calibration optimization result is usable
            solutionNotUsable = ~obj.SolutionInfo.IsSolutionUsable;

            % compute calibration status
            checks = [rpeCheckFailed,predCheckFailed,biasCheckFailed, ...
                solutionConvergenseFailed,solutionNotUsable];
            failedCheckIds = find(checks);

            if isempty(failedCheckIds)
                status = nav.algs.internal.CameraIMUCalibrationStatus(0);
            elseif isscalar(failedCheckIds)
                status = nav.algs.internal.CameraIMUCalibrationStatus(failedCheckIds);
            else
                status = nav.algs.internal.CameraIMUCalibrationStatus(6);
            end

            % store verification results
            info = struct('ReprojectionErrorAboveThreshold', rpeCheckFailed, ...
                'PredictionErrorAboveThreshold', predCheckFailed, ...
                'BiasValuesOutOfBounds', biasCheckFailed, ...
                'CalibrationOptimizationNotConverged', solutionConvergenseFailed, ...
                'CalibrationOptimizationResultNotUsable', solutionNotUsable);
        end
    end
end

% helper functions
function meanErr = computeMeanReprojectionErrorPerImage(reprojectionErrors)
h = squeeze(hypot(reprojectionErrors(:,1,:),reprojectionErrors(:,2,:)));
meanErr= sum(h,1,"omitmissing")./sum(~isnan(h));
end

function ax = createTwoTabsWithSixAxes(titleIdTab1,titleIdTab2,tag)
% creates a figure with 2 tabs and 3 axes in each tab
% stacked vertically. Returns the vector of 6 axes handles.

% create a new figure
f = figure("Tag",tag);
title1 = getString(message(strcat('nav:navalgs:camimucalibration:',titleIdTab1)));
title2 = getString(message(strcat('nav:navalgs:camimucalibration:',titleIdTab2)));
% create 2 tabs inside the figure
tabgp = uitabgroup(f);
tab1 = uitab(tabgp,'Title',title1);
tab2 = uitab(tabgp,'Title',title2);
% create 3 axes stacked vertically in the first tab
tl1 = tiledlayout(tab1,3,1);
ax1 = nexttile(tl1);
ax2 = nexttile(tl1);
ax3 = nexttile(tl1);
% create 3 axes stacked vertically in the second tab
tl2 = tiledlayout(tab2,3,1);
ax4 = nexttile(tl2);
ax5 = nexttile(tl2);
ax6 = nexttile(tl2);
% create vector of 6 axes handles
ax = [ax1,ax2,ax3,ax4,ax5,ax6];
end

function plotBarGraphWithMeanAndThreshold(ax, val, th, labelX, labelY, ...
                                            titleAx, legendMean, legendTh)
%plotBarGraphWithMeanAndThreshold plots the values provided as a bar graph 
%    on the provided axes. Additionally plots the mean of the values and
%    specified threshold lines for reference.
%       labelX     - String message identifier of X axis Label
%       labelY     - String message identifier of Y axis Label
%       titleAx    - String message identifier of axes title
%       legendMean - String message identifier of mean line legend
%       legendTh   - String message identifier of threshold line legend

% get current axes hold state
holdState = get(ax,'NextPlot');
m = mean(val);
% plot mean error line for all images
line1 = plot(ax,repmat(m,numel(val),1),'--','SeriesIndex',3);
% set axes state to hold on
set(ax, 'NextPlot', 'add');
% plot mean errors per image
bar(ax,val,'SeriesIndex',1);
ylim(ax,[0,5*m]);
% add axis labels
xlabel(ax, getString(message(strcat('nav:navalgs:camimucalibration:',labelX))));
ylabel(ax, getString(message(strcat('nav:navalgs:camimucalibration:',labelY))));
% add title
title(ax, getString(message(strcat('nav:navalgs:camimucalibration:',titleAx))));
legend1 = getString(message(strcat('nav:navalgs:camimucalibration:',legendMean),num2str(m)));
if ~isempty(th)
    % plot threshold line when specified
    line2 = plot(ax,repmat(th,numel(val),1),'--',"SeriesIndex",7);
    legend2 = getString(message(strcat('nav:navalgs:camimucalibration:',legendTh),num2str(th)));
    % add threshold and mean line legends
    legend(ax,[line1(1),line2(1)],legend1,legend2,AutoUpdate="off");
    yl = ylim(ax);
    if yl(2) <= th
        ylim(ax,[0,1.1*th]);
    end
else
    % add mean line legend
    legend(line1(1),legend1,AutoUpdate="off");
end
% reset hold state back to it's previous value
set(ax, 'NextPlot', holdState);
end

function plotValueAlongWithBounds(ax,t,val,bounds,labelX,labelY,titleAx,legendVal,legendBound)
%plotValueAlongWithBounds plots the values along with bounds as lines
%    on the provided axes. 
%       labelX      - String message identifier of X axis Label
%       labelY      - String message identifier of Y axis Label
%       titleAx     - String message identifier of axes title
%       legendVal   - String message identifier of value line
%       legendBound - String message identifier of bound line

% get current axes hold state
holdState = get(ax,'NextPlot');
% plot value line
valLine = plot(ax,t,val);
% set axes state to hold on
set(ax,'NextPlot', 'add');
% plot bounds
boundLine = plot(ax,t,bounds(:,1),'SeriesIndex',7);
plot(ax,t,bounds(:,2),'SeriesIndex',7);
% add axis labels
xlabel(ax, getString(message(strcat('nav:navalgs:camimucalibration:',labelX))));
ylabel(ax, getString(message(strcat('nav:navalgs:camimucalibration:',labelY))));
% add title
title(ax, getString(message(strcat('nav:navalgs:camimucalibration:',titleAx))));
% add legend
legend1 = getString(message(strcat('nav:navalgs:camimucalibration:',legendVal)));
legend2 = getString(message(strcat('nav:navalgs:camimucalibration:',legendBound)));
legend([valLine,boundLine],legend1,legend2,AutoUpdate="off");

% reset hold state back to it's previous value
set(ax, 'NextPlot', holdState);
end

% Custom validation functions
function vth = validateIMUPredictionThreshold(th, emptyOk)
    % Test for valid size
    if isempty(th) && emptyOk
        vth = [];
        return;
    elseif length(th) == 2
        vth = [th(1),th(1),th(1),th(2),th(2),th(2)];
        return;
    elseif length(th) == 6
        vth = th(:)';
        return;
    end
    coder.internal.error("nav:navalgs:camimucalibration:IMUThresholdLength");
end

function v =validateAxesHandleVector(ax)
% returns true if all the specified handles are axes

v = all(ishghandle(ax,'axes'));
if ~v
    coder.internal.error("nav:navalgs:camimucalibration:InvalidAxisHandle");
end
end
