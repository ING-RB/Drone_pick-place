function [p,signalCheck] = processDialogDataPF(blkH,dlgParams)
% processDialogDataPF Process user data from the PF block dialog
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

%   Copyright 2017-2018 The MathWorks, Inc.

%% State orientation, data type
p.DataType = localValidateDataType(dlgParams.DataType);
[p.IsStateOrientationColumn,particleManager] = localGetParticleManager(dlgParams.StateOrientation);

%% Random number generation
% These must be processed before we process the initialization params
[p.Seed,p.RandomNumberGenerator] = localValidateRandomnessAndSeed(dlgParams.Seed,dlgParams.Randomness);

%% Initialization
p.NumParticles = localValidateNumberOfParticles(dlgParams.NumberOfParticles, p.DataType);
% Set Particles, Weights, IsStateVariableCircular, NumStates
p = localValidateInitialDistributionParticlesWeights(dlgParams,particleManager,p);

%% Resampling
p.ResamplingMethod = localValidateResamplingMethod(dlgParams.ResamplingMethod);
[p.TriggerMethod, p.SamplingInterval, p.MinEffectiveParticleRatio] = ...
    localValidateTriggerMethod(...
    dlgParams.TriggerMethod,...
    dlgParams.SamplingInterval,...
    dlgParams.MinEffectiveParticleRatio,...
    p.DataType);

%% Sample times
p.SampleTimes = matlabshared.tracking.internal.blocks.validateSampleTime(blkH,dlgParams);

%% Functions
[p.StateTransitionFcn, p.MeasurementFcn] = matlabshared.tracking.internal.blocks.validateFcns(dlgParams);

%% Outputs
p.StateEstimationMethod = localValidateStateEstimationMethod(dlgParams.StateEstimationMethod);
p.OutputStateCovariance = localValidateOutputStateCovariance(dlgParams.OutputStateCovariance,p.StateEstimationMethod);

%% Convert option strings to lower-case to make them match with command-line object
p.ResamplingMethod = lower(p.ResamplingMethod);
p.TriggerMethod = lower(p.TriggerMethod);
p.StateEstimationMethod = lower(p.StateEstimationMethod);

%% Data for signal check blocks
signalCheck = localGetSignalCheckData(blkH, dlgParams, p);
end

function [isStateOrientationColumn,particleManager] = localGetParticleManager(stateOrientation)
switch stateOrientation
    case slsvInternal('slsvGetEnStringFromCatalog','shared_tracking:blocks:maskPromptPFColumn')
        isStateOrientationColumn = true();
    case slsvInternal('slsvGetEnStringFromCatalog','shared_tracking:blocks:maskPromptPFRow')
        isStateOrientationColumn = false();
    otherwise
        assert(false);
end
particleManager = matlabshared.tracking.internal.ParticleFilter.initializeParticleManager(isStateOrientationColumn);
end

function resamplingMethod = localValidateResamplingMethod(resamplingMethod)
% Ensure the string we have is in EN locale
switch resamplingMethod
    case  {slsvInternal('slsvGetEnStringFromCatalog','shared_tracking:blocks:maskPromptPFMultinomial');
           slsvInternal('slsvGetEnStringFromCatalog','shared_tracking:blocks:maskPromptPFSystematic');
           slsvInternal('slsvGetEnStringFromCatalog','shared_tracking:blocks:maskPromptPFStratified');
           slsvInternal('slsvGetEnStringFromCatalog','shared_tracking:blocks:maskPromptPFResidual')}
       % Ensure resamplingMethod is char (not string)
       % * This matches with command-line behavior
       % * MLFcn block does not support passing strings in and out
       resamplingMethod = char(resamplingMethod);
    otherwise
        assert(false);
end
end

function [triggerMethod,samplingInterval,minEffParticleRatio] = ...
    localValidateTriggerMethod(triggerMethod,samplingInterval,minEffParticleRatio,dataType)
% Ensure the string we have is in EN locale
switch triggerMethod
    case slsvInternal('slsvGetEnStringFromCatalog','shared_tracking:blocks:maskPromptPFRatio')
        minEffParticleRatio = localVerifyMinEffectiveParticleRatio(minEffParticleRatio,dataType);
        samplingInterval = cast(0,dataType);
    case slsvInternal('slsvGetEnStringFromCatalog','shared_tracking:blocks:maskPromptPFInterval')
        minEffParticleRatio = cast(0,dataType);
        samplingInterval = localVerifySamplingInterval(samplingInterval,dataType);
    otherwise
        assert(false);
end
% Ensure triggerMethod is char (not string)
% * This matches with command-line behavior
% * MLFcn block does not support passing strings in and out
triggerMethod = char(triggerMethod);
end

function [seed,randomNumberGenerator] = localValidateRandomnessAndSeed(seed,randomness)

% We set and initialize the random number generator via
% rng(seed,randomNumberGenerator). Use the Mersenne Twister. It's the
% default in MATLAB, and supports codegen in the function rng()
randomNumberGenerator = 'twister';

% Verify the Randomness combobox. If user provided a Seed, also verify that 
switch randomness
    case slsvInternal('slsvGetEnStringFromCatalog','shared_tracking:blocks:maskPromptPFRepeatable')
        % user provided seed, verify
        fieldName = matlabshared.tracking.internal.blocks.getFieldName('shared_tracking:blocks:maskPromptPFSeed');
        if isempty(seed)
            error(message('shared_tracking:blocks:errorExpectedNonempty', fieldName));
        end        
        if ~isnumeric(seed)
            error(message('shared_tracking:blocks:errorExpectedNumeric', fieldName));
        end
        if ~isscalar(seed)
            error(message('shared_tracking:blocks:errorExpectedScalar', fieldName));
        end
        if ~isreal(seed)
            error(message('shared_tracking:blocks:errorExpectedReal', fieldName));
        end        
        if ~isfinite(seed)
            error(message('shared_tracking:blocks:errorExpectedFinite', fieldName));
        end
        if floor(seed)~=seed
            error(message('shared_tracking:blocks:errorExpectedInteger', fieldName));
        end
        if seed<0
            error(message('shared_tracking:blocks:errorExpectedNonnegative', fieldName));
        end
        if seed>2^32-1
            error(message('shared_tracking:blocks:errorNotLessEqual', fieldName, 2^32-1, seed));
        end
        
        if issparse(seed)
            seed = full(seed);
        end        
    case slsvInternal('slsvGetEnStringFromCatalog','shared_tracking:blocks:maskPromptPFNotRepeatable')
        % generate a seed in [0 (2^32)-1]
        seed = randi(2^32,1)-1;
    otherwise % unexpected value in Randomness combobox
        assert(false);
end

% Cast to uint32
% * This is what rng() expects. Otherwise generated C/C++ code includes
% type casting from double, with overflow protection. These are unnecessary
% due to checks here.
% * In addition, when generating single-precision code, not perofrming this
% cast leaves a double-precision variable in generated code
seed = uint32(seed);
end


function m = localValidateStateEstimationMethod(m)
% Ensure the string we have is in EN locale
switch m
    case {slsvInternal('slsvGetEnStringFromCatalog','shared_tracking:blocks:maskPromptPFStateEstMethodMean');
          slsvInternal('slsvGetEnStringFromCatalog','shared_tracking:blocks:maskPromptPFStateEstMethodMaxWeight');
          slsvInternal('slsvGetEnStringFromCatalog','shared_tracking:blocks:maskPromptPFStateEstMethodNone')}
       % Ensure StateEstimationMethod is char (not string)
       % * This matches with command-line behavior
       % * MLFcn block does not support passing strings in and out
       m = char(m);
    otherwise
        assert(false);
end
end

function outputStateCovariance = localValidateOutputStateCovariance(outputStateCovariance,stateEstimationMethod)

% We can output state covariance only when the state estimation method is
% mean
switch stateEstimationMethod
    case slsvInternal('slsvGetEnStringFromCatalog','shared_tracking:blocks:maskPromptPFStateEstMethodMean')
        outputStateCovariance = logical(outputStateCovariance);
    case {slsvInternal('slsvGetEnStringFromCatalog','shared_tracking:blocks:maskPromptPFStateEstMethodMaxWeight');...
            slsvInternal('slsvGetEnStringFromCatalog','shared_tracking:blocks:maskPromptPFStateEstMethodNone')}
        % 'maxweight' and 'none' options do not have state covariance
        outputStateCovariance = false();
    otherwise
        assert(false);
end
end

function d = localValidateDataType(d)
% DataType must be 'single' or 'double', regardless of locale
d = validatestring(d,{'double','single'});
end

function n = localValidateNumberOfParticles(n,dataType)

fieldName = matlabshared.tracking.internal.blocks.getFieldName('shared_tracking:blocks:maskPromptPFNumParticles');
if isempty(n)
    error(message('shared_tracking:blocks:errorExpectedNonempty', fieldName));
end
if ~isnumeric(n)
    error(message('shared_tracking:blocks:errorExpectedNumeric', fieldName));
end
if ~isscalar(n)
    error(message('shared_tracking:blocks:errorExpectedScalar', fieldName));
end
if ~isreal(n)
    error(message('shared_tracking:blocks:errorExpectedReal', fieldName));
end
if ~isfinite(n)
    error(message('shared_tracking:blocks:errorExpectedFinite', fieldName));
end
if floor(n)~=n
    error(message('shared_tracking:blocks:errorExpectedInteger', fieldName));
end
if n<1
    error(message('shared_tracking:blocks:errorExpectedPositive', fieldName));
end
% MaskInit code of the PF's Correct block assumes n can fit into int32.
% Changing this requires changing the MaskInit code there, and the C++
% S-Function responsible for registering Simulink Fcns
% (pfRegisterSimulinkFcn)
if n>intmax('int32')
    error(message('shared_tracking:blocks:errorNotLessEqual', fieldName, intmax('int32'), n));
end

% No support for sparse matrices in block code and ML/SL Coder
if issparse(n)
    n = full(n);
end
% NumberOfParticles is used in various expressions that require floating
% point variables. Leave it as a floating point variable, but cast it to
% the data type of the filter (single or double)
n = cast(n,dataType);
end


function stateBounds = localValidateStateBounds(stateBounds,dataType)
% Must be kept in sync with:
% matlabshared.tracking.internal.ParticleFilterInputParser.validStateBounds

fieldName = matlabshared.tracking.internal.blocks.getFieldName('shared_tracking:blocks:maskPromptPFStateBounds');
if isempty(stateBounds)
    error(message('shared_tracking:blocks:errorExpectedNonempty', fieldName));
end
if ~isnumeric(stateBounds)
    error(message('shared_tracking:blocks:errorExpectedNumeric', fieldName));
end
if ~ismatrix(stateBounds)
    error(message('shared_tracking:blocks:errorExpectedMatrix', fieldName));
end
if size(stateBounds,2)~=2
    error(message('shared_tracking:blocks:errorIncorrectNumberOfColumns', fieldName, 2, size(stateBounds,2)));
end
if ~isreal(stateBounds)
    error(message('shared_tracking:blocks:errorExpectedReal', fieldName));
end
if ~all(all(isfinite(stateBounds)))
    error(message('shared_tracking:blocks:errorExpectedFinite', fieldName));
end
if issparse(stateBounds)
    error(message('shared_tracking:blocks:errorExpectedNonsparse', fieldName));
end

stateBounds = cast(stateBounds,dataType);
end

function circularVariables = localValidateCircularVariables(circularVariables,numberOfStates)
% Must be kept in sync with:
% matlabshared.tracking.internal.ParticleFilterInputParser.validateNameValuePairCircularVariables

fieldName = matlabshared.tracking.internal.blocks.getFieldName('shared_tracking:blocks:maskPromptCircularVariables');
if isempty(circularVariables)
    error(message('shared_tracking:blocks:errorExpectedNonempty', fieldName));
end
if ~isnumeric(circularVariables) && ~islogical(circularVariables)
    error(message('shared_tracking:blocks:errorExpectedNumericOrLogical', fieldName));
end
if ~isvector(circularVariables)
    error(message('shared_tracking:blocks:errorExpectedVector', fieldName));
end
if ~isreal(circularVariables)
    error(message('shared_tracking:blocks:errorExpectedReal', fieldName));
end
if ~all(isfinite(circularVariables))
    error(message('shared_tracking:blocks:errorExpectedFinite', fieldName));
end
if isscalar(circularVariables) % Scalar expansion
    circularVariables = repmat(circularVariables,1,numberOfStates);
elseif numel(circularVariables)~=numberOfStates
    error(message('shared_tracking:blocks:errorIncorrectNumel', fieldName, numberOfStates, numel(circularVariables)));
end

% Covert to a logical row vector
circularVariables = logical(circularVariables);
if iscolumn(circularVariables)
    circularVariables = circularVariables.';
end
end

function mean = localValidateMean(mean,dataType)
% Must be kept in sync with:
% matlabshared.tracking.internal.ParticleFilterInputParser.validateMean
fieldName = matlabshared.tracking.internal.blocks.getFieldName('shared_tracking:blocks:maskPromptPFMean');
if ~isnumeric(mean)
    error(message('shared_tracking:blocks:errorExpectedNumeric', fieldName));
end
if isempty(mean)
    error(message('shared_tracking:blocks:errorExpectedNonempty', fieldName));
end
if ~isvector(mean)
    error(message('shared_tracking:blocks:errorExpectedVector', fieldName));
end
if ~isreal(mean)
    error(message('shared_tracking:blocks:errorExpectedReal', fieldName));
end
if ~all(isfinite(mean))
    error(message('shared_tracking:blocks:errorExpectedFinite', fieldName));
end

% Convert to a row vector of desired type
mean = cast(mean,dataType);
if iscolumn(mean)
    mean = mean.';
end
if issparse(mean)
    mean = full(mean);
end
end

function p = localValidateInitialDistributionParticlesWeights(dlgParams,particleManager,p)

% Initialization involves random number generation, unless user provided
% the initial set of particles directly. 
% * Use the seed specified in block dialog
% * Ensure we're not changing the base MATLAB's rng state
oldRNGState = rng();
restoreRNGStateObj = onCleanup(@() rng(oldRNGState));
rng(p.Seed,p.RandomNumberGenerator);

switch dlgParams.InitialDistribution
    case slsvInternal('slsvGetEnStringFromCatalog','shared_tracking:blocks:maskPromptPFGaussian')
        dlgParams.InitialMean = localValidateMean(dlgParams.InitialMean,p.DataType);
        p.NumStates = numel(dlgParams.InitialMean);
        p.IsStateVariableCircular = localValidateCircularVariables(dlgParams.CircularVariables,p.NumStates);
        dlgParams.InitialCovariance = matlabshared.tracking.internal.blocks.validateCovariance(...
            dlgParams.InitialCovariance, ...
            true(), ...% enforce strict positive definiteness
            p.NumStates, ...
            p.DataType, ...
            matlabshared.tracking.internal.blocks.getFieldName('shared_tracking:blocks:maskPromptCovariance'));
        
        p.Particles = particleManager.allocateMemoryParticles(p.NumParticles,p.NumStates,p.DataType);
        p.Weights = particleManager.getUniformWeights(p.NumParticles,p.DataType);
        
        numCircular = nnz(p.IsStateVariableCircular);
        numNonCircular = p.NumStates - numCircular;
        
        % Sample for non-circular state variables
        if numNonCircular > 0
            normalDistr = matlabshared.tracking.internal.NormalDistribution(numNonCircular);
            normalDistr.Mean = dlgParams.InitialMean(~p.IsStateVariableCircular);
            normalDistr.Covariance = dlgParams.InitialCovariance(~p.IsStateVariableCircular, ~p.IsStateVariableCircular);
            p.Particles = particleManager.setStates(...
                p.Particles, ...
                ~p.IsStateVariableCircular, ...
                normalDistr.sample(p.NumParticles, particleManager.StateOrientation));
        end
        % Sample for circular state variables
        if numCircular > 0
            wrappedNormalDistr =  matlabshared.tracking.internal.WrappedNormalDistribution(numCircular);
            wrappedNormalDistr.Mean = dlgParams.InitialMean(p.IsStateVariableCircular);
            wrappedNormalDistr.Covariance = dlgParams.InitialCovariance(p.IsStateVariableCircular, p.IsStateVariableCircular);
            p.Particles = particleManager.setStates(...
                p.Particles, ...
                p.IsStateVariableCircular, ...
                wrappedNormalDistr.sample(p.NumParticles, particleManager.StateOrientation));
        end
        
    case slsvInternal('slsvGetEnStringFromCatalog','shared_tracking:blocks:maskPromptPFUniform')
        p.StateBounds = localValidateStateBounds(dlgParams.InitialStateBounds,p.DataType);
        p.NumStates = size(p.StateBounds,1);
        p.IsStateVariableCircular = localValidateCircularVariables(dlgParams.CircularVariables,p.NumStates);
        p.StateBounds = matlabshared.tracking.internal.ParticleFilterInputParser.validateStateBoundsLimits(p.StateBounds, p.IsStateVariableCircular);
        
        % Pre-allocate space
        p.Particles = particleManager.allocateMemoryParticles(p.NumParticles,p.NumStates,p.DataType);
        p.Weights = particleManager.getUniformWeights(p.NumParticles,p.DataType);
        
        numCircular = sum(p.IsStateVariableCircular);
        numNonCircular = length(p.IsStateVariableCircular) - numCircular;
        
        % Sample for non-circular state variables
        if numNonCircular > 0
            uniformDistr = matlabshared.tracking.internal.UniformDistribution(numNonCircular);
            uniformDistr.RandomVariableLimits = p.StateBounds(~p.IsStateVariableCircular,:);
            p.Particles = particleManager.setStates(...
                p.Particles, ...
                ~p.IsStateVariableCircular, ...
                uniformDistr.sample(p.NumParticles, particleManager.StateOrientation));
        end
        % Sample for circular state variables
        if numCircular > 0
            wrappedUniformDistr = matlabshared.tracking.internal.WrappedUniformDistribution(numCircular);
            wrappedUniformDistr.RandomVariableLimits = p.StateBounds(p.IsStateVariableCircular,:);
            p.Particles = particleManager.setStates(...
                p.Particles, ...
                p.IsStateVariableCircular, ...
                wrappedUniformDistr.sample(p.NumParticles, particleManager.StateOrientation));
        end
        
    case slsvInternal('slsvGetEnStringFromCatalog','shared_tracking:blocks:maskPromptPFCustom')
        % No dimension checks for Particles, we take it as the truth for
        % all checks
        
        if strcmp(particleManager.StateOrientation,'column')
            isStateOrientationColumn = true();
        else
            isStateOrientationColumn = false();
        end        
        
        % Validate Weights       
        fieldName = matlabshared.tracking.internal.blocks.getFieldName('shared_tracking:blocks:maskPromptPFWeights');
        if isempty(dlgParams.Weights)
            error(message('shared_tracking:blocks:errorExpectedNonempty', fieldName));
        end
        if ~isfloat(dlgParams.Weights)
            error(message('shared_tracking:blocks:errorExpectedFloat', fieldName, class(dlgParams.Weights)));
        end
        if ~isreal(dlgParams.Weights)
            error(message('shared_tracking:blocks:errorExpectedReal', fieldName));
        end
        if ~isvector(dlgParams.Weights)
            error(message('shared_tracking:blocks:errorExpectedVector', fieldName));
        end
        if ~all(isfinite(dlgParams.Weights))
            error(message('shared_tracking:blocks:errorExpectedFinite', fieldName));
        end
        if ~all(dlgParams.Weights>0)
            error(message('shared_tracking:blocks:errorExpectedPositive', fieldName));
        end
        if issparse(dlgParams.Weights)
            error(message('shared_tracking:blocks:errorExpectedNonsparse', fieldName));
        end
        if numel(dlgParams.Weights)~=p.NumParticles
            error(message('shared_tracking:blocks:errorIncorrectNumel', fieldName, p.NumParticles, numel(dlgParams.Weights)));
        end
        if isStateOrientationColumn
            if isrow(dlgParams.Weights)
                p.Weights = dlgParams.Weights;
            else
                p.Weights = dlgParams.Weights.';
            end
        else
            if iscolumn(dlgParams.Weights)
                p.Weights = dlgParams.Weights;
            else
                p.Weights = dlgParams.Weights.';
            end
        end
        % Normalize. No risk of div. by 0 because we checked all(Weights>0)
        p.Weights = p.Weights / sum(p.Weights);
        
        % Validate particles
        fieldName = matlabshared.tracking.internal.blocks.getFieldName('shared_tracking:blocks:maskPromptPFParticles');
        if isempty(dlgParams.Particles)
            error(message('shared_tracking:blocks:errorExpectedNonempty', fieldName));
        end
        if ~isfloat(dlgParams.Particles)
            error(message('shared_tracking:blocks:errorExpectedFloat', fieldName, class(dlgParams.Particles)));
        end
        if ~isreal(dlgParams.Particles)
            error(message('shared_tracking:blocks:errorExpectedReal', fieldName));
        end
        if ~ismatrix(dlgParams.Particles)
            error(message('shared_tracking:blocks:errorExpectedMatrix', fieldName));
        end
        if ~all(all(isfinite(dlgParams.Particles)))
            error(message('shared_tracking:blocks:errorExpectedFinite', fieldName));
        end
        if issparse(dlgParams.Particles)
            error(message('shared_tracking:blocks:errorExpectedNonsparse', fieldName));
        end
        if isStateOrientationColumn
            if size(dlgParams.Particles,2)~=p.NumParticles
                error(message('shared_tracking:blocks:errorIncorrectNumberOfColumns', fieldName, p.NumParticles, size(dlgParams.Particles,2)));
            end
            p.NumStates = size(dlgParams.Particles,1);
        else
            if size(dlgParams.Particles,1)~=p.NumParticles
                error(message('shared_tracking:blocks:errorIncorrectNumberOfRows', fieldName, p.NumParticles, size(dlgParams.Particles,1)));
            end
            p.NumStates = size(dlgParams.Particles,2);
        end
        
        % Validate IsStateVariableCircular 
        p.IsStateVariableCircular = localValidateCircularVariables(dlgParams.CircularVariables,p.NumStates);
        
        % Make the assignment, ensure the circular vars are wrapped
        p.Particles = dlgParams.Particles;
        p.Particles = particleManager.setStates(...
            p.Particles, ...
            p.IsStateVariableCircular, ...
            matlabshared.tracking.internal.wrapToPi(particleManager.getStates(p.Particles, p.IsStateVariableCircular)) );
    otherwise
        assert(false);
end

% MaskInit code of the PF's Correct block assumes NumStates can fit into
% int32. Changing this requires changing the MaskInit code there, and the
% C++ S-Function responsible for registering Simulink Fcns (pfRegisterSimulinkFcn)
if p.NumStates>intmax('int32')
    error(message('shared_tracking:blocks:errorMaxNumberOfStates'));
end

% Enforce the correct data type
p.Particles = cast(p.Particles,p.DataType);
p.Weights = cast(p.Weights,p.DataType);
end

function u = localVerifyMinEffectiveParticleRatio(u,dataType)
% This must be in sync with set.MinEffectiveParticleRatio in
% matlabshared.tracking.internal.ResamplingPolicy

fieldName = matlabshared.tracking.internal.blocks.getFieldName('shared_tracking:blocks:maskPromptPFMinEffectiveParticleRatio');
if isempty(u)
    error(message('shared_tracking:blocks:errorExpectedNonempty', fieldName));
end
if ~isnumeric(u)
    error(message('shared_tracking:blocks:errorExpectedNumeric', fieldName));
end
if ~isscalar(u)
    error(message('shared_tracking:blocks:errorExpectedScalar', fieldName));
end
if ~isreal(u)
    error(message('shared_tracking:blocks:errorExpectedReal', fieldName));
end
if ~isfinite(u)
    error(message('shared_tracking:blocks:errorExpectedFinite', fieldName));
end
if u<0
    error(message('shared_tracking:blocks:errorExpectedNonnegative', fieldName));
end
if u>1
    error(message('shared_tracking:blocks:errorNotLessEqual', fieldName, '1', sprintf('%.4f',u)));
end


if issparse(u)
    u = full(u);
end
% Enforce the correct data type
u = cast(u,dataType);
end

function u = localVerifySamplingInterval(u,dataType)
% This must be in sync with set.SamplingInterval in
% matlabshared.tracking.internal.ResamplingPolicy

fieldName = matlabshared.tracking.internal.blocks.getFieldName('shared_tracking:blocks:maskPromptPFSamplingInterval');
if ~isnumeric(u)
    error(message('shared_tracking:blocks:errorExpectedNumeric', fieldName));
end
if isempty(u)
    error(message('shared_tracking:blocks:errorExpectedNonempty', fieldName));
end
if ~isscalar(u)
    error(message('shared_tracking:blocks:errorExpectedScalar', fieldName));
end
if ~isreal(u)
    error(message('shared_tracking:blocks:errorExpectedReal', fieldName));
end
if isnan(u)
    error(message('shared_tracking:blocks:errorExpectedNonNaN', fieldName));
end
if u<0
    error(message('shared_tracking:blocks:errorNotGreaterEqual', fieldName, 0, sprintf('%.4f',u)));
end
if floor(u)~=u
    error(message('shared_tracking:blocks:errorExpectedInteger', fieldName));
end

if issparse(u)
    u = full(u);
end
% Enforce the correct data type
u = cast(u,dataType);
end

function signalCheck = localGetSignalCheckData(blkH, dlgParams, p)
% Gather data required for the signal check S-Fcns. The data types used
% here must match with the types required in ekfukfCheckSignals.cpp

signalCheck.BlockPath = getfullname(blkH);
signalCheck.DataType = matlabshared.tracking.internal.blocks.getSSDataType(p.DataType);
signalCheck.StateTransitionFcn.PortDimensions = {int32(-1)};

% State fcn
signalCheck.StateTransitionFcn.PortNames = {'StateTransitionFcnInputs'};
signalCheck.StateTransitionFcn.SampleTime = p.SampleTimes.StateTransitionFcn;

% MeasurementFcn
signalCheck.MeasurementFcn = cell(dlgParams.NumberOfMeasurements,1);
for kk=1:dlgParams.NumberOfMeasurements
    % Enable port is always scalar. We never know the dims of last 2 signals
    signalCheck.MeasurementFcn{kk}.PortDimensions = {int32(1),int32(-1),int32(-1)};
    % Port names
    signalCheck.MeasurementFcn{kk}.PortNames = {...
        sprintf('Enable%d',kk),...
        sprintf('y%d',kk),...
        sprintf('MeasurementFcn%dInputs',kk)};
    % Sample time
    signalCheck.MeasurementFcn{kk}.SampleTime = p.SampleTimes.MeasurementFcn(kk);
end
end
