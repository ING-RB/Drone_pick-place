classdef TabInteractor < matlab.uiautomation.internal.interactors.AbstractComponentInteractor
    % This class is undocumented and subject to change in a future release
    
    % Copyright 2016-2019 The MathWorks, Inc.
    
    methods
        
        function uichoose(actor)
            import matlab.uiautomation.internal.interactors.TabGroupInteractor;
            
            tab = actor.Component;
            
            % must be parented to check if it's already selected
            if isempty( ancestor(tab, 'root') )
                error( message('MATLAB:uiautomation:Driver:RootDescendant') );
                % Otherwise we can assume standard parenting-rules apply
            end
            
            % dispatch on the tabgroup
            tabgroup = tab.Parent;
            groupActor = TabGroupInteractor(tabgroup, actor.Dispatcher);
            
            index = find(tabgroup.Children == tab, 1);
            uichoose(groupActor, index);
        end
        
    end
    
end