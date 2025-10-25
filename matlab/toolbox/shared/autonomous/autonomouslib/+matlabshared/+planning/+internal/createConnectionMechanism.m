function connMech = createConnectionMechanism(method, d, r, n)
%createConnectionMechanism - Create a connection mechanism object.
%
%   connMech = createConnectionMechanism(connMethod, connDistance, turnRadius, numSteps)

% Copyright 2018 The MathWorks, Inc.

%#codegen

% method has already been validated to be either Dubins or Reeds-Shepp.
switch method
    case 'Dubins'
        connMech = matlabshared.planning.internal.DubinsConnectionMechanism;
    case 'Reeds-Shepp'
        connMech = matlabshared.planning.internal.ReedsSheppConnectionMechanism;
end

connMech.ConnectionDistance = d;
connMech.TurningRadius      = r;
connMech.NumSteps           = n;
end