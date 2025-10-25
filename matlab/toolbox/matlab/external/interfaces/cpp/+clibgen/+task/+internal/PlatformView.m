%   Platform view of ui widgets

%   Copyright 2022-2023 The MathWorks, Inc.
classdef PlatformView < handle
    properties (GetAccess = public, Transient, Hidden, SetAccess = private)
        LayoutManager                       matlab.ui.container.GridLayout
        Accordion                           matlab.ui.container.internal.Accordion

        SelectFilesGrid                     matlab.ui.container.GridLayout
        LibraryTypeLabel                    matlab.ui.control.Label
        LibraryTypeButtonGroup              matlab.ui.container.ButtonGroup
        LibraryStartPathLabel               matlab.ui.control.Label
        LibraryStartPathSelection           matlab.ui.control.Label
        LibraryStartPathBrowseButton        matlab.ui.control.Button
        LibraryStartPathRemoveButton        matlab.ui.control.Image
        InterfaceFilesGrid                  matlab.ui.container.GridLayout
        InterfaceFilesTextArea              matlab.ui.control.TextArea
        InterfaceFilesListBox               matlab.ui.control.ListBox
        IncludePathGrid                     matlab.ui.container.GridLayout
        IncludePathTextArea                 matlab.ui.control.TextArea
        IncludePathListBox                  matlab.ui.control.ListBox
        IncludePathNotRequiredCheckBox      matlab.ui.control.CheckBox
        LibrariesGrid                       matlab.ui.container.GridLayout
        LibrariesTextArea                   matlab.ui.control.TextArea
        LibrariesListBox                    matlab.ui.control.ListBox
        SourceFilesGrid                     matlab.ui.container.GridLayout
        SourceFilesTextArea                 matlab.ui.control.TextArea
        SourceFilesListBox                  matlab.ui.control.ListBox

        SetupGrid                           matlab.ui.container.GridLayout
        CompilerDropDown                    matlab.ui.control.DropDown
        PackageNameEditField                matlab.ui.control.EditField
        PackageNameStatusLabel              matlab.ui.control.Label
        OutputFolderLabel                   matlab.ui.control.Label
        OutputFolderBrowseButton            matlab.ui.control.Button
        OutputFolderSelection               matlab.ui.control.Label
        OverwriteFilesCheckBox              matlab.ui.control.CheckBox

        CLinkageCheckBox                    matlab.ui.control.CheckBox
        BuildOptionsSection                 matlab.ui.container.internal.AccordionPanel
        BuildOptionsGrid                    matlab.ui.container.GridLayout
        DefinedMacrosGrid                   matlab.ui.container.GridLayout
        DefinedMacrosFirstAddButton         matlab.ui.control.Button
        DefinedMacrosCompilerFlagLabels     matlab.ui.control.Label
        DefinedMacrosIds                    matlab.ui.control.EditField
        DefinedMacrosEqualLabels            matlab.ui.control.Label
        DefinedMacrosValues                 matlab.ui.control.EditField
        DefinedMacrosAddButtons             matlab.ui.control.Image
        DefinedMacrosSubtractButtons        matlab.ui.control.Image
        UndefinedMacrosGrid                 matlab.ui.container.GridLayout
        UndefinedMacrosFirstAddButton       matlab.ui.control.Button
        UndefinedMacrosCompilerFlagLabels   matlab.ui.control.Label
        UndefinedMacrosIds                  matlab.ui.control.EditField
        UndefinedMacrosAddButtons           matlab.ui.control.Image
        UndefinedMacrosSubtractButtons      matlab.ui.control.Image
        AdditionalCompilerGrid              matlab.ui.container.GridLayout
        AdditionalCompilerFirstAddButton    matlab.ui.control.Button
        AdditionalCompilerLabel             matlab.ui.control.Label
        AdditionalCompilerValues            matlab.ui.control.EditField
        AdditionalCompilerAddButtons        matlab.ui.control.Image
        AdditionalCompilerSubtractButtons   matlab.ui.control.Image
        AdditionalLinkerGrid                matlab.ui.container.GridLayout
        AdditionalLinkerFirstAddButton      matlab.ui.control.Button
        AdditionalLinkerValues              matlab.ui.control.EditField
        AdditionalLinkerAddButtons          matlab.ui.control.Image
        AdditionalLinkerSubtractButtons     matlab.ui.control.Image

        DefineOptionsSection                matlab.ui.container.internal.AccordionPanel
        DefineOptionsGrid                   matlab.ui.container.GridLayout
        TreatObjPtrDropDown                 matlab.ui.control.DropDown
        TreatConstCharPtrDropDown           matlab.ui.control.DropDown
        ReturnCArraysDropDown               matlab.ui.control.DropDown        
        GenerateDocCheckBox                 matlab.ui.control.CheckBox
        DisplayResultsSection               matlab.ui.container.internal.AccordionPanel
        DisplayResultsGrid                  matlab.ui.container.GridLayout
        VerboseCheckBox                     matlab.ui.control.CheckBox
        SummaryCheckBox                     matlab.ui.control.CheckBox
        startingDir
        initialSelectedCompiler
        InterfaceHeaderFiles                (1,:) cell
        InterfaceSourceFiles                (1,:) cell
        IncludePath                         (1,:) cell
        Libraries                           (1,:) cell
        DLLFiles                            (1,:) cell
        SourceFiles                         (1,:) cell
        FileChooser                         clibgen.task.internal.FileChooser = clibgen.task.internal.DefaultFileChooser
        HelpImageSource (1, :) char = fullfile(matlabroot, 'toolbox', ...
            'matlab', 'external', 'interfaces', 'cpp', 'resources', 'help.png')
        RemoveImageSource (1, :) char = fullfile(matlabroot, 'toolbox', ...
            'matlab', 'external', 'interfaces', 'cpp', 'resources', 'remove.png');
        AddImageSource (1,:) char = fullfile(matlabroot, 'toolbox', ...
            'matlab', 'external', 'interfaces', 'cpp', 'resources', 'add.png');
        SubtractImageSource (1,:) char = fullfile(matlabroot, 'toolbox', ...
            'matlab', 'external', 'interfaces', 'cpp', 'resources', 'subtract.png');
    end
    properties (Constant, Access = private, Hidden)
        DelimiterCode = [', ...' newline];
        MicrosoftCppCompilersShortName = 'MSVCPP';
        LibraryStartPathTag = '<startpath>';
        DefinitionFileExistsStatus = 1;
        PackageIsLoadedStatus = 2;
        PackageNameInvalidStatus = 3;
        PackageNameEmpty = 4;
        NoLibraryDefinition = 5;
        ImageSizeInGrid = 20; % Ensures images are the same size in a grid
    end
    properties
        PlatformTab
        Summary
    end

    events
        % Live task subscribes to these event
        PlatformChanged
    end
    methods (Hidden)
        % Constructor for widget creation
        function platform = PlatformView(platformTab, fileChooser)
            if platformTab.Tag == "none"
                return;
            end
            if nargin == 2
                platform.FileChooser = fileChooser;
            end
            platform.PlatformTab = platformTab;
            platform.LayoutManager = uigridlayout(platform.PlatformTab);
            platform.LayoutManager.ColumnWidth = {'fit'};
            platform.LayoutManager.RowHeight = {'fit'};
            platform.setup;
        end
    end
    methods (Access = private,Hidden)
        function createComponents(platform)
            platform.Accordion = matlab.ui.container.internal.Accordion('Parent',platform.LayoutManager);
            createWidgets(platform);
        end
        function createWidgets(platform)
            createSelectFilesSection(platform);
            createSetupSection(platform);
            drawnow;
            createBuildOptionsSection(platform);
            createDefineOptionsSection(platform);
            createDisplayResultsSection(platform);
        end
        function createSetupSection(platform)
            [~,G] = createNewSection(platform,platform.getMsgText('SetupSectionLabel'), ...
                {'fit' 'fit' 'fit' 'fit'},{'fit' 'fit' 'fit' 'fit', 'fit'});
            platform.SetupGrid = G;

            compilerLabel = uilabel(G,'Tag','CompilerLabel');
            compilerLabel.Text = platform.getMsgText('SelectCompilerLabel');
            compilerLabel.Tooltip = platform.getMsgText('SelectCompilerLabelTooltip');

            compilerGrid = uigridlayout(G,'RowHeight',{platform.ImageSizeInGrid}, ...
                'ColumnWidth',{'fit' 'fit' 'fit'},'Padding',0);
            platform.setRowColumn(compilerGrid,1,[2 5]);

            platform.CompilerDropDown = uidropdown(compilerGrid);
            platform.CompilerDropDown.Tooltip = platform.getMsgText('SelectCompilerDropDownTooltip');            
            installedCompilers = mex.getCompilerConfigurations('C++','Installed');
            if ~isempty(installedCompilers)
                platform.CompilerDropDown.Items = {installedCompilers.Name};
                platform.CompilerDropDown.ItemsData = {installedCompilers.ShortName};
            else
                platform.CompilerDropDown.Items = {};
                platform.CompilerDropDown.ItemsData = {};
            end
            platform.CompilerDropDown.ValueChangedFcn = @platform.updateControls;

            compilerHelpImage = uiimage(compilerGrid);
            compilerHelpImage.HorizontalAlignment = 'left';
            compilerHelpImage.ImageSource = platform.HelpImageSource;
            compilerHelpImage.ImageClickedFcn = @platform.compilerHelpImageClicked;
            compilerHelpImage.Tooltip = platform.getMsgText('SelectCompilerHelpTooltip');
            matlab.ui.control.internal.specifyIconID(compilerHelpImage,'helpUI',16);

            packageNameLabel = uilabel(G,'Tag','PackageNameLabel');
            packageNameLabel.Text = platform.getMsgText('PackageNameLabel');
            packageNameLabel.Tooltip = platform.getMsgText('PackageNameLabelTooltip');

            platform.PackageNameEditField = uieditfield(G);
            platform.PackageNameEditField.Tooltip = platform.getMsgText('PackageNameEditFieldTooltip');
            platform.PackageNameEditField.ValueChangingFcn = @platform.PackageNameChanging;
            platform.PackageNameEditField.ValueChangedFcn = @platform.PackageNameChanged;
            platform.PackageNameEditField.Tag = 'valid';
            platform.PackageNameEditField.Placeholder = platform.getMsgText('RequiredPlaceholder');
            platform.PackageNameEditField.FontAngle = 'italic';

            platform.PackageNameStatusLabel = uilabel(G);
            platform.setRowColumn(platform.PackageNameStatusLabel,2,[3,5]);
            platform.PackageNameStatusLabel.Visible = 'off';

            outputFolderGrid = uigridlayout(G,'RowHeight',{'fit'}, ...
                'ColumnWidth',{'fit' 'fit' 'fit'},'Padding',0);
            platform.setRowColumn(outputFolderGrid,3,[1 5]);
            outputFolderLabel = uilabel(outputFolderGrid,'Tag','OutputFolder');
            outputFolderLabel.Text = platform.getMsgText('OutputFolderLabel');
            outputFolderLabel.Tooltip = platform.getMsgText('OutputFolderLabelTooltip');
            platform.OutputFolderBrowseButton = uibutton(outputFolderGrid,'Text',platform.getMsgText('SelectFileOrPathBtnBrowse'),'Tag','OutputFolderCustom');
            platform.OutputFolderBrowseButton.HorizontalAlignment = 'center';
            platform.OutputFolderBrowseButton.ButtonPushedFcn = @platform.selectOutputFolder;
            platform.OutputFolderSelection = uilabel(outputFolderGrid,'Tag','OutputFolderCustom');
            platform.OutputFolderSelection.Text = pwd;
            platform.OutputFolderSelection.Tooltip = platform.OutputFolderSelection.Text;

            platform.OverwriteFilesCheckBox = uicheckbox(G);
            platform.OverwriteFilesCheckBox.Text = platform.getMsgText('OverwriteFilesCheckBox');
            platform.OverwriteFilesCheckBox.Tooltip = platform.getMsgText('OverwriteFilesCheckBoxTooltip','');
            platform.OverwriteFilesCheckBox.ValueChangedFcn = @platform.updateControls;
            platform.setRowColumn(platform.OverwriteFilesCheckBox,4,[1 2]);
        end
        function createSelectFilesSection(platform)
            % Select files grid is 4 rows by 4 columns with column 2 for
            % horizontal spacing (5 pixels) between the list boxes
            [~,G] = createNewSection(platform,platform.getMsgText('SelectFilesSectionLabel'), ...
                {'fit' 'fit' 'fit' 'fit'},{'fit' 5 'fit' 'fit'});
            platform.SelectFilesGrid = G;

            % library type and radio buttons
            libraryTypeGrid = uigridlayout(G,'RowHeight',{30}, ...
                'ColumnWidth',{'fit' 670},'Padding',0);
            platform.setRowColumn(libraryTypeGrid,1,[1 4]);
            platform.LibraryTypeLabel = uilabel(libraryTypeGrid, ...
                'Text',platform.getMsgText('LibraryTypeLabel'), ...
                'Tooltip',platform.getMsgText('LibraryTypeLabelTooltip'));

            % library type buttons
            platform.LibraryTypeButtonGroup = uibuttongroup(libraryTypeGrid, ...
                'Tag','LibraryType','SelectionChangedFcn',@platform.updateControls);
            platform.LibraryTypeButtonGroup.BorderType = 'none';

            uiradiobutton(platform.LibraryTypeButtonGroup, ...
                'Text',platform.getMsgText('HeaderAndLibraryLabel'), ...
                'Tooltip',platform.getMsgText('HeaderAndLibraryLabelTooltip'), ...
                'Position',[20 0 320 30],'Tag','HeaderAndLibrary');
            uiradiobutton(platform.LibraryTypeButtonGroup, ...
                'Text',platform.getMsgText('HeaderOnlyLabel'), ...
                'Tooltip',platform.getMsgText('HeaderOnlyLabelTooltip'), ...
                'Position',[250 0 90 30],'Tag','HeaderOnly');
            uiradiobutton(platform.LibraryTypeButtonGroup, ...
                'Text',platform.getMsgText('HeaderAndSourceLabel'), ...
                'Tooltip',platform.getMsgText('HeaderAndSourceLabelTooltip'), ...
                'Position',[345 0 200 30],'Tag','HeaderAndSource');
            uiradiobutton(platform.LibraryTypeButtonGroup, ...
                'Text',platform.getMsgText('CustomLabel'), ...
                'Tooltip',platform.getMsgText('CustomLabelTooltip'), ...
                'Position',[520 0 150 30],'Tag','Custom');

            % library start path
            libraryStartPathGrid = uigridlayout(G,'RowHeight',{platform.ImageSizeInGrid}, ...
                'ColumnWidth',{'fit' 'fit' platform.ImageSizeInGrid 'fit'},'Padding',0);
            platform.setRowColumn(libraryStartPathGrid,2,[1 4]);

            platform.LibraryStartPathLabel = uilabel(libraryStartPathGrid,'Text',platform.getMsgText('LibraryStartPathLabel'));
            platform.LibraryStartPathLabel.Tooltip = platform.getMsgText('LibraryStartPathLabelTooltip', platform.LibraryStartPathTag);

            platform.LibraryStartPathBrowseButton = uibutton(libraryStartPathGrid,'Text',platform.getMsgText('SelectFileOrPathBtnBrowse'),'Tag','LibraryStartPath');
            platform.LibraryStartPathBrowseButton.HorizontalAlignment = 'left';
            platform.LibraryStartPathBrowseButton.ButtonPushedFcn = @platform.selectLibraryStartPath;

            platform.LibraryStartPathRemoveButton = uiimage(libraryStartPathGrid,...
                "ImageSource",platform.RemoveImageSource,...
                "ImageClickedFcn",@platform.removeFileOrPath,'Tag','RemoveLibraryStartPath', ...
                'HorizontalAlignment','right','Enable','off');
            matlab.ui.control.internal.specifyIconID(platform.LibraryStartPathRemoveButton,'deleteBorderlessUI',16);

            platform.LibraryStartPathSelection = uilabel(libraryStartPathGrid,'Tag','LibraryStartPath');
            platform.LibraryStartPathSelection.Tooltip = platform.getMsgText('LibraryStartPathTextTooltip');
            platform.LibraryStartPathSelection.Text = platform.getMsgText('SelectFileOrPathOptional');
            platform.LibraryStartPathSelection.FontAngle = "italic";

            % interface files ListBox
            in.parent = G;
            in.tag = 'InterfaceFiles';
            headerFileExtensionsMsg = platform.getMsgText('HeaderFileExtensions');
            interfaceGenerationFileLabel = platform.getMsgText('HeaderFilesLabel');
            if strcmp(platform.LibraryTypeButtonGroup.SelectedObject.Tag,'Custom')
                interfaceGenerationFileLabel = platform.getMsgText('HeaderAndSourceFilesLabel');
            end
            in.title = platform.getMsgText('InterfaceGenerationFilesLabel',interfaceGenerationFileLabel,headerFileExtensionsMsg);
            in.tooltip = platform.getMsgText('InterfaceGenerationFilesLabelTooltip',headerFileExtensionsMsg);
            out = createFilesGrid(platform,in);
            platform.InterfaceFilesGrid = out.grid;
            platform.InterfaceFilesTextArea = out.textArea;
            platform.addPlaceHolderText(platform.InterfaceFilesTextArea,platform.getMsgText('SelectFileOrPathRequiredClick'));
            platform.setRowColumn(out.grid,3,1);

            % include path grid
            in.parent = G;
            in.tag = 'IncludePath';
            in.title = platform.getMsgText('IncludePathLabel');
            in.tooltip = platform.getMsgText('IncludePathLabelTooltip');
            out = createFilesGrid(platform,in);
            platform.IncludePathGrid = out.grid;
            platform.IncludePathTextArea = out.textArea;
            platform.addPlaceHolderText(platform.IncludePathTextArea,platform.getMsgText('SelectFileOrPathRequiredClick'));
            tag = 'IncludePathNotRequiredCheckBox';
            platform.IncludePathNotRequiredCheckBox = uicheckbox(out.grid, ...
                'Text',platform.getMsgText(tag), ...
                'Tooltip',platform.getMsgText([tag 'Tooltip']), ...
                'Tag',tag, ...
                'ValueChangedFcn',@platform.updateControls);
            platform.setRowColumn(out.grid,3,3);

            % libraries grid
            in.parent = G;
            in.tag = 'Libraries';
            in.title = platform.getMsgText('LibrariesLabel','');
            in.tooltip = platform.getMsgText('LibrariesLabelTooltip','');
            out = createFilesGrid(platform,in);
            platform.LibrariesGrid = out.grid;
            platform.LibrariesTextArea = out.textArea;
            platform.addPlaceHolderText(platform.LibrariesTextArea,platform.getMsgText('SelectFileOrPathRequiredClick'));
            platform.setRowColumn(out.grid,4,1);

            drawnow;
            % source files grid
            in.parent = G;
            in.tag = 'SourceFiles';
            sourceFileExtensionsMsg = platform.getMsgText('SourceFileExtensions');
            in.title = platform.getMsgText('SourceFilesLabel',sourceFileExtensionsMsg);
            in.tooltip = platform.getMsgText('SourceFilesLabelTooltip');
            out = createFilesGrid(platform,in);
            platform.SourceFilesGrid = out.grid;
            platform.SourceFilesTextArea = out.textArea;
            platform.addPlaceHolderText(platform.SourceFilesTextArea,platform.getMsgText('SelectFileOrPathOptionalClick'));
            platform.setRowColumn(out.grid,4,3);
            platform.SourceFilesGrid.Parent = [];
        end
        function createBuildOptionsSection(platform)
            [S,G] = createNewSection(platform, ...
                platform.getMsgText('AdvancedOptionsSectionLabel'), ...
                {'fit' 'fit' 'fit'},{'fit' platform.ImageSizeInGrid 'fit'});
            platform.BuildOptionsSection = S;
            platform.BuildOptionsGrid = G;
            platform.BuildOptionsSection.collapse;
            tag = 'CLinkageCheckBox';
            platform.CLinkageCheckBox = uicheckbox(platform.BuildOptionsGrid,...
                'Text',platform.getMsgText(tag,'.h'), ...
                'Tooltip',platform.getMsgText([tag 'Tooltip'],'.h'),'Tag',tag);
            platform.setRowColumn(platform.CLinkageCheckBox,1,1);
            % Define/Undefine macros
            [platform.DefinedMacrosGrid, platform.DefinedMacrosFirstAddButton] = platform.createMacrosGrid(G,'DefinedMacros');
            platform.setRowColumn(platform.DefinedMacrosGrid.Parent,2,1);
            platform.DefinedMacrosFirstAddButton.ButtonPushedFcn = @platform.addDefinedMacrosRow;
            [platform.UndefinedMacrosGrid, platform.UndefinedMacrosFirstAddButton] = platform.createMacrosGrid(G,'UndefinedMacros');
            platform.setRowColumn(platform.UndefinedMacrosGrid.Parent,2,3);
            platform.UndefinedMacrosFirstAddButton.ButtonPushedFcn = @platform.addUndefinedMacrosRow;
            % Additional flags
            [platform.AdditionalCompilerGrid, platform.AdditionalCompilerFirstAddButton] = platform.createAdditionalFlagsGrid(G,'AdditionalCompiler');
            platform.setRowColumn(platform.AdditionalCompilerGrid.Parent,3,1);
            platform.AdditionalCompilerFirstAddButton.ButtonPushedFcn = @platform.addAdditionalCompilerFlagsRow;
            [platform.AdditionalLinkerGrid, platform.AdditionalLinkerFirstAddButton] = platform.createAdditionalFlagsGrid(G,'AdditionalLinker');
            platform.setRowColumn(platform.AdditionalLinkerGrid.Parent,3,3);
            platform.AdditionalLinkerFirstAddButton.ButtonPushedFcn = @platform.addAdditionalLinkerFlagsRow;            
        end
        function createDefineOptionsSection(platform)
            [S,G] = createNewSection(platform, ...
                platform.getMsgText('DefineOptionsSectionLabel'), ...
                {'fit' 'fit'}, {'fit' 'fit' 'fit' 'fit'});
            platform.DefineOptionsSection = S;
            platform.DefineOptionsGrid = G;
            platform.DefineOptionsSection.collapse;

            tag = 'TreatObjectPointer';
            uilabel(G,'Text',platform.getMsgText([tag 'Label']), ...
                'Tooltip',platform.getMsgText([tag 'LabelTooltip']));
            platform.TreatObjPtrDropDown = uidropdown(G, ...
                'Items',{platform.getMsgText([tag 'Undefined']), platform.getMsgText([tag 'Scalar'])}, ...
                'ItemsData',{'undefined','scalar'},'Tag',tag);
            platform.TreatObjPtrDropDown.Tooltip = platform.getMsgText('TreatObjectPointerUndefinedTooltip');
            platform.TreatObjPtrDropDown.ValueChangedFcn = @platform.updateObjectPointerTooltip;

            tag = 'TreatConstCharPointer';
            uilabel(G,'Text',platform.getMsgText([tag 'Label']), ...
                'Tooltip',platform.getMsgText([tag 'LabelTooltip']));
            platform.TreatConstCharPtrDropDown = uidropdown(G, ...
                'Items',{platform.getMsgText([tag 'Undefined']), platform.getMsgText([tag 'NullTerminated'])}, ...
                'ItemsData',{'undefined','nullTerminated'},'Tag',tag);
            platform.TreatConstCharPtrDropDown.Tooltip = platform.getMsgText('TreatConstCharPointerUndefinedTooltip');
            platform.TreatConstCharPtrDropDown.ValueChangedFcn = @platform.updateConstCharacterPointerTooltip;

            tag = 'ReturnCArrays';
            uilabel(G,'Text',platform.getMsgText([tag 'Label']), ...
                'Tooltip',platform.getMsgText([tag 'LabelTooltip']));
            platform.ReturnCArraysDropDown = uidropdown(G, ...
                'Items',{platform.getMsgText([tag 'ClibArray']), platform.getMsgText([tag 'MATLABArray'])}, ...
                'ItemsData',{'ClibArray','MATLABArray'},'Tag',tag);
            platform.ReturnCArraysDropDown.Tooltip = platform.getMsgText('ReturnCArraysClibArrayTooltip');
            platform.ReturnCArraysDropDown.ValueChangedFcn = @platform.updateReturnCArraysTooltip;

            tag = 'GenerateDocCheckBox';
            platform.GenerateDocCheckBox = uicheckbox(G,...
                'Text',platform.getMsgText(tag), ...
                'Tooltip',platform.getMsgText([tag 'Tooltip']),'Tag',tag);
            platform.setRowColumn(platform.GenerateDocCheckBox,2,[3 4]);       
        end
        function createDisplayResultsSection(platform)
            [S,G] = createNewSection(platform, ...
                platform.getMsgText('DisplayResultsSectionLabel'),{'fit'},{'fit' 'fit'});
            platform.DisplayResultsSection = S;
            platform.DisplayResultsGrid = G;
            platform.DisplayResultsSection.collapse;
            
            platform.VerboseCheckBox = uicheckbox(G, ...
                'Text',platform.getMsgText('VerboseCheckBox'), ...
                'Tooltip',platform.getMsgText('VerboseCheckBoxTooltip'));
            platform.VerboseCheckBox.ValueChangedFcn = @platform.updateControls;

            platform.SummaryCheckBox = uicheckbox(G, ...
                'Text',platform.getMsgText('SummaryCheckBox'), ...
                'Tooltip',platform.getMsgText('SummaryCheckBoxTooltip'));
            platform.SummaryCheckBox.ValueChangedFcn = @platform.updateControls;
        end
        function [S,G] = createNewSection(platform,textLabel,r,c)
            S = matlab.ui.container.internal.AccordionPanel('Parent',platform.Accordion);
            S.Title = textLabel;
            G = uigridlayout(S,'RowHeight',r,'ColumnWidth',c,'Padding',10);
        end
        function out = createFilesGrid(platform, in)
            out.grid = uigridlayout(in.parent,...
                'RowHeight',{'fit' 30}, 'ColumnWidth',{'fit'},'Padding',0);
            titleGrid = uigridlayout(out.grid,'RowHeight',{platform.ImageSizeInGrid}, ...
                'ColumnWidth',{250 'fit' platform.ImageSizeInGrid},'Padding',0);
            uilabel(titleGrid, ...
                'Text',in.title, ...
                'Tooltip',in.tooltip, ...
                'Tag',in.tag, ...
                'HorizontalAlignment','left');
            uibutton(titleGrid,...  
                'Text',platform.getMsgText('SelectFileOrPathBtnBrowse'), ...
                'ButtonPushedFcn',@platform.selectFileOrPath,'Tag',in.tag, ...
                'HorizontalAlignment','right');
            removeImg = uiimage(titleGrid,...
                "ImageSource",platform.RemoveImageSource,...
                "ImageClickedFcn",@platform.removeFileOrPath,'Tag',['Remove' in.tag], ...
                'HorizontalAlignment','right','Enable','off');
            matlab.ui.control.internal.specifyIconID(removeImg,'deleteBorderlessUI',16);
            out.textArea = uitextarea(out.grid,'Tag',in.tag,'Editable','off');
        end
        function [MG,addButton] = createMacrosGrid(platform,parent,tag)
            G = uigridlayout(parent,'RowHeight',{'fit' 'fit'}, ...
                'ColumnWidth',{'fit'},'Padding',0);
            uilabel(G,'Text',platform.getMsgText([tag 'Label']), ...
                'Tooltip',platform.getMsgText([tag 'LabelTooltip']));

            if strcmp(tag,'DefinedMacros')
                columns = {'fit' 'fit' 'fit' 'fit' 16 16};
            else
                columns = {'fit' 'fit' 16 16};
            end
            MG = uigridlayout(G,'RowHeight',{platform.ImageSizeInGrid}, ...
                'ColumnWidth',columns,'Padding',0);

            addButton = uibutton(MG,'Text',platform.getMsgText('ButtonAdd'), ...
                'Tag',tag);
            platform.setRowColumn(addButton,1,1);
        end
        function addDefinedMacrosRow(platform,src,~)
            if strcmp(src.Type,'uiimage')
                nextRow = numel(platform.DefinedMacrosAddButtons) + 1;
                k = src.UserData;
            else % first add button
                nextRow = 1;
                k = 0;
                platform.DefinedMacrosFirstAddButton.Parent = [];
            end
            platform.DefinedMacrosCompilerFlagLabels(nextRow) = uilabel(platform.DefinedMacrosGrid,'Text','-D');
            platform.setRowColumn(platform.DefinedMacrosCompilerFlagLabels(nextRow),nextRow,1);
            platform.DefinedMacrosGrid.RowHeight{end} = platform.ImageSizeInGrid;
            platform.DefinedMacrosIds(nextRow) = uieditfield(platform.DefinedMacrosGrid, ...
                'ValueChangingFcn',@platform.MacroNameChanging, ...
                'ValueChangedFcn',@platform.MacroNameChanged, ...
                'Tag','identifier', ...
                'Placeholder', platform.getMsgText('MacroIdentifierPlaceholder'),'FontAngle','italic');
            platform.DefinedMacrosIds(nextRow).UserData.status = 'valid';
            platform.setRowColumn(platform.DefinedMacrosIds(nextRow),nextRow,2);
            platform.DefinedMacrosEqualLabels(nextRow) = uilabel(platform.DefinedMacrosGrid,'Text','=');
            platform.setRowColumn(platform.DefinedMacrosEqualLabels(nextRow),nextRow,3);
            platform.DefinedMacrosValues(nextRow) = uieditfield(platform.DefinedMacrosGrid, ...
                'ValueChangingFcn',@platform.MacroNameChanging, ...
                'ValueChangedFcn',@platform.MacroNameChanged, ...
                'Tag','value', ...
                'Placeholder', platform.getMsgText('MacroFlagValuePlaceholder'),'FontAngle','italic');
            platform.DefinedMacrosValues(nextRow).UserData.status = 'valid';
            platform.setRowColumn(platform.DefinedMacrosValues(nextRow),nextRow,4);
            platform.DefinedMacrosSubtractButtons(nextRow) = uiimage(platform.DefinedMacrosGrid, ...
                'ImageSource',platform.SubtractImageSource, ...
                'ImageClickedFcn',@platform.subtractDefinedMacrosRow,'UserData',nextRow);
            matlab.ui.control.internal.specifyIconID(platform.DefinedMacrosSubtractButtons(nextRow),'minusUI',16);
            platform.setRowColumn(platform.DefinedMacrosSubtractButtons(nextRow),nextRow,5);
            platform.DefinedMacrosAddButtons(nextRow) = uiimage(platform.DefinedMacrosGrid, ...
                'ImageSource',platform.AddImageSource, ...
                'ImageClickedFcn',@platform.addDefinedMacrosRow,'UserData',nextRow);
            matlab.ui.control.internal.specifyIconID(platform.DefinedMacrosAddButtons(nextRow),'plusUI',16);
            platform.setRowColumn(platform.DefinedMacrosAddButtons(nextRow),nextRow,6);

            % shift data downwards from row 'k' to nextRow
            for idx = nextRow:-1:k+2
                platform.DefinedMacrosIds(idx).Value = platform.DefinedMacrosIds(idx-1).Value;
                platform.DefinedMacrosValues(idx).Value = platform.DefinedMacrosValues(idx-1).Value;
            end
            platform.DefinedMacrosIds(k+1).Value = '';
            platform.DefinedMacrosValues(k+1).Value = '';
        end
        function subtractDefinedMacrosRow(platform,src,~)
            k = src.UserData;
            delete(platform.DefinedMacrosCompilerFlagLabels(k));
            platform.DefinedMacrosCompilerFlagLabels(k) = [];
            delete(platform.DefinedMacrosIds(k));
            platform.DefinedMacrosIds(k) = [];
            delete(platform.DefinedMacrosEqualLabels(k));
            platform.DefinedMacrosEqualLabels(k) = [];
            delete(platform.DefinedMacrosValues(k));
            platform.DefinedMacrosValues(k) = [];
            delete(platform.DefinedMacrosAddButtons(k));
            platform.DefinedMacrosAddButtons(k) = [];
            delete(platform.DefinedMacrosSubtractButtons(k));
            platform.DefinedMacrosSubtractButtons(k) = [];

            for idx = k:numel(platform.DefinedMacrosSubtractButtons)
                platform.DefinedMacrosCompilerFlagLabels(idx).Layout.Row = idx;
                platform.DefinedMacrosIds(idx).Layout.Row = idx;
                platform.DefinedMacrosEqualLabels(idx).Layout.Row = idx;
                platform.DefinedMacrosValues(idx).Layout.Row = idx;
                platform.DefinedMacrosAddButtons(idx).Layout.Row = idx;
                platform.DefinedMacrosAddButtons(idx).UserData = idx;
                platform.DefinedMacrosSubtractButtons(idx).Layout.Row = idx;
                platform.DefinedMacrosSubtractButtons(idx).UserData = idx;
            end
            platform.DefinedMacrosGrid.RowHeight(end) = '';
            if numel(platform.DefinedMacrosSubtractButtons) == 0
                platform.DefinedMacrosFirstAddButton.Parent = platform.DefinedMacrosGrid;
                platform.setRowColumn(platform.DefinedMacrosFirstAddButton,1,1);
            end
            notify(platform,'PlatformChanged');
        end
        function addUndefinedMacrosRow(platform,src,~)
            if strcmp(src.Type,'uiimage')
                nextRow = numel(platform.UndefinedMacrosAddButtons) + 1;
                k = src.UserData;
            else % first add button
                nextRow = 1;
                k = 0;
                platform.UndefinedMacrosFirstAddButton.Parent = [];
            end
            platform.UndefinedMacrosCompilerFlagLabels(nextRow) = uilabel(platform.UndefinedMacrosGrid,'Text','-U');
            platform.setRowColumn(platform.UndefinedMacrosCompilerFlagLabels(nextRow),nextRow,1);
            platform.UndefinedMacrosGrid.RowHeight{end} = platform.ImageSizeInGrid;
            platform.UndefinedMacrosIds(nextRow) = uieditfield(platform.UndefinedMacrosGrid, ...
                'ValueChangingFcn',@platform.MacroNameChanging, ...
                'ValueChangedFcn',@platform.MacroNameChanged, ...
                'Tag','identifier', ...
                'Placeholder', platform.getMsgText('MacroIdentifierPlaceholder'),'FontAngle','italic');
            platform.UndefinedMacrosIds(nextRow).UserData.status = 'valid';
            platform.setRowColumn(platform.UndefinedMacrosIds(nextRow),nextRow,2);
            platform.UndefinedMacrosSubtractButtons(nextRow) = uiimage(platform.UndefinedMacrosGrid, ...
                'ImageSource',platform.SubtractImageSource, ...
                'ImageClickedFcn',@platform.subtractUndefinedMacrosRow,'UserData',nextRow);
            matlab.ui.control.internal.specifyIconID(platform.UndefinedMacrosSubtractButtons(nextRow),'minusUI',16);
            platform.setRowColumn(platform.UndefinedMacrosSubtractButtons(nextRow),nextRow,3);
            platform.UndefinedMacrosAddButtons(nextRow) = uiimage(platform.UndefinedMacrosGrid, ...
                'ImageSource',platform.AddImageSource, ...
                'ImageClickedFcn',@platform.addUndefinedMacrosRow,'UserData',nextRow);
            matlab.ui.control.internal.specifyIconID(platform.UndefinedMacrosAddButtons(nextRow),'plusUI',16);
            platform.setRowColumn(platform.UndefinedMacrosAddButtons(nextRow),nextRow,4);

            % shift data downwards from row 'k' to nextRow
            for idx = nextRow:-1:k+2
                platform.UndefinedMacrosIds(idx).Value = platform.UndefinedMacrosIds(idx-1).Value;
            end
            platform.UndefinedMacrosIds(k+1).Value = '';
        end
        function subtractUndefinedMacrosRow(platform,src,~)
            k = src.UserData;
            delete(platform.UndefinedMacrosCompilerFlagLabels(k));
            platform.UndefinedMacrosCompilerFlagLabels(k) = [];
            delete(platform.UndefinedMacrosIds(k));
            platform.UndefinedMacrosIds(k) = [];
            delete(platform.UndefinedMacrosAddButtons(k));
            platform.UndefinedMacrosAddButtons(k) = [];
            delete(platform.UndefinedMacrosSubtractButtons(k));
            platform.UndefinedMacrosSubtractButtons(k) = [];

            for idx = k:numel(platform.UndefinedMacrosSubtractButtons)
                platform.UndefinedMacrosCompilerFlagLabels(idx).Layout.Row = idx;
                platform.UndefinedMacrosIds(idx).Layout.Row = idx;
                platform.UndefinedMacrosAddButtons(idx).Layout.Row = idx;
                platform.UndefinedMacrosAddButtons(idx).UserData = idx;
                platform.UndefinedMacrosSubtractButtons(idx).Layout.Row = idx;
                platform.UndefinedMacrosSubtractButtons(idx).UserData = idx;
            end
            platform.UndefinedMacrosGrid.RowHeight(end) = '';
            if numel(platform.UndefinedMacrosSubtractButtons) == 0
                platform.UndefinedMacrosFirstAddButton.Parent = platform.UndefinedMacrosGrid;
                platform.setRowColumn(platform.UndefinedMacrosFirstAddButton,1,1);
            end
            notify(platform,'PlatformChanged');
        end
        function [MG,addButton] = createAdditionalFlagsGrid(platform,parent,tag)
            G = uigridlayout(parent,'RowHeight',{'fit' 'fit'}, ...
                'ColumnWidth',{'fit'},'Padding',0);
            uilabel(G,'Text',platform.getMsgText([tag 'Label']), ...
                'Tooltip',platform.getMsgText([tag 'LabelTooltip']));

            columns = {'fit' 16 16};
            MG = uigridlayout(G,'RowHeight',{platform.ImageSizeInGrid}, ...
                'ColumnWidth',columns,'Padding',0);

            addButton = uibutton(MG,'Text',platform.getMsgText('ButtonAdd'), ...
                'Tag',tag);
            platform.setRowColumn(addButton,1,1);
        end
        function addAdditionalCompilerFlagsRow(platform,src,~)
            if strcmp(src.Type,'uiimage')
                nextRow = numel(platform.AdditionalCompilerAddButtons) + 1;
                k = src.UserData;
            else % first add button
                nextRow = 1;
                k = 0;
                platform.AdditionalCompilerFirstAddButton.Parent = [];
            end
            platform.AdditionalCompilerValues(nextRow) = uieditfield(platform.AdditionalCompilerGrid, ...
                'ValueChangingFcn',@platform.MacroNameChanging, ...
                'ValueChangedFcn',@platform.MacroNameChanged, ...
                'Tag','value', ...
                'Placeholder', platform.getMsgText('MacroFlagValuePlaceholder'),'FontAngle','italic');
            platform.AdditionalCompilerValues(nextRow).UserData.status = 'valid';
            platform.setRowColumn(platform.AdditionalCompilerValues(nextRow),nextRow,1);
            platform.AdditionalCompilerGrid.RowHeight{end} = platform.ImageSizeInGrid;
            platform.AdditionalCompilerSubtractButtons(nextRow) = uiimage(platform.AdditionalCompilerGrid, ...
                'ImageSource',platform.SubtractImageSource, ...
                'ImageClickedFcn',@platform.subtractAdditionalCompilerFlagsRow,'UserData',nextRow);
            matlab.ui.control.internal.specifyIconID(platform.AdditionalCompilerSubtractButtons(nextRow),'minusUI',16);
            platform.setRowColumn(platform.AdditionalCompilerSubtractButtons(nextRow),nextRow,2);
            platform.AdditionalCompilerAddButtons(nextRow) = uiimage(platform.AdditionalCompilerGrid, ...
                'ImageSource',platform.AddImageSource, ...
                'ImageClickedFcn',@platform.addAdditionalCompilerFlagsRow,'UserData',nextRow);
            matlab.ui.control.internal.specifyIconID(platform.AdditionalCompilerAddButtons(nextRow),'plusUI',16);
            platform.setRowColumn(platform.AdditionalCompilerAddButtons(nextRow),nextRow,3);

            % shift data downwards from row 'k' to nextRow
            for idx = nextRow:-1:k+2
                platform.AdditionalCompilerValues(idx).Value = platform.AdditionalCompilerValues(idx-1).Value;
            end
            platform.AdditionalCompilerValues(k+1).Value = '';
        end
        function addAdditionalLinkerFlagsRow(platform,src,~)
            if strcmp(src.Type,'uiimage')
                nextRow = numel(platform.AdditionalLinkerAddButtons) + 1;
                k = src.UserData;
            else % first add button
                nextRow = 1;
                k = 0;
                platform.AdditionalLinkerFirstAddButton.Parent = [];
            end
            platform.AdditionalLinkerValues(nextRow) = uieditfield(platform.AdditionalLinkerGrid, ...
                'ValueChangingFcn',@platform.MacroNameChanging, ...
                'ValueChangedFcn',@platform.MacroNameChanged, ...
                'Tag','value', ...
                'Placeholder', platform.getMsgText('MacroFlagValuePlaceholder'),'FontAngle','italic');
            platform.AdditionalLinkerValues(nextRow).UserData.status = 'valid';
            platform.setRowColumn(platform.AdditionalLinkerValues(nextRow),nextRow,1);
            platform.AdditionalLinkerGrid.RowHeight{end} = platform.ImageSizeInGrid;
            platform.AdditionalLinkerSubtractButtons(nextRow) = uiimage(platform.AdditionalLinkerGrid, ...
                'ImageSource',platform.SubtractImageSource, ...
                'ImageClickedFcn',@platform.subtractAdditionalLinkerFlagsRow,'UserData',nextRow);
            matlab.ui.control.internal.specifyIconID(platform.AdditionalLinkerSubtractButtons(nextRow),'minusUI',16);
            platform.setRowColumn(platform.AdditionalLinkerSubtractButtons(nextRow),nextRow,2);
            platform.AdditionalLinkerAddButtons(nextRow) = uiimage(platform.AdditionalLinkerGrid, ...
                'ImageSource',platform.AddImageSource, ...
                'ImageClickedFcn',@platform.addAdditionalLinkerFlagsRow,'UserData',nextRow);
            matlab.ui.control.internal.specifyIconID(platform.AdditionalLinkerAddButtons(nextRow),'plusUI',16);
            platform.setRowColumn(platform.AdditionalLinkerAddButtons(nextRow),nextRow,3);

            % shift data downwards from row 'k' to nextRow
            for idx = nextRow:-1:k+2
                platform.AdditionalLinkerValues(idx).Value = platform.AdditionalLinkerValues(idx-1).Value;
            end
            platform.AdditionalLinkerValues(k+1).Value = '';
        end
        function subtractAdditionalCompilerFlagsRow(platform,src,~)
            k = src.UserData;
            delete(platform.AdditionalCompilerValues(k));
            platform.AdditionalCompilerValues(k) = [];
            delete(platform.AdditionalCompilerAddButtons(k));
            platform.AdditionalCompilerAddButtons(k) = [];
            delete(platform.AdditionalCompilerSubtractButtons(k));
            platform.AdditionalCompilerSubtractButtons(k) = [];

            for idx = k:numel(platform.AdditionalCompilerSubtractButtons)
                platform.AdditionalCompilerValues(idx).Layout.Row = idx;
                platform.AdditionalCompilerAddButtons(idx).Layout.Row = idx;
                platform.AdditionalCompilerAddButtons(idx).UserData = idx;
                platform.AdditionalCompilerSubtractButtons(idx).Layout.Row = idx;
                platform.AdditionalCompilerSubtractButtons(idx).UserData = idx;
            end
            platform.AdditionalCompilerGrid.RowHeight(end) = '';
            if numel(platform.AdditionalCompilerSubtractButtons) == 0
                platform.AdditionalCompilerFirstAddButton.Parent = platform.AdditionalCompilerGrid;
                platform.setRowColumn(platform.AdditionalCompilerFirstAddButton,1,1);
            end
            notify(platform,'PlatformChanged');
        end
        function subtractAdditionalLinkerFlagsRow(platform,src,~)
            k = src.UserData;
            delete(platform.AdditionalLinkerValues(k));
            platform.AdditionalLinkerValues(k) = [];
            delete(platform.AdditionalLinkerAddButtons(k));
            platform.AdditionalLinkerAddButtons(k) = [];
            delete(platform.AdditionalLinkerSubtractButtons(k));
            platform.AdditionalLinkerSubtractButtons(k) = [];

            for idx = k:numel(platform.AdditionalLinkerSubtractButtons)
                platform.AdditionalLinkerValues(idx).Layout.Row = idx;
                platform.AdditionalLinkerAddButtons(idx).Layout.Row = idx;
                platform.AdditionalLinkerAddButtons(idx).UserData = idx;
                platform.AdditionalLinkerSubtractButtons(idx).Layout.Row = idx;
                platform.AdditionalLinkerSubtractButtons(idx).UserData = idx;
            end
            platform.AdditionalLinkerGrid.RowHeight(end) = '';
            if numel(platform.AdditionalLinkerSubtractButtons) == 0
                platform.AdditionalLinkerFirstAddButton.Parent = platform.AdditionalLinkerGrid;
                platform.setRowColumn(platform.AdditionalLinkerFirstAddButton,1,1);
            end
            notify(platform,'PlatformChanged');
        end
        function PackageNameChanging(platform,~,evt)
            str = evt.Value;
            outputFolder = platform.OutputFolderSelection.Text;
            interfaceDir = fullfile(outputFolder,str);
            status = 0;
            if isempty(str)
                status = platform.PackageNameEmpty;
            elseif ~strcmp(str,matlab.lang.makeValidName(str))
                status = platform.PackageNameInvalidStatus;
            elseif isfile(interfaceDir)
                status = platform.DefinitionFileExistsStatus;
            elseif clibgen.internal.clibpackageisLoaded(string(str))
                status = platform.PackageIsLoadedStatus;
            end

            if status == 0
                platform.PackageNameEditField.Tag = 'valid';
                platform.PackageNameStatusLabel.Visible = 'off';
            else
                platform.PackageNameEditField.Tag = 'invalid';
                if status == platform.PackageNameEmpty
                    platform.showPackageNameStatus(platform.getMsgText('PackageNameEmptyLabel'));
                elseif status == platform.PackageNameInvalidStatus
                    platform.showPackageNameStatus(platform.getMsgText('InvalidPackageNameLabel'));
                elseif status == platform.DefinitionFileExistsStatus
                    platform.showPackageNameStatus(platform.getMsgText('FileWithPackageNameExistsLabel'));
                elseif status == platform.PackageIsLoadedStatus
                    platform.showPackageNameStatus(platform.getMsgText('PackageNameInUseLabel',platform.PackageNameEditField.Value));
                end
            end

            % show placeholder text in italics if name is empty
            if isempty(str)
                platform.PackageNameEditField.FontAngle = 'italic';
            else
                platform.PackageNameEditField.FontAngle = 'normal';
            end
        end
        function PackageNameChanged(platform,~,~)
            if strcmp(platform.PackageNameEditField.Tag, 'invalid')
                platform.PackageNameEditField.Value = '';
                platform.PackageNameEditField.Tag = 'valid';
            end
            platform.PackageNameStatusLabel.Visible = 'off';
            platform.updateControls;
            notify(platform,'PlatformChanged');
        end
        function status = showDefinitionFileOrPackageNameExists(platform,showstate)
            arguments
                platform (1,1) clibgen.task.internal.PlatformView
                showstate (1,1) logical = false
            end
            mFileName = ['define' platform.PackageNameEditField.Value '.m'];
            outputFolder = platform.OutputFolderSelection.Text;

            mFileExists = isfile(fullfile(outputFolder,mFileName));

            if mFileExists
                libDefExists = evalin('base','exist(''libraryDefinitionFromTask'',''var'')');
                % If library definition file exists but library definition
                % variable does not exist, return NoLibraryDefinition
                if ~libDefExists
                    status = platform.NoLibraryDefinition;
                    return;
                end
                packageName = platform.PackageNameEditField.Value;
                if isempty(packageName)
                    definitionFile = '';                
                else
                    definitionFile = [' ''define' packageName '.m'''];
                end
                platform.OverwriteFilesCheckBox.Tooltip = ...
                    platform.getMsgText('OverwriteFilesCheckBoxTooltip',definitionFile);
            else
                platform.OverwriteFilesCheckBox.Tooltip = ...
                    platform.getMsgText('OverwriteFilesCheckBoxTooltip','');
            end

            if clibgen.internal.clibpackageisLoaded(string(platform.PackageNameEditField.Value))
                platform.showPackageNameStatus(platform.getMsgText('PackageNameInUseLabel',platform.PackageNameEditField.Value));
                status = platform.PackageIsLoadedStatus;
            elseif ~platform.OverwriteFilesCheckBox.Value && mFileExists
                if showstate
                    platform.showPackageNameStatus(platform.getMsgText('DefinitionFileExistsLabel',mFileName));
                end
                status = platform.DefinitionFileExistsStatus;
            else
                platform.PackageNameStatusLabel.Visible = 'off';
                status = 0;
            end
        end
        function updateLibrariesForCompiler(platform)
            platform.updateLibrariesTooltip;
            platform.updateLibraryFilesControls;
        end
        function updateLibrariesTooltip(platform)
            if isempty(platform.CompilerDropDown.Value)
                msgid = '';
            else
                if ispc
                    compilerName = platform.CompilerDropDown.Value;
                    if startsWith(compilerName,platform.MicrosoftCppCompilersShortName)
                        msgid = 'MicrosoftLibraryExtensions';
                    else
                        msgid = 'NonMicrosoftLibraryExtensions';
                    end
                elseif ismac
                    msgid = 'MacLibraryExtensions';
                else
                    msgid = 'LinuxLibraryExtensions';
                end
            end
            if isempty(msgid)
                librariesExtensionsMsg = '';
            else
                librariesExtensionsMsg = platform.getMsgText(msgid);
            end
            librariesLabel = findobj(platform.LibrariesGrid, ...
                '-isa','matlab.ui.control.Label','Tag','Libraries');
            librariesLabel.Text = platform.getMsgText('LibrariesLabel',librariesExtensionsMsg);
            librariesLabel.Tooltip = platform.getMsgText('LibrariesLabelTooltip',librariesExtensionsMsg);
        end
        function selectOutputFolder(platform,~,~)
            pathname = platform.FileChooser.browseFolders(pwd, ...
                platform.getMsgText('OutputFolderBrowseMsg'));
            if pathname ~= 0
                platform.OutputFolderSelection.Text = pathname;
                platform.showDefinitionFileOrPackageNameExists(true);
                % Confirm output folder selection with multiple platforms and
                % ends with platform specific folder name
                currentPlatform = computer("arch");
                if platform.isMultiPlatform && ~endsWith(platform.OutputFolderSelection.Text,currentPlatform)
                    taskFigure = platform.getTabFigure;
                    selection = uiconfirm(taskFigure, ...
                        platform.getMsgText('OutputFolderActionMsg',currentPlatform), ...
                        platform.getMsgText('OutputFolderWarnTitle'),...
                        'Options',{platform.getMsgText('OutputFolderConfirmBtnCreate',currentPlatform),platform.getMsgText('OutputFolderBtnCancel')},...
                        'DefaultOption',2,'CancelOption',2,...
                        'Icon','warning');
                    if strcmp(selection,platform.getMsgText('OutputFolderBtnCancel'))
                       platform.updateControls;
                        return;
                    end
                    % Add platform specific output folder
                    platform.OutputFolderSelection.Text = fullfile(platform.OutputFolderSelection.Text,currentPlatform);
                end
                platform.updateControls;
            end
        end
        function hasStartTag = hasStartTagItems(platform)
            hasStartTag = false;
            if isvalid(platform.InterfaceFilesListBox)
                for idx=1:length(platform.InterfaceFilesListBox.Items)
                    if contains(platform.InterfaceFilesListBox.Items{idx}, platform.LibraryStartPathTag)
                        hasStartTag = true;
                        return;
                    end
                end
            end
            if isvalid(platform.IncludePathListBox)
                for idx=1:length(platform.IncludePathListBox.Items)
                    if contains(platform.IncludePathListBox.Items{idx}, platform.LibraryStartPathTag)
                        hasStartTag = true;
                        return;
                    end
                end
            end
            if isvalid(platform.LibrariesListBox)
                for idx=1:length(platform.LibrariesListBox.Items)
                    if contains(platform.LibrariesListBox.Items{idx}, platform.LibraryStartPathTag)
                        hasStartTag = true;
                        return;
                    end
                end
            end
            if isvalid(platform.SourceFilesListBox)
                for idx=1:length(platform.SourceFilesListBox.Items)
                    if contains(platform.SourceFilesListBox.Items{idx}, platform.LibraryStartPathTag)
                        hasStartTag = true;
                        return;
                    end
                end
            end
        end
        function validpath = hasStartPath(platform)
            validpath = true;
            if strcmp(platform.LibraryStartPathSelection.Text,platform.getMsgText('SelectFileOrPathOptional')) || ...
               strcmp(platform.LibraryStartPathSelection.Text,platform.getMsgText('SelectFileOrPathRequiredClick'))
                validpath = false;
            end
        end
        function deleteStartTagItems(platform, listbox)
            if isempty(listbox) || ~ishandle(listbox)
                return;
            end
            for idx=1:length(listbox.Items)
                if contains(listbox.Items{idx}, platform.LibraryStartPathTag)
                    if isempty(listbox.Value)
                        listbox.Value = listbox.Items{idx};
                    else
                        listbox.Value{end+1} = listbox.Items{idx};
                    end
                end
            end
            fileRemoveBtn = findobj(platform.SelectFilesGrid, ...
                '-isa','matlab.ui.control.Image','Tag',['Remove' listbox.Tag]);
            platform.removeFileOrPath(fileRemoveBtn);
        end
        function selectLibraryStartPath(platform,~,~)
            % If startpath already set, confirm the change if files
            % selected include the startpath tag
            if platform.hasStartTagItems && platform.hasStartPath
                taskFigure = platform.getTabFigure;
                selection = uiconfirm(taskFigure, ...
                    platform.getMsgText('ConfirmChangingStartPathPrompt',platform.LibraryStartPathTag), ...
                    platform.getMsgText('ConfirmChangingStartPathTitle'),...
                    'Options',{platform.getMsgText('ConfirmChangingStartPathBtnChange'),platform.getMsgText('ConfirmBtnCancel')},...
                    'DefaultOption',2,'CancelOption',2,...
                    'Icon','warning');
                if strcmp(selection,'Cancel')
                    return;
                end
                % Remove any existing startpath entries in the selected
                % files. The removal order is intentional to retain input 
                % requirements.
                platform.deleteStartTagItems(platform.SourceFilesListBox);
                platform.deleteStartTagItems(platform.LibrariesListBox);
                platform.deleteStartTagItems(platform.IncludePathListBox);                
                platform.deleteStartTagItems(platform.InterfaceFilesListBox);
            end
            pathname = platform.FileChooser.browseFolders(platform.startingDir, ...
                 platform.getMsgText('LibraryStartPathBrowseMsg'));
            if pathname ~= 0
                platform.startingDir = pathname;
                platform.LibraryStartPathSelection.Text = pathname;
                platform.updateLibraryStartPathUsage(true);
                platform.updateControls;
            end
        end
        function setControlsToDefault(platform)
            if ~isempty(platform.initialSelectedCompiler)
                if ~ismember(platform.initialSelectedCompiler.ShortName,platform.CompilerDropDown.ItemsData)
                    platform.CompilerDropDown.Items{end+1} = platform.initialSelectedCompiler.Name;
                    platform.CompilerDropDown.ItemsData{end+1} = platform.initialSelectedCompiler.ShortName;
                end
                platform.CompilerDropDown.Value = platform.initialSelectedCompiler.ShortName;
            else
                if (isempty(platform.CompilerDropDown.Items))
                    platform.CompilerDropDown.Value = {};
                else
                    platform.CompilerDropDown.Value = '';
                end
            end
            platform.startingDir = pwd;
            platform.PackageNameEditField.Value = '';
            platform.OutputFolderSelection.Text = pwd;
            platform.OverwriteFilesCheckBox.Value = false;
            libraryType = 'HeaderAndLibrary';
            libraryTypeControl = findobj(platform.LibraryTypeButtonGroup,'Tag',libraryType);
            platform.LibraryTypeButtonGroup.SelectedObject = libraryTypeControl;
            platform.LibraryStartPathSelection.Text = platform.getMsgText('SelectFileOrPathOptional');
            platform.LibraryStartPathSelection.FontAngle = 'italic';
            platform.InterfaceHeaderFiles = {};
            platform.InterfaceSourceFiles = {};
            platform.IncludePath = {};
            platform.IncludePathNotRequiredCheckBox.Value = false;
            platform.DLLFiles = {};
            platform.Libraries = {};
            platform.SourceFiles = {};

            platform.resetBuildOptionalControls;
            platform.ReturnCArraysDropDown.Value = 'ClibArray';
            platform.TreatConstCharPtrDropDown.Value = 'undefined';
            platform.TreatObjPtrDropDown.Value = 'undefined';
            platform.GenerateDocCheckBox.Value = true;
            platform.VerboseCheckBox.Value = false;
            platform.SummaryCheckBox.Value = true;

            platform.BuildOptionsSection.collapse;
            platform.DefineOptionsSection.collapse;
            platform.DisplayResultsSection.collapse;
        end
        function updateControls(platform,~,~)
            platform.showLibraryTypeControls;
            enable = any(isvalid(platform.InterfaceFilesListBox));
            if isvalid(platform.IncludePathNotRequiredCheckBox)
                % Disable include path grid if not required or no compiler
                hasCompiler = ~isempty(platform.CompilerDropDown.Items);
                platform.enableFilesGrid(platform.IncludePathGrid,hasCompiler && ~platform.IncludePathNotRequiredCheckBox.Value);
                % Set enable if InterfaceFiles and IncludePath not required
                enable = enable && platform.IncludePathNotRequiredCheckBox.Value;
            end
            if enable
                switch(platform.LibraryTypeButtonGroup.SelectedObject.Tag)
                case 'HeaderAndLibrary'
                    enable = any(isvalid(platform.LibrariesListBox));
                case 'HeaderAndSource'
                    enable = any(isvalid(platform.SourceFilesListBox));
                end
            end

            if platform.hasStartPath
                platform.LibraryStartPathSelection.FontAngle = 'normal';
                platform.LibraryStartPathSelection.Tooltip = platform.LibraryStartPathSelection.Text;
                platform.LibraryStartPathRemoveButton.Enable = 'on';
                % Update start path entries to use the tag
                platform.updateLibraryStartPathUsage(true);
            else
                platform.LibraryStartPathSelection.FontAngle = 'italic';
                platform.LibraryStartPathSelection.Tooltip = platform.getMsgText('LibraryStartPathTextTooltip');
                platform.LibraryStartPathRemoveButton.Enable = 'off';
                % Update start path entries to use the actual path
                platform.updateLibraryStartPathUsage(false);
            end

            if isempty(platform.CompilerDropDown.Value)
                  enable = false;
            end

            if isempty(platform.CompilerDropDown.Items)
                hasCompiler = false;
            else
                hasCompiler = true;
            end

            if ~hasCompiler
                platform.showNoCompilerLabel;
            else
                platform.deleteNoCompilerLabel;
            end

            platform.PackageNameEditField.Enable = enable && platform.isFirstPlatformTabEnabled;
            if isempty(platform.PackageNameEditField.Value)
                platform.PackageNameEditField.FontAngle = 'italic';
            else
                platform.PackageNameEditField.FontAngle = 'normal';
            end
            enable = enable && ~isempty(platform.PackageNameEditField.Value);

            platform.OutputFolderSelection.Tooltip = platform.OutputFolderSelection.Text;
            platform.OutputFolderSelection.Enable = enable;
            platform.OutputFolderBrowseButton.Enable = enable;
            platform.OverwriteFilesCheckBox.Enable = enable;
            platform.showDefinitionFileOrPackageNameExists;
            
            platform.CLinkageCheckBox.Enable = enable;
            platform.enableGrid(platform.DefinedMacrosGrid,enable,{'uilabel'});
            platform.enableGrid(platform.UndefinedMacrosGrid,enable,{'uilabel'});
            platform.enableGrid(platform.AdditionalCompilerGrid,enable,{'uilabel'});
            platform.enableGrid(platform.AdditionalLinkerGrid,enable,{'uilabel'});
            platform.enableGrid(platform.DefineOptionsGrid,enable,{'uilabel'});
            platform.enableGrid(platform.DisplayResultsGrid,enable,{'uilabel'});    

            platform.updateObjectPointerTooltip;
            platform.updateConstCharacterPointerTooltip;
            platform.updateReturnCArraysTooltip;

            % Trigger the live editor to update the generated script            
            notify(platform,'PlatformChanged');
        end
        function selectFileOrPath(platform,src,~)
            libraryType = platform.LibraryTypeButtonGroup.SelectedObject.Tag;
            switch(src.Tag)
                case 'InterfaceFiles'
                    if strcmp(libraryType,'Custom')
                        filter = {'*.h;*.hpp;*.hxx;*.cpp;*.cxx', 'C++ Files(*.h, *.hpp, *.hxx, *.cpp, *.cxx)';
                                '*.h',  'Header Files(*.h)'; ...
                                '*.hpp',  'Header Files(*.hpp)'; ...
                                '*.hxx',  'Header Files(*.hxx)'; ...
                                '*.cpp',  'Source Files(*.cpp)'; ...
                                '*.cxx',  'Source Files(*.cxx)'};
                    else
                        filter = {'*.h;*.hpp;*.hxx', 'C++ Files(*.h, *.hpp, *.hxx)';
                                '*.h',  'Header Files(*.h)'; ...
                                '*.hpp',  'Header Files(*.hpp)'; ...
                                '*.hxx',  'Header Files(*.hxx)'};
                    end
                case 'IncludePath'
                    pathname = platform.browsePath;
                    if pathname ~= 0
                        % Check and substitute platform.libraryStartPathTag
                        pathname = platform.substituteLibraryStartPathTag(pathname);
                        added = false;
                        if ~ismember(pathname,platform.IncludePath)
                            platform.IncludePath{end+1} = pathname;
                            added = true;
                        end
                        platform.updateIncludePathControls;
                        if added
                            notify(platform,'PlatformChanged');
                        end
                    end
                case 'Libraries'
                    if ispc
                        compilerName = platform.CompilerDropDown.Value;
                        if startsWith(compilerName,platform.MicrosoftCppCompilersShortName)
                            filter = {'*.lib;*.dll', 'Library Files(*.lib, *.dll)';
                             '*.lib',  'Import Library Files(*.lib)'; ...
                            '*.dll',  'Shared Library Files(*.dll)'};
                        else
                            filter = {'*.lib', 'Library Files(*.lib)'};
                        end
                    elseif ismac
                        filter = {'*.dylib', 'Library Files(*.dylib)';
                            '*.a', 'Archive Files(*.a)'};
                    else
                        filter = {'*.so', 'Library Files(*.so)';
                            '*.a', 'Archive Files(*.a)'};
                    end
                case 'SourceFiles'
                    filter = {'*.cpp;*.cxx;*.c',  'Source Files(*.cpp, *.cxx, *.c)';
                        '*.cpp',  'Source Files(*.cpp)'; ...
                        '*.cxx',  'Source Files(*.cxx)'; ...
                        '*.c',  'Source Files(*.c)'};
            end
            if strcmp(src.Tag,'IncludePath')
                platform.updateControls;
                return;
            end

            [filenames, pathname] = platform.browseFiles(filter);
            if ~iscell(filenames)
                if filenames == 0
                    return;
                else
                    filenames = {filenames};
                end
            end

            added = false;

            switch(src.Tag)
                case 'InterfaceFiles'
                    for idx=1:length(filenames)
                        [~,~,fileext] = fileparts(filenames{idx});
                        fullfilename = fullfile(pathname,filenames{idx});
                        % Check and substitute platform.libraryStartPathTag
                        fullfilename = platform.substituteLibraryStartPathTag(fullfilename);
                        if strcmpi(fileext,'.h') || strcmpi(fileext,'.hpp') ...
                                || strcmpi(fileext,'.hxx')
                            if ~ismember(fullfilename,platform.InterfaceHeaderFiles)
                                platform.InterfaceHeaderFiles{end+1} = fullfilename;
                                added = true;
                            end
                        else % .cpp, .cxx files
                            if ~ismember(fullfilename,platform.InterfaceSourceFiles)
                                % check if the interface source file is already selected as supporting source file
                                if ~ismember(fullfilename,platform.SourceFiles)
                                    platform.InterfaceSourceFiles{end+1} = fullfilename;
                                    added = true;
                                else
                                    % error and don't add
                                    interfaceGenerationFileLabel = platform.getMsgText('HeaderFilesLabel');
                                    if strcmp(platform.LibraryTypeButtonGroup.SelectedObject.Tag,'Custom')
                                        interfaceGenerationFileLabel = platform.getMsgText('HeaderAndSourceFilesLabel');
                                    end
                                    interfaceFilesLabel = platform.getMsgText('InterfaceGenerationFilesLabel',interfaceGenerationFileLabel,'');
                                    sourceFilesLabel = platform.getMsgText('SourceFilesLabel','');
                                    msg = platform.getMsgText('DuplicateFileError', fullfilename, ...
                                        sourceFilesLabel, interfaceFilesLabel);
                                    title = platform.getMsgText('FileSelectionErrorTitle');
                                    uialert(platform.getTabFigure,msg,title,'Icon','error');
                                end
                            end
                        end
                    end
                    platform.updateInterfaceFilesControls;
                    if isempty(platform.PackageNameEditField.Value)
                        platform.setPackageName(platform.choosePackageName);
                    end
                case 'Libraries'
                    for idx=1:length(filenames)
                        [~,~,fileext] = fileparts(filenames{idx});
                        fullfilename = fullfile(pathname,filenames{idx});
                        % Check and substitute platform.libraryStartPathTag
                        fullfilename = platform.substituteLibraryStartPathTag(fullfilename);
                        if ispc
                            if strcmpi(fileext,'.dll')
                                if ~ismember(fullfilename,platform.DLLFiles)
                                    platform.DLLFiles{end+1} = fullfilename;
                                    added = true;
                                end
                            else % .lib files
                                if ~ismember(fullfilename,platform.Libraries)
                                    platform.Libraries{end+1} = fullfilename;
                                    added = true;
                                end
                            end
                        else
                            if ~ismember(fullfilename,platform.Libraries)
                                platform.Libraries{end+1} = fullfilename;
                                added = true;
                            end
                        end
                    end
                    platform.updateLibraryFilesControls;
                case 'SourceFiles'
                    for idx=1:length(filenames)
                        fullfilename = fullfile(pathname,filenames{idx});
                        % Check and substitute platform.libraryStartPathTag
                        fullfilename = platform.substituteLibraryStartPathTag(fullfilename);
                        if ~ismember(fullfilename,platform.SourceFiles)
                            % check if the source file is already selected as interface file
                            if ~ismember(fullfilename,platform.InterfaceSourceFiles)
                                platform.SourceFiles{end+1} = fullfilename;
                                added = true;
                            else
                                % error popup and don't add
                                interfaceGenerationFileLabel = platform.getMsgText('HeaderFilesLabel');
                                if strcmp(platform.LibraryTypeButtonGroup.SelectedObject.Tag,'Custom')
                                    interfaceGenerationFileLabel = platform.getMsgText('HeaderAndSourceFilesLabel');
                                end
                                interfaceFilesLabel = platform.getMsgText('InterfaceGenerationFilesLabel',interfaceGenerationFileLabel,'');
                                sourceFilesLabel = platform.getMsgText('SourceFilesLabel','');
                                msg = platform.getMsgText('DuplicateFileError', fullfilename, ...
                                    interfaceFilesLabel, sourceFilesLabel);
                                title = platform.getMsgText('FileSelectionErrorTitle');
                                uialert(platform.getTabFigure,msg,title,'Icon','error');
                            end
                        end
                    end
                    platform.updateSourceFilesControls;
            end
            platform.updateControls;
            if added
                notify(platform,'PlatformChanged');
            end
        end
        function [filenames, pathname] = browseFiles(platform,filter)
            [filenames, pathname] = platform.FileChooser.browseFiles(filter, ...
                platform.getMsgText('FileBrowseMsg'),platform.startingDir);
        end
        function pathname = browsePath(platform)
            pathname = platform.FileChooser.browseFolders(platform.startingDir,platform.getMsgText('PathBrowseMsg'));
        end
        function removeFileOrPath(platform,src,~)
            switch(extractAfter(src.Tag,'Remove'))
                case 'LibraryStartPath'
                    % Reset the LibraryStartPath value
                    platform.updateLibraryStartPathUsage(false);
                    platform.LibraryStartPathSelection.Text = platform.getMsgText('SelectFileOrPathOptional');
                    src.Enable = 'off';
                    deleted = true;
                case 'InterfaceFiles'
                    filesToRemove = platform.InterfaceFilesListBox.Value;
                    headerFilesToRemove = {};
                    sourceFilesToRemove = {};
                    for idx=1:numel(filesToRemove)
                        [~,~,fileext] = fileparts(filesToRemove{idx});
                        if strcmpi(fileext,'.h') || strcmpi(fileext,'.hpp') ...
                                || strcmpi(fileext,'.hxx')
                            headerFilesToRemove{end+1} = filesToRemove(idx);
                        else % .cpp, .cxx files
                            sourceFilesToRemove{end+1} = filesToRemove(idx);
                        end
                    end
                    [platform.InterfaceHeaderFiles, deletedHeaders] = platform.deleteElements(platform.InterfaceHeaderFiles,headerFilesToRemove);
                    [platform.InterfaceSourceFiles, deletedSources] = platform.deleteElements(platform.InterfaceSourceFiles,sourceFilesToRemove);
                    deleted = deletedHeaders | deletedSources;
                    platform.updateInterfaceFilesControls;
                case 'IncludePath'
                    deleted = platform.deleteItems(platform.IncludePathListBox);
                    platform.IncludePath = platform.IncludePathListBox.Items;
                    platform.updateIncludePathControls;
                case 'Libraries'
                    if ispc
                        filesToRemove = platform.LibrariesListBox.Value;
                        DLLFilesToRemove = {};
                        LibraryFilesToRemove = {};
                        for idx=1:numel(filesToRemove)
                            [~,~,fileext] = fileparts(filesToRemove{idx});
                            if strcmpi(fileext,'.dll')
                                DLLFilesToRemove{end+1} = filesToRemove(idx);
                            else % .lib files
                                LibraryFilesToRemove{end+1} = filesToRemove(idx);
                            end
                        end
                        [platform.DLLFiles, deletedDlls] = platform.deleteElements(platform.DLLFiles,DLLFilesToRemove);
                        [platform.Libraries, deletedLibs] = platform.deleteElements(platform.Libraries,LibraryFilesToRemove);
                        deleted = deletedDlls | deletedLibs;
                    else
                        deleted = platform.deleteItems(platform.LibrariesListBox);
                        platform.Libraries = platform.LibrariesListBox.Items;
                    end
                    platform.updateLibraryFilesControls;
                case 'SourceFiles'
                    deleted = platform.deleteItems(platform.SourceFilesListBox);
                    platform.SourceFiles = platform.SourceFilesListBox.Items;
                    platform.updateSourceFilesControls;
            end
            src.Enable = 'off';
            platform.updateControls;
            if deleted
                notify(platform,'PlatformChanged');
            end
        end
        function showLibraryTypeControls(platform,~,~)
            libraryType = platform.LibraryTypeButtonGroup.SelectedObject.Tag;
            interfaceGenerationFileLabel = platform.getMsgText('HeaderFilesLabel');
            % update interface files label/tooltips
            if strcmp(libraryType,'Custom')
                labelExtensionsMsg = '';
                tooltipExtensionMsg = platform.getMsgText('HeaderAndSourceFileExtensions');
                interfaceGenerationFileLabel = platform.getMsgText('HeaderAndSourceFilesLabel');
            else
                labelExtensionsMsg = platform.getMsgText('HeaderFileExtensions');
                tooltipExtensionMsg = labelExtensionsMsg;
            end
            interfaceFilesLabel = findobj(platform.InterfaceFilesGrid, ...
                '-isa','matlab.ui.control.Label','Tag','InterfaceFiles');
            interfaceFilesLabel.Text = platform.getMsgText('InterfaceGenerationFilesLabel',interfaceGenerationFileLabel,labelExtensionsMsg);
            interfaceFilesLabel.Tooltip = platform.getMsgText('InterfaceGenerationFilesLabelTooltip',tooltipExtensionMsg);

            % show implementation files
            switch(libraryType)
                case 'HeaderOnly'
                    showLibs = false; showSources = false;
                    sourcesColumn = 0;
                case 'HeaderAndLibrary'
                    showLibs = true; showSources = false;
                    sourcesColumn = 0;
                case 'HeaderAndSource'
                    showLibs = false; showSources = true;
                    sourcesColumn = 1;
                case 'Custom'
                    showLibs = true; showSources = true;
                    sourcesColumn = 3;
            end
            platform.showImplementationFiles(showLibs,showSources,sourcesColumn);

            platform.updateInterfaceFilesControls;
            platform.updateIncludePathControls;
            platform.updateLibraryFilesControls;
            platform.updateSourceFilesControls;
        end
        function showImplementationFiles(platform,showLibs,showSources,sourcesColumn)
            if showLibs
                platform.LibrariesGrid.Parent = platform.SelectFilesGrid;
                platform.setRowColumn(platform.LibrariesGrid,4,1);
            else
                platform.LibrariesGrid.Parent = [];
            end
            if showSources
                platform.SourceFilesGrid.Parent = platform.SelectFilesGrid;
                platform.setRowColumn(platform.SourceFilesGrid,4,sourcesColumn);
            else
                platform.SourceFilesGrid.Parent = [];
            end
        end
        function showNoCompilerLabel(platform)
            noCompilerLabel = findobj(platform.CompilerDropDown.Parent, ...
                '-isa','matlab.ui.control.uilabel');
            if isempty(noCompilerLabel)
                noCompilerLabel = uilabel(platform.CompilerDropDown.Parent, ...
                    'Text',platform.getMsgText('NoCompilerFoundLabel'), ...
                    'FontWeight','bold');
                platform.setRowColumn(noCompilerLabel,1,[4 5]);
            end
        end
        function deleteNoCompilerLabel(platform)
            noCompilerLabel = findobj(platform.CompilerDropDown.Parent, ...
                '-isa','matlab.ui.control.uilabel');
            delete(noCompilerLabel);
        end
        function updateLibraryStartPathUsage(platform, useStartPathTag)
            % Update any startpath usage in list boxes to the
            % actual path or startpath tag depending on valid start path value
            filenames = platform.InterfaceHeaderFiles;
            for idx=1:length(filenames)
                if useStartPathTag
                    fullfilename = platform.substituteLibraryStartPathTag(filenames{idx});
                else
                    fullfilename = platform.substituteLibraryStartPathValue(filenames{idx});
                end
                platform.InterfaceHeaderFiles{idx} = fullfilename;
            end
            filenames = platform.InterfaceSourceFiles;
            for idx=1:length(filenames)
                if useStartPathTag
                    fullfilename = platform.substituteLibraryStartPathTag(filenames{idx});
                else
                    fullfilename = platform.substituteLibraryStartPathValue(filenames{idx});
                end
                platform.InterfaceSourceFiles{idx} = fullfilename;
            end
            filenames = platform.IncludePath;
            for idx=1:length(filenames)
                if useStartPathTag
                    fullfilename = platform.substituteLibraryStartPathTag(filenames{idx});
                else
                    fullfilename = platform.substituteLibraryStartPathValue(filenames{idx});
                end
                platform.IncludePath{idx} = fullfilename;
            end
            filenames = platform.Libraries;
            for idx=1:length(filenames)
                if useStartPathTag
                    fullfilename = platform.substituteLibraryStartPathTag(filenames{idx});
                else
                    fullfilename = platform.substituteLibraryStartPathValue(filenames{idx});
                end
                platform.Libraries{idx} = fullfilename;
            end
            filenames = platform.DLLFiles;
            for idx=1:length(filenames)
                if useStartPathTag
                    fullfilename = platform.substituteLibraryStartPathTag(filenames{idx});
                else
                    fullfilename = platform.substituteLibraryStartPathValue(filenames{idx});
                end
                platform.DLLFiles{idx} = fullfilename;
            end
            filenames = platform.SourceFiles;
            for idx=1:length(filenames)
                if useStartPathTag
                    fullfilename = platform.substituteLibraryStartPathTag(filenames{idx});
                else
                    fullfilename = platform.substituteLibraryStartPathValue(filenames{idx});
                end
                platform.SourceFiles{idx} = fullfilename;
            end
        end
        function updateInterfaceFilesControls(platform)
            libraryType = platform.LibraryTypeButtonGroup.SelectedObject.Tag;
            if strcmp(libraryType,'Custom')
                interfaceFiles = [platform.InterfaceHeaderFiles platform.InterfaceSourceFiles];
            else
                interfaceFiles = platform.InterfaceHeaderFiles;
            end
            if isempty(interfaceFiles)
                % delete listbox if exist and create text area if doesn't exist
                if isvalid(platform.InterfaceFilesListBox)
                    delete(platform.InterfaceFilesListBox)
                end
                if ~isvalid(platform.InterfaceFilesTextArea)
                    platform.InterfaceFilesTextArea = platform.createTextAreaWidget(platform.InterfaceFilesGrid,2,1,'InterfaceFiles');
                end
                platform.addPlaceHolderText(platform.InterfaceFilesTextArea,platform.getMsgText('SelectFileOrPathRequiredClick'));
            else
                % delete text area if exist and create listbox if doesn't exist
                if isvalid(platform.InterfaceFilesTextArea)
                    delete(platform.InterfaceFilesTextArea)
                end
                if ~any(isvalid(platform.InterfaceFilesListBox))
                    platform.InterfaceFilesListBox = platform.createListboxWidget(platform.InterfaceFilesGrid,2,1,'InterfaceFiles');
                end
                platform.InterfaceFilesGrid.RowHeight{end} = platform.getListBoxHeight(numel(interfaceFiles));
                platform.InterfaceFilesListBox.Items = interfaceFiles;
                platform.InterfaceFilesListBox.Value = {};
                fileRemoveBtn = findobj(platform.SelectFilesGrid, ...
                    '-isa','matlab.ui.control.Image','Tag',['Remove' platform.InterfaceFilesListBox.Tag]);
                if ~isempty(fileRemoveBtn)
                    fileRemoveBtn.Enable = 'off';
                end
            end
        end
        function updateIncludePathControls(platform)
            if isempty(platform.IncludePath)
                % delete listbox if exist and create text area if doesn't exist
                if isvalid(platform.IncludePathListBox)
                    delete(platform.IncludePathListBox)
                end
                if ~isvalid(platform.IncludePathTextArea)
                    platform.IncludePathTextArea = platform.createTextAreaWidget(platform.IncludePathGrid,2,1,'IncludePath');
                    tag = 'IncludePathNotRequiredCheckBox';
                    platform.IncludePathNotRequiredCheckBox = uicheckbox(platform.IncludePathGrid, ...
                        'Text',platform.getMsgText(tag), ...
                        'Tooltip',platform.getMsgText([tag 'Tooltip']), ...
                        'Tag',tag, ...
                        'ValueChangedFcn',@platform.updateControls);
                end
                if platform.IncludePathNotRequiredCheckBox.Value
                    platform.addPlaceHolderText(platform.IncludePathTextArea,'');
                else
                    platform.addPlaceHolderText(platform.IncludePathTextArea,platform.getMsgText('SelectFileOrPathRequiredClick'));
                end
            else
                % delete text area if exist and create listbox if doesn't exist
                if isvalid(platform.IncludePathTextArea)
                    delete(platform.IncludePathTextArea);
                    delete(platform.IncludePathNotRequiredCheckBox);
                end
                if ~any(isvalid(platform.IncludePathListBox))
                    platform.IncludePathListBox = platform.createListboxWidget(platform.IncludePathGrid,2,1,'IncludePath');
                end
                platform.IncludePathGrid.RowHeight{end} = platform.getListBoxHeight(numel(platform.IncludePath));
                platform.IncludePathListBox.Items = platform.IncludePath;
                platform.IncludePathListBox.Value = {};
                fileRemoveBtn = findobj(platform.SelectFilesGrid, ...
                    '-isa','matlab.ui.control.Image','Tag',['Remove' platform.IncludePathListBox.Tag]);
                if ~isempty(fileRemoveBtn)
                    fileRemoveBtn.Enable = 'off';
                end
            end
        end
        function updateLibraryFilesControls(platform)
            if ispc
                compilerName = platform.CompilerDropDown.Value;
                if startsWith(compilerName,platform.MicrosoftCppCompilersShortName)
                    libraryFiles = [platform.Libraries platform.DLLFiles];
                else
                    libraryFiles = platform.Libraries;
                end
            else
                libraryFiles = platform.Libraries;
            end
            if isempty(libraryFiles)
                % delete listbox if exist and create text area if doesn't exist
                if isvalid(platform.LibrariesListBox)
                    delete(platform.LibrariesListBox)
                end
                if ~isvalid(platform.LibrariesTextArea)
                    platform.LibrariesTextArea = platform.createTextAreaWidget(platform.LibrariesGrid,2,1,'Libraries');
                end
                libraryType = platform.LibraryTypeButtonGroup.SelectedObject.Tag;
                if strcmp(libraryType,'HeaderAndLibrary')
                    platform.addPlaceHolderText(platform.LibrariesTextArea,platform.getMsgText('SelectFileOrPathRequiredClick'));
                else
                    platform.addPlaceHolderText(platform.LibrariesTextArea,platform.getMsgText('SelectFileOrPathOptionalClick'));
                end
            else
                % delete text area if exist and create listbox if doesn't exist
                if isvalid(platform.LibrariesTextArea)
                    delete(platform.LibrariesTextArea)
                end
                if ~any(isvalid(platform.LibrariesListBox))
                    platform.LibrariesListBox = platform.createListboxWidget(platform.LibrariesGrid,2,1,'Libraries');
                end
                platform.LibrariesGrid.RowHeight{end} = platform.getListBoxHeight(numel(libraryFiles));
                platform.LibrariesListBox.Items = libraryFiles;
                platform.LibrariesListBox.Value = {};
                fileRemoveBtn = findobj(platform.SelectFilesGrid, ...
                    '-isa','matlab.ui.control.Image','Tag',['Remove' platform.LibrariesListBox.Tag]);
                if ~isempty(fileRemoveBtn)
                    fileRemoveBtn.Enable = 'off';
                end
            end
        end
        function updateSourceFilesControls(platform)
            if isempty(platform.SourceFiles)
                % delete listbox if exist and create text area if doesn't exist
                if isvalid(platform.SourceFilesListBox)
                    delete(platform.SourceFilesListBox)
                end
                if ~isvalid(platform.SourceFilesTextArea)
                    platform.SourceFilesTextArea = platform.createTextAreaWidget(platform.SourceFilesGrid,2,1,'SourceFiles');
                end
                libraryType = platform.LibraryTypeButtonGroup.SelectedObject.Tag;
                if strcmp(libraryType,'HeaderAndSource')
                    platform.addPlaceHolderText(platform.SourceFilesTextArea,platform.getMsgText('SelectFileOrPathRequiredClick'));
                else
                    platform.addPlaceHolderText(platform.SourceFilesTextArea,platform.getMsgText('SelectFileOrPathOptionalClick'));
                end
            else
                % delete text area if exist and create listbox if doesn't exist
                if isvalid(platform.SourceFilesTextArea)
                    delete(platform.SourceFilesTextArea)
                end
                if ~any(isvalid(platform.SourceFilesListBox))
                    platform.SourceFilesListBox = platform.createListboxWidget(platform.SourceFilesGrid,2,1,'SourceFiles');
                end
                platform.SourceFilesGrid.RowHeight{end} = platform.getListBoxHeight(numel(platform.SourceFiles));
                platform.SourceFilesListBox.Items = platform.SourceFiles;
                platform.SourceFilesListBox.Value = {};
                fileRemoveBtn = findobj(platform.SelectFilesGrid, ...
                    '-isa','matlab.ui.control.Image','Tag',['Remove' platform.SourceFilesListBox.Tag]);
                if ~isempty(fileRemoveBtn)
                    fileRemoveBtn.Enable = 'off';
                end
            end
        end
        function height = getListBoxHeight(~,ListBoxSize)
            % Height of list box should be between 40-100
            height = min(100,max(40,20*(1+ListBoxSize)));
        end
        function enableFilesGrid(~,grid,enable)
            % enable label
            label = findobj(grid,'-isa','matlab.ui.control.Label');
            label.Enable = enable;
            % enable browse button
            browseButton = findobj(grid,'-isa','matlab.ui.control.Button');
            browseButton.Enable = enable;
            % enable listbox
            listbox = findobj(grid,'-isa','matlab.ui.control.ListBox');
            if ~isempty(listbox)
                listbox.Enable = enable;
            end
            % enable textarea
            textarea = findobj(grid,'-isa','matlab.ui.control.TextArea');
            if ~isempty(textarea)
                textarea.Enable = enable;
            end
        end
        function enableGrid(platform,grid,enable,exclude)
            arrayfun(@(x) enableWidget(platform,x,enable,exclude),grid.Children);
        end
        function enableWidget(platform,widget,enable,exclude)
            if strcmp(widget.Type,'uigridlayout')
                platform.enableGrid(widget,enable,exclude)
            elseif ~any(cellfun(@(x) strcmp(widget.Type,x),exclude))
                set(widget,'Enable',enable);
            end
        end
        function chosenName = choosePackageName(platform)
            interfaceFiles = [platform.InterfaceHeaderFiles platform.InterfaceSourceFiles];
            if isempty(interfaceFiles)
                return;
            end
            [~,firstFileName,~] = fileparts(interfaceFiles{1});
            chosenName = matlab.lang.makeValidName(firstFileName);
            outputFolder = platform.OutputFolderSelection.Text;
            existingNames = {};
            while 1
                mFileName = ['define' chosenName '.m'];
                interfaceDir = fullfile(outputFolder,chosenName);
                if ~isfile(fullfile(outputFolder,mFileName)) && ...
                    ~isfile(interfaceDir) && ...
                    ~clibgen.internal.clibpackageisLoaded(string(chosenName))
                    % Choose a package name such that there is 
                    % no definition file with the package name,
                    % no file exists with the package name,
                    % no interface loaded with the package name
                    break;
                end
                existingNames(end+1) = {chosenName};
                chosenName = matlab.lang.makeUniqueStrings(chosenName,existingNames);
            end
        end
        function setPackageName(platform,packageName)
            platform.PackageNameEditField.Value = packageName;
            platform.PackageNameEditField.FontAngle = 'normal';
        end
        function showPackageNameStatus(platform,msg)
            platform.PackageNameStatusLabel.Visible = 'on';
            platform.PackageNameStatusLabel.Text = msg;
        end
        function listbox = createListboxWidget(platform,parent,row,column,tag)
            listbox = uilistbox(parent,'Items',{},'Multiselect','on', ...
                'ValueChangedFcn',@platform.ListboxValueChanged,'Tag',tag);
            platform.setRowColumn(listbox,row,column);
            parent.RowHeight{end} = 40;
        end
        function textarea = createTextAreaWidget(platform,parent,row,column,tag)
            textarea = uitextarea(parent,'Tag',tag);
            platform.setRowColumn(textarea,row,column);
            parent.RowHeight{end} = 25;
            textarea.Editable = 'off';
        end
        function addPlaceHolderText(~,widget,text)
            widget.FontAngle = 'italic';
            widget.Placeholder = text;
            widget.HorizontalAlignment = 'center';
        end
        function removePlaceHolderText(~,widget)
            widget.FontAngle = 'normal';
            widget.Placeholder = '';
        end
        function MacroNameChanging(~,src,evt)
            str = evt.Value;
            if strcmp(src.Tag,'identifier')
                valid = isempty(str) || strcmp(str,matlab.lang.makeValidName(str));
            else
                valid = true;
            end
            if ~valid
                src.UserData.status = 'invalid';
            else
                src.UserData.status = 'valid';
            end
            if isempty(src.Value)
                src.FontAngle = 'italic';
            else
                src.FontAngle = 'normal';
            end
        end
        function MacroNameChanged(platform,src,~)
            if strcmp(src.UserData.status, 'invalid')
                src.Value = '';
                src.UserData.status = 'valid';
            end
            if isempty(src.Value)
                src.FontAngle = 'italic';
            else
                src.FontAngle = 'normal';
            end
            notify(platform,'PlatformChanged');
        end
        function ListboxValueChanged(~,src,~)
            removeControl = findobj(src.Parent,'Tag',['Remove' src.Tag]);
            if ~isempty(src.Value)
                removeControl.Enable = 'on';
            else
                removeControl.Enable = 'off';
            end
        end
        function resetBuildOptionalControls(platform)
            % reset defined macros
            delete(platform.DefinedMacrosCompilerFlagLabels);
            platform.DefinedMacrosCompilerFlagLabels(:) = [];
            delete(platform.DefinedMacrosIds);
            platform.DefinedMacrosIds(:) = [];
            delete(platform.DefinedMacrosEqualLabels);
            platform.DefinedMacrosEqualLabels(:) = [];
            delete(platform.DefinedMacrosValues);
            platform.DefinedMacrosValues(:) = [];
            delete(platform.DefinedMacrosAddButtons);
            platform.DefinedMacrosAddButtons(:) = [];
            delete(platform.DefinedMacrosSubtractButtons);
            platform.DefinedMacrosSubtractButtons(:) = [];
            platform.DefinedMacrosFirstAddButton.Parent = platform.DefinedMacrosGrid;
            platform.setRowColumn(platform.DefinedMacrosFirstAddButton,1,1);

            % reset undefined macros
            delete(platform.UndefinedMacrosCompilerFlagLabels);
            platform.UndefinedMacrosCompilerFlagLabels(:) = [];
            delete(platform.UndefinedMacrosIds);
            platform.UndefinedMacrosIds(:) = [];
            delete(platform.DefinedMacrosValues);
            platform.DefinedMacrosValues(:) = [];
            delete(platform.UndefinedMacrosAddButtons);
            platform.UndefinedMacrosAddButtons(:) = [];
            delete(platform.UndefinedMacrosSubtractButtons);
            platform.UndefinedMacrosSubtractButtons(:) = [];
            platform.UndefinedMacrosFirstAddButton.Parent = platform.UndefinedMacrosGrid;
            platform.setRowColumn(platform.UndefinedMacrosFirstAddButton,1,1);

            % reset additional compiler flags
            delete(platform.AdditionalCompilerValues);
            platform.AdditionalCompilerValues(:) = [];
            delete(platform.AdditionalCompilerAddButtons);
            platform.AdditionalCompilerAddButtons(:) = [];
            delete(platform.AdditionalCompilerSubtractButtons);
            platform.AdditionalCompilerSubtractButtons(:) = [];
            platform.AdditionalCompilerFirstAddButton.Parent = platform.AdditionalCompilerGrid;
            platform.setRowColumn(platform.AdditionalCompilerFirstAddButton,1,1);
            
            % reset additional linker flags
            delete(platform.AdditionalLinkerValues);
            platform.AdditionalLinkerValues(:) = [];
            delete(platform.AdditionalLinkerAddButtons);
            platform.AdditionalLinkerAddButtons(:) = [];
            delete(platform.AdditionalLinkerSubtractButtons);
            platform.AdditionalLinkerSubtractButtons(:) = [];
            platform.AdditionalLinkerFirstAddButton.Parent = platform.AdditionalLinkerGrid;
            platform.setRowColumn(platform.AdditionalLinkerFirstAddButton,1,1);
        end
        function setBuildOptionalControls(platform,definedMacrosIds,definedMacrosValues, ...
                undefinedMacrosIds,additionalCompilerValues, additionalLinkerValues)
            % Define macros
            for nextRow=1:numel(definedMacrosIds)
                platform.DefinedMacrosCompilerFlagLabels(nextRow) = uilabel(platform.DefinedMacrosGrid,'Text','-D');
                platform.setRowColumn(platform.DefinedMacrosCompilerFlagLabels(nextRow),nextRow,1);
                platform.DefinedMacrosGrid.RowHeight{end} = platform.ImageSizeInGrid;
                platform.DefinedMacrosIds(nextRow) = uieditfield(platform.DefinedMacrosGrid, ...
                    'ValueChangingFcn',@platform.MacroNameChanging, ...
                    'ValueChangedFcn',@platform.MacroNameChanged, ...
                    'Tag','identifier', ...
                    'Placeholder', platform.getMsgText('MacroIdentifierPlaceholder'));
                platform.DefinedMacrosIds(nextRow).UserData.status = 'valid';
                platform.setRowColumn(platform.DefinedMacrosIds(nextRow),nextRow,2);
                platform.DefinedMacrosIds(nextRow).Value = definedMacrosIds{nextRow};
                if isempty(platform.DefinedMacrosIds(nextRow).Value)
                    platform.DefinedMacrosIds(nextRow).FontAngle = 'italic';
                end
                platform.DefinedMacrosEqualLabels(nextRow) = uilabel(platform.DefinedMacrosGrid,'Text','=');
                platform.setRowColumn(platform.DefinedMacrosEqualLabels(nextRow),nextRow,3);
                platform.DefinedMacrosValues(nextRow) = uieditfield(platform.DefinedMacrosGrid, ...
                    'ValueChangingFcn',@platform.MacroNameChanging, ...
                    'ValueChangedFcn',@platform.MacroNameChanged, ...
                    'Tag','value', ...
                    'Placeholder', platform.getMsgText('MacroFlagValuePlaceholder'));
                platform.DefinedMacrosValues(nextRow).UserData.status = 'valid';
                platform.setRowColumn(platform.DefinedMacrosValues(nextRow),nextRow,4);
                platform.DefinedMacrosValues(nextRow).Value = definedMacrosValues{nextRow};
                if isempty(platform.DefinedMacrosValues(nextRow).Value)
                    platform.DefinedMacrosValues(nextRow).FontAngle = 'italic';
                end
                platform.DefinedMacrosSubtractButtons(nextRow) = uiimage(platform.DefinedMacrosGrid, ...
                    'ImageSource',platform.SubtractImageSource, ...
                    'ImageClickedFcn',@platform.subtractDefinedMacrosRow,'UserData',nextRow);
                matlab.ui.control.internal.specifyIconID(platform.DefinedMacrosSubtractButtons(nextRow),'minusUI',16);
                platform.setRowColumn(platform.DefinedMacrosSubtractButtons(nextRow),nextRow,5);
                platform.DefinedMacrosAddButtons(nextRow) = uiimage(platform.DefinedMacrosGrid, ...
                    'ImageSource',platform.AddImageSource, ...
                    'ImageClickedFcn',@platform.addDefinedMacrosRow,'UserData',nextRow);
                matlab.ui.control.internal.specifyIconID(platform.DefinedMacrosAddButtons(nextRow),'plusUI',16);
                platform.setRowColumn(platform.DefinedMacrosAddButtons(nextRow),nextRow,6);
            end
            if ~isempty(definedMacrosIds)
                platform.DefinedMacrosFirstAddButton.Parent = [];
            end
            % Undefine macros
            for nextRow=1:numel(undefinedMacrosIds)
                platform.UndefinedMacrosCompilerFlagLabels(nextRow) = uilabel(platform.UndefinedMacrosGrid,'Text','-U');
                platform.setRowColumn(platform.UndefinedMacrosCompilerFlagLabels(nextRow),nextRow,1);
                platform.UndefinedMacrosGrid.RowHeight{end} = platform.ImageSizeInGrid;
                platform.UndefinedMacrosIds(nextRow) = uieditfield(platform.UndefinedMacrosGrid, ...
                    'ValueChangingFcn',@platform.MacroNameChanging, ...
                    'ValueChangedFcn',@platform.MacroNameChanged, ...
                    'Tag','identifier', ...
                    'Placeholder', platform.getMsgText('MacroIdentifierPlaceholder'));
                platform.UndefinedMacrosIds(nextRow).UserData.status = 'valid';
                platform.setRowColumn(platform.UndefinedMacrosIds(nextRow),nextRow,2);
                platform.UndefinedMacrosIds(nextRow).Value = undefinedMacrosIds{nextRow};
                if isempty(platform.UndefinedMacrosIds(nextRow).Value)
                    platform.UndefinedMacrosIds(nextRow).FontAngle = 'italic';
                end
                platform.UndefinedMacrosSubtractButtons(nextRow) = uiimage(platform.UndefinedMacrosGrid, ...
                    'ImageSource',platform.SubtractImageSource, ...
                    'ImageClickedFcn',@platform.subtractUndefinedMacrosRow,'UserData',nextRow);
                matlab.ui.control.internal.specifyIconID(platform.UndefinedMacrosSubtractButtons(nextRow),'minusUI',16);
                platform.setRowColumn(platform.UndefinedMacrosSubtractButtons(nextRow),nextRow,3);
                platform.UndefinedMacrosAddButtons(nextRow) = uiimage(platform.UndefinedMacrosGrid, ...
                    'ImageSource',platform.AddImageSource, ...
                    'ImageClickedFcn',@platform.addUndefinedMacrosRow,'UserData',nextRow);
                matlab.ui.control.internal.specifyIconID(platform.UndefinedMacrosAddButtons(nextRow),'plusUI',16);
                platform.setRowColumn(platform.UndefinedMacrosAddButtons(nextRow),nextRow,4);
            end
            if ~isempty(undefinedMacrosIds)
                platform.UndefinedMacrosFirstAddButton.Parent = [];
            end
            % Additional compiler flags
            for nextRow=1:numel(additionalCompilerValues)
                platform.AdditionalCompilerValues(nextRow) = uieditfield(platform.AdditionalCompilerGrid, ...
                    'ValueChangingFcn',@platform.MacroNameChanging, ...
                    'ValueChangedFcn',@platform.MacroNameChanged, ...
                    'Tag','value', ...
                    'Placeholder', platform.getMsgText('MacroFlagValuePlaceholder'));
                platform.AdditionalCompilerValues(nextRow).UserData.status = 'valid';
                platform.setRowColumn(platform.AdditionalCompilerValues(nextRow),nextRow,1);
                platform.AdditionalCompilerValues(nextRow).Value = additionalCompilerValues{nextRow};
                if isempty(platform.AdditionalCompilerValues(nextRow).Value)
                    platform.AdditionalCompilerValues(nextRow).FontAngle = 'italic';
                end
                platform.AdditionalCompilerSubtractButtons(nextRow) = uiimage(platform.AdditionalCompilerGrid, ...
                    'ImageSource',platform.SubtractImageSource, ...
                    'ImageClickedFcn',@platform.subtractAdditionalCompilerFlagsRow,'UserData',nextRow);
                matlab.ui.control.internal.specifyIconID(platform.AdditionalCompilerSubtractButtons(nextRow),'minusUI',16);
                platform.setRowColumn(platform.AdditionalCompilerSubtractButtons(nextRow),nextRow,2);
                platform.AdditionalCompilerAddButtons(nextRow) = uiimage(platform.AdditionalCompilerGrid, ...
                    'ImageSource',platform.AddImageSource, ...
                    'ImageClickedFcn',@platform.addAdditionalCompilerFlagsRow,'UserData',nextRow);
                matlab.ui.control.internal.specifyIconID(platform.AdditionalCompilerAddButtons(nextRow),'plusUI',16);
                platform.setRowColumn(platform.AdditionalCompilerAddButtons(nextRow),nextRow,3);
            end
            if ~isempty(additionalCompilerValues)
                platform.AdditionalCompilerFirstAddButton.Parent = [];
            end
            % Additional linker flags
            for nextRow=1:numel(additionalLinkerValues)
                platform.AdditionalLinkerValues(nextRow) = uieditfield(platform.AdditionalLinkerGrid, ...
                    'ValueChangingFcn',@platform.MacroNameChanging, ...
                    'ValueChangedFcn',@platform.MacroNameChanged, ...
                    'Tag','value', ...
                    'Placeholder', platform.getMsgText('MacroFlagValuePlaceholder'));
                platform.AdditionalLinkerValues(nextRow).UserData.status = 'valid';
                platform.setRowColumn(platform.AdditionalLinkerValues(nextRow),nextRow,1);
                platform.AdditionalLinkerValues(nextRow).Value = additionalLinkerValues{nextRow};
                if isempty(platform.AdditionalLinkerValues(nextRow).Value)
                    platform.AdditionalLinkerValues(nextRow).FontAngle = 'italic';
                end
                platform.AdditionalLinkerSubtractButtons(nextRow) = uiimage(platform.AdditionalLinkerGrid, ...
                    'ImageSource',platform.SubtractImageSource, ...
                    'ImageClickedFcn',@platform.subtractAdditionalLinkerFlagsRow,'UserData',nextRow);
                matlab.ui.control.internal.specifyIconID(platform.AdditionalLinkerSubtractButtons(nextRow),'minusUI',16);
                platform.setRowColumn(platform.AdditionalLinkerSubtractButtons(nextRow),nextRow,2);
                platform.AdditionalLinkerAddButtons(nextRow) = uiimage(platform.AdditionalLinkerGrid, ...
                    'ImageSource',platform.AddImageSource, ...
                    'ImageClickedFcn',@platform.addAdditionalLinkerFlagsRow,'UserData',nextRow);
                matlab.ui.control.internal.specifyIconID(platform.AdditionalLinkerAddButtons(nextRow),'plusUI',16);
                platform.setRowColumn(platform.AdditionalLinkerAddButtons(nextRow),nextRow,3);
            end
            if ~isempty(additionalLinkerValues)
                platform.AdditionalLinkerFirstAddButton.Parent = [];
            end
        end
        function added = addItem(~,listbox,item)
            added = false;
            if ~ismember(item,listbox.Items)
                listbox.Items{end+1} = item;
                added = true;
            end
        end
        function deleted = deleteItems(platform,listbox)
            [listbox.Items,deleted] = platform.deleteElements(listbox.Items,listbox.Value);
        end
        function [array,deleted] = deleteElements(~,array,elementsToRemove)
            indices = false(size(array));
            for idx=1:numel(elementsToRemove)
                indices = indices | strcmp(array,elementsToRemove{idx});
            end
            array(indices) = [];
            if any(indices)
                deleted = true;
            else
                deleted = false;
            end
        end
        function updateObjectPointerTooltip(platform,src,~)
            if nargin < 2
                dropdown = findobj(platform.DefineOptionsSection,'Tag','TreatObjectPointer', ...
                    '-isa','matlab.ui.control.DropDown');
            else
                dropdown = src;
            end
            if strcmp(dropdown.Value,'undefined')
                dropdown.Tooltip = platform.getMsgText('TreatObjectPointerUndefinedTooltip');
            else
                dropdown.Tooltip = platform.getMsgText('TreatObjectPointerScalarTooltip');
            end
        end
        function updateConstCharacterPointerTooltip(platform,src,~)
            if nargin < 2
                dropdown = findobj(platform.DefineOptionsSection,'Tag','TreatConstCharPointer', ...
                    '-isa','matlab.ui.control.DropDown');
            else
                dropdown = src;
            end
            if strcmp(dropdown.Value,'undefined')
                dropdown.Tooltip = platform.getMsgText('TreatConstCharPointerUndefinedTooltip');
            else
                dropdown.Tooltip = platform.getMsgText('TreatConstCharPointerNullTerminatedTooltip');
            end
        end
        function updateReturnCArraysTooltip(platform,src,~)
            if nargin < 2
                dropdown = findobj(platform.DefineOptionsSection,'Tag','ReturnCArrays', ...
                    '-isa','matlab.ui.control.DropDown');
            else
                dropdown = src;
            end
            if strcmp(dropdown.Value,'ClibArray')
                dropdown.Tooltip = platform.getMsgText('ReturnCArraysClibArrayTooltip');
            else
                dropdown.Tooltip = platform.getMsgText('ReturnCArraysMATLABArrayTooltip');
            end
        end
        function setRowColumn(~,widget,r,c)
            widget.Layout.Row = r;
            widget.Layout.Column = c;
        end
        function code = generateCodeForFiles(platform,files)
            code = '';
            if (length(files)>1)
                code = [code '['];
            end
            for idx = 1:length(files)-1
                % Check and substitute platform.libraryStartPathTag with actual
                % start path value
                fullfilename = platform.substituteLibraryStartPathValue(files{idx});
                code = [code '"' char(fullfilename) '"' platform.DelimiterCode];
                code = [code '       ']; % 2 tabs(4 spaces)
            end
            % Check and substitute platform.libraryStartPathTag with actual
            % start path value
            fullfilename = platform.substituteLibraryStartPathValue(files{end});
            code = [code '"' fullfilename '"'];
            if (length(files)>1)
                code = [code ']'];
            end
        end
        function code = generateCodeForMacros(~,macros)
            code = '';
            if (length(macros)>1)
                code = [code '['];
            end
            for idx = 1:length(macros)-1
                code = [code '"' macros{idx} '"'];
                code = [code ' ']; % 1 space
            end
            code = [code '"' macros{end} '"'];
            if (length(macros)>1)
                code = [code ']'];
            end
        end
        function code = generateCodeForPlatform(~,tag)
            code = '';
            % Add platform guard
            switch(tag)
                case 'win64'
                    code = [code 'if ispc' newline];
                case 'glnxa64'
                    code = [code 'if isunix' newline];
                case {'maci64','maca64'}
                    code = [code 'if ismac' newline];
            end
        end
        function setListbox(~,listbox,items)
            if ~isempty(items)
                listbox.Items = items;
            else
                listbox.Items = {};
            end
        end
        function path = substituteLibraryStartPathTag(platform, fullfilename)
            if platform.hasStartPath &&...
                strncmp(fullfilename, platform.LibraryStartPathSelection.Text, ...
                    strlength(platform.LibraryStartPathSelection.Text))
                fullfilename = fullfilename(strlength(platform.LibraryStartPathSelection.Text)+1:end);
                path = [platform.LibraryStartPathTag fullfilename];
            else
                path = fullfilename;
            end
        end
        function path = substituteLibraryStartPathValue(platform, fullfilename)
            if platform.hasStartPath &&...
                contains(fullfilename, platform.LibraryStartPathTag)
                fullfilename = fullfilename(strlength(platform.LibraryStartPathTag)+1:end);
                path = [char(platform.LibraryStartPathSelection.Text) fullfilename];
            else
                path = fullfilename;
            end
        end
        function s = getMsgText(~,msgId,varargin)
            % gets the appropriate char from the message catalog
            s = getString(message(['MATLAB:CPPUI:' msgId],varargin{:}));
        end
        function children = getTabGroupChildren(platform)
            % gets the TabGroup children
            children = platform.PlatformTab.Parent.Children;
        end
        function fig = getTabFigure(platform)
            % gets the TabGroup children
            fig = platform.PlatformTab.Parent.Parent.Parent;
        end
        function multiplatform = isMultiPlatform(platform)
            multiplatform = length(platform.getTabGroupChildren) > 1;
        end
        function firsttabenabled = isFirstPlatformTabEnabled(platform)
            firsttabenabled = platform.PlatformTab.Parent.SelectedTab == platform.PlatformTab.Parent.Children(1);
            firsttabenabled = firsttabenabled && strcmp(platform.PlatformTab.Parent.SelectedTab.Tag,computer("arch"));
        end
        function compilerHelpImageClicked(~,~,~)
            helpview('matlab','choose_cpp_compiler')
        end
    end
    methods (Access = protected)
        function setup(platform)
            platform.initialSelectedCompiler = mex.getCompilerConfigurations('C++','Selected');
            platform.createComponents;
            platform.setControlsToDefault;
            platform.updateControls;
            if isempty(platform.initialSelectedCompiler)
                platform.disablePlatformWidgets;
            end
        end
    end
    methods
        function [code, outputs] = generateCode(~,platforms)
            outputs = [];
            vars = {'interfaceGenerationFiles'};
           
            hasIncludePath = false;
            hasLibraries = false;
            hasSupportingSourceFiles = false;
            hasDefinedMacros = false;
            hasUndefinedMacros = false;
            hasAdditionalCompilerFlags = false;
            hasAdditionalLinkerFlags = false;

            code = ['% Generate library definition' newline newline];
            code = [code '% Setup platform specific variables' newline];
            numPlatforms = length(platforms);
            for platformIdx = 1:numPlatforms
                % set the platform
                platform = platforms(platformIdx);

                % Begin platform specific guard
                code = [code platform.generateCodeForPlatform(platform.PlatformTab.Tag)];
    
                if ~any(isvalid(platform.InterfaceFilesListBox))
                    code = [code '    error(''' platform.getMsgText('InterfaceGenerationFilesGenerateCode') ''')' newline 'end' newline];
                    if length(platforms) == 1
                        return;
                    else
                        continue;
                    end
                end
    
                if ~any(isvalid(platform.IncludePathListBox)) && ~platform.IncludePathNotRequiredCheckBox.Value
                    code = [code '    error(''' platform.getMsgText('IncludePathGenerateCode') ''')' newline 'end' newline];
                    if length(platforms) == 1
                        return;
                    else
                        continue;
                    end
                end

                switch(platform.LibraryTypeButtonGroup.SelectedObject.Tag)
                case 'HeaderAndLibrary'
                    if ~any(isvalid(platform.LibrariesListBox))
                        code = [code '    error("' platform.getMsgText('LibrariesGenerateCode',platform.getMsgText('HeaderAndLibraryLabel')) '")' newline 'end' newline];
                        if length(platforms) == 1
                            return;
                        else
                            continue;
                        end
                    end
                case 'HeaderAndSource'
                    if ~any(isvalid(platform.SourceFilesListBox))
                        code = [code '    error("' platform.getMsgText('SourceFilesGenerateCode',platform.getMsgText('HeaderAndSourceLabel')) '")' newline 'end' newline];
                        if length(platforms) == 1
                            return;
                        else
                            continue;
                        end
                    end
                end
    
                if isempty(platform.CompilerDropDown.Value)
                    code = [code '    error(''Select C++ compiler'')' newline 'end' newline];
                    if length(platforms) == 1
                        return;
                    else
                        continue;
                    end
                end
    
                if isempty(platform.PackageNameEditField.Value)
                    code = [code '    error(''Specify library interface name'')' newline 'end' newline];
                    if length(platforms) == 1
                        return;
                    else
                        continue;
                    end
                end
    
                status = platform.showDefinitionFileOrPackageNameExists;
                if status == platform.DefinitionFileExistsStatus
                    mFileName = ['define' platform.PackageNameEditField.Value '.m'];
                    % Return an error about existing definition
                    % file and information about how to proceed
                    defFileExistsMsg = platform.getMsgText('DefinitionFileExistsCode',mFileName);
                    if platform.isMultiPlatform
                        defFileExistsMsg = platform.getMsgText('DefinitionFileExistsMultiPlatformCode',mFileName);
                    end
                    code = [code '`    error`(''' defFileExistsMsg ''')' newline 'end' newline];
                    if length(platforms) == 1
                        return;
                    else
                        continue;
                    end
                elseif status == platform.PackageIsLoadedStatus
                    code = [code '    error(''' platform.getMsgText('PackageNameInUseCode',platform.PackageNameEditField.Value) ''')' newline 'end' newline];
                    if length(platforms) == 1
                        return;
                    else
                        continue;
                    end
                end

                % setup compiler
                code = [code '    % Set up compiler'];
                idx = find(cellfun(@(x) strcmp(x,platform.CompilerDropDown.Value),platform.CompilerDropDown.ItemsData, 'UniformOutput', 1));
                compilerName = platform.CompilerDropDown.Items(idx);
                code = [code ' - ' compilerName{:}];
                code = [code newline '    mex -setup:' platform.CompilerDropDown.Value ';'];
                code = [code newline];

                % setup variables
                code = [code newline '    `interfaceGenerationFiles` = '];
                code = [code platform.generateCodeForFiles(platform.InterfaceFilesListBox.Items) ';'];
        
                if isvalid(platform.IncludePathListBox)
                    hasIncludePath = true;
                    vars{end+1} = 'includePath';
                    code = [code newline '    `includePath` = '];
                    code = [code platform.generateCodeForFiles(platform.IncludePathListBox.Items) ';'];
                end
    
                switch(platform.LibraryTypeButtonGroup.SelectedObject.Tag)
                    case 'HeaderOnly'
                        % nothing additional to generate
                    case 'HeaderAndLibrary'
                        hasLibraries = true;
                        vars{end+1} = 'libraries';
                        code = [code newline '    `libraries` = '];
                        code = [code platform.generateCodeForFiles(platform.LibrariesListBox.Items) ';'];
                    case 'HeaderAndSource'
                        hasSupportingSourceFiles = true;
                        vars{end+1} = 'supportingSourceFiles';
                        code = [code newline '    `supportingSourceFiles` = '];
                        code = [code platform.generateCodeForFiles(platform.SourceFilesListBox.Items) ';'];
                    case 'Custom'
                        if isvalid(platform.LibrariesListBox)
                            hasLibraries = true;
                            vars{end+1} = 'libraries';
                            code = [code newline '    `libraries` = '];
                            code = [code platform.generateCodeForFiles(platform.LibrariesListBox.Items) ';'];
                        end
                        if isvalid(platform.SourceFilesListBox)
                            hasSupportingSourceFiles = true;
                            vars{end+1} = 'supportingSourceFiles';
                            code = [code newline '    `supportingSourceFiles` = '];
                            code = [code platform.generateCodeForFiles(platform.SourceFilesListBox.Items) ';'];
                        end
                end

                definedMacros = [];
                if ~isempty(platform.DefinedMacrosIds)
                    definedMacrosIds = {platform.DefinedMacrosIds.Value};
                    definedMacrosValues = {platform.DefinedMacrosValues.Value};
                    nonemptyRows = cellfun(@(x)(~isempty(x)),definedMacrosIds);
                    definedMacrosIds = definedMacrosIds(nonemptyRows);
                    definedMacrosValues = definedMacrosValues(nonemptyRows);
                    definedMacros = strcat(definedMacrosIds,'=',definedMacrosValues);
                    % Remove '=' at the end for identifiers with empty values
                    definedMacros = extractBefore(definedMacros,regexpPattern('=?$'));
                    definedMacros = unique(definedMacros,'stable');
                end
                if ~isempty(definedMacros)
                    hasDefinedMacros = true;
                    definedMacros = platform.generateCodeForMacros(definedMacros);
                    vars{end+1} = 'definedMacros';
                    code = [code newline '    `definedMacros` = '];
                    code = [code definedMacros ';'];
                end

                undefinedMacrosIds = [];
                if ~isempty(platform.UndefinedMacrosIds)
                    undefinedMacrosIds = {platform.UndefinedMacrosIds.Value};
                    undefinedMacrosIds = undefinedMacrosIds(~cellfun(@isempty,undefinedMacrosIds));
                    undefinedMacrosIds = unique(undefinedMacrosIds,'stable');
                end
                if ~isempty(undefinedMacrosIds)
                    hasUndefinedMacros = true;
                    undefinedMacrosIds = platform.generateCodeForMacros(undefinedMacrosIds);
                    vars{end+1} = 'undefinedMacros';
                    code = [code newline '    `undefinedMacros` = '];
                    code = [code undefinedMacrosIds ';'];
                end

                additionalCompilerFlags = [];
                if ~isempty(platform.AdditionalCompilerValues)
                    compilerValues = {platform.AdditionalCompilerValues.Value};
                    nonemptyRows = cellfun(@(x)(~isempty(x)),compilerValues);
                    compilerValues = compilerValues(nonemptyRows);
                    additionalCompilerFlags = unique(compilerValues,'stable');
                end
                if ~isempty(additionalCompilerFlags)
                    hasAdditionalCompilerFlags = true;
                    additionalCompilerFlags = platform.generateCodeForMacros(additionalCompilerFlags);
                    vars{end+1} = 'additionalCompilerFlags';
                    code = [code newline '    `additionalCompilerFlags` = '];
                    code = [code additionalCompilerFlags ';'];
                end

                additionalLinkerFlags = [];
                if ~isempty(platform.AdditionalLinkerValues)
                    linkerValues = {platform.AdditionalLinkerValues.Value};
                    nonemptyRows = cellfun(@(x)(~isempty(x)),linkerValues);
                    linkerValues = linkerValues(nonemptyRows);
                    additionalLinkerFlags = unique(linkerValues,'stable');
                end
                if ~isempty(additionalLinkerFlags)
                    hasAdditionalLinkerFlags = true;
                    additionalLinkerFlags = platform.generateCodeForMacros(additionalLinkerFlags);
                    vars{end+1} = 'additionalLinkerFlags';
                    code = [code newline '    `additionalLinkerFlags` = '];
                    code = [code additionalLinkerFlags ';'];
                end

                vars{end+1} = 'outputFolder';
                code = [code newline '    `outputFolder` = '];
                code = [code '"' platform.OutputFolderSelection.Text '";'];

                vars{end+1} = 'overwriteExistingDefinitionFiles';
                code = [code newline '    `overwriteExistingDefinitionFiles` = '];
                if platform.OverwriteFilesCheckBox.Value
                    code = [code 'true;'];
                else
                    code = [code 'false;'];
                end

                % Handle platform specific guards
                if platformIdx == numPlatforms
                    % Add matching end for the last platform
                    code = [code newline 'else' newline];
                    code = [code '    error(''' platform.getMsgText('PlatformNotConfiguredCode') ''')'];
                    code = [code newline 'end' newline];
                else
                    % This else becomes elseif when not the last platform
                    code = [code newline 'else'];
                end
            end

            % Display message with link to restore the library defintion
            % workspace variable when it doesn't exist and the definition
            % file is available but overwrite is not selected
            code = [code newline '% Check if the library definition exists'];
            mFileName = ['define' platform.PackageNameEditField.Value];
            code = [code newline 'if ~`overwriteExistingDefinitionFiles` && isfile(fullfile(`outputFolder`,''' mFileName '.m'')) && evalin(''base'',''exist(''''libraryDefinitionFromTask'''',''''var'''') == 0'')'];
            code = [code newline '    `disp`(''' platform.getMsgText('RestoreLibraryDefinitionMsg',[mFileName '.m']) ''');'];
            restoreDefinitionLnkCode = platform.getMsgText('RestoreLibraryDefinition_link',mFileName,platform.getMsgText('RestoreLibraryDefinition_linkname'));
            code = [code newline '    `disp`(''' restoreDefinitionLnkCode ''');'];
            code = [code newline 'end' newline];

            code = [code newline '% Generate definition file for C++ library'];

            code = [code newline 'clibgen.generateLibraryDefinition(`interfaceGenerationFiles`'];
            if hasIncludePath
                code = [code platform.DelimiterCode];
                code = [code '    "IncludePath",`includePath`'];
            end
            if hasLibraries
                code = [code platform.DelimiterCode];
                code = [code '    "Libraries",`libraries`'];
            end
            if hasSupportingSourceFiles
                code = [code platform.DelimiterCode];
                code = [code '    "SupportingSourceFiles",`supportingSourceFiles`'];
            end
            code = [code platform.DelimiterCode];
            code = [code '    "OutputFolder",`outputFolder`'];
            code = [code platform.DelimiterCode];
            code = [code '    "InterfaceName",'];
            code = [code '"' platform.PackageNameEditField.Value '"'];
            code = [code platform.DelimiterCode];
            code = [code '    "OverwriteExistingDefinitionFiles",`overwriteExistingDefinitionFiles`'];

            if platform.CLinkageCheckBox.Value
                code = [code platform.DelimiterCode];
                code = [code '    "CLinkage",'];
                code = [code 'true'];
            end

            if hasDefinedMacros
                code = [code platform.DelimiterCode];
                code = [code '    "DefinedMacros",`definedMacros`'];
            end

            if hasUndefinedMacros
                code = [code platform.DelimiterCode];
                code = [code '    "UndefinedMacros",`undefinedMacros`'];
            end

            if hasAdditionalCompilerFlags
                code = [code platform.DelimiterCode];
                code = [code '    "AdditionalCompilerFlags",`additionalCompilerFlags`'];
            end

            if hasAdditionalLinkerFlags
                code = [code platform.DelimiterCode];
                code = [code '    "AdditionalLinkerFlags",`additionalLinkerFlags`'];
            end

            if strcmp(platform.TreatObjPtrDropDown.Value,'scalar')
                code = [code platform.DelimiterCode];
                code = [code '    "TreatObjectPointerAsScalar",'];
                code = [code 'true'];
            end
            if strcmp(platform.TreatConstCharPtrDropDown.Value,'nullTerminated')
                code = [code platform.DelimiterCode];
                code = [code '    "TreatConstCharPointerAsCString",'];
                code = [code 'true'];
            end
            if strcmp(platform.ReturnCArraysDropDown.Value,'MATLABArray')
                code = [code platform.DelimiterCode];
                code = [code '    "ReturnCArrays",'];
                code = [code 'false'];
            end
            if ~platform.GenerateDocCheckBox.Value
                code = [code platform.DelimiterCode];
                code = [code '    "GenerateDocumentationFromHeaderFiles",'];
                code = [code 'false'];
            end
            if platform.VerboseCheckBox.Value
                code = [code platform.DelimiterCode];
                code = [code '    "Verbose",'];
                code = [code 'true'];
            end
            code = [code ');' newline];

            % Output the library definition object
            % NOTE: The output of live task is empty value
            %outputs = {'libDefFromTask'};
            code = [code newline '% Create the library definition object' newline];
            code = [code 'addpath(`outputFolder`);' newline];
            code = [code '`libraryDefinitionFromTask` = feval("define' platform.PackageNameEditField.Value '");' newline];

            if platform.SummaryCheckBox.Value
                code = [code newline '% Show available constructs'];
                code = [code newline 'summary(`libraryDefinitionFromTask`);' newline];
            end

            % Capture clear call for temporary variables
            clearVars = ['clear(''' strjoin(unique(vars,'stable'),''',''') ''');'];

            code = [code newline '% Clear temporary variables'];
            code = [code newline clearVars];
        end
        function summary = get.Summary(platform)
            if ~isempty(platform.PackageNameEditField.Value)
                summary = platform.getMsgText('TaskSummaryDefault',[' `' platform.PackageNameEditField.Value '`']);
            else
                summary = platform.getMsgText('TaskSummaryDefault','');
            end

            if ~any(isvalid(platform.InterfaceFilesListBox))
                return;
            end

            switch(platform.LibraryTypeButtonGroup.SelectedObject.Tag)
            case 'HeaderAndLibrary'
                if ~any(isvalid(platform.LibrariesListBox))
                    return;
                end
            case 'HeaderAndSource'
                if ~any(isvalid(platform.SourceFilesListBox))
                    return;
                end
            end

            if isempty(platform.CompilerDropDown.Value)
                  return;
            end
            if isempty(platform.PackageNameEditField.Value)
                return;
            end
            if platform.PackageIsLoadedStatus == platform.showDefinitionFileOrPackageNameExists
                return;
            end
            summary =  platform.getMsgText('TaskSummaryComplete',platform.PackageNameEditField.Value);
        end
        function platformState = getStateForPlatform(platform, currentPlatform)
            state = struct;
            state.(currentPlatform).CompilerDropDownValue = platform.CompilerDropDown.Value;
            state.(currentPlatform).CompilerDropDownLongName = {};
            idx = find(cellfun(@(x) strcmp(x,platform.CompilerDropDown.Value),platform.CompilerDropDown.ItemsData, 'UniformOutput', 1));
            % Check for no compiler
            if (~isempty(idx))
                compilerName = platform.CompilerDropDown.Items(idx);
                state.(currentPlatform).CompilerDropDownLongName = compilerName{:};
            end
            state.(currentPlatform).PackageNameEditFieldValue = platform.PackageNameEditField.Value;
            state.(currentPlatform).OutputFolderSelectionText = platform.OutputFolderSelection.Text;
            state.(currentPlatform).OverwriteFilesCheckBox = platform.OverwriteFilesCheckBox.Value;
            state.(currentPlatform).LibraryType = platform.LibraryTypeButtonGroup.SelectedObject.Tag;
            state.(currentPlatform).LibraryStartPathSelectionText = platform.LibraryStartPathSelection.Text;
            if strcmp(state.(currentPlatform).LibraryType,'Custom')
                state.(currentPlatform).InterfaceHeaderFiles = platform.InterfaceHeaderFiles;
                state.(currentPlatform).InterfaceSourceFiles = platform.InterfaceSourceFiles;
            else
                state.(currentPlatform).InterfaceHeaderFiles = platform.InterfaceHeaderFiles;
                state.(currentPlatform).InterfaceSourceFiles = {};
            end
            state.(currentPlatform).IncludePath = platform.IncludePath;
            if isvalid(platform.IncludePathNotRequiredCheckBox)
                state.(currentPlatform).IncludePathNotRequiredCheckBoxValue = platform.IncludePathNotRequiredCheckBox.Value;
            end
            if ispc
                compilerName = platform.CompilerDropDown.Value;
                if startsWith(compilerName,platform.MicrosoftCppCompilersShortName)
                    state.(currentPlatform).DLLFiles = platform.DLLFiles;
                    state.(currentPlatform).Libraries = platform.Libraries;
                else
                    state.(currentPlatform).DLLFiles = {};
                    state.(currentPlatform).Libraries = platform.Libraries;
                end
            else
                state.(currentPlatform).DLLFiles = {};
                state.(currentPlatform).Libraries = platform.Libraries;
            end
            state.(currentPlatform).SourceFiles = platform.SourceFiles;

            state.(currentPlatform).CLinkageCheckBoxValue = platform.CLinkageCheckBox.Value;
            state.(currentPlatform).DefinedMacrosIds = {};
            state.(currentPlatform).DefinedMacrosValues = {};
            if ~isempty(platform.DefinedMacrosIds)
                 state.(currentPlatform).DefinedMacrosIds = {platform.DefinedMacrosIds.Value};
                 state.(currentPlatform).DefinedMacrosValues = {platform.DefinedMacrosValues.Value};
            end
            state.(currentPlatform).UndefinedMacrosIds = {};
            if ~isempty(platform.UndefinedMacrosIds)
                state.(currentPlatform).UndefinedMacrosIds = {platform.UndefinedMacrosIds.Value};
            end
            state.(currentPlatform).AdditionalCompilerValues = {};
            if ~isempty(platform.AdditionalCompilerValues)
                 state.(currentPlatform).AdditionalCompilerValues = {platform.AdditionalCompilerValues.Value};
            end
            state.(currentPlatform).AdditionalLinkerValues = {};
            if ~isempty(platform.AdditionalLinkerValues)
                state.(currentPlatform).AdditionalLinkerValues = {platform.AdditionalLinkerValues.Value};
            end

            state.(currentPlatform).ReturnCArraysValue = platform.ReturnCArraysDropDown.Value;
            state.(currentPlatform).TreatConstCharPtrValue = platform.TreatConstCharPtrDropDown.Value;
            state.(currentPlatform).TreatObjPtrValue = platform.TreatObjPtrDropDown.Value;
            state.(currentPlatform).GenerateDocCheckBox = platform.GenerateDocCheckBox.Value;
            state.(currentPlatform).VerboseCheckBox = platform.VerboseCheckBox.Value;
            state.(currentPlatform).SummaryCheckBox = platform.SummaryCheckBox.Value;
            platformState = state.(currentPlatform);
        end
        function setStateForPlatform(platform, state)
            % Classify the stored compiler from state into one of these:
            if ismember(state.CompilerDropDownValue,platform.CompilerDropDown.ItemsData)
                % Compiler is member of the current platform dropdown
                % - Select the stored compiler
               platform.CompilerDropDown.Value = state.CompilerDropDownValue;
            elseif ~strcmp(platform.PlatformTab.Tag,computer("arch"))
                % Compiler is disabled tab's compiler selection
                % - Set the Items, ItemsData for the stored compiler only
                % - Select the stored compiler
                platform.CompilerDropDown.Items = {state.CompilerDropDownLongName};
                platform.CompilerDropDown.ItemsData = {state.CompilerDropDownValue};
                platform.CompilerDropDown.Value = {state.CompilerDropDownValue};
            else
                % Compiler is non-member of the current platform dropdown
                % - Append the Items, ItemsData for the stored compiler
                platform.CompilerDropDown.Items{end+1} = state.CompilerDropDownLongName;
                platform.CompilerDropDown.ItemsData{end+1} = state.CompilerDropDownValue;
                platform.CompilerDropDown.Value = state.CompilerDropDownValue;
            end
            platform.PackageNameEditField.Value = state.PackageNameEditFieldValue;
            platform.OutputFolderSelection.Text = state.OutputFolderSelectionText;
            platform.OverwriteFilesCheckBox.Value = state.OverwriteFilesCheckBox;
            libraryType = state.LibraryType;
            libraryTypeControl = findobj(platform.LibraryTypeButtonGroup,'Tag',libraryType);
            platform.LibraryTypeButtonGroup.SelectedObject = libraryTypeControl;
            platform.LibraryStartPathSelection.Text = state.LibraryStartPathSelectionText;
            platform.InterfaceHeaderFiles = state.InterfaceHeaderFiles;
            platform.InterfaceSourceFiles = state.InterfaceSourceFiles;
            platform.IncludePath = state.IncludePath;
            if isfield(state, 'IncludePathNotRequiredCheckBoxValue')
                platform.IncludePathNotRequiredCheckBox.Value = state.IncludePathNotRequiredCheckBoxValue;
            end
            platform.DLLFiles = state.DLLFiles;
            platform.Libraries = state.Libraries;
            platform.SourceFiles = state.SourceFiles;
            platform.CLinkageCheckBox.Value = state.CLinkageCheckBoxValue;
            platform.setBuildOptionalControls(state.DefinedMacrosIds,state.DefinedMacrosValues,...
                state.UndefinedMacrosIds,state.AdditionalCompilerValues,state.AdditionalLinkerValues);
            platform.ReturnCArraysDropDown.Value = state.ReturnCArraysValue;
            platform.TreatConstCharPtrDropDown.Value = state.TreatConstCharPtrValue;
            platform.TreatObjPtrDropDown.Value = state.TreatObjPtrValue;
            platform.GenerateDocCheckBox.Value = state.GenerateDocCheckBox;
            platform.VerboseCheckBox.Value = state.VerboseCheckBox;
            platform.SummaryCheckBox.Value = state.SummaryCheckBox;
            % update controls
            platform.updateControls;
        end
        function disablePlatformWidgets(platform)
            disable = 'off';
            platform.CompilerDropDown.Enable = disable;
            platform.PackageNameEditField.Enable = disable;
            platform.OutputFolderSelection.Enable = disable;
            platform.OutputFolderBrowseButton.Enable = disable;
            platform.OverwriteFilesCheckBox.Enable = disable;
            platform.LibraryTypeButtonGroup.Enable = disable;
            platform.LibraryStartPathSelection.Enable = disable;
            platform.LibraryStartPathBrowseButton.Enable = disable;
            platform.LibraryStartPathRemoveButton.Enable = disable;
            platform.enableFilesGrid(platform.InterfaceFilesGrid ,disable);
            platform.enableFilesGrid(platform.IncludePathGrid,disable);
            if isvalid(platform.IncludePathNotRequiredCheckBox)
                platform.IncludePathNotRequiredCheckBox.Enable = disable;
            end
            platform.enableFilesGrid(platform.LibrariesGrid,disable);
            platform.enableFilesGrid(platform.SourceFilesGrid,disable);
            platform.CLinkageCheckBox.Enable = disable;
            if ~isempty(platform.DefinedMacrosFirstAddButton)
                platform.DefinedMacrosFirstAddButton.Enable = disable;
            end
            if ~isempty(platform.DefinedMacrosIds)
                for idx=1:length(platform.DefinedMacrosIds)
                    platform.DefinedMacrosIds(idx).Enable = disable;
                end
            end
            if ~isempty(platform.DefinedMacrosValues)
                for idx=1:length(platform.DefinedMacrosValues)
                    platform.DefinedMacrosValues(idx).Enable = disable;
                end
            end
            if ~isempty(platform.DefinedMacrosAddButtons)
                for idx=1:length(platform.DefinedMacrosAddButtons)
                    platform.DefinedMacrosAddButtons(idx).Enable = disable;
                end
            end
            if ~isempty(platform.DefinedMacrosSubtractButtons)
                for idx=1:length(platform.DefinedMacrosSubtractButtons)
                    platform.DefinedMacrosSubtractButtons(idx).Enable = disable;
                end
            end
            if ~isempty(platform.UndefinedMacrosFirstAddButton)
                platform.UndefinedMacrosFirstAddButton.Enable = disable;
            end
            if ~isempty(platform.UndefinedMacrosIds)
                for idx=1:length(platform.UndefinedMacrosIds)
                    platform.UndefinedMacrosIds(idx).Enable = disable;
                end
            end
            if ~isempty(platform.UndefinedMacrosAddButtons)
                for idx=1:length(platform.UndefinedMacrosAddButtons)
                    platform.UndefinedMacrosAddButtons(idx).Enable = disable;
                end
            end
            if ~isempty(platform.UndefinedMacrosSubtractButtons)
                for idx=1:length(platform.UndefinedMacrosSubtractButtons)
                    platform.UndefinedMacrosSubtractButtons(idx).Enable = disable;
                end
            end
            if ~isempty(platform.AdditionalCompilerFirstAddButton)
                platform.AdditionalCompilerFirstAddButton.Enable = disable;
            end
            if ~isempty(platform.AdditionalCompilerValues)
                for idx=1:length(platform.AdditionalCompilerValues)
                    platform.AdditionalCompilerValues(idx).Enable = disable;
                end
            end
            if ~isempty(platform.AdditionalLinkerValues)
                for idx=1:length(platform.AdditionalLinkerValues)
                    platform.AdditionalLinkerValues(idx).Enable = disable;
                end
            end
            if ~isempty(platform.AdditionalCompilerAddButtons)
                for idx=1:length(platform.AdditionalCompilerAddButtons)
                    platform.AdditionalCompilerAddButtons(idx).Enable = disable;
                end
            end
            if ~isempty(platform.AdditionalCompilerSubtractButtons)
                for idx=1:length(platform.AdditionalCompilerSubtractButtons)
                    platform.AdditionalCompilerSubtractButtons(idx).Enable = disable;
                end
            end
            if ~isempty(platform.AdditionalLinkerFirstAddButton)
                platform.AdditionalLinkerFirstAddButton.Enable = disable;
            end
            if ~isempty(platform.AdditionalLinkerAddButtons)
                for idx=1:length(platform.AdditionalLinkerAddButtons)
                    platform.AdditionalLinkerAddButtons(idx).Enable = disable;
                end
            end
            if ~isempty(platform.AdditionalLinkerSubtractButtons)
                for idx=1:length(platform.AdditionalLinkerSubtractButtons)
                    platform.AdditionalLinkerSubtractButtons(idx).Enable = disable;
                end
            end
            platform.TreatObjPtrDropDown.Enable = disable;
            platform.TreatConstCharPtrDropDown.Enable = disable;
            platform.ReturnCArraysDropDown.Enable = disable;
            platform.GenerateDocCheckBox.Enable = disable;
            platform.SummaryCheckBox.Enable = disable;
            platform.VerboseCheckBox.Enable = disable;
        end
        function data = getPortableData(platform)
            data = struct;
            data.PackageNameEditFieldValue = platform.PackageNameEditField.Value;
            data.LibraryType = platform.LibraryTypeButtonGroup.SelectedObject.Tag;
            if platform.hasStartPath
                data.LibraryStartPathSelectionText = platform.getMsgText('SelectFileOrPathRequiredClick');
                if strcmp(data.LibraryType,'Custom')
                    data.InterfaceHeaderFiles = platform.InterfaceHeaderFiles;
                    data.InterfaceSourceFiles = platform.InterfaceSourceFiles;
                else
                    data.InterfaceHeaderFiles = platform.InterfaceHeaderFiles;
                    data.InterfaceSourceFiles = {};
                end
                data.IncludePath = platform.IncludePath;
                data.SourceFiles = platform.SourceFiles;
            else
                data.LibraryStartPathSelectionText = platform.getMsgText('SelectFileOrPathOptional');
            end
            if isvalid(platform.IncludePathNotRequiredCheckBox)
                data.IncludePathNotRequiredCheckBoxValue = platform.IncludePathNotRequiredCheckBox.Value;
            end
            data.CLinkageCheckBoxValue = platform.CLinkageCheckBox.Value;
            data.ReturnCArraysValue = platform.ReturnCArraysDropDown.Value;
            data.TreatConstCharPtrValue = platform.TreatConstCharPtrDropDown.Value;
            data.TreatObjPtrValue = platform.TreatObjPtrDropDown.Value;
            data.GenerateDocCheckBox = platform.GenerateDocCheckBox.Value;
            data.VerboseCheckBox = platform.VerboseCheckBox.Value;
            data.SummaryCheckBox = platform.SummaryCheckBox.Value;
        end
        function setPortableData(platform, data)
            platform.PackageNameEditField.Value = data.PackageNameEditFieldValue;
            libraryType = data.LibraryType;
            libraryTypeControl = findobj(platform.LibraryTypeButtonGroup,'Tag',libraryType);
            platform.LibraryTypeButtonGroup.SelectedObject = libraryTypeControl;
            platform.LibraryStartPathSelection.Text = data.LibraryStartPathSelectionText;
            if strcmp(platform.LibraryStartPathSelection.Text,platform.getMsgText('SelectFileOrPathRequiredClick'))
                platform.InterfaceHeaderFiles = strrep(data.InterfaceHeaderFiles,'\','/');
                platform.InterfaceSourceFiles = strrep(data.InterfaceSourceFiles,'\','/');
                platform.IncludePath = strrep(data.IncludePath,'\','/');
                platform.SourceFiles = strrep(data.SourceFiles,'\','/');
            end
            if isfield(data, 'IncludePathNotRequiredCheckBoxValue')
                platform.IncludePathNotRequiredCheckBox.Value = data.IncludePathNotRequiredCheckBoxValue;
            end
            platform.OutputFolderSelection.Text = platform.getMsgText('SelectFileOrPathRequiredClick');
            platform.OutputFolderSelection.Tooltip = platform.OutputFolderSelection.Text;
            platform.CLinkageCheckBox.Value = data.CLinkageCheckBoxValue;
            platform.ReturnCArraysDropDown.Value = data.ReturnCArraysValue;
            platform.TreatConstCharPtrDropDown.Value = data.TreatConstCharPtrValue;
            platform.TreatObjPtrDropDown.Value = data.TreatObjPtrValue;
            platform.GenerateDocCheckBox.Value = data.GenerateDocCheckBox;
            platform.VerboseCheckBox.Value = data.VerboseCheckBox;
            platform.SummaryCheckBox.Value = data.SummaryCheckBox;
            % update controls
            platform.updateControls;
        end
        function reset(platform)
            platform.setControlsToDefault;
            platform.updateControls;
        end
    end
end

% LocalWords:  MSVCPP startpath CLinkage CArrays Clib uiimage uilabel hxx
% LocalWords:  cxx dylib uigridlayout Multiselect maci maca CString
