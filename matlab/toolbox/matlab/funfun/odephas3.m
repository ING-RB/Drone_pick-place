function status = odephas3(~,y,flag,varargin)
%ODEPHAS3  3-D phase plane ODE output function.
%   When the function odephas3 is passed to an ODE solver as the 'OutputFcn'
%   property, i.e. options = odeset('OutputFcn',@odephas3), the solver
%   calls ODEPHAS3(T,Y,'') after every timestep.  The ODEPHAS3 function plots
%   the first three components of the solution it is passed as it is
%   computed, adapting the axis limits of the plot dynamically.  To plot
%   three particular components, specify their indices in the 'OutputSel'
%   property passed to the ODE solver.
%
%   At the start of integration, a solver calls ODEPHAS3(TSPAN,Y0,'init') to
%   initialize the output function.  After each integration step to new time
%   point T with solution vector Y the solver calls STATUS = ODEPHAS3(T,Y,'').
%   If the solver's 'Refine' property is greater than one (see ODESET), then
%   T is a column vector containing all new output times and Y is an array
%   comprised of corresponding column vectors.  The STATUS return value is 1
%   if the STOP button has been pressed and 0 otherwise.  When the
%   integration is complete, the solver calls ODEPHAS3([],[],'done').
%
%   See also ODEPLOT, ODEPHAS2, ODEPRINT, ODE45, ODE15S, ODESET.

%   Mark W. Reichelt and Lawrence F. Shampine, 3-24-94
%   Copyright 1984-2023 The MathWorks, Inc.

% bind the correct function call to data passed from solver
switch(flag)
    case ''
        fun = @(ud) pointAdder(ud,y);
    case 'init'
        fun = @(ud,ishold,ta) initializer(ud,ishold,ta,y);
    case 'done'
        fun = @(ud,ta) cleanup(ud,ta);
    otherwise
        fun = [];
end
% update plots
status = odePlotImpl(fun,flag,"odephas3");
end

function ud = initializer(ud,ishold,TARGET_AXIS,y)
    % To be called with the 'init' flag. Creates the animated line.
    if ~ishold || ~isfield(ud,'line')
        ud.line = plot3(y(1),y(2),y(3),'-o','Parent',TARGET_AXIS);
    end
    ud.anim = animatedline(y(1),y(2),y(3),'Parent',TARGET_AXIS,...
        'Color',get(ud.line,'Color'),...
        'Marker',get(ud.line,'Marker'));
    grid on
end

function ud = pointAdder(ud,y)
    % To be called with the "" flag. Update the plot with new points.
    addpoints(ud.anim,y(1,:),y(2,:),y(3,:));
end

function ud = cleanup(ud,ta)
    % To be called with the "done" flag. Delete animation and set up final
    % plot.
    [y1,y2,y3] = getpoints(ud.anim);
    ud.line = plot3(y1,y2,y3,'Parent',ta,...
        'Color',get(ud.anim,'Color'),...
        'Marker',get(ud.anim,'Marker'));
    grid on
    delete(ud.anim);
end