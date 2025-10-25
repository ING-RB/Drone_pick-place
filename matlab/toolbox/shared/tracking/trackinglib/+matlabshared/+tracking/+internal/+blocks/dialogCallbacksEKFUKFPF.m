function dialogCallbacksEKFUKFPF(blkH,callbackIdentifier,varargin)
% dialogCallbacksEKFUKFPF Dialog callbacks for the EKF/UKF/PF blocks
%
%   dialogCallbacks(blkH,callbackIdentifier)
%
%   Inputs:
%     blkH               - Handle to the block
%     callbackIdentifier - Source of the callback

%   Copyright 2016-2017 The MathWorks, Inc.

switch callbackIdentifier
    case 'checkBoxHasJacobianFcn'
        % Callback for HasXJacobianFcn checkbox, X=varargin{1}
        localCheckBoxHasJacobianFcn(blkH,varargin{:});
    case 'checkboxIsCovarianceTimeVarying'
        localCheckboxIsCovarianceTimeVarying(blkH,varargin{:});
    case 'checkBoxHasMultirate'
        localCheckBoxHasMultirate(blkH)
    case 'buttonAddMeasurement'
        % varargin{1} is 'MeasurementFcn' (EKF, UKF) or 'MeasurementLikelihoodFcn' (PF)
        localButtonAddMeasurement(blkH,varargin{1});
    case 'buttonRemoveMeasurement'
        % varargin{1} is 'MeasurementFcn' (EKF, UKF) or 'MeasurementLikelihoodFcn' (PF)
        localButtonRemoveMeasurement(blkH,varargin{1});
    case 'editboxNumberOfMeasurements'
        % varargin{1} is 'MeasurementFcn' (EKF, UKF) or 'MeasurementLikelihoodFcn' (PF)
        localEditboxNumberOfMeasurements(blkH,varargin{1});
    case 'comboboxInitialDistribution'
        localComboboxInitialDistribution(blkH);
    case 'comboboxTriggerMethod'
        localComboboxTriggerMethod(blkH); % PF's TriggerMethod widget
    case 'comboboxRandomness'
        localComboboxRandomness(blkH); % PF's Randomness and Seed widgets
    case 'comboboxStateEstimationMethod'
        localComboboxStateEstimationMethod(blkH); % PF's StateEstimationMethod widget
    otherwise
        assert(false);
end
end

function localCheckBoxHasMultirate(blkH)
% localCheckBoxHasMultirate Callback for the EnableMultirate checkbox
%
% When this box is checked:
% * SampleTime is widget is hidden.
% * GroupMultirateSampleTimes is visible
%
% 	Dependent widgets:
%     SampleTime, StateTransitionFcnSampleTime, MeasurementNFcnSampleTime
isMultirate = strcmp(get_param(blkH,'EnableMultirate'),'on');
if isMultirate
    desiredSampleTimeVisibility = 'off';
    desiredMultirateVisibility = 'on';
else
    desiredSampleTimeVisibility = 'on';
    desiredMultirateVisibility = 'off';
end

maskNames = get_param(blkH,'MaskNames');
maskVisibilities = get_param(blkH,'MaskVisibilities');
maskEnables = get_param(blkH,'MaskEnables');


isDifferent = false();
% SampleTime: Hide when EnableMultirate is 'on'. State transition fcn and
% each measurement fcn will gave their own sample time widget
idxSampleTime = strcmp(maskNames,'SampleTime');
if ~strcmp(maskVisibilities{idxSampleTime},desiredSampleTimeVisibility)
    maskVisibilities{idxSampleTime} = desiredSampleTimeVisibility;
    isDifferent = true();
end
% GroupMultirateSampleTimes: Show/hide the group that contains individual
% sample time widgets for state transition fcn and each measurement fcn 
maskObj = Simulink.Mask.get(blkH);
groupMultirateObj = maskObj.getDialogControl('GroupMultirateSampleTimes');
if ~strcmp(groupMultirateObj.Visible, desiredMultirateVisibility)
    groupMultirateObj.Visible = desiredMultirateVisibility;
end
% Ensure that the sample time widget for the state transition fcn is
% enabled. 
%
% Prior to 2018a, we were enabling/disabling multirate sample time widgets
% instead of making them visible/invisible based on the HasMultirate
% setting. Hence a model saved in a prior version can come with a disabled
% widget. In this case we need to Enable it once.
idxSampleTime = strcmp(maskNames,'StateTransitionFcnSampleTime');
if ~strcmp(maskEnables{idxSampleTime},'on')
    maskEnables{idxSampleTime} = 'on';
    isDifferent = true();
end


% Updates for dependent widgets:
%    N/A - The modified widgets here do not impact any others
% Update the dialog
if isDifferent
    set_param(blkH,'MaskVisibilities',maskVisibilities,'MaskEnables',maskEnables);
end
end


function localCheckboxIsCovarianceTimeVarying(blkH,checkboxName,editboxName)
% localCheckboxEnableMultirate Callback for the IsTimeVaryingX checkboxes
%
% When this box is checked the nearby text field is disabled
%
% 	Dependent widgets:
%     ProcessNoise or MeasurementXNoise
isTimeVarying = strcmp(get_param(blkH,checkboxName),'on');
if isTimeVarying
    desiredEditboxEnable = 'off';
else
    desiredEditboxEnable = 'on';
end

maskNames = get_param(blkH,'MaskNames');
maskEnables = get_param(blkH,'MaskEnables');

isSame = true();
idxEditbox = strcmp(maskNames,editboxName);
if ~strcmp(maskEnables{idxEditbox},desiredEditboxEnable)
    maskEnables{idxEditbox} = desiredEditboxEnable;
    isSame = false();
end
% Updates for dependent widgets:
%    N/A - The modified widgets here do not impact any others
% Update the dialog
if ~isSame
    set_param(blkH,'MaskEnables',maskEnables);
end
end


function localCheckBoxHasJacobianFcn(blkH,fcnName,idStr)
% localCheckBoxHasJacobianFcn Callback for checkboxes that enable/disable
% their respective Jacobian fcn name editboxes.
%
% The widget duos are named as: HasXJacobianFcn<->EditXJacobianFcn where
% X=fcnName
%
% 	Dependent widgets:
%     EditXJacobianFcn

if nargin<3
    idStr = '';
end

% Configure dependent widgets
localConfigureJacobianEditBox(blkH,fcnName,idStr);
end

function localConfigureJacobianEditBox(blkH,fcnName,idStr)
% localConfigureHasJacobianButton
%
%   EditXJacobianFcn button is disabled if the HasXJacobianFcn checkbox is
%   off
%
%   Dependent widgets:
%     N/A

editBoxName = [fcnName 'JacobianFcn' idStr];
checkBoxName = ['Has' editBoxName];
enableEditBox = get_param(blkH,checkBoxName);
maskNames = get_param(blkH,'MaskNames');
maskEnables = get_param(blkH,'MaskEnables');

idx = strcmp(maskNames,editBoxName);
% Only one dependent parameter, set immediately (but only if we need to)
if ~strcmp(maskEnables{idx},enableEditBox)
    maskEnables{idx} = enableEditBox;
    set_param(blkH,'MaskEnables',maskEnables);
end
end

function localButtonAddMeasurement(blkH, fcnName)
% Add a measurement model
%
% Inputs:
%   blkH    - Handle to the EKF/UKF/PF block
%   fcnName - 'MeasurementFcn' for EKF/UKF, 'MeasurementLikelihoodFcn' for PF

maskNames = get_param(blkH,'MaskNames');
maskValues = get_param(blkH,'MaskValues');
idx = strcmp(maskNames,'NumberOfMeasurements');
numberOfMeasurements = str2double(maskValues(idx));
maxNumberOfMeasurements = matlabshared.tracking.internal.blocks.getMaxMeasurementModels();
if numberOfMeasurements < maxNumberOfMeasurements
    numberOfMeasurements = numberOfMeasurements + 1;
    maskValues{idx} = sprintf('%d',numberOfMeasurements);
    % Get updates from dependent widgets
    [~,maskVisibilities,maskEnables] = localEditboxNumberOfMeasurements(blkH, fcnName, numberOfMeasurements);
    % maskValues are surely changed. set_param is needed
    set_param(blkH,'MaskValues',maskValues,'MaskVisibilities',maskVisibilities,'MaskEnables',maskEnables);
elseif numberOfMeasurements == maxNumberOfMeasurements
    maxMeasModelException = MSLException(blkH, ...
        message('shared_tracking:blocks:errorMaxNumberOfMeasurementModels',maxNumberOfMeasurements,getfullname(blkH)));
    sldiagviewer.reportError(maxMeasModelException);
else
    assert(false()); % This should never happen, but if it does, stop
end
end

function localButtonRemoveMeasurement(blkH, fcnName)
% Remove a measurement model
%
% Inputs:
%   blkH    - Handle to the EKF/UKF/PF block
%   fcnName - 'MeasurementFcn' for EKF/UKF, 'MeasurementLikelihoodFcn' for PF
maskNames = get_param(blkH,'MaskNames');
maskValues = get_param(blkH,'MaskValues');
idx = strcmp(maskNames,'NumberOfMeasurements');
numberOfMeasurements = str2double(maskValues(idx));
if numberOfMeasurements>1
    numberOfMeasurements = numberOfMeasurements - 1;
    maskValues{idx} = sprintf('%d',numberOfMeasurements);
    % Get updates from dependent widgets
    [~,maskVisibilities,maskEnables] = localEditboxNumberOfMeasurements(blkH, fcnName, numberOfMeasurements);
    % maskValues are surely changed. set_param is needed
    set_param(blkH,'MaskValues',maskValues,'MaskVisibilities',maskVisibilities,'MaskEnables',maskEnables);
elseif numberOfMeasurements==1
    minMeasModelException = MSLException(blkH, ...
        message('shared_tracking:blocks:errorMinNumberOfMeasurementModels',getfullname(blkH)));
    sldiagviewer.reportError(minMeasModelException);
else
    assert(false()); % This should never happen, but if it does, stop
end
end

function [isSame,maskVisibilities,maskEnables] = localEditboxNumberOfMeasurements(blkH, fcnName, numberOfMeasurements)
% Set the visibility of widgets that are based on # of measurement models
%
% Inputs:
%   blkH    - Handle to the EKF/UKF/PF block
%   fcnName - 'MeasurementFcn' for EKF/UKF, 'MeasurementLikelihoodFcn' for PF
%
% This fcn can be called from two sources:
% * Mask itself can call it without output args, and two input args. This
% makes sure the state of all widgets are good.
% * Add/Remove measurement buttons can call this, with output args and three
% input args. This call is done before NumberOfMeasurements is set to its
% new value, to avoid calling set_param twice
if nargin<3
    numberOfMeasurements = get_param(blkH,'NumberOfMeasurements');
    numberOfMeasurements = str2double(numberOfMeasurements);
end

% Get necessary variables
MaxNumberOfMeasurements = matlabshared.tracking.internal.blocks.getMaxMeasurementModels();
maskNames = get_param(blkH,'MaskNames');
maskVisibilities = get_param(blkH,'MaskVisibilities');
maskEnables = get_param(blkH,'MaskEnables');
isSame = true();

% Ensure that the sample time widget for the first measurement model is
% enabled. 
%
% Prior to 2018a, we were enabling/disabling multirate sample time widgets
% instead of making them visible/invisible based on the HasMultirate
% setting. Hence a model saved in a prior version can come with a disabled
% widget. In this case we need to Enable it once.
idxSampleTime = strcmp(maskNames,sprintf('%s1SampleTime',fcnName));
if ~strcmp(maskEnables{idxSampleTime},'on')
    maskEnables{idxSampleTime} = 'on';
    isSame = false();
end

maskObj = Simulink.Mask.get(blkH);
% Make the widgets visible for all available measurement models
for kk=2:numberOfMeasurements % Start from 2, 1st meas is always there, and on
    measurementGroupObj = maskObj.getDialogControl(sprintf('GroupMeasurement%d',kk));
    if ~strcmp(measurementGroupObj.Visible,'on')
        measurementGroupObj.Visible = 'on';
    end
    idxSampleTime = strcmp(maskNames,sprintf('%s%dSampleTime',fcnName,kk));
    if ~strcmp(maskVisibilities{idxSampleTime},'on')
        maskVisibilities{idxSampleTime} = 'on';
        isSame = false();
    end
    % Enable the widget, if needed. See the notes above for why this is
    % needed. Also note that we do not disable widgets anymore.
    if ~strcmp(maskEnables{idxSampleTime},'on')
        maskEnables{idxSampleTime} = 'on';
        isSame = false();
    end
end
% Widgets for the unused measurement model slots are not visible
for kk=numberOfMeasurements+1:MaxNumberOfMeasurements
    measurementGroupObj = maskObj.getDialogControl(sprintf('GroupMeasurement%d',kk));
    if ~strcmp(measurementGroupObj.Visible,'off')
        measurementGroupObj.Visible = 'off';
    end
    idxSampleTime = strcmp(maskNames,sprintf('%s%dSampleTime',fcnName,kk));
    if ~strcmp(maskVisibilities{idxSampleTime},'off')
        maskVisibilities{idxSampleTime} = 'off';
        isSame = false();
    end
end

% set_param only if anything has changed, and the caller itself won't do a
% set_param
if ~isSame && nargout==0
    set_param(blkH,'MaskVisibilities',maskVisibilities,'MaskEnables',maskEnables);
end
end


function localComboboxInitialDistribution(blkH)
% Callback for the InitialDistribution combobox of PF
%
% InitialDistribution controls visibility of:
%    InitialMean, InitialCovariance, StateBounds, InitialParticles, InitialWeights
%
% If InitialDistribution is:
% * Gaussian: Show InitialMean, InitialCovariance
% * Uniform: Show StateBounds
% * Custom: Show InitialParticles, InitialWeights
%
% 	Dependent widgets:
%     (all listed above)
visibilityInitialMeanCovariance = 'off';
visibilityStateBounds = 'off';
visibilityInitialParticlesWeights = 'off';
switch get_param(blkH,'InitialDistribution')
    case slsvInternal('slsvGetEnStringFromCatalog','shared_tracking:blocks:maskPromptPFGaussian')
        visibilityInitialMeanCovariance = 'on';
    case slsvInternal('slsvGetEnStringFromCatalog','shared_tracking:blocks:maskPromptPFUniform')
        visibilityStateBounds = 'on';
    case slsvInternal('slsvGetEnStringFromCatalog','shared_tracking:blocks:maskPromptPFCustom')
        visibilityInitialParticlesWeights = 'on';
    otherwise
        assert(false);
end

maskNames = get_param(blkH,'MaskNames');
maskVisibilities = get_param(blkH,'MaskVisibilities');

isDifferent = false();
% InitialMean, InitialCovariance
idxInitialMean = strcmp(maskNames,'InitialMean');
if ~strcmp(maskVisibilities{idxInitialMean},visibilityInitialMeanCovariance)
    maskVisibilities{idxInitialMean} = visibilityInitialMeanCovariance;
    isDifferent = true();
end
idxInitialCovariance = strcmp(maskNames,'InitialCovariance');
if ~strcmp(maskVisibilities{idxInitialCovariance},visibilityInitialMeanCovariance)
    maskVisibilities{idxInitialCovariance} = visibilityInitialMeanCovariance;
    isDifferent = true();
end
% StateBounds
idxStateBounds = strcmp(maskNames,'InitialStateBounds');
if ~strcmp(maskVisibilities{idxStateBounds},visibilityStateBounds)
    maskVisibilities{idxStateBounds} = visibilityStateBounds;
    isDifferent = true();
end
% InitialParticles, InitialWeights
idxInitialParticles = strcmp(maskNames,'InitialParticles');
if ~strcmp(maskVisibilities{idxInitialParticles},visibilityInitialParticlesWeights)
    maskVisibilities{idxInitialParticles} = visibilityInitialParticlesWeights;
    isDifferent = true();
end
idxInitialWeights = strcmp(maskNames,'InitialWeights');
if ~strcmp(maskVisibilities{idxInitialWeights},visibilityInitialParticlesWeights)
    maskVisibilities{idxInitialWeights} = visibilityInitialParticlesWeights;
    isDifferent = true();
end

% Updates for dependent widgets:
%    N/A - The modified widgets here do not impact any others
% Update the dialog
if isDifferent
    set_param(blkH,'MaskVisibilities',maskVisibilities);
end
end

function localComboboxTriggerMethod(blkH)
% Callback for the TriggerMethod combobox of PF
%
% TriggerMethod controls visibility of:
%    SamplingInterval, MinEffectiveParticleRatio
%
% If TriggerMethod is:
% * Ratio: Show MinEffectiveParticleRatio
% * Interval: Show SamplingInterval
%
% 	Dependent widgets:
%     (all listed above)
visibilitySamplingInterval = 'off';
visibilityMinEffectiveParticleRatio = 'off';
switch get_param(blkH,'TriggerMethod')
    case slsvInternal('slsvGetEnStringFromCatalog','shared_tracking:blocks:maskPromptPFRatio')
        visibilityMinEffectiveParticleRatio = 'on';
    case slsvInternal('slsvGetEnStringFromCatalog','shared_tracking:blocks:maskPromptPFInterval')
        visibilitySamplingInterval = 'on';
    otherwise
        assert(false);
end

maskNames = get_param(blkH,'MaskNames');
maskVisibilities = get_param(blkH,'MaskVisibilities');

isDifferent = false();
% MinEffectiveParticleRatio
idxMinEffectiveParticleRatio = strcmp(maskNames,'MinEffectiveParticleRatio');
if ~strcmp(maskVisibilities{idxMinEffectiveParticleRatio},visibilityMinEffectiveParticleRatio)
    maskVisibilities{idxMinEffectiveParticleRatio} = visibilityMinEffectiveParticleRatio;
    isDifferent = true();
end
% SamplingInterval
idxSamplingInterval = strcmp(maskNames,'SamplingInterval');
if ~strcmp(maskVisibilities{idxSamplingInterval},visibilitySamplingInterval)
    maskVisibilities{idxSamplingInterval} = visibilitySamplingInterval;
    isDifferent = true();
end

% Updates for dependent widgets:
%    N/A - The modified widgets here do not impact any others
% Update the dialog
if isDifferent
    set_param(blkH,'MaskVisibilities',maskVisibilities);
end
end

function localComboboxRandomness(blkH)
% localComboBoxRandomness Callback for the Randomness combobox
%
% * When Randomness is 'Repeatable', then Seed editbox is shown.
% * When Randomness is 'Not repeatable', then Seed editbox is hidden.
%
% 	Dependent widgets:
%     Seed
isRepeatable = strcmp(get_param(blkH,'Randomness'),...
    slsvInternal('slsvGetEnStringFromCatalog','shared_tracking:blocks:maskPromptPFRepeatable'));
if isRepeatable
    desiredSeedVisibility = 'on';
else
    desiredSeedVisibility = 'off';
end

maskNames = get_param(blkH,'MaskNames');
maskVisibilities = get_param(blkH,'MaskVisibilities');

isDifferent = false();
% SampleTime
idxSeed = strcmp(maskNames,'Seed');
if ~strcmp(maskVisibilities{idxSeed},desiredSeedVisibility)
    maskVisibilities{idxSeed} = desiredSeedVisibility;
    isDifferent = true();
end

% Updates for dependent widgets:
%    N/A - The modified widgets here do not impact any others
% Update the dialog
if isDifferent
    set_param(blkH,'MaskVisibilities',maskVisibilities);
end
end

function localComboboxStateEstimationMethod(blkH)
% localComboboxStateEstimationMethod Callback for the StateEstimationMethod combobox
%
% * When StateEstimationMethod is anything other than 'mean', the
% OutputStateCovariance editbox is disabled
% * When StateEstimationMethod is 'none', the 'OutputParticles' is set to
% 'on' and it is disabled in the dialog
%
% 	Dependent widgets:
%     OutputStateCovariance, OutputParticles

switch get_param(blkH,'StateEstimationMethod')
    case slsvInternal('slsvGetEnStringFromCatalog','shared_tracking:blocks:maskPromptPFStateEstMethodMean')
        isStateEstimationMethodMean = true();
        isStateEstimationMethodNone = false();
    case slsvInternal('slsvGetEnStringFromCatalog','shared_tracking:blocks:maskPromptPFStateEstMethodMaxWeight')
        isStateEstimationMethodMean = false();
        isStateEstimationMethodNone = false();   
    case slsvInternal('slsvGetEnStringFromCatalog','shared_tracking:blocks:maskPromptPFStateEstMethodNone')
        isStateEstimationMethodMean = false();
        isStateEstimationMethodNone = true();
end
        
if isStateEstimationMethodMean
    desiredOutputStateCovarianceEnable = 'on';
else
    desiredOutputStateCovarianceEnable = 'off';
end
if isStateEstimationMethodNone
    desiredOutputParticlesEnable = 'off';
else
    desiredOutputParticlesEnable = 'on';
end

maskNames = get_param(blkH,'MaskNames');
maskEnables = get_param(blkH,'MaskEnables');

isDifferent = false();
% OutputStateCovariance
idxOutputStateCovariance = strcmp(maskNames,'OutputStateCovariance');
if ~strcmp(maskEnables{idxOutputStateCovariance},desiredOutputStateCovarianceEnable)
    maskEnables{idxOutputStateCovariance} = desiredOutputStateCovarianceEnable;
    isDifferent = true();
end
% OutputParticles
idxOutputParticles = strcmp(maskNames,'OutputParticles');
if ~strcmp(maskEnables{idxOutputParticles},desiredOutputParticlesEnable)
    maskEnables{idxOutputParticles} = desiredOutputParticlesEnable;
    isDifferent = true();
end
if isStateEstimationMethodNone && ~strcmp(get_param(blkH,'OutputParticles'),'on')
    extraParameterSettings = {'OutputParticles','on'};
    isDifferent = true();
else
    extraParameterSettings = {};
end

% Updates for dependent widgets:
%    N/A - The modified widgets here do not impact any others further
%          downstream. Can perform the update now
% Update the dialog
if isDifferent
    set_param(blkH,'MaskEnables',maskEnables,extraParameterSettings{:});
end
end