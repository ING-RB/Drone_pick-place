classdef (Hidden) ClickableComponent < appdesservices.internal.interfaces.model.AbstractModelMixin

    properties(NonCopyable, Dependent, AbortSet)
        
        ClickedFcn matlab.internal.datatype.matlab.graphics.datatype.Callback = [];
    end
    
    properties(NonCopyable, Access = 'protected')
        % Internal properties
        %
        % These exist to provide:
        % - fine grained control to each properties
        % - circumvent the setter, because sometimes multiple properties
        %   need to be set at once, and the object will be in an
        %   inconsistent state between properties being set
                        
        PrivateClickedFcn matlab.internal.datatype.matlab.graphics.datatype.Callback = [];
    end
    
    events(NotifyAccess = {?appdesservices.internal.interfaces.model.AbstractModel})        
        Clicked;
    end

    methods

        % ----------------------------------------------------------------------
        function set.ClickedFcn(obj, newValue)
            % Property Setting
            obj.PrivateClickedFcn = newValue; 
            
            obj.markPropertiesDirty({'ClickedFcn'});
        end
        
        function value = get.ClickedFcn(obj)
            value = obj.PrivateClickedFcn;
        end
    end
end