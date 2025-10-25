function isValid = validateCallback(callback)
% VALIDATECALLBACK  Determines whether the inputted callback is valid. This 
% includes checks for all acceptable callback types.

% Copyright 2021, MathWorks Inc.

isValid = internal.Callback.validate(callback);

if ~isValid
    error(message('MATLAB:datatypes:callback:CreateCallback'));
end

end
