%matlabshared.planning.internal.ConnectionMechanism Interface for connection mechanism
%
%   This class defines an interface for a connection method.
%
%   Inherit from this class and implement distance() and interpolate()
%   methods.
%
%   See also matlabshared.planning.internal.DubinsConnectionMechanism,
%   matlabshared.planning.internal.ReedsSheppConnectionMechanism.

% Copyright 2017-2018 The MathWorks, Inc.

%#codegen
classdef ConnectionMechanism < handle
    
    properties
        ConnectionDistance  = 5
        
        NumSteps            = 50
    end
    
    properties (Abstract, Constant)
        Exact
        
        Name
    end
    
    methods (Abstract)
        d = distance(this, from, to)
        
        poses = interpolate(this, from, to)
    end
    
end
