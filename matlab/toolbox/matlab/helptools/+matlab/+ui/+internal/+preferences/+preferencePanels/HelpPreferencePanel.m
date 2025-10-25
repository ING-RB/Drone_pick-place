classdef HelpPreferencePanel < handle
    %HELPPREFERENCEPANEL The preference panel for MATLAB help preferences
    %   The class describing the MATLAB Help Preferences panel in the 
    %   Preferences window.

%   Copyright 2022-2024 The MathWorks, Inc.

    properties (Access = public)
        UIFigure;
        UIFigureGrid;
        LocationButtonGroup;
        LanguageDropDown;
        DocLocationGrid;
        OptionalDocGrid;
        DocLanguageGrid;
        MessageLabel;
        InstallDocButton;
        SettingsObj;
        PanelWidth;
        GeneralPadding;
        GeneralRowHeight;
        OptionalDocRowHeight;
    end

    methods (Access = public)
        function obj = HelpPreferencePanel()
            %HELPPREFERENCEPANEL Construct an instance of this class.

            % Call builtins to ensure that the doc language and doc
            % location infrastructure is initialized.
            activeLoc = matlab.internal.doc.getDocLocation;
            matlab.internal.doc.i18n.getDocLanguage;

            % Cache the settings object for use later.
            obj.SettingsObj = settings;

            % Create uiFigure
            obj.UIFigure = uifigure;

            % Create the main 'top grid' container for the locataion and
            % language grids. 3 rows, 1 column.
            obj.UIFigureGrid = uigridlayout(obj.UIFigure, [2, 1]);
            obj.UIFigureGrid.RowHeight = {'fit','fit'};
            obj.UIFigureGrid.ColumnWidth = {'fit'};

            obj.PanelWidth = 550;
            obj.GeneralPadding = 10;
            obj.GeneralRowHeight = 22;
            obj.OptionalDocRowHeight = 35;
            locRadioButtonGridRowHeight = 86;
            indentedPadding = 24;
            indentedPanelWidth = obj.PanelWidth - indentedPadding;

            % Create grid For Doc Location section
            % Size 5 rows, 1 column
            % Heading, Button Group, and the "optional doc" sub-panel which
            % contains a Message Label, the Install Doc Button and the 
            % after install action (restart MATLAB).
            obj.DocLocationGrid = uigridlayout(obj.UIFigureGrid, [4, 1]); 
            obj.DocLocationGrid.RowHeight = {'fit', locRadioButtonGridRowHeight, 0};
            obj.DocLocationGrid.ColumnWidth = obj.PanelWidth;

            locationHeader = uilabel(obj.DocLocationGrid);
            locationHeader.Text = getString(message('MATLAB:helpprefs:DocumentationLocation'));
            locationHeader.FontWeight = 'bold';

            % Location Button Group

            iconWidthHeight = 16;
            radioButtonLabelWidth = obj.PanelWidth - obj.GeneralPadding - iconWidthHeight;            

            % Layout for location radio buttons
            % Workaround for using HTML markup in uiradiobutton text.
            % Put a grid layout and labels in a button group, then position 
            % the uiradiobuttons parented to the button group on top.  
            % Size 1 row, 2 columns
            % Column 1, radio buttons
            % Column 2, button labels            
            radioButtonGrid = uigridlayout(obj.DocLocationGrid, [1, 2]);
            radioButtonGrid.Padding = [obj.GeneralPadding, 0, 0, 0];
            radioButtonGrid.RowSpacing = 0;
            radioButtonGrid.ColumnSpacing = 0;
            radioButtonGrid.RowHeight = {locRadioButtonGridRowHeight};

            radioButtonGrid.ColumnWidth = {iconWidthHeight, radioButtonLabelWidth};

            % Radio Buttons
            obj.LocationButtonGroup = uibuttongroup(radioButtonGrid,...
                                                   'BorderType', 'none',...
                                                   'SelectionChangedFcn',@obj.locationSelectCallback);
            [~] = uiradiobutton(obj.LocationButtonGroup, ...
                    'Text', '', ...
                    'Position',[1 45 iconWidthHeight iconWidthHeight], ...
                    'UserData', string(matlab.internal.doc.services.DocLocation.WEB));
            [~] = uiradiobutton(obj.LocationButtonGroup, ...
                    'Text', '', ...
                    'Position',[1 5 iconWidthHeight iconWidthHeight], ...
                    'UserData', string(matlab.internal.doc.services.DocLocation.INSTALLED));

            % Button Labels
            % Size 2 rows, 1 column
            rbLabelGrid = uigridlayout(radioButtonGrid, [2, 1]);
            % The first row has 3 lines of html formatted text. Height is 3
            % times the standard height for the radio button.
            rbLabelGrid.RowHeight = {iconWidthHeight*3,iconWidthHeight};
            rbLabelGrid.ColumnWidth = {radioButtonLabelWidth};
            [~] = uilabel(rbLabelGrid, ...
                   'Text', getString(message('MATLAB:helpprefs:WEB')), ...
                   'Interpreter', 'html');
            [~] = uilabel(rbLabelGrid, ...
                   'Text', getString(message('MATLAB:helpprefs:INSTALLED')), ...
                   'Interpreter', 'html');
            
            if activeLoc == string(matlab.internal.doc.services.DocLocation.WEB)
                locationSelectedIdx = 1;
            else
                locationSelectedIdx = 2;
            end
            obj.LocationButtonGroup.Buttons(locationSelectedIdx).Value = true;

            if isOptionalDocInstall(obj)
                docIsInstalled = isDocInstalled(obj);
                % Layout for optional doc UI elements
                % Size 3 rows, 1 column
                % Message Label, the Install Doc Button and the after 
                % install action (restart MATLAB) message.
                obj.OptionalDocGrid = uigridlayout(obj.DocLocationGrid, [3, 1]);
                obj.OptionalDocGrid.Padding = [indentedPadding, 0, 0, 0];
                obj.OptionalDocGrid.RowSpacing = 0;
                obj.OptionalDocGrid.ColumnSpacing = 0;                
                obj.OptionalDocGrid.RowHeight = {obj.OptionalDocRowHeight, obj.OptionalDocRowHeight, obj.OptionalDocRowHeight};
                obj.OptionalDocGrid.ColumnWidth = indentedPanelWidth;
                
                % 1 row, 1 column
                messageGrid = uigridlayout(obj.OptionalDocGrid, [1, 1]); 
                messageGrid.RowHeight = {'fit'};
                messageGrid.ColumnWidth = {'fit'};
                messageText = getString(message('MATLAB:helpprefs:DocumentationIsNotInstalled'));
                obj.MessageLabel = uilabel(messageGrid,...
                                        "Text", messageText, ...
                                        'Position', [obj.GeneralPadding, obj.GeneralPadding, indentedPanelWidth, obj.GeneralRowHeight]);

                % 1 row, 2 columns
                installDocButtonGrid = uigridlayout(obj.OptionalDocGrid, [1, 2]);
                installDocButtonGrid.RowHeight = {obj.GeneralRowHeight};
                installDocButtonGrid.ColumnWidth = {'fit','fit'};
                if docIsInstalled
                    buttonLabel = getString(message('MATLAB:helpprefs:InstallAdditionalDocumentation'));
                else
                    buttonLabel = getString(message('MATLAB:helpprefs:InstallDocumentation'));
                end
                obj.InstallDocButton = uibutton(installDocButtonGrid,...
                                    "Text", buttonLabel,...
                                    "VerticalAlignment","bottom",...
                                    "ButtonPushedFcn", @obj.installDocPushedCallback);
                internetRequiredText = getString(message('MATLAB:helpprefs:InternetConnectionRequired'));
                [~] = uilabel(installDocButtonGrid,...
                        "Text", internetRequiredText);

                % 1 row, 2 columns
                % Workaround for not being able to an an icon to uilabels.
                % Put a uiimage next to the uilabel.
                afterInstallGrid = uigridlayout(obj.OptionalDocGrid, [1, 2]);
                afterInstallGrid.RowHeight = {obj.GeneralRowHeight};
                afterInstallGrid.ColumnWidth = {iconWidthHeight, indentedPanelWidth - iconWidthHeight};

                infoImage = uiimage(afterInstallGrid,...
                        'Position', [obj.GeneralPadding obj.GeneralPadding iconWidthHeight, iconWidthHeight]);
                matlab.ui.control.internal.specifyIconID(infoImage, 'infoUI', 12);

                afterInstallText = getString(message('MATLAB:helpprefs:AfterDocInstall'));
                [~] = uilabel(afterInstallGrid,...
                        "Text", afterInstallText, ...
                        'Position', [obj.GeneralPadding, obj.GeneralPadding, obj.PanelWidth - iconWidthHeight, obj.GeneralRowHeight]);

                % Show or hide the optional install UI elements.
                if activeLoc == matlab.internal.doc.services.DocLocation.INSTALLED
                    if docIsInstalled
                       % Set the row height for the "doc is not installed" 
                       % message to 0.
                       % Set the size allowed for the optional doc
                       % sub-panel to hold 2 rows.
                       obj.OptionalDocGrid.RowHeight{1} = 0;
                       obj.DocLocationGrid.RowHeight{3} = obj.OptionalDocRowHeight * 2;
                    else
                       % Set the size allowed for the optional doc
                       % sub-panel to hold 3 rows, inlcuding the "doc is not installed"
                       % message row.
                       obj.DocLocationGrid.RowHeight{3} = obj.OptionalDocRowHeight * 3;
                    end
                else
                   obj.DocLocationGrid.RowHeight{3} = 0;
                end
            end

            % Populate the language panel.
            populateLanguagePanel(obj);
            % Show language panel.
            setDocLanguageGridVisiblity(obj,'on');

            desktopHelpSettingGroup = obj.SettingsObj.matlab.desktop.help;
            addlistener(desktopHelpSettingGroup, 'DocLanguage', 'PostSet', @obj.languageChangeCallback);

            helpSettingGroup = obj.SettingsObj.matlab.help;
            addlistener(helpSettingGroup, 'DocLocation', 'PostSet', @obj.locationChangeCallback);            
        end

        function result = validate(~)
            % Return true. The UI guards against invalid choices.
            result = true;
        end
         
        function result = commit(obj)
            try
                loc = obj.LocationButtonGroup.SelectedObject.UserData;
                if loc ~= matlab.internal.doc.services.DocLocation.getActiveLocation
                    setDocLocation(obj, loc);
                end

                if ~isempty(obj.LanguageDropDown)
                    lang = obj.LanguageDropDown.Value;
                    if lang ~= matlab.internal.doc.i18n.getDocLanguage
                        setDocLanguage(obj, lang);
                    end
                end

                result = true;
            catch
                result = false;
            end
        end
         
        function delete(obj)
            delete(obj.UIFigure);
        end    
    end

    methods(Access = 'private')
        function locationSelectCallback(obj, source, ~)
           selectedLoc = source.SelectedObject.UserData;
           switch selectedLoc
               case matlab.internal.doc.services.DocLocation.WEB
                   % Hide the optional install UI elements.
                   obj.DocLocationGrid.RowHeight{3} = 0;
               case matlab.internal.doc.services.DocLocation.INSTALLED
                   % Show the optional install UI elements.
                   if isOptionalDocInstall(obj)
                       if isDocInstalled(obj)
                           % Set the "install doc" button text.
                           obj.InstallDocButton.Text = getString(message('MATLAB:helpprefs:InstallAdditionalDocumentation'));
                           % Set the row height for the "doc is not installed" 
                           % message to 0.
                           % Set the size allowed for the optional doc
                           % sub-panel to hold 2 rows
                           obj.OptionalDocGrid.RowHeight{1} = 0;
                           obj.DocLocationGrid.RowHeight{3} = obj.OptionalDocRowHeight * 2;
                       else
                           % Set the "install doc" button text.
                           obj.InstallDocButton.Text = getString(message('MATLAB:helpprefs:InstallDocumentation'));
                           % Set the row height to see the "doc is not installed" 
                           % message.
                           % Set the size allowed for the optional doc
                           % sub-panel to hold 3 rows.
                           obj.OptionalDocGrid.RowHeight{1} = obj.OptionalDocRowHeight;
                           obj.DocLocationGrid.RowHeight{3} = obj.OptionalDocRowHeight * 3;
                       end
                   end
                   % Show the language panel.
                   setDocLanguageGridVisiblity(obj,'on');
           end
        end 

        function languageChangeCallback(obj, ~, evt)
            if  ~isobject(obj) || ~isvalid(obj) || ~isvalid(obj.LanguageDropDown)
                return;
            end
            if (matlab.internal.doc.services.DocLocation.getActiveLocation == matlab.internal.doc.services.DocLocation.INSTALLED && ~isempty(obj.LanguageDropDown))
                newLang = evt.AffectedObject.DocLanguage.ActiveValue;
                obj.LanguageDropDown.Value = newLang;
            end
        end

        function locationChangeCallback(obj, ~, evt)
            if  ~isobject(obj) || ~isvalid(obj) || ~isvalid(obj.LocationButtonGroup)
                return;
            end
            newLoc = evt.AffectedObject.DocLocation.ActiveValue;

            buttons = obj.LocationButtonGroup.Buttons;
            for i = 1:length(buttons)
                button = buttons(i);
                if newLoc == button.UserData
                    button.Value = true;
                    break;
                end
            end
        end

        function installDocPushedCallback(~, ~, ~)
            matlab.internal.doc.services.installDocumentation;
        end

        function populateLanguagePanel(obj)
            persistent installedLanguages;
            if isempty(installedLanguages)
                installedLanguages = matlab.internal.doc.i18n.getInstalledDocLanguages;
            end

            currentInstalledLanguages = matlab.internal.doc.i18n.getInstalledDocLanguages;
            if ~isequal(currentInstalledLanguages, installedLanguages)
                installedLanguages = currentInstalledLanguages; 
                installedLanguageChanged = true;
            else
                installedLanguageChanged = false;
            end

            % If we haven't already populated the panel or the installed 
            % languages have changed, populate the panel now.
            if isempty(obj.DocLanguageGrid) || installedLanguageChanged
                % Create grid For Doc Language section
                % Size 2 rows, 1 column
                % Heading, Button Group.
                obj.DocLanguageGrid = uigridlayout(obj.UIFigureGrid, [2, 1]);
                % Allow 22 for the height of the dropdown or textarea plus 
                % 20 for space at the top and bottom.
                languageGridRowHeight = obj.GeneralRowHeight + 20;
                obj.DocLanguageGrid.RowHeight = {'fit', languageGridRowHeight};
                obj.DocLanguageGrid.ColumnWidth = obj.PanelWidth;
    
                languageHeader = uilabel(obj.DocLanguageGrid);
                languageHeader.Text = getString(message('MATLAB:helpprefs:Language'));
                languageHeader.FontWeight = 'bold';

                numLanguages = length(installedLanguages);

                langPref = matlab.internal.doc.i18n.getDocLanguage;

                % If there's more than one choice, create a dropdown.
                % If there's only one choice, create a label.
                if numLanguages > 1
                    % Language Drop Down
                    langCellArray = arrayfun(@(x) char(getLanguageLabel(obj,installedLanguages(x))),1:numel(installedLanguages),'uni',false);
                    obj.LanguageDropDown = uidropdown(obj.DocLanguageGrid,...
                        'Position', [obj.GeneralPadding, obj.GeneralPadding, obj.PanelWidth, obj.GeneralRowHeight],...
                        'Items',langCellArray,...
                        'ItemsData',installedLanguages,...
                        'Value',langPref);
                else
                    % Language Panel with Label and Border
                    languagePanel = uipanel(obj.DocLanguageGrid,...
                        'BorderType', 'line');
                    [~] = uilabel(languagePanel,...
                        "Text",getLanguageLabel(obj,installedLanguages), ...
                        'Position', [obj.GeneralPadding, obj.GeneralPadding, obj.PanelWidth, obj.GeneralRowHeight]);
                end
            end
        end

        function langLabel = getLanguageLabel(~, lang)
            try
               langLabel = getString(message(strcat('MATLAB:helpprefs:',lang)));
            catch
               % Not sure what else to do here. We found a  
               % supported language that's not in the message 
               % catalog.
               langLabel = lang;
            end
        end

        function setDocLanguageGridVisiblity(obj,visiblity)
            % Populate the language panel if it's not populated or the
            % language choices have changed.
            if isequal(visiblity,'on')
                populateLanguagePanel(obj);
            end
            obj.DocLanguageGrid.Visible = visiblity;
        end

        function setDocLocation(obj, newLoc)
            locSetting = obj.SettingsObj.matlab.help.DocLocation;
            locSetting.PersonalValue = newLoc;
            if locSetting.hasTemporaryValue
                locSetting.TemporaryValue = newLoc;
            end                
        end

        function setDocLanguage(obj, newLang)
            langSetting = obj.SettingsObj.matlab.desktop.help.DocLanguage;
            langSetting.PersonalValue = newLang;
            if langSetting.hasTemporaryValue
                langSetting.TemporaryValue = newLang;
            end                
        end

        function optional_doc_install = isOptionalDocInstall(obj)
            optional_doc_install = obj.SettingsObj.matlab.help.OptionalDocInstall.ActiveValue;
        end

        function is_doc_installed = isDocInstalled(~)
            % Doc is installed if matlab.internal.doc.docroot.getDocroot is
            % a location under matlabshared.supportpkg.getSupportPackageRoot.
            is_doc_installed = 0;
            
            spRoot = matlabshared.supportpkg.getSupportPackageRoot;
            if isempty(spRoot)
                return;
            end

            spRootFileLocation = matlab.internal.web.FileLocation(spRoot);
            docRoot = matlab.internal.doc.docroot.getDocroot;
            docrootFileLocation = matlab.internal.web.FileLocation(docRoot);

            relPath = docrootFileLocation.getRelativeUriFrom(spRootFileLocation);
            is_doc_installed = ~isempty(relPath);
        end
    end

    methods(Static)
        function result = shouldShow()
            % Show or hide the panel in the preferences UI.
            import matlab.internal.capability.Capability;
            result = Capability.isSupported(Capability.LocalClient);
        end
    end    
end