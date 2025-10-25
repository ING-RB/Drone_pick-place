classdef (Hidden) TickComponentController < ...
        appdesservices.internal.interfaces.controller.AbstractControllerMixin
    
    % TICKCOMPONENTCONTROLLER This is controller class for any component
    % with tick properties.
    
    % Copyright 2011-2021 The MathWorks, Inc.
    
    methods
        function obj = TickComponentController(varargin)
            obj.NumericProperties = [obj.NumericProperties, {'Value', 'MajorTicks', 'MinorTicks', 'Limits'}];
        end
    end
    
    methods(Access = 'protected')
        
        function viewPvPairs = getTickPropertiesForView(obj, propertyNames)
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

            checkFor = ["MajorTickLabelsMode", "MajorTicksMode", "MinorTicksMode"];
            isPresent = ismemberForStringArrays(checkFor, propertyNames);
                        
            % Tick - related
            if isPresent(1) || isPresent(2)
                % Labels should always the server value, no matter
                % if MajorTickLabelsMode is auto or manual, the client will
                % take care of this requirement
                [majorTickLabelsMode, mode] = obj.getModePropertyForView(obj.Model.MajorTicksMode, obj.Model.MajorTickLabelsMode);

                viewPvPairs = [viewPvPairs, ...
                    {'WidgetMajorTickLabelsMode', majorTickLabelsMode,...
                    'WidgetMajorTicksMode', mode}
                    ];
            end
            
            if isPresent(3)
                % When either changes, need to populate the Major Tick
                % labels
                viewPvPairs = [viewPvPairs, ...
                    {'WidgetMinorTicksMode', obj.Model.MinorTicksMode}
                    ];
            end
        end
        
        function changedPropertiesStruct = handlePropertiesChanged(obj, changedPropertiesStruct)
            changedPropertiesStruct = privatelyUpdateTicksProperties(obj, changedPropertiesStruct);
        end
        
        function handleEvent(obj, src, event)
            switch(lower(event.Data.Name))
                
                case 'tickschanged'
                    % At runtime, tick related properties are updated via an event
                    [~] = obj.privatelyUpdateTicksProperties(event.Data);
            end
            
        end
    end
    
    methods ( Access = 'private' )
        
        function changedPropertiesStruct = privatelyUpdateTicksProperties(obj, changedPropertiesStruct)
            
            % Update Private version of MajorTicks, MinorTicks and
            % MajorTickLabels so that the mode property is not flipped.
            
            % Handle a MajorTickLabels changed
            % If MajorTickLabels is empty, it will be passed to the server
            % as the empty double array []. We need to convert it to a cell
            % since MajorTickLabels only accept cells.
            if(isfield(changedPropertiesStruct, 'MajorTickLabels'))
                newLabels = changedPropertiesStruct.MajorTickLabels;
                if(isempty(newLabels) && isa(newLabels, 'double'))
                    newLabels = num2cell(newLabels);
                end
                % Change the value of MajorTickLabels on the structure
                % itself and let the super class handle the property
                % change.
                % The super class has some logic that sets MajorTickLabels
                % or not depending on the mode property. If we were to set
                % MajorTickLabels here, we would loose the logic in the
                % super class.
                obj.Model.handleMajorTickLabelsChanged(newLabels);
                changedPropertiesStruct = rmfield(changedPropertiesStruct, 'MajorTickLabels');
            end
            
            % While checking if MajorTicks has changed, we also need to
            % verify if the MajorTickLabelsMode has been modified
            % If it has been switched to manual, the labels should not be
            % updated - g1700885
            if(isfield(changedPropertiesStruct, 'MajorTicks'))
                if isfield(changedPropertiesStruct, 'MajorTickLabelsMode')
                    % Mode has changed
                    majorTickLabelsMode = changedPropertiesStruct.MajorTickLabelsMode;
                else
                    % Mode has not changed
                    majorTickLabelsMode = obj.Model.MajorTickLabelsMode;
                end
                % Pass MajorTickLabelsMode while handling
                % MajorTicksChanged
                obj.Model.handleMajorTicksChanged(changedPropertiesStruct.MajorTicks,majorTickLabelsMode);
                changedPropertiesStruct = rmfield(changedPropertiesStruct, 'MajorTicks');
            end
            
            if(isfield(changedPropertiesStruct, 'MinorTicks'))
                obj.Model.handleMinorTicksChanged(changedPropertiesStruct.MinorTicks);
                changedPropertiesStruct = rmfield(changedPropertiesStruct, 'MinorTicks');
            end
        end
    end

    methods(Static)
        function [majorTickLabelsMode, mode] = getModePropertyForView(majorTicksMode, majorTickLabelsMode)
            % When either changes, need to populate the Major Tick
            % labels

            % PROPERTY DEPENDENCY
            % Consider MajorTickLabelsMode when setting MajorTicksMode
            isMajorTicksManual = any(strcmp('manual', {majorTicksMode, majorTickLabelsMode}));
            if (isMajorTicksManual)
                mode = 'manual';
            else
                mode = majorTicksMode;
            end
        end
    end
    
end

