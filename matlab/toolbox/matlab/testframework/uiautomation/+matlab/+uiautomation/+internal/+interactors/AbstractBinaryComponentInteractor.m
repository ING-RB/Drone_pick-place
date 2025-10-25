classdef (Abstract) AbstractBinaryComponentInteractor < matlab.uiautomation.internal.interactors.AbstractComponentInteractor & ...
                                                        matlab.uiautomation.internal.interactors.mixin.ContextMenuable
    % This class is undocumented and subject to change in a future release
    
    % Copyright 2016-2018 The MathWorks, Inc.
    
    methods
        
        function uipress(actor, varargin)
            
            narginchk(1, 1);
            
            actor.Dispatcher.dispatch(...
                actor.Component, 'uipress', varargin{:});
        end
        
        function uichoose(actor, value)
            
            narginchk(1, 2);
            
            if nargin < 2
                value = true;
            end
            
            validateattributes(value, {'logical'}, {'scalar'});
            
            component = actor.Component;
            
            if component.Value ~= value
                actor.uipress();
            end
            
        end
        
    end
    
end