function h = meshc(arg1, arg2, arg3, arg4, arg5, propArgs)
    %MESHC  Combination mesh/contour plot.
    %   MESHC(...) is the same as MESH(...) except that a contour plot
    %   is drawn beneath the mesh.
    %
    %   Because CONTOUR does not handle irregularly spaced data, this
    %   routine only works for surfaces defined on a rectangular grid.
    %   The matrices or vectors X and Y define the axis limits only.
    %
    %   See also MESH, MESHZ.
    
    %   Clay M. Thompson 4-10-91
    %   Copyright 1984-2020 The MathWorks, Inc.

    arguments
        arg1 = [];
        arg2 = [];
        arg3 = [];
        arg4 = [];
        arg5 = [];
        propArgs.?matlab.graphics.chart.primitive.Surface
    end
    propCell = namedargs2cell(propArgs);
    
    args = {arg1, arg2, arg3, arg4, arg5 };
    [~, cax, args] = parseplotapi(args{1:nargin}, '-mfilename', mfilename);
    
    if isfield(propArgs,'Parent') % Always honor the 'Parent' PVPair value
        cax = propArgs.Parent;
    end
    
    nargs = length(args);
    if nargs < 1
        error(message('MATLAB:narginchk:notEnoughInputs'));
    elseif nargs > 4
        error(message('MATLAB:narginchk:tooManyInputs'));
    end
    
    if nargs == 1  % Generate x, y matrices for surface z.
        z = args{1};
        z = matlab.graphics.chart.internal.datachk(z,'numeric');
        [m, n] = size(z);
        [x, y] = meshgrid(1 : n, 1 : m);
    elseif nargs == 2
        z = args{1};
        c = args{2};
        z = matlab.graphics.chart.internal.datachk(z,'numeric');
        c = matlab.graphics.chart.internal.datachk(c,'numeric');
        [m, n] = size(z);
        [x, y] = meshgrid(1 : n, 1 : m);
    else
        [x, y, z] = deal(args{1 : 3});
        x = matlab.graphics.chart.internal.datachk(x,'numeric');
        y = matlab.graphics.chart.internal.datachk(y,'numeric');
        z = matlab.graphics.chart.internal.datachk(z,'numeric');
        if nargs == 4
            c = args{4};
            c = matlab.graphics.chart.internal.datachk(c,'numeric');
        end
    end
    
    if min(size(z)) == 1
        error(message('MATLAB:meshc:MatrixInput'));
    end
    
    % Determine state of system
    cax = newplot(cax);
    nextPlot = cax.NextPlot;
    
    % Plot mesh.
    try
        if nargs == 2 || nargs == 4
            hm = mesh(cax, x, y, z, c, propCell{:});
        else
            hm = mesh(cax, x, y, z, propCell{:});
        end
    catch e
        throw(e);
    end
    
    % Set NextPlot to 'add' so that the contour object is added to the
    % existing axes. 'mesh' calls 'newplot', so the Figure's NextPlot
    % property will already be set to 'add' at this point.
    cax.NextPlot = 'add';
    
    a = get(cax, 'ZLim');
    
    % Always put contour at the ZMin.
    
    % Get the contour data
    [~, hh] = contour(cax, x, y, z, 'ZLocation', "ZMin");
    
    % Restore the original value for NextPlot.
    cax.NextPlot = nextPlot;
    
    if nargout > 0
        h = [hm; hh(:)];
    end
end
