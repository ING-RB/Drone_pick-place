classdef BaseObject < handle
    properties
        Tag = '';
        Enabled = true;
        Tooltip = '';
    end
    
    properties(SetAccess=protected)
        Type = '';
    end    
end