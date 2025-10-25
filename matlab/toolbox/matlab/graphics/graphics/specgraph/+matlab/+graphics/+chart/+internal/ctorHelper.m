function ctorHelper(obj, pvpairs)
%

%   Copyright 2014-2015 The MathWorks, Inc.
try
    if isstruct(pvpairs) && isa(obj,'matlab.graphics.chart.internal.ChartBaseProxy')
        set(obj, pvpairs);
    elseif isscalar(pvpairs)
        error(message('MATLAB:class:BadParamValuePairs'))
    elseif ~isempty(pvpairs)
        set(obj, pvpairs{:});
    end
catch e
    % Clean the zombie chart out of the tree
    obj.Parent = [];
    throwAsCaller(e);
end

end
