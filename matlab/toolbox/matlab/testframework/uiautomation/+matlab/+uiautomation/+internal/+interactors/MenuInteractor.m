classdef MenuInteractor < matlab.uiautomation.internal.interactors.AbstractComponentInteractor
    % This class is undocumented and subject to change in a future release
    
    % Copyright 2017-2018 The MathWorks, Inc.
    
    methods
        
        function uipress(actor, varargin)
            
            narginchk(1,1);
            
            menu = actor.Component;
            if ~isempty(menu.Children)
                error( message('MATLAB:uiautomation:Driver:NotALeafMenu') );
            end
            
            if isempty( ancestor(menu, 'root') )
                error( message('MATLAB:uiautomation:Driver:RootDescendant') );
                % Otherwise we can assume standard parenting-rules apply
            end
            
            actor.Dispatcher.dispatch(menu, 'flush');

            doTopDown(menu)
            
            function doTopDown(menu)
                parent = menu.Parent;
                if parent.Type == "uimenu"
                    doTopDown(parent)
                end
                
                actor.Dispatcher.dispatch(menu, 'uipress');
            end
            
        end
        
    end
    
end

