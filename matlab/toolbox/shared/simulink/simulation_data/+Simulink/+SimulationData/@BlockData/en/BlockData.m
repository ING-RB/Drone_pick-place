classdef BlockData< Simulink.SimulationData.Element
% SIMULINK.SIMULATIONDATA.BLOCKDATA  creates a Simulink Simulation Data BlockData element object.
%
%   The Simulink.SimulationData.BlockData object stores Simulink logging
%   information for signals related to a single block.
%
%   The Values field of this object may be a single MATLAB <a href="matlab: help timeseries"
%   >timeseries</a> or <a href="matlab: help timetable">timetable</a> or 
%   MATLAB struct of timeseries / timetables (to represent bus signals).
%
%   See also Simulink.SimulationData.Dataset,
%   Simulink.SimulationData.Signal,
%   Simulink.SimulationData.DataStoreMemory,
%   Simulink.SimulationData.BlockPath

 
% Copyright 2009-2024 The MathWorks, Inc.

    methods
        function out=BlockData
        end

        function out=copy(~) %#ok<STOUT>
            % Method to perform deep copy of values
            % This is only relevant when Values contains SimulationDatastores
        end

        function out=disp(~) %#ok<STOUT>
            % Display function for BlockData objects.
        end

        function out=find(~) %#ok<STOUT>
            % find must return an Element or Dataset of a contained element.
            % Because this class contains no objects of type Element, we return
            % empty. Note that bus data is stored in structure format and
            % therefore using find to return a part of the bus is not useful.
            % For example, to find element "c" in the bus:
            %   >> ds.find('my_bus').a.b.c
        end

        function out=isequal(~) %#ok<STOUT>
        end

        function out=isequaln(~) %#ok<STOUT>
        end

        function out=plot(~) %#ok<STOUT>
            % Plot the signal data in the Simulation Data Inspector
        end

    end
    properties
        %BlockPath -  Location of block that logged this data
        BlockPath;

        %Values -  Time and data that were logged
        Values;

    end
end
