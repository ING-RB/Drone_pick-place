function Fx = constantSpeedJacobian(state) %#ok<INUSD>
  % The Jacobian matrix associated with the above example of
  % constantSpeedConstantTime.
  % Note that since constantSpeedConstantTime is a linear example, this
  % Jacobian is independent of the state at time k-1.
  
  %#codegen
      
  % Copyright 2016-2020 The MathWorks, Inc.
  
  Fx = [1 1 0 0; 0 1 0 0; 0 0 1 1; 0 0 0 1];
end
