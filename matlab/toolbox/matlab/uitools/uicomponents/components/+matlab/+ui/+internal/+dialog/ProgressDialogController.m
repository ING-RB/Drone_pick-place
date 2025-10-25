classdef ProgressDialogController < matlab.ui.internal.dialog.DialogController
    %Progress Dialog controller for dialogs in WebGUIs

%   Copyright 2017-2024 The MathWorks, Inc.
    
    properties (Constant)
        CancelRequestedText = getString(message('MATLAB:uitools:uidialogs:CancelRequested'));
    end
    
    properties
        InterruptCloseCallbackChannelID = '';
        InterruptCloseSubscription;
        ViewDataFields = {'Value','Message','Title','Indeterminate','ShowPercentage','Cancelable','CancelText','CancelRequestedText','Icon','Interpreter','action','callbackChannelID','instanceID','TargetFigureID'};
    end
    
    properties (Access = private)        
        IsShown = false;
    end
    
    methods
        function this = ProgressDialogController(params, model)
            validParams = {'Figure','FigureID'};
            this@matlab.ui.internal.dialog.DialogController(params,validParams);

            this.InterruptCloseCallbackChannelID = [this.ChannelID '/' this.InstanceID '/close'];
            
            this.ChannelID = [this.ChannelID '/ProgressDialog'];            
            
            this.ViewData.action = 'displayProgressDialog';
            this.ViewData.instanceID = this.InstanceID;
           
            this.ViewData.Title = model.Title;
            this.ViewData.Value = model.Value;
            this.ViewData.Message = model.Message;
            this.ViewData.Indeterminate = model.Indeterminate;
            this.ViewData.ShowPercentage = model.ShowPercentage;
            this.ViewData.Cancelable = model.Cancelable;
            this.ViewData.CancelText = model.CancelText;
            this.ViewData.CancelRequestedText = this.CancelRequestedText;
            this.ViewData.Icon = this.setupIconForView(model.Icon,model.IconType);
            this.ViewData.Interpreter = model.Interpreter;
            this.ViewData.TargetFigureID = this.ModelProperties.FigureID;
            cellfun(@(prop) addlistener(model, prop, 'PostSet', @(p,e) this.updateProperty(p.Name, e.AffectedObject)), properties(model));
           
        end
        
        function show(this)
            show@matlab.ui.internal.dialog.DialogController(this);
            this.IsShown = true;
        end
        
        function updateProperty(this, prop, model)
            val = model.(prop);
            if strcmp(prop,'Icon')
                val = this.setupIconForView(model.Icon,model.IconType);
            end
            
            this.ViewData.(prop) = val;
                        
            s = struct('action', 'updateProgressDialog', ...
                'instanceID', this.InstanceID, ...
                prop, val);
            
            this.publishWhenViewReady(s);
        end

        function delete(this)
            if (~this.IsShown)
                return;
            end

            s = struct('action', 'deleteProgressDialog', ...
                'instanceID', this.InstanceID);
            
            this.publishWhenViewReady(s);            
            this.destroyListeners();    
        end
        
        function out = getCancelRequested(this)
            out = matlab.ui.internal.dialog.ProgressDialogController.getCancelRequestedState(this.CallbackChannelID);
        end
        
        function setCancelRequested(this, val)
            matlab.ui.internal.dialog.ProgressDialogController.setCancelRequestedState(this.CallbackChannelID, val);
        end
        
    end
    
    methods (Access = protected)
        % DialogController
        function val = setupIconForView(~, val, type)
            % Serialize icons
            try
                val = matlab.ui.internal.IconUtils.getIconForView(val,type);
            catch E
                val = 'error';
                warning ('MATLAB:DialogController:UnexpectedErrorInIcon', 'Error occured when parsing the icon file:\n%s', E.getReport());
            end           
        end
        
        function processEventData(~, ~)
        end
        
        function setupListeners(this)
            matlab.ui.internal.dialog.ProgressDialogController.subscribeToCancelCallback(this.CallbackChannelID);
            this.InterruptCloseSubscription = message.subscribe(this.InterruptCloseCallbackChannelID, @(evd) this.handleCloseOfProgressDialog(evd));
        
            this.CallbackSubscription = message.subscribe(this.CallbackChannelID, @(evd) matlab.ui.internal.dialog.DialogHelper.handleMatlabLink(evd.URL));
        end

        function handleCloseOfProgressDialog(this, ~)            
           this.IsDisplayed = false;             
        end 
        
        function destroyListeners(this)
            destroyListeners@matlab.ui.internal.dialog.DialogController(this);
            matlab.ui.internal.dialog.ProgressDialogController.unsubscribeToCancelCallback(this.CallbackChannelID);
            message.unsubscribe(this.CallbackSubscription);    
            message.unsubscribe(this.InterruptCloseSubscription);
        end
        
    end
    
end
