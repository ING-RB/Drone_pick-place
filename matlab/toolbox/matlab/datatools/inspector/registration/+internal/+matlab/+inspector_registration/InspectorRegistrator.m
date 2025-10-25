classdef InspectorRegistrator < handle
    % This class is unsupported and might change or be removed without
    % notice in a future version.
    
    % This abstract class is the using during build time for the registration of
    % proxy views for the Property Inspector.
    
    % See inspector.internal.registrator.UIComponentsInspectorRegistrator as an
    % example.
    
    % Copyright 2018-2022 The MathWorks, Inc.

    % Public Abstract Methods
    methods(Access = public, Abstract = true)
        % Register the components with the inspector registration manager
        registerInspectorComponents(this);
        
        % Return the app name for registration
        name = getRegistrationName(this);
        
        % Return the file path for the registration file
        filename = getRegistrationFilePath(this);       
    end
    
    properties
        inspectorRegistrationManager;
    end
    
    methods
        % Constructor, creates the InspectorRegistrationManager instance
        function this = InspectorRegistrator()
            this.inspectorRegistrationManager = ...
                internal.matlab.inspector_registration.InspectorRegistrationManager();
        end
    end
end
