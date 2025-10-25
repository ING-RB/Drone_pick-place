classdef UnsupportedComponentRemover < appdesigner.internal.serialization.loader.interface.DecoratorLoader
    %UNSUPPORTEDCOMPONENTREMOVER A decorator class that removes unknown components from the app
    
    % Copyright 2017-2021 The MathWorks, Inc.
    
    methods
        
        function obj = UnsupportedComponentRemover(loader)
            obj@appdesigner.internal.serialization.loader.interface.DecoratorLoader(loader);
        end
        
        function appData = load(obj)
            appData = obj.Loader.load();
            obj.removeUnsupportedComponents(appData.components.UIFigure);
        end
        
    end
    
    methods (Access='private')
        
        function removeUnsupportedComponents(obj, uifigure)
            % remove unsupported components unknown to the release
            
            % get the suppported component types
            adapterMap = appdesigner.internal.application.getComponentAdapterMap();
            supportedComponentTypes = adapterMap.keys;
            
            % retrieve all components under the UIFigure and delete them if
            % not a supported component type.  Go in reverse order so as
            % not to delete components in the middle of the array while
            % looping.  It also guarantees that components within
            % containers are listed before the container
            
            components = findall(uifigure, '-property', 'DesignTimeProperties');
            
            for idx = length(components):-1:1
                component = components(idx);
                
                % Always keep user components in the file.  If they are
                % unknown, they will have been removed during the MAT-file
                % loading process.  The component adapter map will not know
                % about the particular user class, so skip checking if this
                % component's class is in the map.
                if isa(component, 'matlab.ui.componentcontainer.ComponentContainer')
                    if obj.isUnlicensedToolboxUserComponent(component)
                        delete(component);
                    else
                       continue;
                    end
                elseif (~any(strcmp(class(component), supportedComponentTypes)))
                    % Unknown
                    delete(component);
                else
                    % Known, but maybe not licensed
                    %
                    % Asked the adapter
                    adapterClass = adapterMap(class(component));
                    adapterInstance = feval(adapterClass);
                    isAvailable = adapterInstance.isAvailable();
                    
                    % Delete if not available
                    if(~isAvailable)
                        delete(component);
                    end
                end
            end
        end


        function isUnlicensed = isUnlicensedToolboxUserComponent(~, component)
            % returns true if the component is an internal toolbox user
            % component and doesn't have a valid license. Temporary
            % workaround for g2443267.

            isUnlicensed = false;

            componentClass = class(component);

            % As a temporary workaround, hard coding a license check
            % against SLRT components because they use a generic user
            % component adapter that doesn't perform the license check (see
            % g2443267).
            if startsWith(componentClass, 'slrealtime.ui.control')
                isUnlicensed = ~appdesigner.internal.license.LicenseChecker.isProductAvailable("xpc_target");
            end
        end
    end
end

