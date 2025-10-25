function measurement = positionSensor(state)
%positionSensor. An example for a MeasurementFcn with only a state input.
% Here we assume a sensor that measures only the position in 2-D of an
% object, whose state is given by [x,xdot,y,ydot]'.

%  Copyright 2016 The MathWorks, Inc.

%#codegen
%#ok<*EMCLS>
%#ok<*EMCA>
%#ok<*MCSUP>
measurement = [state(1);state(3)];
end