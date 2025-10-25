classdef AbstractDialogGC < ctrluis.component.AbstractGC & ctrluis.component.MixedInDialog
    % Super class for any Dialog GC as part of TC/GC pair implementation 
    
    % Author(s): Rong Chen
    % Copyright 2014 The MathWorks, Inc.
    
    methods(Access = public)
        
        function this = AbstractDialogGC(tcpeer)
            % The constructor takes in an AbstractTC object
            %   obj = AbstractDialogGC(tcpeer)
            
            % super
            this = this@ctrluis.component.AbstractGC(tcpeer);
        end
        
    end
    
end