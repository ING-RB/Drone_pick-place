function obj = polarregionhelper(dimension, varargin)

%

%   Copyright 2023 The MathWorks, Inc.

narginchk(2,inf);

[parentAxes, args] = matlab.graphics.chart.internal.inputparsingutils.peelFirstArgParent(varargin);
[posargs, pvpairs] = matlab.graphics.chart.internal.inputparsingutils.splitPositionalFromPV(args, 1, true);
parentAxes = matlab.graphics.chart.internal.inputparsingutils.getParent(parentAxes, pvpairs, 2);

if isscalar(posargs)
    isSize2 = size(posargs{1})==2;
    assert(ismatrix(posargs{1}) && any(isSize2), ...
        message('MATLAB:graphics:constantline:InvalidSyntax'))

    % Prefer splitting columns, unless the row dimension is the only one
    % with size 2.
    splitDimension = 2;
    if ~isSize2(1) && isSize2(2)
        splitDimension = 1;
    end
    posargs = num2cell(posargs{1},splitDimension);
end
[msg, s1, s2] = matlab.graphics.chart.primitive.internal.findMatchingDimensions(posargs{1},posargs{2});

assert(isempty(msg), message('MATLAB:graphics:constantline:InvalidSyntax'))
assert(isreal(s1) && isreal(s2), message('MATLAB:graphics:constantline:ComplexValue', dimension))

dims = ["ThetaSpan" "RadiusSpan"];
infprop = dims(dims~=dimension);
numprop = dimension;

% Now that the data are validated, create an axes if necessary:
if isempty(parentAxes)
    cf = gcf;
    parentAxes = cf.CurrentAxes;
    if isempty(parentAxes)
        parentAxes=polaraxes;
    end
end

obj = repmat(matlab.graphics.chart.decoration.PolarRegion, size(s1));
for i = 1:numel(s1)
    obj(i) = matlab.graphics.chart.decoration.PolarRegion( ...
        "Parent", parentAxes, ...
        infprop, [-inf inf], ...
        numprop, [s1(i) s2(i)], ...
        pvpairs{:});
end
end