classdef ToolStripViewer < handle
    %This class is for internal use only. It may be removed in the future.

    %   Copyright 2024 The MathWorks, Inc.

    properties(Access = {?matlab.unittest.TestCase, ?ros.internal.rosgraph.view.AppView})
        
        AppContainer
        LayoutDropDown
        DefaultTopicCheckBox
        DefaultServiceCheckBox
        ActionTopicServiceCheckBox
        NameSpaceLevelSpinner

        FindConnectionElement1Dropdown
        FindConnectionElement2Dropdown

        KeyWordFilter
        ApplyKeywordFilterBtn

        RefreshBtn
        AutoArrange
        UnreachableCheckBox
        DeadSinkCheckBox
        LeafTopicCheckBox
        ExportButton
        AdvancedFilters
        QABHelpButton

        RosNetworkDetailsEntered = function_handle.empty
        RefreshButtonCallback = function_handle.empty
        ArrangeButtonCallback = function_handle.empty
        FilterSettingsChangedCallback = function_handle.empty
        AdvancedFilterCallback = function_handle.empty
        LayoutChangedCallback = function_handle.empty
        ExportButtonCallback = function_handle.empty
        NameSpaceLevelChangedCallback = function_handle.empty
        FindConnectionDropdownCallback = function_handle.empty
        DeleteProgressDlgCallback = function_handle.empty
    end

    properties (Constant, Access = ?matlab.unittest.TestCase)

        %% Preference group for MATLAB preference
        PrefGroup = 'ROS_Toolbox'
        LastUsedROSDomainIDs = 'VIS_APP_LAST_USED_ROS_DOMAIN_IDS'

        %% Tags
        TagTabGroup = "RosGraphViewerTabGroup"
        TagTabMain = "ApplicationTab"
        TagQABHelpButton = "Ros2NetworkAnalyzerQABHelpButton"

        TagConnectionSection = "ConnectionSection"
        TagConnectCol = "ConnectCol"
        TagConnectBtn = "ConnectBtn"
        TagConnectSubmit ="ConnectSubmit"

        TagRefreshCol = "RefreshCol"
        TagRefreshBtn = "RefreshBtn"
        
        TagViewSection = "ViewSection"
        TagAutoArrangeCol = "AutoArrangeCol"
        TagAutoArrange = "AutoArrange"
        TagAdvancedFilters = "AdvancedFilters"
        
        TagFilterSection = "FilterSection"
        TagFilterCol1 = "FilterCol1"
        TagFilterCol2 = "FilterCol2"
        TagFilterCol3 = "FilterCol3"
        TagFilterCol4 = "FilterCol4"
        
        TagUnreachableChkBox = "UnreachableChkBox"
        TagDefaultTopicCheckBox = "DefaultTopicCheckBox"
        TagDeadSinkChkBox = "DeadSinkChkBox"
        TagLeafTopicChkBox = "LeafTopicChkBox"
        TagDefaultSvcChkBox = "DefaultServicesChkBox";
        TagActionSvcTopicChkBox = "ActionSvcTopicChkBox";

        TagLayoutSection = "LayoutSection";
        TagLayoutCol = "LayoutLabelCol"
        TagLayoutLabel = "LayoutLabel"

        TagLayoutDropdown = "LayoutDropdown"
        TagNameSpaceSpinnerLabel = "NameSpaceSpinnerLabel"
        TagNameSpaceSpinner ="NameSpaceSpinner"

        TagDomainIdInputTxtArea = "DomainIdInputTxtArea"
        TagExportSection = "ExportSection"
        TagExportBtn = "ExportBtn"
        TagExportCol = "ExportCol"

        TagFindConnectionSection = "FindConnectionSection"
        TagFindConnectionLabelCol1 = "FindConnectionLabelCol1"
        TagElement1Label = "FindConnectionElement1Label"
        TagElement2Label = "FindConnectionElement2Label"
        TagFindConnectionLabelCol2 = "TagfindConnectionLabelCol2"
        TagElement1DropDown = "FindConnectionElement1Dropdown"
        TagElement2DropDown = "FindConnectionElement2Dropdown"

        TagKeyWordFilterTextArea = "KeyWordFilterTextArea"
        TagApplyKeywordFilterBtn = "ApplyKeywordFilterBtn"
        %% Catalogs
        TitleTabMain = getString(message("ros:rosgraphapp:view:TitleTabMain"))
        TitleConnectionSection = getString(message("ros:rosgraphapp:view:TitleConnectionSection"))

        TextConnectButton = getString(message("ros:rosgraphapp:view:TextConnectButton"))
        DescriptionConnectButton = getString(message("ros:rosgraphapp:view:DescriptionConnectButton"))

        TextRefreshButton = getString(message("ros:rosgraphapp:view:TextRefreshButton"))
        DescriptionRefreshButton = getString(message("ros:rosgraphapp:view:DescriptionRefreshButton"))

        TitleViewSection = getString(message("ros:rosgraphapp:view:TitleViewSection"))
        TextAutoArrangeButton = getString(message("ros:rosgraphapp:view:TextAutoArrangeButton"))
        DescriptionAutoArrangedButton = getString(message("ros:rosgraphapp:view:DescriptionAutoArrangehButton"))

        TitleFilterSection = getString(message("ros:rosgraphapp:view:TitleFilterSection"))

        TextUnreachableChkBox = getString(message("ros:rosgraphapp:view:TextUnreachableChkBox"))
        TextDefaultChkBox = getString(message("ros:rosgraphapp:view:TextDefaultChkBox"))
        TextDeadSinkChkBox = getString(message("ros:rosgraphapp:view:TextDeadSinkChkBox"))
        TextLeafTopicChkBox = getString(message("ros:rosgraphapp:view:TextLeafTopicChkBox"))
        TextDefaultSvcChkBox = getString(message("ros:rosgraphapp:view:TextDefaultSvcChkBox"))
        TextActionSvcTopicChkBox = getString(message("ros:rosgraphapp:view:TextActionSvcTopicChkBox"))
        TextAdvancedFilterButton = getString(message("ros:rosgraphapp:view:TextAdvancedFilterButton"))
        DescriptionUnreachableChkBox = getString(message("ros:rosgraphapp:view:DescriptionUnreachableChkBox"))
        DescriptionDefaultChkBox = getString(message("ros:rosgraphapp:view:DescriptionDefaultChkBox"))
        DescriptionDeadSinkChkBox = getString(message("ros:rosgraphapp:view:DescriptionDeadSinkChkBox"))
        DescriptionLeafTopicChkBox = getString(message("ros:rosgraphapp:view:DescriptionLeafTopicChkBox"))
        DescriptionDefaultSvcChkBox = getString(message("ros:rosgraphapp:view:DescriptionDefaultSvcChkBox"))
        DescriptionActionSvcTopicChkBox = getString(message("ros:rosgraphapp:view:DescriptionActionSvcTopicChkBox"))

        DescriptionNameSpaceSpinner = getString(message("ros:rosgraphapp:view:DescriptionNameSpaceSpinner"))

        TitleLayoutSection = getString(message("ros:rosgraphapp:view:TitleLayoutSection"))
        TextLayoutLabel = getString(message("ros:rosgraphapp:view:TextLayoutLabel"))
        DescriptionLayoutDropDown = getString(message("ros:rosgraphapp:view:DescriptionLayoutDropDown"))
        LayoutKlay = getString(message("ros:rosgraphapp:view:LayoutKlay"))
        LayoutDagre = getString(message("ros:rosgraphapp:view:LayoutDagre"))
        LayoutBreadthfirst = getString(message("ros:rosgraphapp:view:LayoutBreadthfirst"))
        LayoutCose = getString(message("ros:rosgraphapp:view:LayoutCose"))
        LayoutCircle = getString(message("ros:rosgraphapp:view:LayoutCircle"))
        LayoutGrid = getString(message("ros:rosgraphapp:view:LayoutGrid"))
        LayoutConcentric = getString(message("ros:rosgraphapp:view:LayoutConcentric"))
        
        TextNameSpaceSpinnerLbl = getString(message("ros:rosgraphapp:view:TextNameSpaceSpinnerLbl"))
        TitleExportBtn = getString(message("ros:rosgraphapp:view:TitleExportBtn"))
        DescriptionExportBtn = getString(message("ros:rosgraphapp:view:DescriptionExportBtn"))
        TextExportBtn = getString(message("ros:rosgraphapp:view:TextExportBtn"))
        TextLabelDomainId = getString(message("ros:rosgraphapp:view:TextLabelDomainId"))
        TextEnterDomainIdBtn = getString(message("ros:rosgraphapp:view:TextEnterDomainIdBtn"))

        TitleFindConnectionSection = "Find connection between 2 elements"
        TextElement1Label = "Element1"
        TextElement2Label = "Element2"
        DescriptionElement1DropDown = "Select Element1"
        DescriptionElement2DropDown = "Select Element2"
        DescriptionKeyWordFilterTextArea = getString(message("ros:rosgraphapp:view:DescriptionKeyWordFilterTextArea"))
        TextApplyKeywordFilterBtn = getString(message("ros:rosgraphapp:view:TextApplyKeywordFilterBtn"))

        FilterPlaceHolder = getString(message("ros:rosgraphapp:view:PlaceHolderApplyKeywordFilter"))
        LabelFilter = getString(message("ros:rosgraphapp:view:LabelSearch"))

        HelpButtonAchorID = "ros2NetworkAnalyzer_app"
    end

    methods
        function obj = ToolStripViewer(appContainer)
           obj.AppContainer =appContainer;
           createToolstrip(obj,appContainer)

           buildQAB(obj,appContainer)

        end

        function buildQAB(obj,appContainer)
            % buildQAB used to build Quick Access Bar
            % add Help button to QAB

            obj.QABHelpButton = matlab.ui.internal.toolstrip.qab.QABHelpButton();
            obj.QABHelpButton.Tag = obj.TagQABHelpButton;
            obj.QABHelpButton.ButtonPushedFcn = @(varargin) helpview('ros', obj.HelpButtonAchorID);
            appContainer.add(obj.QABHelpButton)
        end

        function createToolstrip(obj, appContainer)
            tabGroup = matlab.ui.internal.toolstrip.TabGroup();
            tabGroup.Tag = obj.TagTabGroup;
            appContainer.add(tabGroup);

            visualizerTab = matlab.ui.internal.toolstrip.Tab();
            visualizerTab.Tag = obj.TagTabMain;
            visualizerTab.Title = obj.TitleTabMain;
            tabGroup.add(visualizerTab);
            
            connectionSection = matlab.ui.internal.toolstrip.Section();
            connectionSection.Tag = obj.TagConnectionSection;
            connectionSection.Title = obj.TitleConnectionSection;
            visualizerTab.add(connectionSection);
            
            connectCol = matlab.ui.internal.toolstrip.Column();
            connectCol.Tag = obj.TagConnectCol;
            connectionSection.add(connectCol);
            connectIcon = matlab.ui.internal.toolstrip.Icon("new");
            connectButton = matlab.ui.internal.toolstrip.Button(obj.TextConnectButton, connectIcon);
            connectButton.Tag = obj.TagConnectBtn;
            connectButton.Description = obj.DescriptionConnectButton;
            connectButton.ButtonPushedFcn = @(src, event) obj.connectButtonCallback;%{@obj.connect, obj};
            connectCol.add(connectButton);

            refreshCol = matlab.ui.internal.toolstrip.Column();
            refreshCol.Tag = obj.TagRefreshCol;
            connectionSection.add(refreshCol);
            refreshIcon = matlab.ui.internal.toolstrip.Icon("refresh");
            refreshButton = matlab.ui.internal.toolstrip.Button(obj.TextRefreshButton, refreshIcon);
            refreshButton.Tag = obj.TagRefreshBtn;
            refreshButton.Description = obj.DescriptionRefreshButton;
            refreshButton.ButtonPushedFcn = @(src, event) makeCallback(obj.RefreshButtonCallback, src, event);%{@obj.refresh, obj};
            refreshCol.add(refreshButton);
            obj.RefreshBtn = refreshButton;

            viewSection = matlab.ui.internal.toolstrip.Section();
            viewSection.Tag = obj.TagViewSection;
            viewSection.Title = obj.TitleViewSection;
            visualizerTab.add(viewSection);
            autoArrangeCol = matlab.ui.internal.toolstrip.Column();
            autoArrangeCol.Tag = obj.TagAutoArrangeCol;
            viewSection.add(autoArrangeCol);
            arrangeIcon = matlab.ui.internal.toolstrip.Icon("autoArrange");
            arrangeButton = matlab.ui.internal.toolstrip.Button(obj.TextAutoArrangeButton, arrangeIcon);
            arrangeButton.Tag = obj.TagAutoArrange;
            arrangeButton.Description = obj.DescriptionAutoArrangedButton;
            arrangeButton.ButtonPushedFcn = @(src, event) makeCallback(obj.ArrangeButtonCallback, src, event);%{@obj.autoArrange, obj};
            autoArrangeCol.add(arrangeButton);
            obj.AutoArrange = arrangeButton;

            %Filter section
            filterSection = matlab.ui.internal.toolstrip.Section();
            filterSection.Tag = obj.TagFilterSection;
            filterSection.Title = obj.TitleFilterSection;
            visualizerTab.add(filterSection);
            filterCol1 = matlab.ui.internal.toolstrip.Column();
            filterCol1.Tag = obj.TagFilterCol1;
            filterSection.add(filterCol1);
            filterCol2 = matlab.ui.internal.toolstrip.Column();
            filterCol2.Tag = obj.TagFilterCol2;
            filterSection.add(filterCol2);
            filterCol3 = matlab.ui.internal.toolstrip.Column();
            filterCol3.Tag = obj.TagFilterCol3;
            filterSection.add(filterCol3);

            unreachableCheckBox = matlab.ui.internal.toolstrip.CheckBox(obj.TextUnreachableChkBox);
            unreachableCheckBox.Tag = obj.TagUnreachableChkBox;
            unreachableCheckBox.ValueChangedFcn = @(src, event) makeCallback(obj.FilterSettingsChangedCallback, src, event);%{@obj.filter, obj};
            unreachableCheckBox.Value = true;
            unreachableCheckBox.Description = obj.DescriptionUnreachableChkBox;
            deadSinkCheckBox = matlab.ui.internal.toolstrip.CheckBox(obj.TextDeadSinkChkBox);
            deadSinkCheckBox.Tag = obj.TagDeadSinkChkBox;
            deadSinkCheckBox.Value = true;
            deadSinkCheckBox.Description = obj.DescriptionDeadSinkChkBox;
            deadSinkCheckBox.ValueChangedFcn = @(src, event) makeCallback(obj.FilterSettingsChangedCallback, src, event);%{@obj.filter, obj};
            leafTopicCheckBox = matlab.ui.internal.toolstrip.CheckBox(obj.TextLeafTopicChkBox);
            leafTopicCheckBox.Tag = obj.TagLeafTopicChkBox;
            leafTopicCheckBox.Value = true;
            leafTopicCheckBox.ValueChangedFcn = @(src, event) makeCallback(obj.FilterSettingsChangedCallback, src, event);%{@obj.filter, obj};
            leafTopicCheckBox.Description = obj.DescriptionLeafTopicChkBox;

            obj.UnreachableCheckBox = unreachableCheckBox;
            obj.DeadSinkCheckBox = deadSinkCheckBox;
            obj.LeafTopicCheckBox = leafTopicCheckBox;

            defaultTopicCheckBox = matlab.ui.internal.toolstrip.CheckBox(obj.TextDefaultChkBox);
            defaultTopicCheckBox.Tag = obj.TagDefaultTopicCheckBox;
            defaultTopicCheckBox.Value = false;
            defaultTopicCheckBox.Description = obj.DescriptionDefaultChkBox;
            defaultTopicCheckBox.ValueChangedFcn = @(src, event) makeCallback(obj.FilterSettingsChangedCallback, src, event);%{@obj.filter, obj};
            defaultServiceCheckbox = matlab.ui.internal.toolstrip.CheckBox(obj.TextDefaultSvcChkBox);
            defaultServiceCheckbox.Tag = obj.TagDefaultSvcChkBox;
            defaultServiceCheckbox.Value = false;
            defaultServiceCheckbox.Description = obj.DescriptionDefaultSvcChkBox;
            defaultServiceCheckbox.ValueChangedFcn = @(src, event) makeCallback(obj.FilterSettingsChangedCallback, src, event);%{@obj.filter, obj};
            actionTopicsServicesCheckbox = matlab.ui.internal.toolstrip.CheckBox(obj.TextActionSvcTopicChkBox);
            actionTopicsServicesCheckbox.Tag = obj.TagActionSvcTopicChkBox;
            actionTopicsServicesCheckbox.Value = false;
            actionTopicsServicesCheckbox.ValueChangedFcn = @(src, event) makeCallback(obj.FilterSettingsChangedCallback, src, event);%{@obj.filter, obj};
            actionTopicsServicesCheckbox.Description = obj.DescriptionActionSvcTopicChkBox;

            obj.DefaultTopicCheckBox = defaultTopicCheckBox;
            obj.DefaultServiceCheckBox = defaultServiceCheckbox;
            obj.ActionTopicServiceCheckBox = actionTopicsServicesCheckbox;

            filterIcon = matlab.ui.internal.toolstrip.Icon("filter");
            filterButton = matlab.ui.internal.toolstrip.ToggleButton(obj.TextAdvancedFilterButton, filterIcon);
            filterButton.Tag = obj.TagAdvancedFilters;
            filterButton.Value = true;
            filterButton.ValueChangedFcn = @(src, event) makeCallback(obj.AdvancedFilterCallback, src, event);%{@obj.autoArrange, obj};
            
            obj.AdvancedFilters = filterButton;
            
            filterCol1.add(unreachableCheckBox);
            filterCol1.add(deadSinkCheckBox);
            filterCol1.add(leafTopicCheckBox);
            filterCol2.add(defaultTopicCheckBox);
            filterCol2.add(defaultServiceCheckbox);
            filterCol2.add(actionTopicsServicesCheckbox);

            filterCol3.add(filterButton);
            
            %filter section end

            %Layout Section%%
            layoutSection = matlab.ui.internal.toolstrip.Section();
            layoutSection.Tag = obj.TagLayoutSection;
            layoutSection.Title = obj.TitleLayoutSection;
            visualizerTab.add(layoutSection);
            layoutLabelCol = matlab.ui.internal.toolstrip.Column();
            layoutLabelCol.Tag = obj.TagLayoutCol;
            layoutSection.add(layoutLabelCol);
            layoutLabel = matlab.ui.internal.toolstrip.Label(obj.TextLayoutLabel);
            layoutLabel.Tag = obj.TagLayoutLabel;
            
            % Create a dropdown with some items
            layoutDropdown = matlab.ui.internal.toolstrip.DropDown();
            %layoutDropdown.Editable = true;
            layoutDropdown.Tag = obj.TagLayoutDropdown;
            layoutDropdown.Description = obj.DescriptionLayoutDropDown;
            % Add items to the layoutDropdown
            layoutDropdown.addItem({'klay',obj.LayoutKlay});
            layoutDropdown.addItem({'dagre',obj.LayoutDagre});
            layoutDropdown.addItem({'breadthfirst',obj.LayoutBreadthfirst});
            layoutDropdown.addItem({'cose',obj.LayoutCose});
            layoutDropdown.addItem({'circle',obj.LayoutCircle});
            layoutDropdown.addItem({'grid',obj.LayoutGrid});
            layoutDropdown.addItem({'concentric',obj.LayoutConcentric});
            layoutDropdown.Value = 'dagre';
            
            obj.LayoutDropDown = layoutDropdown;
            % Set the callback function for the layoutDropdown selection changed event
            layoutDropdown.ValueChangedFcn = @(src, event) makeCallback(obj.LayoutChangedCallback, src, event);%{@obj.layoutSelectionChanged, obj};
            % Add the layoutDropdown to the column
            
            layoutControlCol = matlab.ui.internal.toolstrip.Column();
            layoutSection.add(layoutControlCol);
            nameSpaceSpinnerLabel = matlab.ui.internal.toolstrip.Label(obj.TextNameSpaceSpinnerLbl);
            nameSpaceSpinnerLabel.Tag = obj.TagNameSpaceSpinnerLabel;
            namespaceSpinner = matlab.ui.internal.toolstrip.Spinner([0, 10], 0);
            namespaceSpinner.Tag = obj.TagNameSpaceSpinner;
            namespaceSpinner.ValueChangedFcn = @(src, event) makeCallback(obj.NameSpaceLevelChangedCallback, src, event);
            namespaceSpinner.Description = obj.DescriptionNameSpaceSpinner;
            obj.NameSpaceLevelSpinner = namespaceSpinner;

            layoutLabelCol.add(layoutLabel);
            layoutLabelCol.add(nameSpaceSpinnerLabel);
            layoutControlCol.add(layoutDropdown);
            layoutControlCol.add(namespaceSpinner);
            %layout section end

            %Layout Section%%
            findConnectionSection = matlab.ui.internal.toolstrip.Section();
            findConnectionSection.Tag = obj.TagFindConnectionSection;
            findConnectionSection.Title = obj.TitleFindConnectionSection;
            visualizerTab.add(findConnectionSection);

            findConnectionLabelCol = matlab.ui.internal.toolstrip.Column();
            findConnectionLabelCol.Tag = obj.TagFindConnectionLabelCol1;
            findConnectionSection.add(findConnectionLabelCol);
            element1Label = matlab.ui.internal.toolstrip.Label(obj.TextElement1Label);
            element1Label.Tag = obj.TagElement1Label;
            element2Label = matlab.ui.internal.toolstrip.Label(obj.TextElement2Label);
            element2Label.Tag = obj.TagElement2Label;
            findConnectionLabelCol.add(element1Label);
            findConnectionLabelCol.add(element2Label);

            findConnectionLabelCol2 = matlab.ui.internal.toolstrip.Column();
            findConnectionLabelCol2.Tag = obj.TagFindConnectionLabelCol2;
            findConnectionSection.add(findConnectionLabelCol2);
            
            element1DropDown = matlab.ui.internal.toolstrip.DropDown();
            element1DropDown.Editable = true;
            element1DropDown.Tag = obj.TagElement1DropDown;
            element1DropDown.Description = obj.DescriptionElement1DropDown;
            element2DropDown = matlab.ui.internal.toolstrip.DropDown();
            element2DropDown.Editable = true;
            element2DropDown.Tag = obj.TagElement2DropDown;
            element2DropDown.Description = obj.DescriptionElement2DropDown;
            findConnectionLabelCol2.add(element1DropDown);
            findConnectionLabelCol2.add(element2DropDown);

            obj.FindConnectionElement1Dropdown = element1DropDown;
            obj.FindConnectionElement2Dropdown = element2DropDown;
            obj.FindConnectionElement1Dropdown.ValueChangedFcn = @(src, event) makeCallback(obj.FindConnectionDropdownCallback, src, event);
            obj.FindConnectionElement2Dropdown.ValueChangedFcn = @(src, event) makeCallback(obj.FindConnectionDropdownCallback, src, event);

            % TODO : Need to finalize the final UI
            findConnectionSection.delete
            %End
            
            exportSection = matlab.ui.internal.toolstrip.Section();
            exportSection.Tag = obj.TagExportSection;
            exportSection.Title = obj.TitleExportBtn;
            visualizerTab.add(exportSection);
            exportCol = matlab.ui.internal.toolstrip.Column();
            exportCol.Tag = obj.TagExportCol;
            exportSection.add(exportCol);
            exportIcon = matlab.ui.internal.toolstrip.Icon("export");
            exportButton = matlab.ui.internal.toolstrip.Button(obj.TextExportBtn, exportIcon);
            exportButton.Tag = obj.TagExportBtn;
            exportButton.Description = obj.DescriptionExportBtn;
            exportButton.ButtonPushedFcn = @(src, event) makeCallback(obj.ExportButtonCallback, src, event);%{@obj.export, obj};
            exportCol.add(exportButton);
            obj.ExportButton = exportButton;
        end
    
        function deactivateElements(obj)

            obj.RefreshBtn.Enabled = false;
            obj.AutoArrange.Enabled = false;
            obj.UnreachableCheckBox.Enabled = false;
            obj.DeadSinkCheckBox.Enabled = false;
            obj.LeafTopicCheckBox.Enabled = false;
            obj.DefaultTopicCheckBox.Enabled = false;
            obj.DefaultServiceCheckBox.Enabled = false;
            obj.ActionTopicServiceCheckBox.Enabled = false;
            obj.AdvancedFilters.Enabled = false;
            obj.ApplyKeywordFilterBtn.Enabled = false;
            obj.LayoutDropDown.Enabled = false;
            obj.NameSpaceLevelSpinner.Enabled = false;
            obj.ExportButton.Enabled = false;
        end

        function activateElements(obj)

            obj.RefreshBtn.Enabled = true;
            obj.AutoArrange.Enabled = true;
            obj.UnreachableCheckBox.Enabled = true;
            obj.DeadSinkCheckBox.Enabled = true;
            obj.LeafTopicCheckBox.Enabled = true;
            obj.DefaultTopicCheckBox.Enabled = true;
            obj.DefaultServiceCheckBox.Enabled = true;
            obj.ActionTopicServiceCheckBox.Enabled = true;
            obj.AdvancedFilters.Enabled = true;
            obj.ApplyKeywordFilterBtn.Enabled = true;
            obj.LayoutDropDown.Enabled = true;
            obj.NameSpaceLevelSpinner.Enabled = true;
            obj.ExportButton.Enabled = true;
        end

        function graphLoaded(~,~)
            %TODO : Once UI is finalized 
            % obj.FindConnectionElement1Dropdown.Value = "";
            % obj.FindConnectionElement2Dropdown.Value = "";
            % 
            % elements = graph.getNetworkElementList';
            % obj.FindConnectionElement1Dropdown.replaceAllItems(elements);
            % obj.FindConnectionElement2Dropdown.replaceAllItems(elements);
            
        end

        function ret = getDefaultTopicvisibility(obj)

            ret = obj.DefaultTopicCheckBox.Value;
        end

        function ret = getDefaultServicevisibility(obj)

            ret = obj.DefaultServiceCheckBox.Value;
        end

        function ret = getActionTopicServicevisibility(obj)

            ret = obj.ActionTopicServiceCheckBox.Value;
        end

        function ret = getSelectedLayout(obj)

            ret = obj.LayoutDropDown.Value;
        end
        
        function val = getNameSpaceLavel(obj)

            val = obj.NameSpaceLevelSpinner.Value;
        end

        function elements = getSelectedElementsForConnection(obj)

            elements.Element1 = obj.FindConnectionElement1Dropdown.Value;
            elements.Element2 = obj.FindConnectionElement2Dropdown.Value;
            if ~isempty(elements.Element1) && ~isempty(elements.Element2)
                if ~ismember(elements.Element1,obj.FindConnectionElement1Dropdown.Items) ...
                        || ~ismember(elements.Element2,obj.FindConnectionElement2Dropdown.Items)
                    error("Select a valid element")
                end
            end
        end

        function connectButtonCallback(obj)
            % Adding userData to get the present appcontainer data
            fig = uifigure('Position',[500 500 430 200],'WindowStyle','modal', ...
                "UserData", obj.AppContainer);
            fig.Name = getString(message("ros:rosgraphapp:view:EnterNetworkDetails"));
 			matlab.graphics.internal.themes.figureUseDesktopTheme(fig);
            uilabel(fig, 'Position',[100 150 215 15],...
                    'Text', obj.TextLabelDomainId, 'HorizontalAlignment', 'center');

            prefName = obj.LastUsedROSDomainIDs;
            defaultNetworkInput = '0';
            prefNetworkInput = {};
            if ispref(obj.PrefGroup,prefName)
                prefNetworkInput = getpref(obj.PrefGroup,prefName);
            end
            if ~ismember(defaultNetworkInput,prefNetworkInput)
                prefNetworkInput{end+1} = defaultNetworkInput;
                if numel(prefNetworkInput) >10
                    prefNetworkInput(1) = [];
                end
            end

            textarea = uidropdown(fig, 'Position',[100 100 215 30]);
            % Make sure it only shows the valid domain ids
            textarea.Items = prefNetworkInput(~isnan(str2double(prefNetworkInput)));
            textarea.Value = defaultNetworkInput;
            textarea.Tag = obj.TagDomainIdInputTxtArea;
            textarea.Editable = 'on';
            uibutton(fig, ...
                "Text",obj.TextEnterDomainIdBtn,...
                "ButtonPushedFcn",@(src,event)rosNetworkDetailsEntered(fig,src, event,textarea.Value), ...
                'Position',[100 50 215 30], ...
                "Tag",obj.TagConnectSubmit );
            
            function rosNetworkDetailsEntered(fig, src, event,domainId)
                try
                    close(fig);
                    makeCallback(@obj.RosNetworkDetailsEntered, src, event,domainId);
                    if ~ismember(domainId, prefNetworkInput)
                        prefNetworkInput{end+1} = domainId;
                        
                        if numel(prefNetworkInput) >10
                            prefNetworkInput(1) = [];
                        end
                    end
                    setpref(obj.PrefGroup,prefName,prefNetworkInput);
                catch ex
                   errordlg(ex.message,string(getString(message('ros:rosgraphapp:view:ErrorFailedToConnectToNetwork',domainId))),'modal')
                   % Deleting progress bar
                   makeCallback(@obj.DeleteProgressDlgCallback, src, event);
                end
            end
        end

        function query = getKeyWordFilterQuery(obj)
            query = obj.KeyWordFilter.Value;
            if strcmp(query,obj.FilterPlaceHolder)
                query = '';
            end
        end
    end
        
end

function makeCallback(fcn, varargin)
%makeCallback Evaluate specified function with arguments if not empty

    if ~isempty(fcn)
        feval(fcn, varargin{:})
    end
end

% LocalWords:  QAB Chk Svc Dropdown Klay Dagre Breadthfirst Cose Lbl dropdown klay dagre breadthfirst cose appcontainer uilabel textarea uidropdown 