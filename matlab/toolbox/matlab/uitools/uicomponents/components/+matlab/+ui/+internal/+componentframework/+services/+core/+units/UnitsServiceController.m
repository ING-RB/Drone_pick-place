classdef UnitsServiceController
    methods ( Static )
        
        
        % Methods for SERVER --> CLIENT communications
        
        % Returns ValueInUnitsMin
        %   ScreenResolution (MATLAB, not device)
        %   Units
        %   Value
        function valInUnitsStruct = getUnitsValueDataForView(objModel)
            % We currently do not need the Unit Service object from the Model
            % because we are not implementing UnitPos equivalent on the client side
            
            % For now, hardcode the screen resolution to 96--we do not want
            % to get into the business of converting between different DPI
            % for now at least
            import matlab.ui.internal.componentframework.services.core.units.UnitsServiceController.getPositionInPixelsForView
            switch(objModel.Units)
                case {'pixels', 'normalized'}
                    % Keep the values unchanged
                    value = objModel.Position;
                    units = objModel.Units;
                case {'characters', 'centimeters', 'inches',...
                        'points', 'devicepixels', 'platformpixels'}
                    % Convert the value to pixels
                    value = getPositionInPixelsForView(objModel, 'Position');
                    units = 'pixels';
            end
            
            valInUnitsStruct = struct('ScreenResolution', 96, 'Units',units, 'Value', value);
        end
        
        % PositionProp is a user visible position property ie Position,
        % OuterPosition, InnerPosition etc and NOT Size/Location
        function [sizeStruct, locationStruct] = getUnitsValueDataForSizeLocationView(objModel, posValue)
            import matlab.ui.internal.componentframework.services.core.units.UnitsServiceController; 
            units = 'pixels'; 
            if isprop(objModel, 'Units')
                switch(objModel.Units)
                    case {'pixels', 'normalized'}
                        units = objModel.Units; 
                    case {'characters', 'centimeters', 'inches', 'points'}
                        % Convert the value to pixels
                        posValue = UnitsServiceController.getPositionInPixelsForView(objModel, 'Position');
                        units = 'pixels'; 
                end
            end
            sizeStruct = struct('ScreenResolution', 96, 'Units', units, 'Value', posValue(3:4));
            locationStruct = struct('ScreenResolution', 96, 'Units', units, 'Value', posValue(1:2));
        end
        
        function units = getUnits(valInUnitsStruct)
            units = valInUnitsStruct.Units;
        end
        
        function valInUnits = getValue(valInUnitsStruct)
            valInUnits = valInUnitsStruct.Value;
        end
        
        function newValInUnitsStruct = setValueInUnitsValueDataForView(valInUnitsStruct, newVal)
            newValInUnitsStruct = valInUnitsStruct;
            newValInUnitsStruct.Value = newVal;
        end
        
        function valPosInPixels = getPositionInPixelsForView(objModel, propName)
            curUnits = objModel.Units;
            if strcmp(curUnits, 'pixels')
                valPosInPixels = objModel.(propName);
            else
                unitsService = objModel.getUnitsService();
                cleanupObj = onCleanup(@()...
                                    unitsService.setUnits('Units', curUnits)); 
    
                unitsService.setUnits('Units','pixels');
                valPosInPixels = unitsService.getValue(propName);
                unitsService.setUnits('Units',curUnits);
            end
        end
        
        % Methods for SERVER <-- CLIENT communications
        
        function value = getValueFromUnitsServiceClientEventData(evtStructure, propName)
            eventData = evtStructure.valuesInUnits;
            value = eventData.(propName).Value;
        end
       
        function value = getUnitsFromUnitsServiceClientEventData(evtStructure, propName)
            eventData = evtStructure.valuesInUnits;
            value = eventData.(propName).Units;
        end
        
    end
end