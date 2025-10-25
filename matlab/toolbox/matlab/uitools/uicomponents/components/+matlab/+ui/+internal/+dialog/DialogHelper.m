classdef (Abstract) DialogHelper < handle & ...
        matlab.ui.internal.componentframework.services.core.identification.IdentificationService & ...
        matlab.ui.internal.componentframework.services.optional.ViewReadyInterface
    %DIALOGHELPER utility function used by In-App dialogs

    %   Copyright 2015-2023 The MathWorks, Inc.
    
    methods (Static, Hidden)
        function out = getFigureID(f)
            out = f.getId();
            
            if isempty(out)
                matlab.graphics.internal.drawnow.startUpdate % get ID after update
                out = f.getId();
                if isempty(out)
                    throwAsCaller(MException(message('MATLAB:uitools:uidialogs:NotAnAppWindowHandle')));
                end
            end
        end
        
        function [hUIFigure, figureID] = validateUIfigure(h)
            
            isAppContainer = false;
            %check for type AppContainer and return the UIFigure and FigureID
            if(isa(h, 'matlab.ui.container.internal.AppContainer'))
                isAppContainer = true;
                if (h.Visible)
                    h = matlab.ui.internal.dialog.DialogHelper.getFigureOfAppContainer(h);
                else
                    throwAsCaller(MException(message('MATLAB:uitools:uidialogs:InvisibleAppContainer')));
                end
            end    
            
            if isempty(h) || ~isscalar(h) || ~ishghandle(h, 'figure') 
                throwAsCaller(MException(message('MATLAB:uitools:uidialogs:InvalidFigureHandle')));
            end
            
            if ~isAppContainer && ishghandle(h, 'figure') && strcmpi(h.Visible,'off')
                throwAsCaller(MException(message('MATLAB:uitools:uidialogs:InvisibleFigure')));
            end
           
            hUIFigure = h;
            figureID = matlab.ui.internal.dialog.DialogHelper.getFigureID(h);
        end
        
        % Helper functin to return the figure from the appcontainer to
        % support uidalogs
        function h = getFigureOfAppContainer(appContainer)
            if appContainer.hasDocument("dialogParentGroupTag", "globalDialogParentTag")
                parentDoc = appContainer.getDocument("dialogParentGroupTag", "globalDialogParentTag");
            else
                if ~appContainer.hasDocumentGroup("dialogParentGroupTag")
                    group = matlab.ui.internal.FigureDocumentGroup();
                    group.Tag = "dialogParentGroupTag";
                    appContainer.add(group);
                end
                options.DocumentGroupTag = "dialogParentGroupTag";
                options.Tag = "globalDialogParentTag";
                options.Visible = false;
                parentDoc = matlab.ui.internal.FigureDocument(options);
                appContainer.add(parentDoc);
                % Wait for the app container figure to be ready, else the dialogs may not show up.
                % Consider if uiprogressdlg makes MATLAB busy soon after this stack.
                t0 = tic;
                while ~parentDoc.Figure.isViewReady() && toc(t0) <= 60
                    drawnow limitrate;
                end
            end
            h = parentDoc.Figure;
        end    
        
        function msg = validateMessageText(msgString)
            if ischar(msgString) && (isempty(msgString) || isrow(msgString))
                msg = msgString;
                return;
            elseif iscellstr(msgString) && isvector(msgString)
                msg = msgString{1};
                for k = 2:length(msgString)
                    msg = sprintf('%s\n%s', msg, msgString{k});
                end
                return
            end
            throwAsCaller(MException(message('MATLAB:uitools:uidialogs:InvalidMessageText')));
        end
        
        function title = validateTitle(title)
            if ischar(title)
                if isempty(title)
                    return;
                end
                if isrow(title)
                    % Replace \n, \r characters with spaces
                    title = regexprep(title, '\n|\r',' ');
                    return;
                end
            end
            throwAsCaller(MException(message('MATLAB:uitools:uidialogs:InvalidTitleText')));
        end
        
        function [params, iconType] = validatePVPairs(params, varargin)
            %Provide defaults as params struct
            iconType = 'preset';
            
            numArgs = numel(varargin);
            if (numArgs == 0)
                return;
            end
            if (mod(numArgs,2)==1)
                throwAsCaller(MException(message('MATLAB:uitools:uidialogs:IncorrectNameValuePairs')));
            end
            
            fields = fieldnames(params);
            for k = 1:2:numArgs
                % Handle parameter
                param = varargin{k};
                if ~ischar(param)
                    throwAsCaller(MException(message('MATLAB:uitools:uidialogs:IncorrectParameter')));
                end
                paramMatched = strmatch(lower(param), lower(fields)); %#ok<MATCH2> % Partial and Case Insensitive
                if isempty(paramMatched)
                    % Based on error message autoring guidelines 
                    % Rule 4.3.22 AVOID listing more than 5 or 6 items in 
                    % an error message written in solution form (chosing
                    % lower limit of allowing maximum of 5 suggestions)
                    if (length(fields) < 6)
                        throwAsCaller(MException(message('MATLAB:uitools:uidialogs:IncorrectParameterName', param, strjoin(fields, ''', '''))));
                    else
                        throwAsCaller(MException(message('MATLAB:uitools:uidialogs:IncorrectParameterNameShort', param)));
                    end
                end
                param = fields{paramMatched};
                
                % Handle value
                val = varargin{k+1};
                switch (param)
                    case 'Icon'
                        try
                            % allowed preset icons
                            presetIcon = matlab.ui.internal.IconUtils.StatusAndNoneIcon;

                            % validate the given icon
                            [val, iconType] = matlab.ui.internal.IconUtils.validateIcon(val,presetIcon);
                            
                            % Set icon type to 'preset' when value is empty
                            if strcmp(val, '')
                                iconType = 'preset';
                            end
                        catch ex
                            % MnemonicField is last section of error id
                            mnemonicField = ex.identifier(regexp(ex.identifier,'\w*$'):end);
                            % Get messageText from exception
                            messageText = ex.message;
                            
                            if strcmp(mnemonicField, 'invalidIconNotInPath') || strcmp(mnemonicField, 'cannotReadIconFile')  || strcmp(mnemonicField, 'unableToWriteCData')
                                % Set Icon to empty for uidialogs when
                                % warning
                                iconType = 'preset';
                                val = '';
                                % Warn and proceed when icon file cannot be read.
                                % This is done, so that the app can continue working when 
                                % it is loaded and when the Icon file is invalid or dont
                                % exist
                                warning(['MATLAB:uitools:uidialogs:', mnemonicField], '%s', messageText);
                            else
                                % Get Identifier specific for uidialogs as
                                % validateIcon() throws generic icon error.
                                if strcmp(mnemonicField, 'invalidIconFile')
                                    messageText = getString(message('MATLAB:uitools:uidialogs:InvalidIconSpecified'));
                                    mnemonicField = 'InvalidIconSpecified';
                                end
                                % Create and throw exception for other errors 
                                % related to Icon
                                throwAsCaller(MException(['MATLAB:uitools:uidialogs:', mnemonicField], messageText));
                            end
                        end
                        
                    case 'Modal'
                        % Scalar: true, false, 0 or 1 accepted
                        if isempty(val) || ~isscalar(val)  || ~(islogical(val) || isnumeric(val)) || ~(val == 0 || val == 1)
                            throwAsCaller(MException(message('MATLAB:uitools:uidialogs:InvalidModalValue')));
                        end
                        val = logical(val);
                        
                    case 'CloseFcn'
                        validFcn = false;
                        if isempty(val) || ischar(val)
                            validFcn = true;
                        elseif iscell(val)
                            if isempty(val{1}) || ischar(val{1}) || isa(val{1}, 'function_handle')
                                validFcn = true;
                            end
                        elseif isa(val, 'function_handle')
                            validFcn = true;
                        end
                        if ~validFcn
                            throwAsCaller(MException(message('MATLAB:uitools:uidialogs:InvalidCloseFcnValue')));
                        end
                        
                    case 'Options'
                        % valid options are character vector for 1 option or cell array of
                        % character vectors for 1 to 4 options
                        if ischar(val)
                            % convert character vector to cell array of character
                            % vectors
                            val = cellstr(val);
                        end
                        if ~(iscellstr(val) && length(val) >= 1 && length(val) <= 4 && ~any(cellfun(@isempty,val)))
                            throwAsCaller(MException(message('MATLAB:uitools:uidialogs:InvalidOptionsValue')));
                        end
                        % set CustomOptionsFlag to true when custom options
                        % are provided
                        params.CustomOptionsFlag = true;
                        
                        
                    case 'Interpreter'
                        try 
                            val =  matlab.ui.internal.dialog.DialogHelper.validateInterpreter(val);
                        catch ME
                            messageObj = message('MATLAB:uitools:uidialogs:invalidFourStringEnum', ... 
                                'Interpreter', 'none', 'html', 'latex', 'tex');
                            
                            mnemonicField = 'MATLAB:uitools:uidialogs:InvalidInterpreter';
                            messageText = getString(messageObj);
                            
                            throwAsCaller(MException(mnemonicField, messageText));
                        end
                end
                params.(param) = val;
            end
            
        end
        
        function setViewReadyState(f, val)
            % Can be used to set the ViewReady state on an object. 
            % Needed for dispatchWhenViewIsReady when a reload happens for
            % a dialog. 
            f.setViewReady(val);
        end
        
        function dispatchWhenViewIsReady(f, func)
            % If view is ready, dispatch the function handle.
            if ~isvalid(f)
                return
            end
            if (f.isViewReady)
                func()
                return;
            end
            
            % Otherwise Setup a ViewReady Listener and then dispatch all
            % function handles when view is ready.
            p = findprop(f, 'ViewReadyDispatcher');
            if isempty(p)
                p = addprop(f, 'ViewReadyDispatcher');
                p.Hidden = true;
                p.Transient = true;
            end
            if isempty(f.ViewReadyDispatcher)
                l = addlistener(f, 'ViewReady', @(o,e) handleViewReady(o,e));
                f.ViewReadyDispatcher.Listener = l;
                f.ViewReadyDispatcher.CommandStack = {};
            end
            % Queue up the function handle in the command stack
            f.ViewReadyDispatcher.CommandStack{end+1} = func;
        end
        
        function dispatchWhenPeerNodeViewIsReady(model, viewModel, func)
            % If view is ready, dispatch the function handle.
            
            if ~isvalid(model) || isempty(viewModel)
                return
            end
            
            % We attempt to fire only if there is no queued up events. If there are any events already in the queue we add the current event to the queue as well
            if ( (~isprop(model, 'ViewReadyDispatcher')) || (isprop(model, 'ViewReadyDispatcher') && isempty(model.ViewReadyDispatcher)) )
                if (~isempty( viewModel.getProperty('isViewReady') ) && viewModel.getProperty('isViewReady') == true)
                    func()
                    return;
                end
            end
            
            function viewReadyCallback(~, e)
                data = e.getData;
                if (strcmp(data.get('key'), 'isViewReady') ...
                        && isvalid(model))
                    % During re-pareting, the component would be deleted 
                    % and re-created, and so do not run this code when it's 
                    % triggered by viewReady event due to timing issue.
                    handleViewReady(model, e);
                end
            end

            % Otherwise Setup a ViewReady Listener and then dispatch all
            % function handles when view is ready.
            p = findprop(model, 'ViewReadyDispatcher');
            if isempty(p)
                p = addprop(model, 'ViewReadyDispatcher');
                p.Hidden = true;
                p.Transient = true;
            end
            
            % If the peer model is deleted but the model is not such as
            % when reparenting, we have to ensure that the property set
            % listener is cleaned up because we need to now listen to the 
            % new peer node
            function cleanupViewReadyDispatcher(~, ~)
                if isvalid(model) && isprop(model, 'ViewReadyDispatcher') && ~isempty(model.ViewReadyDispatcher)
                    viewReadyListener = model.ViewReadyDispatcher.Listener;
                    delete(viewReadyListener);
                    model.ViewReadyDispatcher = [];
                end
            end

            if isempty(model.ViewReadyDispatcher)
                model.ViewReadyDispatcher.Listener = addlistener(viewModel, 'propertySet', @viewReadyCallback);
                model.ViewReadyDispatcher.CommandStack = {};
                addlistener(viewModel, 'destroyed', @cleanupViewReadyDispatcher);
            end
            
            % Queue up the function handle in the command stack
            model.ViewReadyDispatcher.CommandStack{end+1} = func;
        end
        
        function returnController = setupAlertDialogController(newController)
            persistent controller;
            if isempty(controller)
                controller = @matlab.ui.internal.dialog.AlertDialogController;
            end
            if nargin == 1
                assert(isa(newController, 'function_handle'))
                controller = newController;
            end
            returnController = controller;
        end
        
        function returnController = setupConfirmDialogController(newController)
            persistent controller;
            if isempty(controller)
                controller = @matlab.ui.internal.dialog.ConfirmDialogController;
            end
            if nargin == 1
                assert(isa(newController, 'function_handle'))
                controller = newController;
            end
            returnController = controller;
        end
        
        function returnController = setupProgressDialogController(newController)
            persistent controller;
            if isempty(controller)
                controller = @matlab.ui.internal.dialog.ProgressDialogController;
            end
            if nargin == 1
                assert(isa(newController, 'function_handle'))
                controller = newController;
            end
            returnController = controller;
        end

        function returnController = setupExportDialogController(newController)
            persistent controller;
            if isempty(controller)
                controller = @matlab.ui.internal.dialog.ExportDialog;
            end
            if nargin == 1
                assert(isa(newController, 'function_handle'))
                controller = newController;
            end
            returnController = controller;
        end

        function returnController = setupPrintDialogController(newController)
            persistent controller;
            if isempty(controller)
                controller = @matlab.ui.internal.dialog.PrintDialog;
            end
            if nargin == 1
                assert(isa(newController, 'function_handle'))
                controller = newController;
            end
            returnController = controller;
        end
        
        function handleMatlabLink(linkString)   
            
            if ~isempty(linkString)
                try
                        web(linkString, '-browser')
                catch me
    
                    % MnemonicField is last section of error id
                    mnemonicField = 'failureToLaunchURL';
    
                    messageObj = message('MATLAB:uitools:uidialogs:errorInWeb', ...
                    linkString, me.message);  
                    
                    %No need for warning stack trace to be displayed to user.
                    w = warning('off', 'backtrace');
                    
                    warning(['MATLAB:uitools:uidialogs:' mnemonicField], messageObj.getString())
                    
                    % reset warning state
                    warning(w)
                end
            else
                %Empty url has 2 possible causes
                % 1. User provided empty url
                % 2. User provided invalid protocol that was sanitized

                w = warning('off', 'backtrace');
                mnemonicField = 'failureToLaunchWebURL';
                messageObj = message('MATLAB:uitools:uidialogs:errorInWebEmpty');
                warning(['MATLAB:uitools:uidialogs:' mnemonicField], messageObj.getString())
                
                % reset warning state
                warning(w)
            end     
        end
        
        function interpreter = validateInterpreter(val)
            try
                %check the string is present
                availableStrings = {'none', 'html', 'latex','tex'}; 
                output = validatestring(val,...
                    availableStrings);
                
                %Check for partial match(Internal error
                %message)
                if(~strcmpi(output, val))
                    messageObj = message('MATLAB:uitools:uidialogs:invalidFourStringEnum', ...
                    'Interpreter', 'none', 'html', 'latex', 'tex');
                    
                    throw(MException(messageObj));
                end
                interpreter = output;
            catch ME
                messageObj = message('MATLAB:uitools:uidialogs:invalidFourStringEnum', ... 
                    'Interpreter', 'none', 'html', 'latex', 'tex');
                
                mnemonicField = 'MATLAB:uitools:uidialogs:InvalidInterpreter';
                messageText = getString(messageObj);
                
                throw(MException(mnemonicField, messageText));
            end
        end
        
    end
end


function handleViewReady(src, ~)
% Cleanup Dynamic prop and listeners
viewReadyListener = src.ViewReadyDispatcher.Listener;
dispatcherProp = findprop(src, 'ViewReadyDispatcher');
commandStack = src.ViewReadyDispatcher.CommandStack;
src.ViewReadyDispatcher = [];
delete(viewReadyListener);
delete(dispatcherProp);

% Execute the queued function handles
for k = 1:length(commandStack)
    functionToExecute = commandStack{k};
    functionToExecute();
end
end
