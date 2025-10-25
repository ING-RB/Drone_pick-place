function nextState = constantSpeedConstantTime(state)
%constantSpeedConstantTime. An example for StateTransitionFcn with only a
%state input.
% Assume a two dimensional state vector, that represents
% [x,xdot,y,ydot]', where x and y are horizontal and vertical positions,
% respectively, and xdot and ydot are the corresponding components of the
% velocity vector.
% nextState is the state at the next time step, where time step is
% assumed to be 1.

%  Copyright 2016 The MathWorks, Inc.

%#codegen
%#ok<*EMCLS>
%#ok<*EMCA>
%#ok<*MCSUP>

nextState = [state(1)+state(2);state(2);state(3)+state(4);state(4)];
end