classdef ButtonInteractor < matlab.uiautomation.internal.interactors.AbstractComponentInteractor & ...
                            matlab.uiautomation.internal.interactors.mixin.ContextMenuable
    % This class is undocumented and subject to change in a future release
    
    % Copyright 2016-2019 The MathWorks, Inc.
    
    methods
        
        function uipress(actor, varargin)
            
            narginchk(1, 1);
            
            actor.Dispatcher.dispatch(...
                actor.Component, 'uipress', varargin{:});
        end
        
    end
    
end