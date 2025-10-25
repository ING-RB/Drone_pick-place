classdef (Hidden) DoubleClickableComponent < appdesservices.internal.interfaces.model.AbstractModelMixin

    properties(NonCopyable, Dependent, AbortSet)
        
        DoubleClickedFcn matlab.internal.datatype.matlab.graphics.datatype.Callback = [];
    end
    
    properties(NonCopyable, Access = 'protected')
        % Internal properties
        %
        % These exist to provide:
        % - fine grained control to each properties
        % - circumvent the setter, because sometimes multiple properties
        %   need to be set at once, and the object will be in an
        %   inconsistent state between properties being set
                        
        PrivateDoubleClickedFcn matlab.internal.datatype.matlab.graphics.datatype.Callback = [];
    end
    
    events(NotifyAccess = {?appdesservices.internal.interfaces.model.AbstractModel})        
        DoubleClicked;
    end

    methods
        % ----------------------------------------------------------------------
        function set.DoubleClickedFcn(obj, newValue)
            % Property Setting
            obj.PrivateDoubleClickedFcn = newValue; 
            
            obj.markPropertiesDirty({'DoubleClickedFcn'});
        end
        
        function value = get.DoubleClickedFcn(obj)
            value = obj.PrivateDoubleClickedFcn;
        end
    end
end