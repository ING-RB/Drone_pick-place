classdef MappingInspectorRegistrator < internal.matlab.inspector_registration.InspectorRegistrator
    % Registers component property inspector views
    %
    % This will be called during the property inspector build process.

    % Copyright 2022-2024 The MathWorks, Inc.

    properties (Constant)
        % The graphics inspector provides the default inspector views
        RegistrationName = 'default';
    end

    methods(Static)
        function path = getRegistrationFilePath()
            path = fullfile(toolboxdir("shared"), "maputils", "resources");
        end

        function name = getRegistrationName()
            name = inspector.internal.registrator.MappingInspectorRegistrator.RegistrationName;
        end
    end

    methods
        function obj = MappingInspectorRegistrator
            obj@internal.matlab.inspector_registration.InspectorRegistrator;
        end

        function registerInspectorComponents(obj)
            p = obj.getRegistrationFilePath();
            if ~exist(p, "dir")
                % Create the registration file directory if it doesn't exist already.  Because there
                % are no other files in that directory, it may not exist yet.
                mkdir(p);
            end

            applicationNames = {
                'default' ...
                };

            % Components To Register
            %
            % This list should be able to be updated without needing to update any code
            % further down

            components = {
                'map.graphics.axis.MapAxes',...
                'map.graphics.chart.primitive.Point',...
                'map.graphics.chart.primitive.Line',...
                'map.graphics.chart.primitive.Polygon',...
                'map.graphics.chart.primitive.IconChart',...
                'globe.graphics.GeographicGlobe',...
                };

            % Loop over all components
            for componentIdx = 1:length(components)

                componentFullName = components{componentIdx};
                indices = regexp(componentFullName, '\.');
                componentShortName{componentIdx} = componentFullName(indices(end) + 1 : end);
            end

            % Add HeightReferencedLine which needs a distinct name
            components{end+1} = 'map.graphics.primitive.Line';
            componentShortName{end+1} = 'HeightReferencedLine';

            for componentIdx = 1:length(components)
                componentFullName = components{componentIdx};
                
                % Assume its map.graphics.internal.propertyinspector.views.<ShortName>PropertyView
                %
                % Ex:
                % map.graphics.internal.propertyinspector.views.PolygonPropertyView
                propertyViewClass = sprintf('map.graphics.internal.propertyinspector.views.%sPropertyView', ...
                    componentShortName{componentIdx});

                % Loop over all applications
                for applicationIdx = 1:length(applicationNames)

                    applicationName = applicationNames{applicationIdx};

                    try
                        defaultObj = feval(componentFullName);
                    catch
                        defaultObj = [];
                    end

                    % Register all the objects specified
                    obj.inspectorRegistrationManager.registerInspectorView(...
                        componentFullName, ...
                        applicationName, ...
                        propertyViewClass, ...
                        defaultObj ...
                        );

                    if ~isempty(defaultObj)
                        delete(defaultObj);
                    end
                end
            end
        end
    end
end
