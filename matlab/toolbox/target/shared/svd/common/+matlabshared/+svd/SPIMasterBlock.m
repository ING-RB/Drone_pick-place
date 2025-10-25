classdef (StrictDefaults)SPIMasterBlock < matlabshared.svd.SPIBlock
    %SPIMASTER Summary of this class goes here
    %   Detailed explanation goes here
    
    %#codegen
    %#ok<*EMCA>
    methods
        function obj = SPIMasterBlock(varargin)
            coder.allowpcode('plain');
            obj = obj@matlabshared.svd.SPIBlock(varargin{:});
            
            obj.Mode = 'Master';            
            % Support name-value pair arguments
            setProperties(obj,nargin,varargin{:});
        end
    end

    methods(Access = protected)
        function flag = isInactivePropertyImpl(obj,prop)
            % Return false if property is visible based on object 
            % configuration, for the command line and System block dialog
            flag = isInactivePropertyImpl@matlabshared.svd.SPIBlock(obj, prop);
            switch prop
                case {'Mode'}
                    flag = true;
            end
        end
    end
    
    methods(Static, Access=protected)
        function [groups, PropertyListMain, PropertyListAdvanced, SampleTimeProp] = getPropertyGroupsImpl
            [groups, PropertyListMainOut, PropertyListAdvancedOut] = matlabshared.svd.SPIBlock.getPropertyGroupsImpl;
            
            % Output property list if requested
            if nargout > 1
                PropertyListMain = PropertyListMainOut;
                PropertyListAdvanced = PropertyListAdvancedOut;
                SampleTimeProp = matlab.system.display.internal.Property('SampleTime', 'Description', 'svd:svd:SampleTimePrompt');
            end
        end        
    end
end
