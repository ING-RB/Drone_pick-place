classdef AppController < ...
        appdesservices.internal.interfaces.controller.AbstractController & ...
        appdesservices.internal.interfaces.controller.AppDesignerParentingController & ...
        appdesigner.internal.appalert.AppAlertController

    % AppController is the controller for an App.

    % Copyright 2013-2024 The MathWorks, Inc.

    properties (Constant)
        CURRENT  = 'CURRENT';
    end

    properties (Access = private)
        ActionCompletedObserver

        PropertiesSetListener
    end

    methods
        function obj = AppController(varargin)
            obj = obj@appdesservices.internal.interfaces.controller.AbstractController(varargin{:});

            % construct the DesignTimeParentingController with the factory to
            % create model child objects
            factory = appdesigner.internal.model.AppChildModelFactory;
            obj = obj@appdesservices.internal.interfaces.controller.AppDesignerParentingController(factory);

            obj.ActionCompletedObserver = appdesigner.internal.application.observer.AppActionObserver;
        end

        function populateView(obj, proxyView)
            populateView@appdesservices.internal.interfaces.controller.AbstractController(obj, proxyView);
            populateView@appdesservices.internal.interfaces.controller.AppDesignerParentingController(obj, proxyView);

            if ~isempty(proxyView) && ~isempty(proxyView.PeerNode)
                % Set up propertiesSet event listener
                obj.PropertiesSetListener = addlistener(proxyView.PeerNode, 'propertiesSet', ...
                    obj.wrapLegacyProxyViewPropertiesChangedCallback(@obj.handlePropertiesChanged));
            end

            % Set IsServerSideReady property to let client know that server-side
            % objects for app are created, and so it's good for client-side
            % to send event through app PeerNode, for instances, run or
            % save an app
            % In the future, if more and more peernode basded objects need
            % this mechnism, we can consider moving it up to
            % AbstractController as a framework.
            obj.ViewModel.setProperties({'IsServerSideReady', true});
        end
    end

    methods (Access = {?appdesigner.internal.document.AppDocument})
        function completionObserver = saveApp(obj, fileName)
            obj.ClientEventSender.sendEventToClient('saveAppFromServer', ...
                { 'FileName', fileName });

            % Return an observer so the caller can know when the save has
            % been completed on the server.
            completionObserver = appdesigner.internal.application.observer.AppSavedObserver(obj.ActionCompletedObserver);
        end

        function closeApp(obj, fileName, forceClose)
            narginchk(2, 3);
            if nargin == 2
                forceClose = false;
            end

            obj.ClientEventSender.sendEventToClient('closeAppFromServer', ...
                { 'FileName', fileName, 'ForceClose', forceClose });

            % We do not need to sync any info from the client here so do
            % not return a completion observer.
        end

        function setActiveApp(obj)
            obj.ClientEventSender.sendEventToClient('setActiveAppFromServer', {});

            % We do not need to sync any info from the client here so do
            % not return a completion observer.
        end
    end

    methods(Access = 'protected')

        function propertyNames = getAdditionalPropertyNamesForView(~)
            % Additional properties needed by the App Controller
            propertyNames = {'Name', 'FullFileName', 'IsLaunching', 'IsDebugging', 'ScreenshotPath', 'HasRunSinceLastSave'};
        end

        function pvPairsForView = getPropertiesForView(~, ~)
            % GETPROPERTIESFORVIEW(OBJ, PROPERTYNAMES) gets the properties that
            % will be needed by the view when properties change.
            %
            % Inputs:
            %
            %  propertyNames - a cell array of strings containing the names
            %                  of the property names

            % Right now, there are no App-related properties that need
            % specific conversion
            pvPairsForView = {};
        end

        function handleEvent(obj, ~, event)
            % HANDLEEVENT(OBJ, SOURCE, EVENT) This method receives event from
            % ProxyView class each time a user interacts with the visual
            % representation through mouse or keyboard. The controller sets
            % appropriate properties of the model each time it receives
            % these events.
            %
            % Inputs:
            %
            %   source  - object generating event, i.e ProxyView class object.
            %
            %   event   - the event data that is sent from the ProxyView. The
            %             data is translated to property value of the model.

            % right now, there are no App related events


            switch ( event.Data.Name )

                case 'AppModelClosed'
                    % when an App is closed at the client, the client sends this event
                    % so the server-side MCOS figure  object
                    % can be deleted immediately.
                    delete(obj.Model.CodeModel);
                    delete(obj.Model.UIFigure);

                case 'saveApp'
                    obj.handleSaveApp(event);

                case 'exportAppCode'
                    obj.handleExportApp(event);

                case 'copyApp'
                    obj.handleCopyApp(event);

                case 'runApp'
                    obj.handleRunApp(event);

                case 'ping'
                    obj.handlePing(event);

                case 'removeErroredComponents'
                    obj.handleRemoveErroredComponents(event);
            end

        end

        function handlePing(obj, event)
            % HANDLEPING(obj, event) send result back to the client

            % Send response to client side of the result
            obj.ClientEventSender.sendEventToClient('pingResult', { ...
                'CallbackId', event.Data.CallbackId, ...
                });
        end

        function handleSaveApp(obj, event)
            % HANDLESAVEAPP(obj, event) save app and send result back to
            % the client

            % Initialize the status output
            status = 'success';
            message = '';
            currentFullFileName = obj.Model.FullFileName;
            destinationFullFileName = event.Data.FullFileName;

            exception = [];

            try
                % Synchronize code data.  This is done here to enable save
                % to occur in one event from the client.  If multiple
                % events are used, it's possible to have the event order
                % rearranged such that the code isn't properly synchronized
                % before saving.
                codeData = event.Data.CodeData;
                codeController = obj.Model.CodeModel.getController();
                codeController.updateCodeData(codeData);

                if ~strcmp(currentFullFileName, destinationFullFileName) &&...
                        ~isempty(currentFullFileName)
                    % Performing SaveAs because filenames are different

                    % Copy the app file and then perform the save on top of
                    % the copied file to preserve state of the app that is
                    % not in memory such as the app's screenshot
                    % (g1650481).
                    copyAppFile(obj.Model, destinationFullFileName)
                end

                save(obj.Model, destinationFullFileName);

                % get the FullFileName assigned to App after saving
                destinationFullFileName = obj.Model.FullFileName;
            catch me
                % Return the Status and Message to be used in the error
                % dialog
                status = 'error';
                message = me.message;

                exception = me;
            end

            % Send response to client side of the result
            obj.ClientEventSender.sendEventToClient('saveAppResult', {
                'Status', status, ...
                'FullFileName', destinationFullFileName, ...
                'CallbackId', event.Data.CallbackId, ...
                'Message', message});

            obj.ActionCompletedObserver.notify('SaveActionCompleted', appdesigner.internal.application.observer.SaveCompletedEventData(status, exception));
        end

        function handleExportApp(obj, event)
            % HANDLEEXPORTAPP(obj, event) export app code to .m file and
            % send result back to the client.

            status = 'success';
            message = '';

            try
                exporter = appdesigner.internal.serialization.converter.MLAPPExporter(event.Data.Filepath, event.Data.Options);
                ExportAppCode(exporter, obj.Model.CodeModel.GeneratedCode);
            catch e
                status = 'error';
                message = e.message;
            end

            obj.ClientEventSender.sendEventToClient('exportAppCodeResult', {
                'Status', status, ...
                'Message', message, ...
                'CallbackId', event.Data.CallbackId ...
                });
        end

        function handleCopyApp(obj, event)
            % HANDLECOPYAPP(obj, event) create a copy of the app and send result back to
            % the client

            % Initialize the status output
            status = 'success';
            message = '';
            copyToFullFileName = event.Data.CopyFullFileName;
            updatedCode = event.Data.UpdatedCode;

            try
                if ~isempty(obj.Model.FullFileName)
                    % Copy the app file and then perform the save on
                    % top of the copied file to preserve state of the
                    % app that is not in memory such as the app's
                    % screenshot (g1650481).
                    copyAppFile(obj.Model, copyToFullFileName);
                end

                copy(obj.Model, copyToFullFileName, updatedCode);

            catch me
                % Return the Status and Message to be used in the error
                % dialog
                status = 'error';
                message = me.message;
            end

            obj.ClientEventSender.sendEventToClient('copyAppResult', {
                'Status', status, ...
                'CopyFullFileName', copyToFullFileName, ...
                'CallbackId', event.Data.CallbackId, ...
                'Message', message});
        end

        function handleRunApp(obj, event)
            % HANDLERUNAPP(obj, event) run app and send result back to
            % the client

            fullFileName = event.Data.FullFileName;

            % Check if the client request to change the current working
            % folder before running the app. It happens when there's a name
            % shadowing from the MATLAB's current workding directory to the
            % app to run, and then the user chooses "Change Folder" to run
            % again.
            if isfield(event.Data, 'Action') && ...
                    strcmp(event.Data.Action, 'CHANGE_FOLDER')
                fileFolder = fileparts(fullFileName);
                cd(fileFolder);
            end

            appArguments = '';
            if isfield(event.Data, 'AppArgumentValues')
                appArguments = event.Data.AppArgumentValues;
            end
            
            % define default result values
            status = 'success';
            reason = [];
            message = [];

            try
                runApp(obj.Model, fullFileName, appArguments);
            catch me
                status = 'error';
                reason = me.identifier;
                message = me.message;
            end

            % send result (success or error) to client
            obj.ClientEventSender.sendEventToClient('runAppResult', {
                'Status', status, ...
                'Reason', reason, ...
                'FullFileName', fullFileName, ...
                'CallbackId', event.Data.CallbackId, ...
                'Message', message});
        end

        function handleRemoveErroredComponents(obj, event)
            % If the load process partially fails on the client side, it
            % will send out this event to delete the errored components on
            % the server to ensure the server stays in-sync with the
            % components on the client.
            status = 'success';
            message = '';
            codeNames = event.Data.codeNames;

            try
                obj.Model.removeErroredComponents(codeNames);
            catch me
                status = 'error';
                message = me.message;
            end

            obj.ClientEventSender.sendEventToClient('removeErroredComponentsResult', {
                'Status', status, ...
                'CallbackId', event.Data.CallbackId, ...
                'Message', message});
        end

        function doSendErrorAlertToClient(obj, appException)
            % DOSENDERRORALERTTOCLIENT(obj, appException) sends app
            % startup/run-time error information to the client.
            %
            % Inputs:
            %
            % appException - a decorated MException with a truncated stack

            message = appException.getReport('extended', 'hyperlinks','on');
            line = appException.ErrorLineInApp;
            obj.ClientEventSender.sendEventToClient('runningAppCallbackError',...
                {'line', line, 'message', message, 'type', class(appException)});
        end
    end
end
