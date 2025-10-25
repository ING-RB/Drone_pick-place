function stop = optimplotfval(~,optimValues,state,varargin)
    % OPTIMPLOTFVAL Plot value of the objective function at each iteration.
    %
    %   STOP = OPTIMPLOTFVAL(X,OPTIMVALUES,STATE) plots OPTIMVALUES.fval.  If
    %   the function value is not scalar, a bar plot of the elements at the
    %   current iteration is displayed.  If the OPTIMVALUES.fval field does not
    %   exist, the OPTIMVALUES.residual field is used.
    %
    %   Example:
    %   Create an options structure that will use OPTIMPLOTFVAL as the plot
    %   function
    %     options = optimset('PlotFcns',@optimplotfval);
    %
    %   Pass the options into an optimization problem to view the plot
    %     fminbnd(@sin,3,10,options)

    %   Copyright 2006-2023 The MathWorks, Inc.

    % Always return a "stop" flag of false
    stop = false;

    % Persistent variables
    persistent thePlot

    switch state
        case "iter"
            if optimValues.iteration == 0
                thePlot = matlab.internal.optimfun.plotfcns.Factory.optimplotfval(optimValues);
            else
                thePlot.update(optimValues);
            end
    end
end
