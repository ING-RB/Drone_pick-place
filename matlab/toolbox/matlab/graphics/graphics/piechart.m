function hh = piechart(varargin)
%

%   Copyright 2023 The MathWorks, Inc.

try
    h = matlab.graphics.chart.internal.pieConvenienceHelper('matlab.graphics.chart.PieChart', varargin{:});
catch e
    throw(e);
end

if nargout > 0
    hh = h;
end

end
