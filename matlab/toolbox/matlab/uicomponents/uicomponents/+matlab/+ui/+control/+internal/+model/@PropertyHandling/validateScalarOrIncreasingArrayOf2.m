function output = validateScalarOrIncreasingArrayOf2(input)
% Validate that input is either a number, or a 1x2 array of
% numbers where the first one is less than the second one.
%
% Returns output that is:
% - either a scalar, excluding NaN and +/-Inf
% - a 1x2 vector of increasing numbers


% Ensure the input is at least a double vector with increasing
% values
validateattributes(input, ...
    {'numeric'}, ...
    {'vector', 'increasing', 'integer', 'finite', 'real', 'nonnan','>',0});

% Check that input has either one or two elements
validateattributes(length(input),...
    {'double'},...
    {'>=',1,'<=',2});

% Reshape to row
output = matlab.ui.control.internal.model.PropertyHandling.getOrientedVectorArray(input, 'horizontal');

end