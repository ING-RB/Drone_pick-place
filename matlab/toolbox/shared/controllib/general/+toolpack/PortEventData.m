classdef (ConstructOnLoad) PortEventData < event.EventData
    % Port event data associated with tool components.
    
    %   Author(s): Murad Abu-Khalaf , October 11, 2010
    %   Revised:
    %   Copyright 2010 The MathWorks, Inc.
    
    % ----------------------------------------------------------------------------
    properties (Dependent, GetAccess = public, SetAccess = private)
        % Describes what has changed (read-only string, default = '').
        PortData
    end
    
    properties (Access = protected)
        % Version
        Version = toolpack.ver();
    end
    
    properties (Access = private)
        % String or [] for default value ''.
        PortData_
    end
    
    % ---------------------------------------------------------------------
    methods
        function this = PortEventData(data)
            % Creates an event data object describing the component change.
            %
            % Example: obj = toolpack.ComponentEventData('xlimits')
            if nargin < 1
                % Default argument
                data = [];
            end
            this.PortData = data;
        end
    end
    
    % ---------------------------------------------------------------------
    methods
        function value = get.PortData(this)
            % GET function for ChangeName property.
            value = this.PortData_;
            if isempty(value)
                value = ''; % default
            end
        end
        
        function set.PortData(this, value)
            % SET function for ChangeName property.
            if isempty(value)
                value = [];
            else
%                 if ~ischar(value)
%                     ctrlMsgUtils.error('Controllib:toolpack:StringArgumentNeeded')
%                 end
            end
            this.PortData_ = value;
        end
    end
end
