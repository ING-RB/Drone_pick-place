function stop = optimplotx(x,optimValues,state,varargin)
    % OPTIMPLOTX Plot current point at each iteration.
    %
    %   STOP = OPTIMPLOTX(X,OPTIMVALUES,STATE) plots the current point, X, as a
    %   bar plot of its elements at the current iteration.
    %
    %   Example:
    %   Create an options structure that will use OPTIMPLOTX
    %   as the plot function
    %       options = optimset('PlotFcns',@optimplotx);
    %
    %   Pass the options into an optimization problem to view the plot
    %       fminbnd(@sin,3,10,options)

    %   Copyright 2006-2023 The MathWorks, Inc.

    % Always return a "stop" flag of false
    stop = false;

    % Persistent variables
    persistent thePlot

    % Include x with optimValues
    optimValues.x = x(:);

    switch state
        case "iter"
            if optimValues.iteration == 0
                thePlot = matlab.internal.optimfun.plotfcns.Factory.optimplotx(optimValues);
            else
                thePlot.update(optimValues);
            end
    end
end
