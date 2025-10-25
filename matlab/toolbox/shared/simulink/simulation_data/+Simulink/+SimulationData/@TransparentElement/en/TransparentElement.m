classdef TransparentElement< Simulink.SimulationData.Element
% SIMULINK.SIMULATIONDATA.TRANSPARENTELEMENT creates a TransparentElement object.
%   The Simulink.SimulationData.TransparentElement object is used to store
%   arrays and bus data (a structure with timeseries as leaves) within a data
%   structure. Because a Dataset requires each element to have a "name", it
%   is not possible to add arrays and structs directly to a dataset. To allow
%   this, this class is a thin wrapper to hold the structure and the name
%   of the array/structure. For example,
%
%   >> data.a = timeseries();
%   >> data.b = timeseries();
%   >> dataset.addElement(data);
%
%   When adding this element, a TransparentElement object will be constructed
%   to store the structure with the name "data". This structure is then
%   accessed directly:
%
%   >> data = dataset.find('data')
%   >> class(data)
%   ans =
%   struct
%
%   See also Simulink.SimulationData.Dataset,
%   Simulink.SimulationData.Element, timeseries

 
% Copyright 2010-2024 The MathWorks, Inc.

    methods
        function out=TransparentElement
        end

        function out=copy(~) %#ok<STOUT>
            % Method to perform deep copy of values
        end

        function out=find(~) %#ok<STOUT>
        end

    end
    properties
        Values;

    end
end
