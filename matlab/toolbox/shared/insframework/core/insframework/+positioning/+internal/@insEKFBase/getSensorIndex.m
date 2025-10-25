function idx = getSensorIndex(~, sensor)
%   This function is for internal use only. It may be removed in the future. 
%GETSENSORINDEX Return the index of SENSOR in filt.SENSORS

%   Copyright 2021 The MathWorks, Inc.      

%#codegen   

% We can't just for-loop over the Sensors property searching for the right
% sensor - that doesn't work in codegen. Instead each property is given a
% ListIndex property in the base class which is populated at compile()
% time. The ListIndex property is nontunable (i.e. a constant in the
% generated code). Error out if the ListIndex has not been set.


% There is no simulation semantic (implementation) for
% coder.internal.prop_has_class, so build a MATLAB and codegen version. 
% Throw an error if the ListIndex is not set.

if ~isempty(coder.target)
    % This happens at compile time (when the user calls codegen)
    def = coder.internal.prop_has_class(sensor, 'ListIndex');
    coder.internal.assert(def, 'insframework:insEKF:SensorNotFound');
    % Even though prop_has_class should be enough, we need an
    % assertDefined to avoid a def before use error. We know at this point
    % that ListIndex is indeed defined because the previous line did not
    % assert.
    coder.assumeDefined(sensor.ListIndex); 
    idx = sensor.ListIndex;

else
    coder.internal.assert(~isempty(sensor.ListIndex), ...
        'insframework:insEKF:SensorNotFound');
    idx = sensor.ListIndex;

end
