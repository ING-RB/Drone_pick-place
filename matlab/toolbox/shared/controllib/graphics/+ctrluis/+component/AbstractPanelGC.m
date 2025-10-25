classdef AbstractPanelGC < ctrluis.component.AbstractGC & ctrluis.component.MixedInPanel
    % Super class for any Panel GC as part of TC/GC pair implementation 
    
    % Author(s): Rong Chen
    % Copyright 2014 The MathWorks, Inc.
    
    methods(Access = public)
        
        function this = AbstractPanelGC(tcpeer)
            % The constructor takes in an AbstractTC object
            %   obj = AbstractPanelGC(tcpeer)
            
            % super
            this = this@ctrluis.component.AbstractGC(tcpeer);
        end
        
    end
    
end