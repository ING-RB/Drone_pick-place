function stop = optimplotfunccount(~,optimValues,state,varargin)
    % OPTIMPLOTFUNCCOUNT Plot number of function evaluations at each iteration.
    %
    %   STOP = OPTIMPLOTFUNCCOUNT(X,OPTIMVALUES,STATE) plots the value in
    %   OPTIMVALUES.funccount.
    %
    %   Example:
    %   Create an options structure that will use OPTIMPLOTFUNCCOUNT as the
    %   plot function
    %     options = optimset('PlotFcns',@optimplotfunccount);
    %
    %   Pass the options into an optimization solver to view the plot
    %     fminbnd(@sin,3,10,options)

    %   Copyright 2006-2023 The MathWorks, Inc.

    % Always return a "stop" flag of false
    stop = false;

    % Persistent variables
    persistent thePlot

    switch state
        case "iter"
            if optimValues.iteration == 0
                thePlot = matlab.internal.optimfun.plotfcns.Factory.optimplotfunccount(optimValues);
            else
                thePlot.update(optimValues);
            end
    end
end
