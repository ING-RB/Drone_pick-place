classdef (Hidden) NonserializableComponent < handle & appdesservices.internal.interfaces.model.AbstractModelMixin
    
    % NonserializableComponent provides the functionality to prevent
    % serialization of a component within uifigure.
    
    % Copyright 2016 The MathWorks, Inc.

    
    methods(Access = 'public')
        
        function obj = NonserializableComponent()
            
            % Do not save non serializable component
            obj.Serializable = 'off';
        end
        
        function s = saveobj(obj)
            % Saving an instance of an app object is not supported.
            s = obj;
  
            % Create and throw warning
            backTraceState = warning('query','backtrace');
            cleanup = onCleanup(@()warning(backTraceState));
            warning('off','backtrace');
            warning(message('MATLAB:ui:components:SavingDisabled', class(obj))); 
        end        
    end
end


