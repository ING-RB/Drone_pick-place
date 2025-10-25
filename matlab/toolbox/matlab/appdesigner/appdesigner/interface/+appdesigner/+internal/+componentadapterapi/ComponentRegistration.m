classdef ComponentRegistration < handle
    %
    %ComponentRegistration  An interface to provide information about a component
    %    The ComponentRegistration class is an interface component authors
    %    will implement to provide the App Designer with information
    %    about a component
    %
    %    ComponentRegistration methods:    
    %        getJavaScriptAdapter - the client side adapter's module
    %        getComponentDesignTimeDefaults - structure of component default values
    %                                        to be used on the client
    %        getComponentRuntimeDefaults - structure of run time component default values
    
    %    Copyright 2013-2021 The MathWorks, Inc.
            
    properties(Abstract, SetAccess=protected, GetAccess=public)
        % The component's type
        %
        %    The value must be unique among all components so an
        %    example would be the concatenation of the component's
        %    package and class name
        %
        %    Example:
        %       type = 'matlab.ui.control.Button'
        ComponentType
    end
    
    methods
        function docString = getDocString(obj)
            % By default, the docString will return the ComponentType
            %
            % This method can be overriden if needed, the doc string is
            % different.  
            % 
            % NOTE - if it is overriden, it needs to be defined statically,
            % because that is how it is called in
            % UIComponentsInspectorRegistrator.m.

            docString = obj.ComponentType;
        end
    end            
    
    methods(Static,Abstract)
        %getJavaScriptAdapter  Return the client side adapter's module
        %
        %    adapter = getJavaScriptAdapter will return the module name of
        %    the adapter to be used on the client.
        %
        %    The return value should be the name of the module as it would
        %    need to be loaded by the Dojo loader.
        %
        %    Example:
        %       adapter = 'visualcomponents\adapters\AngularGaugeAdapter'
        adapter = getJavaScriptAdapter()
    end
    
    methods(Abstract)
        % getComponentDesignTimeDefaults  Return a pvPair array of design-time
        %                                 component default
        
        %    pvPairs = getComponentDesignDefaults will return a pvPair array of
        %              component default values
        %
        pvPairs = getComponentDesignTimeDefaults(obj)
        
        % getComponentRunTimeDefaults  Return a pvPair array of run-time
        %                              component default values
        
        %    pvPairs = getComponentRunTimeDefaults will return a pvPair array of
        %              component default values
        % theme = 'light' or 'dark' or 'unthemed'
        % parentType = Default is UIfigure. Few adapters override this method to provide a different parent type.
        % Example: PushTool which can only be parented to Toolbar
        %
        pvPairs = getComponentRunTimeDefaults(obj, theme, parentType)
    end
end


