classdef InflatorBase < matlabshared.autonomous.map.internal.InternalAccess
%This class is for internal use only. It may be removed in the future.
    
%INFLATORBASE is base class for inflators

%   Copyright 2019-2020 The MathWorks, Inc.

%#codegen

    properties 
        InflateRadius
    end
    
    methods
        function set.InflateRadius(obj,radius)
            validateattributes(radius, {'numeric'}, ...
                    {'nonempty','real', 'scalar','nonnan', 'finite'}, 'Inflator', 'InflatorRadius');
            obj.InflateRadius = radius;
        end
    end
end


