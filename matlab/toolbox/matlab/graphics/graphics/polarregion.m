function polarobj = polarregion(varargin)
%

%   Copyright 2023 The MathWorks, Inc.

narginchk(2,inf);

[parentAxes, args] = matlab.graphics.chart.internal.inputparsingutils.peelFirstArgParent(varargin);
[posargs, pvpairs] = matlab.graphics.chart.internal.inputparsingutils.splitPositionalFromPV(args, 2, false);
parentAxes = matlab.graphics.chart.internal.inputparsingutils.getParent(parentAxes, pvpairs, 2);


% For polar region both inputs need to be n x 2 or 2 x n
sz1 = size(posargs{1});
sz2 = size(posargs{2});
if ~(ismatrix(posargs{1}) && any(sz1==2) && ...
     ismatrix(posargs{2}) && any(sz2==2))
    error(message('MATLAB:graphics:constantline:InvalidPolarRegionSyntax'))
end

if sz1(1) ~= 2
    posargs{1} = posargs{1}.';
    sz1 = flip(sz1);
end
if sz2(1) ~= 2
    posargs{2} = posargs{2}.';
    sz2 = flip(sz2);
end

% If a 2 x 1 and 2 x n are specified, repeat the 2 x 1 to match n
n = sz1(2);
if sz1(2) ~= sz2(2)
    if sz2(2) == 1
        posargs{2} = repmat(posargs{2}, 1, n);
    elseif sz1(2) == 1
        n = sz2(2);
        posargs{1} = repmat(posargs{1}, 1, n);
    else
        error(message('MATLAB:graphics:constantline:InvalidPolarRegionSyntax'))
    end
end

if ~isreal(posargs{1})
    error(message('MATLAB:graphics:constantline:ComplexValue', 'ThetaSpan'))
end
if ~isreal(posargs{2})
    error(message('MATLAB:graphics:constantline:ComplexValue', 'RadiusSpan'))
end

% Now that the data are validated, create an axes if necessary:
if isempty(parentAxes)
    cf = gcf;
    parentAxes = cf.CurrentAxes;
    if isempty(parentAxes)
        parentAxes=polaraxes;
    end
end

obj=gobjects(1, n);
for i = 1:n
    obj(i) = matlab.graphics.chart.decoration.PolarRegion( ...
        'Parent', parentAxes, ...
        'ThetaSpan', posargs{1}(:,i), ...
        'RadiusSpan', posargs{2}(:,i), ...
        pvpairs{:});
end

if nargout > 0
    if isempty(obj)
        polarobj=matlab.graphics.chart.decoration.PolarRegion.empty(size(obj));
    else
        polarobj = obj;
    end
end

end
