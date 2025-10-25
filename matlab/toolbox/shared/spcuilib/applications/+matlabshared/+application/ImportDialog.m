classdef ImportDialog < handle
    %ImportDialog   Define the ImportDialog class.

    %   Copyright 2017 The MathWorks, Inc.

    properties (SetAccess = protected)
        Source = 'workspace';
        FileName = '';
    end
    
    properties (SetAccess = protected, Hidden)

        Figure = -1;
        Panel;
        hFilePanel;
        hFileName;
        Controller;
        FigureLayout;
        PanelLayout;
        VariablesCache;
        VariableNames;
        LoadedVariables;
        hWorkspace;
        hMatfile;
        Labels = matlab.ui.control.UIControl.empty;
        Popups = matlab.ui.control.UIControl.empty;
        IsValid = true;
        CantClose = false;
    end

    methods

        function this = ImportDialog(controller)
            %ImportDialog   Construct the ImportDialog class.
            
            this.Controller = controller;
        end

        function varargout = open(this, varargin)
            
            if nargin > 1
                [varargin{:}] = convertStringsToChars(varargin{:});
            end
            
            fig = this.Figure;
            if ~ishghandle(fig)
                render(this);
                fig = this.Figure;
            end
            
            % Make sure that the variables caches are all updated
            updateVariables(this);
            
            % Update the layout and popup strings
            update(this);
            
            % Update the size based on the layout;
            [~, h1] = getMinimumSize(this.FigureLayout);
            [~, h2] = getMinimumSize(this.PanelLayout);
            h = h1 + h2 + 2;
            fig.Position = matlabshared.application.getCenterPosition([400 h], varargin{:});
            figure(fig);
            if nargout
                set(fig, 'WindowStyle', 'modal');
                waitfor(fig, 'Visible', 'off');
                [varargout{1:nargout}] = getSelectedVariables(this);
            else
                set(fig, 'WindowStyle', 'normal');
            end
        end
        
        function varargout = getSelectedVariables(this)
            
            % Get the variable names that are chosen
            variables = this.VariableNames;
            varargout = cell(1, numel(variables));
            if ~this.IsValid
                return;
            end
            if strcmp(this.Source, 'workspace')
                for indx = 1:numel(variables)
                    if ~isempty(variables{indx})
                        
                        % Eval in the base workspace
                        varargout{indx} = evalin('base', variables{indx});
                    end
                end
            else
                loadedVars = this.LoadedVariables;
                for indx = 1:numel(variables)
                    if ~isempty(variables{indx})
                        
                        % Pull them out of the loaded variables
                        varargout{indx} = loadedVars.(variables{indx});
                    end
                end
            end
        end
        
        function close(this)
            if this.CantClose
                return
            end
            fig = this.Figure;
            if ishghandle(fig)
                fig.Visible = 'off';
                delete(fig)
                this.Figure = -1;
            end
        end
        
        function delete(this)
            fig = this.Figure;
            if ishghandle(fig)
                delete(fig);
            end
        end
        
        function chooseFile(this, file)
            
            this.CantClose = true;
            % If the file isnt specified, bring up the dialog
            if nargin < 2
                [file, path] = uigetfile( ...
                    {'*.mat', 'MAT-files (*.mat)'});
                if isequal(file, 0)
                    update(this);
                    this.CantClose = false;
                    return;
                end
                file = fullfile(path, file);
            end
            
            % Load and cache to avoid loaded multiple times
            this.LoadedVariables = load(file);
            this.FileName = file;
            this.Source = 'matfile';
            
            % Make sure everything is updated
            updateVariables(this);
            update(this);
            this.CantClose = false;
        end
    end
    
    methods (Hidden)
        function updateVariables(this_UNIQUE_NAME)
            
            % Use weird names to make it easier to prune out the variables
            % from whos.
            if strcmp(this_UNIQUE_NAME.Source, 'workspace')
                this_UNIQUE_NAME.VariablesCache = evalin('base', 'whos');
            else
                populateVariables(this_UNIQUE_NAME.LoadedVariables);
                w = whos;
                
                this_UNIQUE_NAME.VariablesCache = w(~strcmp({w.name}, 'this_UNIQUE_NAME'));
            end
        end
        
        function currentSelections = getCurrentVariableNames(this, nPopups)
            popups = this.Popups;
            if nargin < 2
                nPopups = numel(popups);
            end
            currentSelections = cell(1, nPopups);
            noSelection = getString(message('Spcuilib:application:ImportNoSelectionMade'));
            noValid     = getString(message('Spcuilib:application:ImportNoSelectionAvailable'));
            for indx = 1:numel(popups)
                str = popups(indx).String{popups(indx).Value};
                if any(strcmp(str, {noSelection, noValid}))
                    str = '';
                end
                currentSelections{indx} = str;
            end
        end
        
        function update(this)
            this.CantClose = true;
            controller = this.Controller;
            fig = this.Figure;
            
            fig.Name = getImportDialogName(controller);
            
            labelStrings = getImportDialogLabels(controller);
            
            labels = this.Labels;
            popups = this.Popups;
            layout = this.PanelLayout;
            
            allVariables = this.VariablesCache;
            
            % Update the radio buttons
            if strcmp(this.Source, 'workspace')
                workValue = 1;
                matValue = 0;
            else
                workValue = 0;
                matValue = 1;
            end
            
            set(this.hWorkspace, 'Value', workValue);
            set(this.hMatfile,   'Value', matValue);
            nPopups = numel(labelStrings);
            
            % Update the file strnig.
            setFileNameString(this);
            
            layout.VerticalWeights = [zeros(1,nPopups + 2) 1];
            noSelection = getString(message('Spcuilib:application:ImportNoSelectionMade'));
            noValid     = getString(message('Spcuilib:application:ImportNoSelectionAvailable'));
            
            % Loop over and update all the popups.
            variableNames = this.VariableNames;
            if numel(variableNames) < nPopups
                variableNames = [variableNames repmat({[]}, 1, nPopups - numel(variableNames))];
            elseif numel(variableNames) > nPopups
                variableNames(nPopups+1:end) = [];
            end
            for indx = 1:nPopups
                if numel(labels) < indx
                    labels(indx) = uicontrol(fig, 'Style', 'text', ...
                        'HorizontalAlignment', 'left');
                    popups(indx) = uicontrol(fig, ...
                        'Style', 'popup', ...
                        'Tag', sprintf('ImportPopup%d', indx), ...
                        'UserData', indx, ...
                        'Callback', @this.popupCallback, ...
                        'String', {noSelection});
                    add(layout, labels(indx), indx + 2, 1, ...
                        'TopInset', 3, ...
                        'MinimumHeight', 17);
                    add(layout, popups(indx), indx + 2, 2, ...
                        'RightInset', 2, ...
                        'Fill', 'Horizontal');
                end
                set(labels(indx), 'String', labelStrings{indx});
                string = validateImportVariables(controller, indx, allVariables, variableNames);
                if isempty(string)
                    variableNames{indx} = [];
                    string = {noValid};
                    value = 1;
                else
                    value = find(strcmp(variableNames{indx}, string), 1, 'first');
                    if isempty(value)
                        variableNames{indx} = [];
                        string = [{noSelection} string]; %#ok<AGROW>
                        value = 1;
                    end
                end
                set(popups(indx), 'String', string, 'Value', value);
            end
            this.VariableNames = variableNames;
            if size(layout.Grid, 1) == nPopups + 2
                insert(layout, 'row', nPopups+3);
            end
            layout.VerticalWeights = [zeros(1,nPopups + 2) 1];
            width = layout.getMinimumWidth(labels);
            
            % Set all the label constraints to the same min width.
            for indx = 1:numel(labels)
                setConstraints(layout, labels(indx), 'MinimumWidth', width);
            end
            
            this.Labels = labels;
            this.Popups = popups;
            this.CantClose = false;
        end
    end
    
    methods (Access = protected)
        function render(this)
            fig = figure(...
				'Tag', 'Import', ...
                'HandleVisibility', 'Off', ...
                'DeleteFcn', @this.deleteFcn, ...
                'CloseRequestFcn', @this.cancelCallback, ...
                'KeyPressFcn', @this.onKeyPress, ...
                'IntegerHandle', 'off', ...
                'NumberTitle', 'off', ...
                'Menubar', 'none', ...
                'Visible', 'off');
            
            this.Figure = fig;
            
            radiopanel = uipanel(fig);
            filepanel = uipanel(radiopanel, ...
                'BorderType', 'none');
            
            figurelayout = matlabshared.application.layout.GridBagLayout(fig, ...
                'VerticalGap', 2, ...
                'HorizontalGap', 2, ...
                'VerticalWeights', [1 0], ...
                'HorizontalWeights', [1 0 0]);
            
            workspace = uicontrol(radiopanel, 'style', 'radio', ...
                'String', getString(message('Spcuilib:application:BaseWorkspace')), ...
                'Value', 1, ...
                'Callback', @this.workspaceCallback);
            matfile = uicontrol(filepanel, 'style', 'radio', ...
                'Callback', @this.fileCallback, ...
                'Position', [1 1 20 20]);
            choose = uicontrol(filepanel, 'style', 'pushbutton', ...
                'Tag', 'ImportChooseFile', ...
                'String', getString(message('Spcuilib:application:ImportChooseFile')), ...
                'Callback', @this.chooseFileCallback);
            choosePos = [21 1 figurelayout.getMinimumWidth(choose) 20];
            set(choose, 'Position', choosePos);
            filename = uicontrol(filepanel, 'style', 'text', ...
                'Position', [choosePos(1) + choosePos(3) 1 100 16], ...
                'HorizontalAlignment', 'left');
            
            okButton = uicontrol(fig, ...
                'String', 'OK', ...
                'Tag', 'OkImport', ...
                'Style', 'pushbutton', ...
                'Callback', @this.okCallback);
            cancelButton = uicontrol(fig, ...
                'String', getString(message('Spcuilib:application:Cancel')), ...
                'Tag', 'CancelImport', ...
                'Style', 'pushbutton', ...
                'Callback', @this.cancelCallback);
            
            buttonWidth = figurelayout.getMinimumWidth([okButton cancelButton]) + 20;
            
            add(figurelayout, radiopanel, 1, [1 3], ...
                'Fill', 'Both');
            add(figurelayout, okButton, 2, 2, ...
                'MinimumWidth', buttonWidth);
            add(figurelayout, cancelButton, 2, 3, ...
                'MinimumWidth', buttonWidth);
            
            panellayout = matlabshared.application.layout.GridBagLayout(radiopanel, ...
                'VerticalGap', 2, ...
                'HorizontalGap', 2, ...
                'VerticalWeights', [0 0 1], ...
                'HorizontalWeights', [0 1]);
            
            add(panellayout, workspace, 1, [1 2], ...
                'MinimumWidth', panellayout.getMinimumWidth(workspace) + 20, ...
                'Anchor', 'West', ...
                'TopInset', 4, ...
                'LeftInset', 4);
            add(panellayout, filepanel, 2, [1 2], ...
                'LeftInset', 4, ...
                'Fill', 'Horizontal');
            
            addlistener(panellayout, 'LayoutPerformed', @this.onPanelLayoutPerformed);
            
            this.FigureLayout = figurelayout;
            this.PanelLayout  = panellayout;
            
            this.Panel = radiopanel;
            
            this.hFileName  = filename;
            
            this.hWorkspace = workspace;
            this.hMatfile   = matfile;
            this.hFilePanel = filepanel;
            
            update(figurelayout, 'force');
        end
        
        function onKeyPress(this, ~, ev)
            if strcmp(ev.Key, 'escape')
                cancelCallback(this);
            end
        end
        
        function chooseFileCallback(this, ~, ~)
            chooseFile(this);
        end
        
        function workspaceCallback(this, ~, ~)
            this.Source = 'workspace';
            updateVariables(this);
            update(this);
        end
        
        function fileCallback(this, ~, ~)
            if isempty(this.FileName)
                this.hWorkspace.Value = false;
                chooseFile(this);
            else
                this.Source = 'matfile';
                updateVariables(this);
                update(this);
            end
        end
        
        function popupCallback(this, hPop, ~)
            this.VariableNames{hPop.UserData} = hPop.String{hPop.Value};
            update(this);
        end
        
        function okCallback(this, ~, ~)
            if this.CantClose
                return
            end
            this.IsValid = true;
            close(this);
        end
        
        function cancelCallback(this, ~, ~)
            if this.CantClose
                return
            end
            this.IsValid = false;
            close(this);
        end
        
        function onPanelLayoutPerformed(this, ~, ~)
            
            % Make sure the file name widget fills the space
            hname = this.hFileName;
            position = hname.Position;
            
            panelpos = getpixelposition(this.hFilePanel);
            
            position(3) = panelpos(3) - position(1) - 5;
            
            hname.Position = position;
            setFileNameString(this);
        end
        
        function setFileNameString(this)
            
            % Make sure the file name shows the beginning and end.
            fileName = this.FileName;
            hname = this.hFileName;
            if isempty(fileName)
                hname.String = getString(message('Spcuilib:application:ImportNoFileLoaded'));
                return;
            end
            
            % Make an invisible widget to iterate on the extent.  This will
            % avoid flickering.
            htest = uicontrol(this.Figure, ...
                'Visible', 'off', ...
                'Style', 'text', ...
                'String', fileName);
            if isequal(fileName(1), filesep)
                sepIndex = strfind(fileName, filesep);
                d = diff(sepIndex);
                firstChar = sepIndex(find(d ~= 1, 1, 'first') + 1);
                
            else
                firstChar = strfind(fileName, filesep);
                firstChar = firstChar(1);
            end
            
            start = fileName(1:firstChar);
            rest  = fileName(firstChar+1:end);
            width = hname.Position(3);
            while htest.Extent(3) > width && numel(rest) > 0
                rest(1) = [];
                htest.String = [start '...' rest];
            end
            if numel(start) + numel(rest) == numel(fileName)
                name = fileName;
            else
                name = [start '...' rest];
            end
            hname.String = name;
            delete(htest);
        end
        
        function deleteFcn(this, ~, ~)
            this.Figure = -1;
            this.Labels = matlab.ui.control.UIControl.empty;
            this.Popups = matlab.ui.control.UIControl.empty;
        end
    end
end

function populateVariables(loadedVars)

vars = fieldnames(loadedVars);
for indx = 1:numel(vars)
    assignin('caller', vars{indx}, loadedVars.(vars{indx}));
end

end

% [EOF]
