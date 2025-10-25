classdef SPIMaster < matlabshared.svd.SPI
    %SPIMASTER Summary of this class goes here
    %   Detailed explanation goes here
    
    %#codegen
    %#ok<*EMCA>
    methods
        function obj = SPIMaster(varargin)
            coder.allowpcode('plain');
            obj = obj@matlabshared.svd.SPI(varargin{:});
            
            obj.Mode = 'Master';            
            % Support name-value pair arguments
            setProperties(obj,nargin,varargin{:});
        end
    end

    methods(Access = protected)
        function flag = isInactivePropertyImpl(obj,prop)
            % Return false if property is visible based on object 
            % configuration, for the command line and System block dialog
            flag = isInactivePropertyImpl@matlabshared.svd.SPI(obj, prop);
            switch prop
                case {'Mode'}
                    flag = true;
            end
        end
    end
    
    methods(Static, Access=protected)
        function [groups, PropertyListMain, PropertyListAdvanced] = getPropertyGroupsImpl
            [groups, PropertyListMainOut, PropertyListAdvancedOut] = matlabshared.svd.SPI.getPropertyGroupsImpl;

            % Output property list if requested
            if nargout > 1
                PropertyListMain = PropertyListMainOut;
                PropertyListAdvanced = PropertyListAdvancedOut;
            end
        end
    end
end
