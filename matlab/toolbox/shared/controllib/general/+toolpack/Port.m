classdef Port < handle
    %Creates an interface port for use by a tool component.
    %
    %  p = toolpack.Port(MODEL,PORTNUMBER) creates a port for a tool
    %  component and assign it an index string PORTNUMBER representing
    %  integer values; the default when not specified is '1'. The data of
    %  the port can be anything and is set by
    %
    %    p.Data = VALUE;
    %
    %  where VALUE is the new data.
    %
    %  The following properties and methods are defined by this class. For
    %  inherited properties and methods, type DOC followed by the full
    %  classname.
    %
    %  Port Properties:
    %     PortNumber              - number of the port of identification
    %     Data                    - data held by the port
    %
    %  Port Methods:
    %     getComponent            - component to which the port is attached
    %
    %  See also Connector.
    
    % Author(s): Murad Abu-Khalaf , October 11, 2010
    % Revised:
    % Copyright 2010-2011 The MathWorks, Inc.
    
    
    %% ----------------------------------- %
    % Properties                           %
    % ------------------------------------ %
    properties (Access = private)
        % The tool component to which this port is attached.
        Component
        ComponentListener
    end
    
    properties (Access = public)
        % Name of the port
        PortNumber
        
        % Data held by the port
        Data
    end
    
    properties (Access = protected)
        % Class version
        Version = toolpack.ver();
    end
    
    %% ----------------------------------- %
    % Events                               %
    % ------------------------------------ %
    events
        % Event broadcasted when data of the port is updated.
        PortChanged
    end
    
    %% ----------------------------------- %
    % Port Construction - Destruction      %
    % ------------------------------------ %
    methods
        function this = Port(model,varargin)
            % Constructor requiring the arguments MODEL, NAME, DATA.
            this.Component = model;
            this.ComponentListener = event.listener(this.Component,'ObjectBeingDestroyed',@(x,y) this.delete);
            if nargin > 1 && ischar(varargin{1})
                this.PortNumber = varargin{1};
            else
                this.PortNumber = '1';
            end
            this.Data = {};
        end
        function delete(this)
%             disp([class(this) ' is deleting...']);
        end
    end
    
    %% ----------------------------------- %
    % SERILIZATION                         %
    % ------------------------------------ %
    methods
        % Never saved or loaded like AbstractGraphicalComponent??
        %         function S = saveobj(obj) %#ok<STOUT,MANU>
        %         end
        %
        %         function obj = reload(obj, S) %#ok<INUSD>
        %         end
    end
    
    %% ----------------------------------- %
    % Execution                            %
    % ------------------------------------ %
    methods
        % Set the data of the port
        function set.Data(this,value)
            this.Data = value;
            
            % Notify listeners to this object of a Portchanged event
            notify(this,'PortChanged', toolpack.PortEventData(value));
        end
        
        % Set the name of the port
        function set.PortNumber(this,number)            
            if isnumeric(number)
                number = int2str(number);
            end
            this.PortNumber = number;
        end
        
        % Returning the tool component to which this port is attached
        function r = getComponent(this)
            r = this.Component;
        end
    end
end
