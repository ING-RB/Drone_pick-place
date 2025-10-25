%#codegen
    
% Copyright 2016-2020 The MathWorks, Inc.
    
function validateDataAttributes(name, value)
  validateattributes(value, ...
    {'single', 'double'}, ...
    {'real', 'finite', 'nonsparse', '2d', 'nonempty'},...
    'KalmanFilter', name);
end
