function hh = donutchart(varargin)
%

%   Copyright 2023 The MathWorks, Inc.

try
    h = matlab.graphics.chart.internal.pieConvenienceHelper('matlab.graphics.chart.DonutChart', varargin{:});
catch e
    throw(e);
end

if nargout > 0
    hh = h;
end

end
