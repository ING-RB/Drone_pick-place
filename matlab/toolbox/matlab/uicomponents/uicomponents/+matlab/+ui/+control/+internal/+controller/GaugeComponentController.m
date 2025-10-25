classdef (Hidden) GaugeComponentController < matlab.ui.control.internal.controller.ComponentController & ...
        matlab.ui.control.internal.controller.mixin.TickComponentController
	% GaugeComponentController This is controller class for all the gauges
	
	% Copyright 2011-2021 The MathWorks, Inc.
	
	methods
		function obj = GaugeComponentController(varargin)
            obj@matlab.ui.control.internal.controller.ComponentController(varargin{:});
			obj@matlab.ui.control.internal.controller.mixin.TickComponentController(varargin{:});
		end
	end
	
	methods(Access = 'protected')
		
		function viewPvPairs = getPropertiesForView(obj, propertyNames)
			% GETPROPERTIESFORVIEW(OBJ, PROPERTYNAME) returns view-specific
			% properties, given the PROPERTYNAMES
			%
			% Inputs:
			%
			%   propertyNames - list of properties that changed in the
			%                   component model.
			%
			% Outputs:
			%
			%   viewPvPairs   - list of {name, value, name, value} pairs
			%                   that should be given to the view.
			import appdesservices.internal.util.ismemberForStringArrays;
            
			viewPvPairs = {};
			
			% Tick Properties from super
			viewPvPairs = [viewPvPairs, ...
				getTickPropertiesForView(obj, propertyNames), ...
                getPropertiesForView@matlab.ui.control.internal.controller.ComponentController(obj, propertyNames) ...
				];
		end
		
		% Handle Gauge specific property sets
		function changedPropertiesStruct = handlePropertiesChanged(obj, changedPropertiesStruct)
			
			% Figure out what properties changed
			changedProperties = fieldnames(changedPropertiesStruct);			
			
			if(isfield(changedPropertiesStruct, 'ValueDisplayVisible'))
				newValue = changedPropertiesStruct.ValueDisplayVisible;
				
				% Convert true/false to on/off
				newValue = matlab.ui.control.internal.model.PropertyHandling.convertTrueFalseToOnOff(newValue);
				
				obj.Model.ValueDisplayVisible = newValue;
				
				% Mark the property as handled
				changedPropertiesStruct = rmfield(changedPropertiesStruct, 'ValueDisplayVisible');
			end
			
			% Call the superclass for unhandled properties
			changedPropertiesStruct = handlePropertiesChanged@matlab.ui.control.internal.controller.mixin.TickComponentController(obj, changedPropertiesStruct);
			handlePropertiesChanged@matlab.ui.control.internal.controller.ComponentController(obj, changedPropertiesStruct);
        end
       
        function handleEvent(obj, src, event)
            handleEvent@matlab.ui.control.internal.controller.mixin.TickComponentController(obj, src, event);
            handleEvent@matlab.ui.control.internal.controller.ComponentController(obj, src, event);
        end
	end
	
end
