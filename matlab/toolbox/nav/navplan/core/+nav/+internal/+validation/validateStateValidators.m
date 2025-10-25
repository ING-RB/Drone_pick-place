function validateStateValidators(validator, fcnName, varName)
%This function is for internal use only. It may be removed in the future.

%validateStateValidators Validate a validatorOccupancyMap,
% validatorVehicleCostmap and validatorOccupancyMap3D objects.
% It is being used by pathmetrics.m

%   Copyright 2019-2023 The MathWorks, Inc.

    validateattributes(validator, {'validatorOccupancyMap', 'validatorVehicleCostmap','validatorOccupancyMap3D'}, {"nonempty", "scalar"}, ...
                       fcnName, varName); 

end
