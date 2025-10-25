classdef ProgressDialog  < handle & matlab.mixin.CustomDisplay & ....
        matlab.mixin.SetGet
    %
    
    % Do not remove above white space
    % Copyright 2017-2024 The MathWorks, Inc.
    
    
    properties (Transient, SetObservable)
        Value (1,1) {mustBeNumeric, mustBeGreaterThanOrEqual(Value,0), mustBeLessThanOrEqual(Value,1)} = 0;
        Message = '';
        Title = '';
        Indeterminate (1,1) matlab.lang.OnOffSwitchState = matlab.lang.OnOffSwitchState.off;
        Icon = '';
        ShowPercentage (1,1) matlab.lang.OnOffSwitchState = matlab.lang.OnOffSwitchState.off;
        Cancelable (1,1) matlab.lang.OnOffSwitchState = matlab.lang.OnOffSwitchState.off;
        CancelText = getString(message('MATLAB:uitools:uidialogs:Cancel'));
        Interpreter = 'none';
    end
    
    properties (Transient, Dependent, SetObservable)
        % This property gets/sets its value from the controller/view
        CancelRequested (1,1) logical;
    end
    
    properties (Transient, Access = {?matlab.ui.internal.dialog.ProgressDialogController, ?testMocks.MockProgressDialog})
        IconType = 'preset';
        FigureHandle;
        FigureID;
        Controller;
        TargetFigureID = '';
    end
    
    methods
        
        function obj = ProgressDialog(f,varargin)
            %
            
            narginchk(1,nargin);
            
            if nargin > 1
                [varargin{:}] = convertStringsToChars(varargin{:});
            end

            argCounts = numel(varargin);
            
            % Validate Figure
            [hUIFigure, figureID] = matlab.ui.internal.dialog.DialogHelper.validateUIfigure(f);
            obj.FigureID = figureID;
            obj.FigureHandle = hUIFigure;
            
            if (nargin > 1)
                if (mod(argCounts,2) == 1)
                    throwAsCaller(MException(message('MATLAB:uitools:uidialogs:IncorrectNameValuePairs')));
                end

                allProperties = properties(obj);
                for argCount = 1:2:argCounts
                    currArg = varargin{argCount};
                    if iscell(currArg)
                        cellfun(@throwIfNotProperty, currArg);
                    else
                        throwIfNotProperty(currArg);
                    end
                end

                % Pass through all PV pairs to set
                set(obj,varargin{:});
            end
            
            params = struct('Figure',hUIFigure,'FigureID',figureID);
            
            % Setup controller
            progressDialogController = matlab.ui.internal.dialog.DialogHelper.setupProgressDialogController;
            obj.Controller = progressDialogController(params, obj);
            obj.Controller.show();

            function throwIfNotProperty(argPropertyName)
                if (~ismember(lower(argPropertyName), lower(allProperties)))
                   throwAsCaller(MException(message('MATLAB:uitools:uidialogs:IncorrectParameterNameShort',argPropertyName))); 
                end
            end
        end

        
        function delete(obj)
            delete(obj.Controller);
        end
        
        function close(obj)
            delete(obj);
        end
        
        function set.Title (obj, titleString)
            titleString = convertStringsToChars(titleString);
            obj.Title = matlab.ui.internal.dialog.DialogHelper.validateTitle(titleString);
        end
        
        function set.Message (obj, msgString)
            msgString = convertStringsToChars(msgString);
            obj.Message = matlab.ui.internal.dialog.DialogHelper.validateMessageText(msgString);
        end
        
        function set.Icon (obj, icon)
            try
                % string conversion for icon
                icon = convertStringsToChars(icon);

                % allowed preset icons
                presetIcon = matlab.ui.internal.IconUtils.StatusAndNoneIcon;

                % validate the given icon
                [newValue, iconType] = matlab.ui.internal.IconUtils.validateIcon(icon,presetIcon);

                % Set icon type to 'preset' when value is empty
                if strcmp(newValue, '')
                   iconType = 'preset';
                end
                
                obj.IconType = iconType;
                obj.Icon = newValue;
            catch ex
                % MnemonicField is last section of error id
                mnemonicField = ex.identifier(regexp(ex.identifier,'\w*$'):end);
                % Get messageText from exception
                messageText = ex.message;
                
                if strcmp(mnemonicField, 'invalidIconNotInPath') || strcmp(mnemonicField, 'cannotReadIconFile')  || strcmp(mnemonicField, 'unableToWriteCData')
                    % Warn and proceed when icon file cannot be read.
                    % This is done, so that the app can continue working when 
                    % it is loaded and when the Icon file is invalid or dont
                    % exist
                    matlab.ui.control.internal.model.PropertyHandling.displayWarning(obj, mnemonicField, messageText);
                else
                    % Get Identifier specific for uiprogressdlg as
                    % validateIcon() throws generic icon error.
                    if strcmp(mnemonicField, 'invalidIconFile')
                        messageText = getString(message('MATLAB:uitools:uidialogs:InvalidIconSpecified'));
                        mnemonicField = 'InvalidIconSpecified';
                    end
                    % Create and throw exception for other errors 
                    % related to Icon
                    exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(obj, mnemonicField, '%s', messageText);
                    throwAsCaller(exceptionObject);
                end
                
            end
        end
        
        function set.Value (obj, val)
            obj.Value = val;
        end
        
        function set.Indeterminate (obj, val)
            obj.Indeterminate = val;
        end
        
        function set.ShowPercentage (obj, val)
            obj.ShowPercentage = val;
        end
        
        function set.Cancelable (obj, val)
            obj.Cancelable = val;
        end
        
        function set.CancelText (obj, val)
            val = convertStringsToChars(val);
            obj.CancelText = matlab.ui.internal.dialog.DialogHelper.validateTitle(val);
        end
        
        function set.CancelRequested (obj, val)
            obj.Controller.setCancelRequested(val);
        end
        
        function out = get.CancelRequested (obj)
            out = obj.Controller.getCancelRequested();
        end
        
        function set.Interpreter (obj,val)
           try 
                val =  matlab.ui.internal.dialog.DialogHelper.validateInterpreter(val);
                obj.Interpreter = val;
           catch ME
               throwAsCaller(ME);
           end
        end
        
        function out = get.Interpreter (obj)
            out = obj.Interpreter;
        end

    end
    
    methods (Access = protected)
        function propgrp = getPropertyGroups(~)
            propgrp = matlab.mixin.util.PropertyGroup({'Value','Message','Title','Indeterminate','Icon','ShowPercentage','Cancelable','Interpreter'});
        end
    end
end

