classdef System< matlab.system.SystemInterface & matlab.system.SystemProp
%matlab.System Base class for System objects
%
% In order to create a System object, you must subclass your object from
% matlab.System. Subclassing allows you to use the implementation and
% service methods provided by this base class to build your object. You use
% this syntax as the first line of your class definition file, where
% ObjectName is the name of your object:
% 
% classdef ObjectName < matlab.System

 
%   Copyright 1995-2024 The MathWorks, Inc.

    methods
        function out=System
        end

        function out=cloneImpl(~) %#ok<STOUT>
        end

        function out=inputDimensionConstraint(~) %#ok<STOUT>
        end

        function out=outputDimensionConstraint(~) %#ok<STOUT>
        end

    end
end
