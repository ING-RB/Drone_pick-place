function filtparams = makeFilterParameters(obj,measNoise, customCost)
%   This function is for internal use only. It may be removed in the future. 
%MAKEFILTERPARAMS create the filter parameters structure
%	  Creates the filter parameters structure used internally by the
%	  TUNE function. This function is also used by the mex generation
%	  build infrastructure. 
%
%     In customCost == true mode, all parameters are included in
%     filtparams. In customCost == false mode, we omit the OrientationFormat
%     parameter for ahrsfilter and imufilter because it is not tolerated by
%     our mex infrastructure. 


%   Copyright 2020-2021 The MathWorks, Inc.    

    % Initialize filtparams structure
    [defaultParams2Tune, defaultStaticParams] = obj.getParamsForAutotuneFromInst;
    allObjParams = [defaultParams2Tune, defaultStaticParams];
    measNames = fieldnames(measNoise);
    p1 = setdiff(allObjParams, measNames); 
    filtparams = measNoise;
    filtparams = copyToStruct(obj, filtparams, p1);
    
    % We force the OrientationFormat to quaternions when necessary. Remove
    % it from the params if necessary.
    if ~customCost && isfield(filtparams, 'OrientationFormat')
        filtparams = rmfield(filtparams, 'OrientationFormat');
    end

    if isa(obj, 'insEKF')
        % Remove handle properties. They'll break codegen
        filtparams = rmfield(filtparams, 'MotionModel');
        filtparams = rmfield(filtparams, 'Sensors');
    end

    %g2278743 - fix the order of the fields in params struct
    filtparams = orderfields(filtparams);
end

function s = copyToStruct(obj, s, fields)
%COPYTOSTRUCT Copy fields from object obj to struct s
    for ii=1:numel(fields)
        s.(fields{ii}) = obj.(fields{ii});
    end
end
