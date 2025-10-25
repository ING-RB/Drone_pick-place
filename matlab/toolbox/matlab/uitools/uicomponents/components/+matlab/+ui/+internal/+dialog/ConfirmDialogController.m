classdef ConfirmDialogController < matlab.ui.internal.dialog.DialogController
    %CONFIRMDIALOGCONTROLLER
    % This controller marshals data to the view to create and manage
    % confirm dialogs on web GUIs.

    %Copyright 2021-2025 The MathWorks, Inc.
    
    
    properties
        ViewDataFields = {'dataTestId','action','title','message','options', ...
                          'callbackChannelID'};
        FigureCloseRequestFcnCache;
        SelectedOption = '';
    end
    
    properties (Constant)
        OK_TEXT = getString(message('MATLAB:uitools:uidialogs:OK'));
        CANCEL_TEXT = getString(message('MATLAB:uitools:uidialogs:Cancel'));
    end

    methods(Access = public)
        function this = ConfirmDialogController(params)
            validParams = {'CloseFcn','Figure','FigureID','Icon','IconType', ...
                'Message','Title','Options','CustomOptionsFlag','DefaultOption', ...
                'CancelOption','Interpreter'};
            this@matlab.ui.internal.dialog.DialogController(params, validParams);
            
            this.ViewData.action = 'displayConfirmDialog';
            this.ViewData.title = this.ModelProperties.Title;
            this.ViewData.message = this.ModelProperties.Message;
            this.ViewData.options.buttonText = this.getOptionsForView();
            this.ViewData.options.defaultAcceptButton = this.ModelProperties.DefaultOption;
            this.ViewData.options.defaultCancelButton = this.ModelProperties.CancelOption;
            this.ViewData.options.interpreter = this.ModelProperties.Interpreter;
            this.ViewData.options.targetFigureID = this.ModelProperties.FigureID;
            this.ViewData.dataTestId = ['ConfirmDialog_' this.InstanceID];
            this.setupIconForView();
        end
    end
    
    methods (Access = protected)
        function e = processEventData(this, eventData)
            e.Source = this.ModelProperties.Figure;
            e.EventName = 'ConfirmDialogClosed';
            e.DialogTitle = this.ModelProperties.Title;
            if strcmp(eventData.eventName, 'DialogServiceReload')
                e.SelectedOptionIndex = this.ModelProperties.CancelOption;
                e.SelectedOption = this.ModelProperties.Options{e.SelectedOptionIndex};
            else                
                e.SelectedOptionIndex = eventData.response;
                e.SelectedOption = this.ModelProperties.Options{e.SelectedOptionIndex};
            end
            this.SelectedOption = e.SelectedOption;
        end
        
        function setupListeners(this)
            % Setup Close function
            this.CallbackSubscription = message.subscribe(this.CallbackChannelID, @(evd) this.closeCallback(evd));
            
            % Disable Figure's Close so that end-user always responds to
            % the confirmation dialog
            this.FigureCloseRequestFcnCache = this.ModelProperties.Figure.CloseRequestFcn;
            this.ModelProperties.Figure.CloseRequestFcn = '';
        end
        
        function destroyListeners(this)
            destroyListeners@matlab.ui.internal.dialog.DialogController(this);
            
            % disable other close callbacks
            message.unsubscribe(this.CallbackSubscription);
            this.ModelProperties.Figure.CloseRequestFcn = this.FigureCloseRequestFcnCache;
            this.FigureCloseRequestFcnCache = '';
        end
    end
    
    methods (Access = private)
        function viewOptions = getOptionsForView(this)
            viewOptions = this.ModelProperties.Options;
            % check if custom options
            if ~(this.ModelProperties.CustomOptionsFlag)
                % send localized strings to view only when custom options
                % are not provided
                viewOptions = {this.OK_TEXT, this.CANCEL_TEXT};
            end
        end
    end
    
end

