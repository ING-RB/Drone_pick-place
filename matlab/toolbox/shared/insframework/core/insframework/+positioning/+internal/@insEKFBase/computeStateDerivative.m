function [xdot, dfdx] = computeStateDerivative(filt,  dt, varargin)
%   This function is for internal use only. It may be removed in the future.
%computeXdot compute xdot and dfdx for prediction step

%   Copyright 2022 The MathWorks, Inc.

%#codegen 

% Preallocate
idx = stateinfo(filt);
Ns = numel(filt.State);
xdot = zeros(Ns, 1, 'like', filt.State);
dfdx = zeros(Ns, 'like', filt.State); % square

% Step the motion model forward
xMotion = stateTransition(filt.MotionModel, filt, dt, varargin{:}); 
dMotiondx = stateTransitionJacobian(filt.MotionModel, filt, dt, varargin{:}); 

% Unpack the structs
xdot = assignFromStruct(xdot, xMotion, idx);
dfdx = assignFromStruct(dfdx, dMotiondx, idx);

% Evolve the states of the sensors
Ns = coder.const(numel(filt.Sensors));
coder.unroll
for ss=1:Ns
   idx = filt.SensorStateInfo{ss};
   xdotSensor = stateTransition(filt.Sensors{ss}, filt, dt, varargin{:});
   if filt.SensorImplementsStateTransition(ss)
       dSensordx = stateTransitionJacobian(filt.Sensors{ss}, filt, dt, varargin{:});
   else
       dSensordx = filt.PrecomputedStateTransitionJacobian{ss};
   end
   xdot = assignFromStruct(xdot, xdotSensor, idx);
   dfdx = assignFromStruct(dfdx, dSensordx, idx);
end

end
function x = assignFromStruct(x, xStruct, idx)
% Assign elements from structure xStruct to preallocated array x.
%   The input x is a preallocated array which will be populated and
%   returned as the output.
%   The input xStruct is a structure. Each field holds values to be copied
%   to a row of x.
%   The input idx is a structure. It has a superset of the fields of
%   xStruct. The values of idx are row indices where the corresponding
%   values of xStruct should be entered into x.
%
%   x = [0 0; 0 0]
%   xStruct = struct('A', [10 20]);
%   idx = struct('A', 2, 'B', 1);
%   output x = [0 0; 10 20];
fn = fieldnames(xStruct);

coder.unroll;
for ii=1:numel(fn)
    thisf = fn{ii};
    x(idx.(thisf),:) = xStruct.(thisf);
end
end
