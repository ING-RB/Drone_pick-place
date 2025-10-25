function h = polarplot(varargin)
%

%   Copyright 2015-2024 The MathWorks, Inc.

matlab.graphics.chart.internal.DDUXLogger(mfilename,varargin);

narginchk(1,inf)
[cax, args] = axescheck(varargin{:});
if ~isempty(cax) && ~isa(cax, 'matlab.graphics.axis.PolarAxes')
    error(message('MATLAB:polarplot:AxesInput'));
end
try
    cax = matlab.graphics.internal.prepareCoordinateSystem('polar', cax);

    % Check for complex input.
    nargs = numel(args);
    if nargs > 0 && isnumeric(args{1}) && ~isreal(args{1}) && ...
            (nargs == 1 || ischar(args{2}) || isstring(args{2}))
        % When complex data is provided, plot the angle as theta and the
        % absolute value as radius.
        Z = double(args{1});
        TH = angle(Z);
        R = abs(Z);
        args = {TH,R,args{2:end}};
    end

    obj = plot(cax, args{:});

    % When ThetaData is not specified, default to linspace(0,2*pi,m).
    for n = 1:numel(obj)
        if obj(n).ThetaDataMode == "auto" && ~obj(n).isDataComingFromDataSource("X")
            m = numel(obj(n).RData);
            obj(n).ThetaData = linspace(0,2*pi,m);
        end
    end
catch e
    throwAsCaller(e);
end

if nargout > 0
    h = obj;
end

