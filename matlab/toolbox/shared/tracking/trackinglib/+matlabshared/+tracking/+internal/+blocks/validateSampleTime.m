function Ts = validateSampleTime(blkH, dlgParams)
% Validate the sample time of the EKF/UKF/PF blocks

%   Copyright 2017-2022 The MathWorks, Inc.

Ts.MeasurementFcn = zeros(dlgParams.NumberOfMeasurements,1);
if dlgParams.EnableMultirate
    % * EnableMultiTasking must be 'off'
    % * Multirate cannot inherit its Ts.
    % * Must ensure MeasFcn Ts are a constant integer multiple of STFcn Ts
    
    % EnableMultiTasking must be off. The option is enabled only when:
    % * SolverType is 'Fixed-Step'
    %      AND
    %  * SampleTimeConstraint is 'Unconstrained' or 'Specified'
    %      AND
    %  * (EnableConcurrentExecution is 'off') OR (ConcurrentTasks is 'off')
    modelH = bdroot(blkH);
    if strcmp(get_param(modelH,'SolverType'),slsvInternal('slsvGetEnStringFromCatalog','RTW:configSet:configSetParamEnumSolver_TypeF')) && ...
            any(strcmp(get_param(modelH,'SampleTimeConstraint'),{slsvInternal('slsvGetEnStringFromCatalog','RTW:configSet:configSetParamEnumSolver_SampleC_Unconstrained'),slsvInternal('slsvGetEnStringFromCatalog','RTW:configSet:configSetParamEnumSolver_SampleC_Specified')})) && ...
            (strcmp(get_param(modelH,'EnableConcurrentExecution'),'off') || strcmp(get_param(modelH,'ConcurrentTasks'),'off')) && ...
            strcmp(get_param(modelH,'EnableMultiTasking'),'on')
        error(message('shared_tracking:blocks:errorMultirateEnableMultiTasking'));
    end
    
    validatedTs = localValidateSampleTime(dlgParams.StateTransitionFcnSampleTime, ...
        getString(message('shared_tracking:blocks:errorPromptStateTransitionTs')));
    Ts.StateTransitionFcn = validatedTs;
    Ts.Output = validatedTs;
    
    for kk=1:dlgParams.NumberOfMeasurements
        Ts.MeasurementFcn(kk) = localValidateSampleTime(dlgParams.MeasurementFcnSampleTime{kk}, ...
            getString(message('shared_tracking:blocks:errorPromptMeasurementTs',kk)));
    end
    
    % Ensure measurement sample times are a constant multiple of
    % state transition sample time
    ratioTs = Ts.MeasurementFcn/Ts.StateTransitionFcn;
    isNotIntegerMultiple = abs(round(ratioTs)./ratioTs - 1)>1e-6;
    if any(isNotIntegerMultiple)
        error(message('shared_tracking:blocks:errorNonIntegerMultipleSampleTime', mat2str(find(isNotIntegerMultiple)) ));
    end
else
    % Single rate: Everything has the same rate
    validatedTs = localValidateSampleTime(dlgParams.SampleTime, ...
        getString(message('shared_tracking:blocks:maskPromptSampleTime')) );
    Ts.StateTransitionFcn = validatedTs;
    Ts.Output = validatedTs;
    Ts.MeasurementFcn(:) = validatedTs;
end

end

function Ts = localValidateSampleTime(Ts,fieldName)
% localValidateSampleTime Validate a sample time specification Ts
if ~isfloat(Ts)
    error(message('shared_tracking:blocks:errorExpectedFloat', fieldName, class(Ts)));
end
if isempty(Ts)
    error(message('shared_tracking:blocks:errorExpectedNonempty', fieldName));
end
if ~isreal(Ts)
    error(message('shared_tracking:blocks:errorExpectedReal', fieldName));
end
if ~isscalar(Ts)
    error(message('shared_tracking:blocks:errorExpectedScalar', fieldName));
end
if ~isfinite(Ts)
    error(message('shared_tracking:blocks:errorExpectedFinite', fieldName));
end
% Allowing Ts = -1 so that the filter blocks can run inside a triggered
% subsystem, which is typical for AUTOSAR simulations.
if Ts <= 0 && Ts ~= -1 
    error(message('shared_tracking:blocks:errorExpectedPositive', fieldName));
end
end
