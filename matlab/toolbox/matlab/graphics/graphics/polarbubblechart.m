function h = polarbubblechart(varargin)
%

%   Copyright 2020-2023 The MathWorks, Inc.

matlab.graphics.chart.internal.DDUXLogger(mfilename,varargin);
narginchk(1,inf)
[cax, args] = axescheck(varargin{:});
if ~isempty(cax) && ~isa(cax, 'matlab.graphics.axis.PolarAxes')
    error(message('MATLAB:polarplot:AxesInput'));
end
try
    cax = matlab.graphics.internal.prepareCoordinateSystem('polar', cax);   
    obj = bubblechart(cax, args{:});
catch e
    switch e.identifier
        case 'MATLAB:scatter:InvalidXYSizeData'
            error(message(e.identifier, 'Theta', 'rho'));
        case 'MATLAB:Chart:InvalidTableSubscript'
            if isequal(e.message,getString(message(e.identifier, 'X')))
                e = MException(message(e.identifier, 'Theta'));
            elseif isequal(e.message,getString(message(e.identifier, 'Y')))
                e = MException(message(e.identifier, 'Rho'));
            end
            throw(e)
        otherwise
            throw(e);
    end
end

if nargout > 0
    h = obj;
end

