classdef Element
% SIMULINK.SIMULATIONDATA.ELEMENT  creates a Simulink Simulation Data Element object.
%
%   The Simulink.SimulationData.Element object is used to store logged data
%   within a Simulink.SimulationData.Dataset. This abstract class contains
%   a Name and provides searching capabilities for objects contained inside
%   a Simulink.SimulationData.Dataset.
%
%   See also Simulink.SimulationData.Dataset,
%   Simulink.SimulationData.BlockData, 
%   Simulink.SimulationData.Signal, 
%   Simulink.SimulationData.DataStoreMemory

 
% Copyright 2009-2024 The MathWorks, Inc.

    methods
        function out=Element
        end

        function out=copy(~) %#ok<STOUT>
            % Naive implementation of copy, which does a shallow copy.
            % Deriving classes are expected to implement deep copy in the
            % overridden copy method.
        end

    end
    properties
        %Name -  Name of Element to use for name-based access.
        Name;

    end
end
