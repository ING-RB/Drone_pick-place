classdef TextTypable < handle
    % This class is undocumented and subject to change in a future release
    
    % Copyright 2016-2019 The MathWorks, Inc.
    
    methods (Sealed)
        
        function uitype(actor, text)
            
            narginchk(2, 2);
            
            H = actor.Component;
            
            editable = true;
            if isprop(H, "Editable")
                editable = H.Editable;
            end
                
            if any(string({editable, H.Enable}) == matlab.lang.OnOffSwitchState.off)
                error( message('MATLAB:uiautomation:Driver:MustBeEditableAndEnabled') );
            end
            
            validateattributes(text, {'char', 'string'}, {'scalartext'});
            
            text = char(text);
            actor.Dispatcher.dispatch(H, 'uitype', 'Text', text);
        end
        
    end
    
end