classdef (Abstract) DialogController < handle & ...
        matlab.ui.internal.componentframework.services.optional.ControllerInterface & ...
        matlab.ui.internal.componentframework.services.optional.ViewReadyInterface
    %Base Dialog controller for dialogs in WebGUIs

%   Copyright 2017-2024 The MathWorks, Inc.
    
    properties
        ModelProperties;
        ViewData;
        ChannelID = '';
        InstanceID = '';
        CallbackChannelID = '';
        ReloadChannelID = '';
        CallbackSubscription;
        ReloadSubscription;
        ViewReadyListener = []; % Listener on figure's view ready status
        IsDisplayed = true; % To track the life of a DialogController view
    end
    
    properties (Abstract = true)
        ViewDataFields;
    end
    
    methods(Access = public)
        function this = DialogController(params, validParams)
            this.validateStruct(params, validParams);
            
            this.InstanceID = char(matlab.lang.internal.uuid());
            this.ChannelID = ['/gbt/figure/DialogService/' params.FigureID];
            this.ModelProperties = params;
            
            this.CallbackChannelID = [this.ChannelID '/' this.InstanceID];
            this.ViewData.callbackChannelID = this.CallbackChannelID;
            
            this.ReloadChannelID = [this.ChannelID '/reload'];
        end
        
        function show(this)
            this.validateStruct(this.ViewData, this.ViewDataFields)
            
            this.setupListeners();
            
            % Send message to client
            this.publishWhenViewReady(this.ViewData);
        end
        
        function closeCallback(this, eventData)
             if isstruct(eventData) && isfield(eventData,'eventName') && ismember(eventData.eventName, {'AlertDialogClosed', 'ConfirmDialogClosed'})
                this.IsDisplayed = false;
            end
           
            if isstruct(eventData) && isfield(eventData,'eventname') && strcmp(eventData.eventname,'link-clicked')
                %Handle MATLAB links
                matlab.ui.internal.dialog.DialogHelper.handleMatlabLink(eventData.URL)
            else
                %Handle close  
                this.destroyListeners();
                e = this.processEventData(eventData);

                % process current CloseFcn if specified
                if ~isempty(this.ModelProperties.CloseFcn)
                    try
                        hgfeval(this.ModelProperties.CloseFcn, e.Source, e);
                    catch e
                        warning(message('MATLAB:uitools:uidialogs:ErrorEvaluatingCloseFcn', e.getReport('basic','hyperlinks','off')));
                    end
                end
            end
        end
    end
    
    methods (Abstract, Access = protected)
        processEventData(this, e);
        setupListeners(this);
    end

    methods (Access = protected)
        function destroyListeners(this)
            if ~this.IsDisplayed
                delete(this.ViewReadyListener);
            end
        end       
        
        function setupIconForView(this)
            try
                % Get icon for view
                icon = matlab.ui.internal.IconUtils.getIconForView(this.ModelProperties.Icon, this.ModelProperties.IconType);
            catch E                
                icon = 'error';
                warning ('MATLAB:DialogController:UnexpectedErrorInIcon', 'Error occured when parsing the icon file:\n%s', E.getReport());
            end
            
            % If icon is empty update to 'error' for uidialogs
            if isempty(icon)
                icon = 'error';
            end
            this.ViewData.options.icon = icon;
        end
        
        function publishWhenViewReady(this, dataStruct)
            fig = this.ModelProperties.Figure;
            if ~isvalid(fig) || ~this.IsDisplayed
                return
            end

            % De-reference 'channelID' for message publish
            channelID = this.ChannelID;            

            % Send message to client only if figure view is ready. Only do
            % the check if the figure window can be shown on the screen.
            % For deployed web apps, an underlying figure is always present so skipping the check for noFigureWindows.
            figController = this.ModelProperties.Figure.getControllerHandle();
            if (matlab.ui.internal.dialog.DialogUtils.isDeployedWebAppEnv() || ~feature('noFigureWindows')) && ~figController.IsFigureViewReady
                % If IsFigureViewReady is true we need not use waitfor.
                % This check is required to prevent certain tests which use
                % qeblockedstate.WaitForExecutor from failing.
                waitfor(figController, 'IsFigureViewReady', true);
            end

            this.publishHandler(fig, channelID, dataStruct);

            % setup a listener in cases when the figure view gets
            % destroyed and recreated.
            if isempty(this.ViewReadyListener)
                this.ViewReadyListener = addlistener(this.ModelProperties.Figure, 'ViewReady', @(o,e) this.viewReadyHandler(fig, channelID, dataStruct));
            end 
        end

        function viewReadyHandler(this, fig, channelID, dataStruct)
            if ~isvalid(fig) || ~this.IsDisplayed
                return
            end
            
            this.publishHandler(fig, channelID, dataStruct);
        end      
    end
    
    methods (Access = private)
        function publishHandler(this, fig, channelID, dataStruct)
            message.publish(channelID, dataStruct);
        end

        

        function validateStruct(this, params, fieldNames)
            validateattributes (params, {'struct'}, {'scalar','nonempty'}, this.getClassName());
            assert(all(isfield(params,fieldNames)), 'MATLAB:DialogController:UnknownParameters', ...
                'Expected struct fields were not provided');
        end
        
        function className = getClassName(this)
            c = strsplit(class(this),'.');
            className = c{end};
        end
    end
end

