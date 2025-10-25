function jacobian = numericJacobian(func, vec, inputToDerive, direction, relativeStep)
%numericJacobian  calculates the Jacobian dfunc/dvec{inputToDerive}.
% This function approximates the Jacobian matrix of a function, func, about
% the point specified by vec{inputToDerive}. 
%
% Inputs:
%   func            - a handle to the function.
%   vec             - a cell array of input arguments to func. 
%   inputToDerive   - the index of the input in vec, about which to derive.
%                       If not given, the value is assumed to be 1.
%   direction       - derivation direction. Valid values are: 'forward',
%                       'backward', and 'middle'. If not given, the value
%                       is assumed to be 'forward'.
%   relativeStep    - the size of the step, delta, for the derivation. If
%                       not given, the value is assumed to be 10*(eps) of
%                       the class of vec{inputToDerive}
%
% Output:
%   jacobian = d(func) / d(vec{inputToDerive}) evaluated @ the point vec{:}

%   Copyright 2016 The MathWorks, Inc.

%#codegen

% Since inputParser is not supported by codegen, parse inputs manually
narginchk(2, 5); %Throw an error if less than 2 inputs are given

switch nargin %simple parsing
    case 2 
        inputToDerive = 1;
        direction     = 'forward';        
    case 3 
        direction     = 'forward';
end

if isempty(inputToDerive)
    inputToDerive = 1;
end

% Until g1354323 is resolved, nargin(fcn) not supported by coder
if coder.target('MATLAB') 
    coder.internal.errorIf(nargin(func) ~= numel(vec) && nargin(func) > 0, ...
        'shared_tracking:ExtendedKalmanFilter:NumberOfInputsToNumericJacobian',...
        nargin(func), numel(vec));
    coder.internal.errorIf(inputToDerive > numel(vec), ...
        'shared_tracking:ExtendedKalmanFilter:DeriveByNonexistentInput',...
        numel(vec), inputToDerive);
end

if nargin < 5
    relativeStep  = sqrt(eps(class(vec{inputToDerive})));
end

switch direction
    case 'forward'
        delta = relativeStep;
        sign  = 1;
    case 'backward'
        delta = relativeStep;
        sign  = -1; %backward
    case 'middle'
        delta = relativeStep/2; %half a step
        sign  = 1;
    otherwise
        delta = relativeStep;
        sign = 1;
end

z = func(vec{:});
m = length(z);
n = length(vec{inputToDerive});
jacobian = zeros(m,n, class(vec{inputToDerive}));
specvec = vec;
for j = 1:n
    imvec = vec{inputToDerive};
    epsilon = sign * max(delta,delta*abs(imvec(j)));
    imvec(j) = imvec(j) + epsilon;
    specvec{inputToDerive} = imvec;
    imz = func(specvec{:});
    if strcmp(direction, 'middle') %Calculate z with half a step backward
        epsilon = -2 * epsilon; %was 1/2 step forward, now 2 halves back
        imvec(j) = imvec(j) - epsilon;
        specvec{inputToDerive} = imvec;
        z = func(specvec{:});        
    end
    deltaz = imz-z;
    jacobian(:, j) = deltaz(:)/epsilon;
end