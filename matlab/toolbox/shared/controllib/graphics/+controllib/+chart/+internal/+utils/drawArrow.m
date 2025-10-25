function drawArrow(hpatch,X,Y,RelArrowSize,optionalArguments)
% Draws arrowhead on line segment connecting (X(1),Y(1)) and (X(2),Y(2)).
% The arrowhead point in the segment direction and is equilateral regardless
% of scale, limits, and plot aspect ratio.

arguments
    hpatch
    X
    Y
    RelArrowSize
    optionalArguments.Style (1,1) string {mustBeMember(optionalArguments.Style,["arrow","diamond"])} = 'arrow'
    optionalArguments.Axes = ancestor(hpatch,'axes')
    optionalArguments.XRange = []
    optionalArguments.YRange = []
    optionalArguments.AspectRatio = []
    optionalArguments.XScale = 'linear';
    optionalArguments.YScale = 'linear';
end

%   Copyright 1986-2021 The MathWorks, Inc.
if isempty(X)
    set(hpatch,'Xdata',[],'Ydata',[])
else
    XLOG = strcmp(optionalArguments.XScale,'log');
    YLOG = strcmp(optionalArguments.YScale,'log');

    % XLim
    if ~isempty(optionalArguments.XRange)
        Xlim = optionalArguments.XRange;
    elseif ~isempty(optionalArguments.Axes)
        Xlim = optionalArguments.Axes.XLim;
        XLOG = strcmp(optionalArguments.Axes.XScale,'log');
    else
        Xlim = [0 1];
    end

    % YLim
    if ~isempty(optionalArguments.YRange)
        Ylim = optionalArguments.YRange;
    elseif ~isempty(optionalArguments.Axes)
        Ylim = optionalArguments.Axes.YLim;
        YLOG = strcmp(optionalArguments.Axes.YScale,'log');
    else
        Ylim = [0 1];
    end

    % PlotBoxAspectRatio
    if ~isempty(optionalArguments.AspectRatio)
        AR = optionalArguments.AspectRatio;
    elseif ~isempty(optionalArguments.Axes)
        AR = optionalArguments.Axes.PlotBoxAspectRatio(1:2);
    else
        AR = [1 0.8];
    end

    % Geometry
    % ax = ancestor(harrow,'axes');
    % Xlim = ax.XLim;
    % Ylim = ax.YLim;
    % AR = ax.PlotBoxAspectRatio(1:2);
    AR = AR/norm(AR);
    
    if XLOG
        Xlim = log10(Xlim);  X = log10(X);
    end
    if YLOG
        Ylim = log10(Ylim);  Y = log10(Y);
    end
    % data to pixel scale factors
    xsf = AR(1)/(Xlim(2)-Xlim(1));
    ysf = AR(2)/(Ylim(2)-Ylim(1));

    % Create arrowhead
    if strcmp(optionalArguments.Style,"arrow")
        aux = exp(2i*pi/3);
        Z = RelArrowSize * [1 aux conj(aux)];   % equilateral triangle pointing east
    else
        Z = RelArrowSize*[-1i,1,1i,-1];
        Z = [Z(:); Z(end)];
    end
    dir = complex((X(2)-X(1))*xsf,(Y(2)-Y(1))*ysf);   % desired pointing direction
    Z = Z * (dir/abs(dir));                 % rotate to point in desired direction
    % Note: Place arrow halfway to minimize risk of overlap and
    %       to stay away from possible kinks at frequency points
    XData = (X(1)+X(2))/2 + real(Z)/xsf;
    YData = (Y(1)+Y(2))/2 + imag(Z)/ysf;
    if XLOG
        XData = 10.^XData;
    end
    if YLOG
        YData = 10.^YData;
    end
    set(hpatch,'Xdata',XData,'Ydata',YData)
end