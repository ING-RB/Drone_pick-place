function [p,signalCheck] = processDialogDataEKFUKF(blkH,dlgParams)
% processDialogDataEKFUKF Process user data from the EKF&UKF block dialogs
%
% This function covers the shared widgets between EKF&UKF. EKF/UKF specific
% widgets are handled in processDialogDataEKF() and ...UKF().
%
%   Inputs:
%     blkH      - Handle to the block
%     dlgParams - Structure that contains the dialog parameters. This
%                 is created in the 'Mask Initialization' tab of the mask.
%                 It contains all data from all widgets in the block mask.
%
%   Outputs:
%     p           - Structure. Contains parameters passed onto the blocks under the mask
%     signalCheck - Structure with parameters for signal check S-Fcns

%   Copyright 2016-2021 The MathWorks, Inc.

%% Data types
p.DataType = localValidateDataType(dlgParams.DataType);

%% Initialization
[p.InitialState,p.Ns] = localValidateX0(dlgParams.InitialState, p.DataType);
p.InitialCovariance = matlabshared.tracking.internal.blocks.validateCovariance(...
    dlgParams.InitialStateCovariance, ...
    true(), ...% enforce strict positive definiteness
    p.Ns, ...
    p.DataType, ...
    matlabshared.tracking.internal.blocks.getFieldName('shared_tracking:blocks:maskPromptEKFUKFInitialCovariance'));
p.InitialCovariance = matlabshared.tracking.internal.cholPSD(p.InitialCovariance);

%% Sample times
p.SampleTimes = matlabshared.tracking.internal.blocks.validateSampleTime(blkH,dlgParams);

%% Additive vs non-additive noise
p.HasAdditiveNoise = localProcessHasAdditiveNoise(dlgParams);

%% Process and measurement noise
p.Q = localProcessProcessNoiseCovariance(dlgParams.ProcessNoise, ...
    p.Ns, p.HasAdditiveNoise.StateTransitionFcn, p.DataType);
p.Q = matlabshared.tracking.internal.cholPSD(p.Q);

%% Determine if Process and Measurement noise covariances are time-invariant or time-varying
p.HasTimeVaryingProcessNoise = dlgParams.HasTimeVaryingProcessNoise;
p.HasTimeVaryingMeasurementNoise = dlgParams.HasTimeVaryingMeasurementNoise;

p.R = localProcessMeasurementNoiseCovariance(dlgParams, p.DataType);
for i = 1:numel(p.R)
    tempVar = p.R{i};
    tempVar = matlabshared.tracking.internal.cholPSD(tempVar);
    p.R{i} = tempVar;
end

%% Wrapping measurements
p.HasWrapping = logical(dlgParams.HasMeasurementWrapping);

%% Functions
[p.StateTransitionFcn, p.MeasurementFcn] = matlabshared.tracking.internal.blocks.validateFcns(dlgParams);

%% Data for signal check blocks
signalCheck = localGetSignalCheckData(blkH, dlgParams, p);
end

function d = localValidateDataType(d)
% DataType must be 'single' or 'double', regardless of locale
d = validatestring(d,{'double','single'});
end

function [x0,Ns] = localValidateX0(x0,dataType)
% localValidateX0 Validate the initial state estimate
%
%   Inputs:
%     x0 - Initial state estimate from user
%
%   Outputs:
%     x0 - Validated x0
%     Ns - # of states
fieldName = matlabshared.tracking.internal.blocks.getFieldName('shared_tracking:blocks:maskPromptEKFUKFInitialState');
if ~isfloat(x0)
    error(message('shared_tracking:blocks:errorExpectedFloat', fieldName, class(x0)));
end
if isempty(x0)
    error(message('shared_tracking:blocks:errorExpectedNonempty', fieldName));
end
if ~isreal(x0)
    error(message('shared_tracking:blocks:errorExpectedReal', fieldName));
end
if ~isvector(x0)
    error(message('shared_tracking:blocks:errorExpectedVector', fieldName));
end
if ~all(isfinite(x0))
    error(message('shared_tracking:blocks:errorExpectedFinite', fieldName));
end
if issparse(x0)
    error(message('shared_tracking:blocks:errorExpectedNonsparse', fieldName));
end

x0 = x0(:); % Ensure x0 is a column vector
x0 = cast(x0,dataType); % Ensure x0 has the block's data type
Ns = numel(x0);
end

function N = localProcessHasAdditiveNoise(dlgParams)
N.StateTransitionFcn = dlgParams.FcnInfo.Predict.HasAdditiveNoise;
N.MeasurementFcn = dlgParams.FcnInfo.Correct.HasAdditiveNoise;
end

function Q = localProcessProcessNoiseCovariance(Q,Ns,hasAdditiveNoise,dataType)
if hasAdditiveNoise
    Nw = Ns; % # of process noise terms = # of states
else
    Nw = -1; % don't know dimensions
end

enforceStrictPosDef = false(); % Q can be positive semi-definite
fieldName = matlabshared.tracking.internal.blocks.getFieldName('shared_tracking:blocks:errorPromptEKFUKFProcessNoiseCovariance');
Q = matlabshared.tracking.internal.blocks.validateCovariance(Q,enforceStrictPosDef,Nw,dataType,fieldName);
end

function R = localProcessMeasurementNoiseCovariance(dlgParams, dataType)
R = cell(dlgParams.NumberOfMeasurements);

enforceStrictPosDef = true(); % R must be positive-definite
fieldName = matlabshared.tracking.internal.blocks.getFieldName('shared_tracking:blocks:errorPromptEKFUKFMeasurementNoiseCovariance');
Ny = -1; % we don't know number of measurements
for kk=1:dlgParams.NumberOfMeasurements
    R{kk} = matlabshared.tracking.internal.blocks.validateCovariance(dlgParams.MeasurementNoise{kk},enforceStrictPosDef,Ny,dataType,fieldName);
end
end


function signalCheck = localGetSignalCheckData(blkH, dlgParams, p)
% Gather data required for the signal check S-Fcns. The data types used
% here must match with the types required in ekfukfCheckSignals.cpp

signalCheck.BlockPath = getfullname(blkH);
signalCheck.DataType = matlabshared.tracking.internal.blocks.getSSDataType(p.DataType);

% State fcn
signalCheck.StateTransitionFcn.PortNames = {'Q','StateTransitionFcnInputs'};
signalCheck.StateTransitionFcn.SampleTime = p.SampleTimes.StateTransitionFcn;
signalCheck.StateTransitionFcn.HasAdditiveNoise = p.HasAdditiveNoise.StateTransitionFcn;
% Dimensions of Q are known if there is additive process noise in State Fcn
if p.HasAdditiveNoise.StateTransitionFcn
    signalCheck.StateTransitionFcn.PortDimensions = {int32([p.Ns p.Ns]),int32(-1)};
else
    signalCheck.StateTransitionFcn.PortDimensions = {int32(-1),int32(-1)};
end

% MeasurementFcn
signalCheck.MeasurementFcn = cell(dlgParams.NumberOfMeasurements,1);
for kk=1:dlgParams.NumberOfMeasurements
    % Dimensions of inport yX is known when there is additive measurement
    % noise, and R is specified in the block dialog
    if p.HasAdditiveNoise.MeasurementFcn(kk) && ~dlgParams.HasTimeVaryingMeasurementNoise(kk)
        dimsY = int32(size(p.R{kk},1));
    else
        dimsY = int32(-1);
    end
    % Enable port is always scalar. We never know the dims of last 2 signals
    signalCheck.MeasurementFcn{kk}.PortDimensions = {int32(1),dimsY,int32(-1),int32(-1)};
    % Port names
    signalCheck.MeasurementFcn{kk}.PortNames = {...
        sprintf('Enable%d',kk),...
        sprintf('y%d',kk),...
        sprintf('R%d',kk),...
        sprintf('MeasurementFcn%dInputs',kk)};
    % Sample time
    signalCheck.MeasurementFcn{kk}.SampleTime = p.SampleTimes.MeasurementFcn(kk);
    % Has additive noise?
    signalCheck.MeasurementFcn{kk}.HasAdditiveNoise = p.HasAdditiveNoise.MeasurementFcn(kk);
end
end
