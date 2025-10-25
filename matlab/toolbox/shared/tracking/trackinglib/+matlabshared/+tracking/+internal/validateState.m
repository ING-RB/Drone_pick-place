%#codegen

% Copyright 2016-2020 The MathWorks, Inc.

function validateState(value, len)
  validateattributes(value, ...
    {'single', 'double'}, ...
    {'real', 'finite', 'nonsparse', 'vector'},...
    'KalmanFilter', 'State');
  
  isInvalid = ~isscalar(value) && numel(value)~=len;
  coder.internal.errorIf(isInvalid, ...
    'shared_tracking:KalmanFilter:invalidStateDims', len);
end
