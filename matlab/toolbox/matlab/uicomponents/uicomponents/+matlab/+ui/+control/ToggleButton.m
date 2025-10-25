classdef (Sealed, ConstructOnLoad=true) ToggleButton < ...
        matlab.ui.control.internal.model.AbstractMutualExclusiveComponent & ...
        matlab.ui.control.internal.model.mixin.ButtonComponent & ...
        matlab.ui.control.internal.model.mixin.FontStyledComponent & ...     
        matlab.ui.control.internal.model.mixin.FocusableComponent & ...   
        matlab.ui.control.internal.model.mixin.IconIDableComponent & ...
        matlab.ui.control.internal.model.mixin.InterpretableComponent
    %
    
    % Do not remove above white space
    % Copyright 2014-2023 The MathWorks, Inc.


    methods
                
        function obj = ToggleButton(varargin)
            %
            
            % Do not remove above white space
            % Defaults 
            defaultLocation = [10, 10];
			obj.PrivateInnerPosition(1:2) = defaultLocation;
			obj.PrivateOuterPosition(1:2) = defaultLocation;
            defaultSize = [100, 22];
			obj.PrivateInnerPosition(3:4) = defaultSize;
			obj.PrivateOuterPosition(3:4) = defaultSize;
            obj.Type = 'uitogglebutton';
            
            % Override the default values 
            obj.doSetPrivateHorizontalAlignment('center');
            defaultText =  getString(message('MATLAB:ui:defaults:togglebuttonText'));
            obj.doSetPrivateText(defaultText);
 
            parsePVPairs(obj,  varargin{:});
                                                
        end
                
    end
           
    
    % ---------------------------------------------------------------------
    % Custom Display Functions
    % ---------------------------------------------------------------------
    methods(Access = protected)
        
        function names = getPropertyGroupNames(obj)
            % GETPROPERTYGROUPNAMES - This function returns common
            % properties for this class that will be displayed in the
            % curated list properties for all components implementing this
            % class.
            
            names = {'Value', ...
                'Text',...
                'Icon'};
                
        end
        
        function str = getComponentDescriptiveLabel(obj)
            % GETCOMPONENTDESCRIPTIVELABEL - This function returns a
            % string that will represent this component when the component
            % is displayed in a vector of ui components.
            str = obj.Text;
        
        end
    end
    
    methods(Access='public', Static=true, Hidden=true)
      function varargout = doloadobj( hObj) 
          % DOLOADOBJ - Graphics framework feature for loading graphics
          % objects
          
          % on component loading, property set will not trigger marking 
          % dirty, so disable view property cache
          % Todo: enable it when we have a better design for loading
          % Todo: need a better way to disable cache instead of in invidudal
          % subclass
          hObj.disableCache();
          
          hObj = doloadobj@matlab.ui.control.internal.model.mixin.IconableComponent(hObj);
          varargout{1} = hObj;
      end
    end

    methods (Hidden, Static) 
        function modifyOutgoingSerializationContent(sObj, obj) 

           % sObj is the serialization content for obj 
           modifyOutgoingSerializationContent@matlab.ui.control.internal.model.mixin.FontStyledComponent(sObj, obj);
           modifyOutgoingSerializationContent@matlab.ui.control.internal.model.mixin.ButtonBackgroundColorableComponent(sObj, obj);
        end
        function modifyIncomingSerializationContent(sObj) 

           % sObj is the serialization content that was saved for obj 
           modifyIncomingSerializationContent@matlab.ui.control.internal.model.mixin.FontStyledComponent(sObj);
           modifyIncomingSerializationContent@matlab.ui.control.internal.model.mixin.ButtonBackgroundColorableComponent(sObj);
        end 

    end
end



