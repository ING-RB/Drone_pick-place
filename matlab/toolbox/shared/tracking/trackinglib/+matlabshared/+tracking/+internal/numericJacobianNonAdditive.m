function jacobian = numericJacobianNonAdditive(func, x, v, vec, inputToDerive, direction, relativeStep)
%numericJacobian  calculates the Jacobian dfunc/dvec{inputToDerive}.
% x or v can also be vec{inputToDerive}.
% This function approximates the Jacobian matrix of a function, func, about
% the point specified by vec{inputToDerive}. This version is specifically
% applicable for the non-additive noise case.
%
% Inputs:
%   func            - a handle to the function.
%   x               - first argument of function to be perturbed
%   v               - second argument of function to be perturbed
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

%   Copyright 2020 The MathWorks, Inc.

%#codegen

% Since inputParser is not supported by codegen, parse inputs manually
narginchk(4, 7); %Throw an error if less than 4 inputs are given

switch nargin %simple parsing
    case 4 
        inputToDerive = 1;
        direction     = 'forward';        
    case 5 
        direction     = 'forward';
end

if isempty(inputToDerive)
    inputToDerive = 1;
end

% Until g1354323 is resolved, nargin(fcn) not supported by coder
if coder.target('MATLAB') 
    coder.internal.errorIf((nargin(func) > 0 && nargin(func) ~= (numel(vec) + 2)) || (isempty(x) || isempty(v)), ...
        'shared_tracking:ExtendedKalmanFilter:NumberOfInputsToNumericJacobian',...
        nargin(func), numel(vec) + 2);
    coder.internal.errorIf(inputToDerive > (numel(vec) + 2), ...
        'shared_tracking:ExtendedKalmanFilter:DeriveByNonexistentInput',...
        numel(vec) + 2, inputToDerive);
end

if nargin < 7
   if inputToDerive == 1
      relativeStep = sqrt(eps(class(x)));
   elseif inputToDerive == 2
      relativeStep = sqrt(eps(class(v)));
   else
      relativeStep  = sqrt(eps(class(vec{inputToDerive})));
   end   
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

z = func(x,v,vec{:});
m = length(z);

% Compute dimensions of Jacobian
if inputToDerive == 1
   n = length(x);
   jacobian = zeros(m,n, class(x));
elseif inputToDerive == 2
   n = length(v);
   jacobian = zeros(m,n, class(v));
else
   n = length(vec{inputToDerive - 2});
   jacobian = zeros(m,n, class(vec{inputToDerive - 2}));
end
specvec = vec;

for j = 1:n 
   % Determine which input is to be perturbed
    if inputToDerive == 1
       imvec = x;
    elseif inputToDerive == 2
       imvec = v;
    else
      imvec = vec{inputToDerive - 2};
    end    
    epsilon = sign * max(delta,delta*abs(imvec(j)));
    imvec(j) = imvec(j) + epsilon;
    
    % Find output of function when input is perturbed
    if inputToDerive == 1
       imz = func(imvec,v,specvec{:});
    elseif inputToDerive == 2
       imz = func(x,imvec,specvec{:});
    else
       specvec{inputToDerive - 1} = imvec;
       imz = func(x,v,specvec{:});
    end 
    
    if strcmp(direction, 'middle') %Calculate z with half a step backward
        epsilon = -2 * epsilon; %was 1/2 step forward, now 2 halves back
        imvec(j) = imvec(j) - epsilon;
        
        if inputToDerive == 1
           z = func(imvec,v,specvec{:});
        elseif inputToDerive == 2
           z = func(x,imvec,specvec{:});
        else
           specvec{inputToDerive - 1} = imvec;
           z = func(x,v,specvec{:});
        end            
    end    
    deltaz = imz-z;
    jacobian(:, j) = deltaz(:)/epsilon;
end