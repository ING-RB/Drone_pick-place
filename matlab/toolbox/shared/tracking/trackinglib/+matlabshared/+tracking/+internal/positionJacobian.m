function Hx = positionJacobian(state) %#ok<INUSD>
  % The Jacobian matrix associated with the above example of
  % positionSensor.
  % Note that since positionSensor is a linear example, this Jacobian is
  % independent of the state at time k.
  
  %#codegen
  
  % Copyright 2016-2020 The MathWorks, Inc.
  
  Hx = [1 0 0 0; 0 0 1 0];
end
