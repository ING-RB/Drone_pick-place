
%

%   Copyright 2016-2022 The MathWorks, Inc.

% Package mask variables so that they can be processed easier by downstream
% functions

matlabshared.tracking.internal.blocks.initializeFilter();

% Get the option string 'Additive' in EN, regardless of locale
additiveMeasStr = slsvInternal('slsvGetEnStringFromCatalog',...
    'shared_tracking:blocks:maskPromptEKFUKFAdditiveNoise');

% State transition fcn
dlgParams.FcnInfo.Predict.Fcn = {StateTransitionFcn};
dlgParams.FcnInfo.Predict.HasAdditiveNoise = strcmp(HasAdditiveProcessNoise,additiveMeasStr);
if dlgParams.FcnInfo.Predict.HasAdditiveNoise
    dlgParams.FcnInfo.Predict.ExpectedNargin = 1;
else
    dlgParams.FcnInfo.Predict.ExpectedNargin = 2;
end
dlgParams.ProcessNoise = ProcessNoise;
dlgParams.HasTimeVaryingProcessNoise = HasTimeVaryingProcessNoise;
dlgParams.StateTransitionFcnSampleTime = StateTransitionFcnSampleTime;
dlgParams.HasStateTransitionFcnExtraArgument = HasStateTransitionFcnExtraArgument;
% x0, P0
dlgParams.InitialState = InitialState;
dlgParams.InitialStateCovariance = InitialStateCovariance;
% Measurement fcns
dlgParams.FcnInfo.Correct.Fcn = cell(NumberOfMeasurements,1);
dlgParams.FcnInfo.Correct.HasAdditiveNoise = false(NumberOfMeasurements,1);
dlgParams.MeasurementNoise = cell(NumberOfMeasurements,1);
dlgParams.HasTimeVaryingMeasurementNoise = false(NumberOfMeasurements,1);
dlgParams.HasMeasurementEnablePort = false(NumberOfMeasurements,1);
dlgParams.MeasurementFcnSampleTime = cell(NumberOfMeasurements,1);
dlgParams.HasMeasurementFcnExtraArgument = false(NumberOfMeasurements,1);
for kk=1:NumberOfMeasurements
    % Functions
    dlgParams.FcnInfo.Correct.Fcn{kk} = eval( sprintf('MeasurementFcn%d',kk) );
    % Sample time
    dlgParams.MeasurementFcnSampleTime{kk} = eval( sprintf('MeasurementFcn%dSampleTime',kk) );
    % The rest
    dlgParams.FcnInfo.Correct.HasAdditiveNoise(kk) = strcmp(eval(sprintf('HasAdditiveMeasurementNoise%d',kk)), additiveMeasStr);
    dlgParams.MeasurementNoise{kk} = eval( sprintf('MeasurementNoise%d',kk) );
    dlgParams.HasTimeVaryingMeasurementNoise(kk) = eval( sprintf('HasTimeVaryingMeasurementNoise%d',kk) );
    dlgParams.HasMeasurementWrapping(kk) = eval( sprintf('HasMeasurementWrapping%d',kk) );
    dlgParams.HasMeasurementEnablePort(kk) = eval( sprintf('HasMeasurementEnablePort%d',kk) );
    dlgParams.HasMeasurementFcnExtraArgument(kk) = eval( sprintf('HasMeasurementFcnExtraArgument%d',kk) );
end
dlgParams.NumberOfMeasurements = NumberOfMeasurements;
dlgParams.FcnInfo.Correct.ExpectedNargin = ones(dlgParams.NumberOfMeasurements,1);
dlgParams.FcnInfo.Correct.ExpectedNargin(~dlgParams.FcnInfo.Correct.HasAdditiveNoise) = 2;
% UKF parameters
dlgParams.Alpha = Alpha;
dlgParams.Beta = Beta;
dlgParams.Kappa = Kappa;
% Settings
dlgParams.UseCurrentEstimator = UseCurrentEstimator;
dlgParams.OutputStateCovariance = OutputStateCovariance;
dlgParams.EnableMultirate = EnableMultirate;
dlgParams.SampleTime = SampleTime;
dlgParams.DataType = DataType;
% Main MaskInit code
[p,signalCheck] = matlabshared.tracking.internal.blocks.maskInitializationFcnUKF(gcbh,dlgParams);
clear dlgParams tempVar; % Avoid block from storing the struct in block's WS
