classdef gyroparams< fusion.internal.IMUSensorParameters & fusion.internal.UnitDisplayer
    methods
        function out=gyroparams
        end

        function out=createSystemObjectImpl(~) %#ok<STOUT>
        end

        function out=getDisplayUnitImpl(~) %#ok<STOUT>
        end

        function out=getPropertyGroups(~) %#ok<STOUT>
        end

        function out=updateSystemObjectImpl(~) %#ok<STOUT>
        end

    end
    properties
        AccelerationBias;

    end
end

 
%   Copyright 2017-2023 The MathWorks, Inc.

