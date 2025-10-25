function throwStringInputValidationError(msgKey,varargin)
% This function is undocumented and may change in a future release.

% Copyright 2017-2022 The MathWorks, Inc.
if nargin > 1
    prefix = 'InvalidValue';
else
    prefix = '';
end
throwAsCaller(MException(...
    message(['MATLAB:automation:StringInputValidation:' prefix msgKey],varargin{:})));
end