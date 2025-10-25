function hcr = xyzregion(varargin)
%This undocumented function may be removed in a future release.

%This function is a middle layer between the convenience function: xregion,
%and yregion. It returns a handle to a ConstantRegion object.

%   Copyright 2023 The MathWorks, Inc.

import matlab.graphics.chart.internal.inputparsingutils.peelFirstArgParent
import matlab.graphics.chart.internal.inputparsingutils.splitPositionalFromPV
import matlab.graphics.chart.internal.inputparsingutils.getParent

%Separate user's input from 'x'/'y'.
args = varargin{2};
axis = varargin{1};

[parentAxes, args] = peelFirstArgParent(args);
[posargs, pvpairs] = splitPositionalFromPV(args, 1, true);
[parentAxes, hasParent] = getParent(parentAxes, pvpairs, 2);

try
    validatePositionalArguments(posargs);
catch err
    throwAsCaller(err)
end

if isscalar(posargs)
    if size(posargs{1}, 1) ~= 2
        % Enforce 2xn orientation without affecting 2x2 matrix.
        posargs{1} = posargs{1}.';
    end
    val1 = posargs{1}(1,:);
    val2 = posargs{1}(2,:);
else
    val1 = posargs{1};
    val2 = posargs{2};
end
hcr = gobjects(numel(val1),1);

% Set parent for ConstantRegion object(s) if one wasn't specified in
% name/value pairs.
if ~hasParent
    parentAxes = gca;
end

% Reshape vectors so all values from val1 and val2 are included
% in configureAxes.
if ~isequal(size(val1), size(val2))
    val = [val1; val2'];
else
    val = [val1; val2];
end

if isa(parentAxes, 'matlab.graphics.axis.Axes')
    switch axis
        case 'x'
            matlab.graphics.internal.configureAxes(parentAxes,val,parentAxes.YLim(1))
        case 'y'
            matlab.graphics.internal.configureAxes(parentAxes,parentAxes.XLim(1),val)
    end
end

% Create ConstantRegion object(s).
try
    for i = 1:numel(val1)
        hcr(i) = matlab.graphics.chart.decoration.ConstantRegion('Parent', parentAxes, 'InterceptAxis', axis, 'Value', [val1(i) val2(i)], pvpairs{:});
    end
catch e
    throwAsCaller(e);
end
end

function validatePositionalArguments(posargs)

for i = 1:numel(posargs)
    assert(~isempty(posargs{i}), message('MATLAB:graphics:constantline:EmptyInputs'))
    assert(~isnumeric(posargs{i}) || isreal(posargs{i}), message('MATLAB:graphics:constantline:ComplexValue','Value'))
end
if isscalar(posargs)
    assert(~isscalar(posargs{1}), message('MATLAB:graphics:constantline:TooFewInput'));
    assert(ismatrix(posargs{1}) && any(size(posargs{1})==2), message('MATLAB:graphics:constantline:InvalidSyntax'))
else
    assert(isvector(posargs{1}) && isvector(posargs{2}), message('MATLAB:graphics:constantline:InvalidSyntax'))
    assert(numel(posargs{1}) == numel(posargs{2}), message('MATLAB:graphics:constantline:UnevenVectors'))
end

end