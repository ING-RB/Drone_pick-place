classdef AppDDUXTimingManager < handle
    %AppDDUXTimingManager Manages the events for DDUX timing

%   Copyright 2024 The MathWorks, Inc.

    methods
        function obj = AppDDUXTimingManager(ams)
            addlistener(ams, 'AppDDUXTimingMarker',...
                @(src,e)obj.markerCallback(e));

            addlistener(ams, 'AppDDUXLogRunning',...
                @(src,e)obj.logAppRunningCallback(e));
        end
    end

    methods (Access = private)
        function markerCallback(~, event)
            validateattributes(event, {'appdesigner.internal.ddux.CreateAppDDUXTimingMarkerEventData'},{});

            if isprop(event.App, "TimingFields") && isprop(event.App.TimingFields, event.DDUXField)
                event.App.TimingFields.(event.DDUXField) = event.MarkerTime;
            end
        end

        function logAppRunningCallback(obj, event)
            validateattributes(event, {'appdesigner.internal.ddux.CreateAppDDUXLogRunningEventData'},{});

            appdesigner.internal.async.AsyncTask(@() obj.logAppRunning(event.App, event.Figure, event.FileName)).run();
        end

        function logAppRunning(obj, app, uiFigure, fileName)
            try
                % Do not log app running information if it's a deployed app
                if isdeployed()
                    return
                end

                mlappMetadataReader = mlapp.internal.MLAPPMetadataReader(fileName);
                metadata = mlappMetadataReader.readMLAPPMetadata();

                if isempty(metadata) || ~isfield(metadata, 'Uuid') || isempty(metadata.Uuid)
                    % The app does not have a Uuid, therefore do not
                    % log any running information
                    return;
                end

                dataToLog.appUuid = metadata.Uuid;

                [~, ~, ext] = fileparts(fileName);
                dataToLog.fileFormat = extractAfter(ext, 1);

                % Filename hash value
                digestBytes = matlab.internal.crypto.BasicDigester("DeprecatedSHA1");
                uint8Digest = digestBytes.computeDigest(fileName);
                fileNameHash = sprintf('%2.2x', double(uint8Digest));
                dataToLog.fileNameHash = fileNameHash;

                % App is running from MATLAB
                dataToLog.appRunPlatform = 'MATLAB';

                % Capture what type of app is running (Responsive, standard)
                dataToLog.appType = metadata.AppType;

                % Capture component information
                %
                % - Only components that can appear in App Designer for now,
                % limited by those parent classes to WebComponent and UIAxes.
                %
                % - Obfuscate ComponentContainer classes

                allAppComponents = findall(uiFigure);
                componentsToKeepIdx = arrayfun(@(h) isa(h, 'matlab.ui.control.WebComponent') || isa(h, 'matlab.ui.control.UIAxes'), allAppComponents);
                componentsToKeep = allAppComponents(componentsToKeepIdx);

                % Find Component Containers
                classList = arrayfun(@class, componentsToKeep, 'UniformOutput', false);
                componentContainersIdx = arrayfun(@(h) isa(h, 'matlab.ui.componentcontainer.ComponentContainer'), componentsToKeep);

                % Obfuscate Component Containers
                for idx = find(componentContainersIdx)'
                    uint8Digest = digestBytes.computeDigest(classList{idx});
                    obfuscatedName = ['UAC_', sprintf('%2.2x', double(uint8Digest))];
                    classList{idx} = obfuscatedName;
                end

                % Count and associate unique class names
                [d, uniqueClasses] = findgroups(classList);
                counts = histcounts(d);

                dataToLog.componentClasses = uniqueClasses;
                dataToLog.componentCounts = counts;


                if (isprop(app, 'Simulation') && isa(app.Simulation, 'simulink.Simulation'))
                    if isempty(app.Simulation)
                        dataToLog.simulinkModelUuid = '';
                        dataToLog.simulinkModelNameHash = '';
                    else
                        dataToLog.simulinkModelUuid = app.Simulation.getModelParameter('ModelUUID').Value;
                        uint8Digest = digestBytes.computeDigest(app.Simulation.ModelName);
                        dataToLog.simulinkModelNameHash = sprintf('%2.2x', double(uint8Digest));
                    end
                end

                % Send when Figure is ready
                matlab.ui.internal.dialog.DialogHelper.dispatchWhenViewIsReady(uiFigure, @() sendDDUXData(obj, app, uiFigure, dataToLog));

            catch me
                % no-op. Catch exception to avoid displaying errors to user
            end
        end

        function sendDDUXData(~, app, uiFigure, dataToLog)
            try
                % Assemble timestamps last so that they are populated
                %
                % Specifically, 'ServerEnded' requires Figure controllers /
                % Viewmodels to be fully populated
                dataToLog = app.TimingFields.addCommonTimingFields(dataToLog);

                % Add plain text specific timing fields
                if strcmp(dataToLog.fileFormat, 'm')
                    dataToLog = app.TimingFields.addPlainTextTimingFields(dataToLog);
                end

                % The channel needs to be unique to the figure
                %
                % Otherwise all open UIFigures would respond
                channel = ['/appmanagementservice/ddux/' uiFigure.Uuid];
                message.publish(channel, dataToLog);
            catch me
                % no-op. Catch exception to avoid displaying errors to user
            end
        end
    end
end
