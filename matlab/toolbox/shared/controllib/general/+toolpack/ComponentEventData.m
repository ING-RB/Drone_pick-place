classdef (ConstructOnLoad) ComponentEventData < event.EventData
  % Event data associated with ComponentChanged events.
  
  % Author(s): Bora Eryilmaz
  % Revised:
  % Copyright 2009-2011 The MathWorks, Inc.
  
  % ----------------------------------------------------------------------------
  properties (Dependent, GetAccess = public, SetAccess = private)
    % Describes what has changed (read-only, default = []).
    EventData
  end
  
  properties (Access = protected)
    % Version
    Version = toolpack.ver();
  end
  
  properties (Access = private)
    % MATLAB object.
    EventData_
  end
  
  % ----------------------------------------------------------------------------
  methods
    function this = ComponentEventData(data)
      % Creates an event data object describing the component change.
      %
      % Example:
      %
      % data = struct('Name', 'Ident', 'Type', 'CLOSED');
      % obj = toolpack.ComponentEventData(data)
      
      if nargin == 1
        this.EventData = data;
      end
    end
    
    function value = get.EventData(this)
      % GET function for EventData property.
      value = this.EventData_;
    end
    
    function set.EventData(this, value)
      % SET function for EventData property.
      this.EventData_ = value;
    end
  end
end
