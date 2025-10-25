classdef EnableArduinoHotPlug < handle
    %EnableArduinoHotPlug Singleton class to hold properties (feature switch) for
    %Arduino DPDM.
    
    % Copyright 2016 The MathWorks, Inc.
    
    properties %(Access = private)
        EnableArduinoDPDM
    end
    
    methods (Access = private)
        function obj = EnableArduinoHotPlug()
            obj.EnableArduinoDPDM = 1;
        end
    end
    
    methods
        % setter
        function setEnableArduinoDPDM(obj,value)
            validateattributes(value, {'logical','double'}, {'nonempty','binary'});
            obj.EnableArduinoDPDM = value;
        end
    end
    
    methods (Static)
        function obj = getInstance()
            % Prevent clearing of persistant varible from memory when
            % 'clear classes' run.  This will avoid reinitialization of
            % singleton class whenever clear classes is run.
            mlock;
            persistent EnableArduinoInstance;
            
            if isempty(EnableArduinoInstance) || ~isvalid(EnableArduinoInstance)
                EnableArduinoInstance = internal.deviceplugindetection.EnableArduinoHotPlug;
            end
            
            obj = EnableArduinoInstance;
        end
        
        function unlockEnableArduinoHotPlug()
            % unlockManager Unlocks the manager function to allow clearing from memory.
            %
            %   This function provides a mechanism whereby the device plugin
            %   detection manager can be unlocked and cleared from memory.
            
            % Unlock the singleton instance function for the manager.
            munlock;
            munlock('internal.deviceplugindetection.EnableArduinoHotPlug');
        end
        
    end
end