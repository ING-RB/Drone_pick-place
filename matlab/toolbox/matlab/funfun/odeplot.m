function status = odeplot(t,y,flag,varargin)
%ODEPLOT  Time series ODE output function.
%   When the function odeplot is passed to an ODE solver as the 'OutputFcn'
%   property, i.e. options = odeset('OutputFcn',@odeplot), the solver calls
%   ODEPLOT(T,Y,'') after every timestep.  The ODEPLOT function plots all
%   components of the solution it is passed as it is computed, adapting
%   the axis limits of the plot dynamically.  To plot only particular
%   components, specify their indices in the 'OutputSel' property passed to
%   the ODE solver.  ODEPLOT is the default output function of the
%   solvers when they are called with no output arguments.
%
%   At the start of integration, a solver calls ODEPLOT(TSPAN,Y0,'init') to
%   initialize the output function.  After each integration step to new time
%   point T with solution vector Y the solver calls STATUS = ODEPLOT(T,Y,'').
%   If the solver's 'Refine' property is greater than one (see ODESET), then
%   T is a column vector containing all new output times and Y is an array
%   comprised of corresponding column vectors.  The STATUS return value is 1
%   if the STOP button has been pressed and 0 otherwise.  When the
%   integration is complete, the solver calls ODEPLOT([],[],'done').
%
%   See also ODEPHAS2, ODEPHAS3, ODEPRINT, ODE45, ODE15S, ODESET.

%   Mark W. Reichelt and Lawrence F. Shampine, 3-24-94
%   Copyright 1984-2023 The MathWorks, Inc.

% bind the correct function call to data passed from solver
setAxis = [];
switch(flag)
    case ''
        fun = @(ud) pointAdder(ud,t,y);
    case 'init'
        fun = @(ud,ishold,ta) initializer(ud,ishold,ta,t,y);
        setAxis = [min(t),max(t)]; % only used in initialization
    case 'done'
        fun = @(ud,ta) cleanup(ud,ta);
    otherwise
        fun = [];
end
% update plots
status = odePlotImpl(fun,flag,"odeplot",SetAxis=setAxis);
end

function ud = initializer(ud,ishold,targetAxis,t,y)
    % To be called with the 'init' flag. Creates the animated line.
    if ~ishold || ~isfield(ud,'lines')
        ud.lines = plot(t(1),y,'-o','Parent',targetAxis);
    end
    for i = 1 : length(y)
        ud.anim(i) = animatedline(t(1),y(i),'Parent',targetAxis,...
            'Color',get(ud.lines(i),'Color'),...
            'Marker',get(ud.lines(i),'Marker'));
    end
end

function ud = pointAdder(ud,t,y)
    % To be called with the "" flag. Update the plot with new points.
    for i = 1 : length(ud.anim)
        addpoints(ud.anim(i),t,y(i,:));
    end
end

function ud = cleanup(ud,ta)
    % To be called with the "done" flag. Delete animation and set up final
    % plot.
    for i = 1 : length(ud.anim)
        [tt,yy] = getpoints(ud.anim(i));
        np = get(ta,'NextPlot');
        set(ta,'NextPlot','add');
        ud.lines(i) = plot(tt,yy,'Parent',ta,...
            'Color',get(ud.anim(i),'Color'),...
            'Marker',get(ud.anim(i),'Marker'));
        set(ta,'NextPlot',np);
        delete(ud.anim(i));
    end
end