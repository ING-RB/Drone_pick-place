% This class is unsupported and might change or be removed without notice in a
% future version.

% This class provides common functionality for importing hierarchical
% scientific file formats like netCDF and HDF5.

% Nodes in the checkbox ui tree contain this information
% NodeData struct:
%   NodeData.ID      % Unique number representing the order the node was
%                      added in the tree. Can serve as an index into
%                      task.treeNodes and task.treeNodesText
%   NodeData.Type    % enum value, e.g. Attribute or GroupsCluster
%   NodeData.Label   % stores text for metadata preview panel
%   NodeData.LocationPath % e.g. /instrument_state/description
%                           only relevant for Attribute, Group,
%                           DatasetOrVariable and DatasetOrVariableWithAtts
%                           nodes
%   NodeData.Dimensions  % stores info struct about variable's dimensions
%                          (only relevant for DatasetOrVariable nodes).
%                          Used for creating subsetting UIs for variables.

% Copyright 2023 The MathWorks, Inc.

classdef HierarchicalSciImportProvider < matlab.internal.importdata.ImportOptionsProvider

    % Abstract properties, concrete subclasses must redefine them
    properties (Abstract)

        % message ID to create label for variable or dataset cluster nodes 
        % (e.g., "Variables (5)" or "Datasets (3)")
        datasetOrVariableClusterNodeMessageID (1,1) string

        % message ID for the header for the subsetting options accordion
        % panel
        subsettingOptionsHeaderMessageID (1,1) string

        % message ID for the high-level code generation radio button
        % tooltip
        highLevelTooltipMessageID (1,1) string

        % message ID for the low-level code generation radio button
        % tooltip
        lowLevelTooltipMessageID (1,1) string

        % message ID for the search button tooltip
        searchTooltipMessageID (1,1) string

        % message ID for the code comment about creating the structure
        createStructureCommentMessageID (1,1) string

        % part of the struct path that should either be Variables or
        % Datasets (e.g., in "example.Groups(1).Variables(2).Attributes(1)"
        % or "example.Groups(1).Datasets(2).Attributes(1)")
        datasetOrVariableStructPathField (1,1) string

        % high- or low-level code generator strategy
        nodeImportCodeGeneratorStrategy (1,1) matlab.internal.importsci.AbstractNodeImportCodeGenerator

        % An object that helps manage the nested-ness level of struct paths
        % by generating code to store substructures in temporary variables
        longStructPathWrangler (1,1) matlab.internal.importsci.LongStructPathWrangler
    end

    properties (Hidden)

        % contains output of ncinfo or h5info
        fileInfo = struct([]);

        % Select Data accordion panel and grid layout inside it
        % (contains search, tree, and metadata label)
        selectDataPanel matlab.ui.container.internal.AccordionPanel
        selectDataGrid matlab.ui.container.GridLayout

        % ui check box tree that represents the file structure
        tree matlab.ui.container.CheckBoxTree

        % label that shows info about each selected node
        metadataLabel matlab.ui.control.Label

        % --- Search-related properties

        % array of all Nodes
        treeNodes = matlab.ui.container.TreeNode.empty();
        % string array with all Node names (same size as treeNodes)
        treeNodesText = string.empty();
        % logical values indicating which nodes match the search term
        matchInds = logical.empty();
        % index of the matched node currrently being displayed out of all
        % found matches (e.g. 2 in 2/20 matches)
        dispCurrentMatchInd = 0;

        % edit field where search query is entered
        searchEditField matlab.ui.control.EditField
        % button that initiates search
        searchButton matlab.ui.control.Button
        % button that resets/stops search
        resetButton matlab.ui.control.Button
        % "down" button to move to next search result
        nextMatchButton matlab.ui.control.Button
        % "up" button to move to previous search result
        prevMatchButton matlab.ui.control.Button
        % label that displays the matches (e.g. "2/20")
        matchesLabel matlab.ui.control.Label

        % Two search grid UI layouts:
        %   - searchGridBeforeLayout has an empty edit field and is ready
        %   for the search query to be entered
        %   - searchGridAfterLayout is after the search was completed and
        %   user can navigate through the results using up and down buttons
        %   or reset the search with reset button
        searchGridBeforeLayout matlab.ui.container.GridLayout
        searchGridAfterLayout matlab.ui.container.GridLayout

        % --- Code-Generation-related properties

        % Accordion Panel for choosing code generation type
        codegenTypePanel matlab.ui.container.internal.AccordionPanel

        % radio buttons to choose the code generation type
        highlevelcodeButton matlab.ui.control.RadioButton
        lowlevelcodeButton matlab.ui.control.RadioButton

        % When generating code we need to generate struct paths (e.g.
        % "file1.Variables(2).Attributes(4)") for each importable node. To
        % do this, we need to know which index each node corresponds to at
        % that level of the struct (e.g. attribute node at location
        % "/instrument_state/description" corresponds to index 4 and to the
        % struct path "file1.Variables(2).Attributes(4)"). This mapping
        % between node location and its index is stored in
        % structPathIndicesDict, i.e.:
        %     "/instrument_state/description" -> 4
        % It is configured as an empty string->double dictionary
        structPathIndicesDict = dictionary(string([]),double([]));

        % To figure out these indices for nodes, we also need to know how
        % many elements at the given struct level have already been added
        % (e.g. to know that attribute node at location
        % "/instrument_state/description" should correspond to index 4 and
        % the struct path "file1.Variables(2).Attributes(4)", we first need
        % to know that there are already 3 elements at the struct level
        % "file1.Variables(2).Attributes"). This mapping between a struct
        % level and the number of elements at that level is stored in
        % countAtStructLevelDict, i.e.:
        %     "file1.Variables(2).Attributes" -> 3
        % It is configured as an empty string->double dictionary
        countAtStructLevelDict = dictionary(string([]),double([]));

        % Arrays for keeping track of checked and partially checked nodes.
        % Partially checked nodes are nodes which have only some of their
        % children checked (also known as "IndeterminateCheckedNodes"). In
        % the UI they show up as a checkbox with a black square in it.
        checkedNodes = matlab.ui.container.TreeNode.empty();
        partiallyCheckedNodes = matlab.ui.container.TreeNode.empty();

        % Whether we are generating high- or low-level NetCDF/HDF5 code
        % (high-level by default)
        isLowLevelCode = false;

        % --- Subsetting-related properties

        % Each variable can have an associated subsetting UI (a grid of
        % numeric edit fields where Start, Stride, Count can be specified
        % for each of its dimensions). Each of these subsetting UIs is
        % placed in each own row in subsettingOptionsGrid. Each subsetting
        % UI is only generated when the associated variable is selected for
        % import. If the variable is deselected, we don't destroy the UI,
        % just hide it. That way we can easily show it again if the
        % variable is selected again.

        % accordion panel containing the grid layout for subsetting options
        subsettingOptionsPanel matlab.ui.container.internal.AccordionPanel

        % Grid layout for all variables' subsetting options UIs. It has as
        % many rows as there are variables.
        subsettingOptionsGrid matlab.ui.container.GridLayout

        % Dictionary to store subsetting options UI for non-scalar
        % variables. We don't pregenerate them - the UIs are generated only
        % when variable is selected for import. But once it is generated,
        % we don't destroy it, even if the variable is unchecked. This
        % dictionary maps the variable (specified by location path) to a
        % struct which contains two pieces of information: rowInd (the row
        % index in the big subsettingOptionsGrid grid layout where the
        % corresponding UI is/should be - this corrseponds to the order of
        % the variables in the tree) and subsettingGrid (the generated grid
        % layout for subsetting options which contains Start, Stride, Count
        % fields or [] if the subsetting options UI hasn't been generated
        % yet for this variable), i.e.:
        %     "/obs_id" -> rowInd: 1
        %                  subsettingGrid: [1×1 GridLayout]
        % or
        %       "/time" -> rowInd: 3
        %                  subsettingGrid: []
        subsettingUIDict = dictionary(string([]), struct());

        % Dictionary to store the subsetting options for non-scalar
        % variables (if they have been modified from default options and
        % need to be included during code generation). This dictionary maps
        % the variable (specified by location path) to the subsetting
        % options (stored as a struct with Start, Stride, and Count
        % fields).
        subsettingOptionsDict = dictionary(string([]), struct());

    end

    properties (Constant)
        % width and height of panel that shows metadata for selected node
        % (in pixels)
        metadataLabelSize = 350;

        % width of the tree and search bar column (in pixels)
        treeWidth = 450;

        % Positions for code generation radio buttons.
        % uiradiobuttons cannot be positioned using a grid layout
        % (g1981566), so their positions need to be hardcoded.
        % [left, bottom, width, height] in pixels:
        highLevelButtonPos = [11 2 102 20];
        lowLevelButtonPos = [132 2 102 20];

        % Code generation layout row height. The uibuttongroup is 210
        % height by default, and there is no way to change it if it is
        % added to a grid layout (g2883792). So we need to hard-code the
        % row height of grid layout instead (otherwise, default row height
        % is '1x', which would stretch to the entire height of
        % uibuttongroup.
        codegenLayoutRowHeight = 22;

        % string labels for Start/Stride/Count subsetting options
        startLabelConst = string(getString(...
            message("import_sci_livetasks:messages:startLabel")));
        strideLabelConst = string(getString(...
            message("import_sci_livetasks:messages:strideLabel")));
        countLabelConst = string(getString(...
            message("import_sci_livetasks:messages:countLabel")));

    end

    methods (Abstract)

        % Return supported file extensions
        getSupportedFileExtensions(task)

        % Return task summary
        summary = getTaskSummary(task)

        % Generate the UI tree based on file structure
        generateTree(task)

        % Create the label text for individual attribute nodes given a
        % struct containing info about that individual attribute
        % (portion of ncinfo/h5info output)
        desc = createAttNodePreview(task, attStruct, locationPath)

        % Crate text representation of attribute value
        dispText = attributeValueDisplay(task, attStruct)

        % Generate node for an individual dataset/variable
        % ("dataset/variable value" node) given a struct containing that
        % dataset's/variable's info (portion of ncinfo/h5info output)
        generateDatasetOrVariableValueNode(task, varStruct, parentNode)

        % Create the label text for an individual dataset/variable node
        % given a struct containing info about that individual
        % dataset/variable (portion of ncinfo/h5info output)
        desc = createDatasetOrVariableNodePreview(task, varStruct, locationPath)

        % Generate node for an individual datatype given a struct
        % containing that datatype's info (portion of ncinfo/h5info output)
        generateDatatypeNode(task, datatypeStruct, parentNode);

        % Create the label text for an individual datatype node
        % given a struct containing info about that individual
        % datatype (portion of ncinfo/h5info output)
        desc = createDatatypeNodePreview(task, datatypeStruct, locationPath)

        % Generate groups "cluster" node (e.g. "Groups (5)") and all the
        % nodes for individual groups given a struct containing
        % group info (portion of ncinfo/h5info output)
        generateGroupsClusterNodes(task, groupsStruct, parentNode)

        % Set nodeImportCodeGeneratorStrategy property which controls how
        % the code is generated (using high- or low-level netCDF or HDF5
        % interfaces)
        setCodeGenerationStrategy(task)
    end

    methods

        % Create an instance of a HierarchicalSciImportProvider
        function this = HierarchicalSciImportProvider(filename)
            arguments
                filename (1,1) string = "";
            end

            this = this@matlab.internal.importdata.ImportOptionsProvider(filename);
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Methods for building UI interface
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        % Function to build UI once a file of appropriate file format is
        % selected
        function fileSelected(task, accordionParent, ~)

            % reset selected nodes back to empty
            task.checkedNodes = matlab.ui.container.TreeNode.empty();
            task.partiallyCheckedNodes = matlab.ui.container.TreeNode.empty();

            % create "Select Data to Import" accordion section

            % The first two rows are the different states of search: empty
            % and ready with results. Hide the second state to start with
            % (set row height to 0x).
            % The height/width of section for metadata label (third row)
            % has to be hardcoded to prevent unreasonable resizing when
            % metadata is really long
            selectDataRowHeights = {'fit', '0x', task.metadataLabelSize};


            % both the tree column and the metadata column have fixed widths
            selectDataColumnWidths = {task.treeWidth, task.metadataLabelSize};

            [task.selectDataPanel, task.selectDataGrid] = task.createAccordionPanel( ...
                accordionParent, ...
                string(getString(message("import_sci_livetasks:messages:selectDataHeader"))), ...
                selectDataColumnWidths, ...
                length(selectDataRowHeights), selectDataRowHeights);
            task.selectDataGrid.RowSpacing = 1;

            % create search grid for before a search is performed
            task.createBeforeSearchGrid();

            % create search grid for after the search results are ready
            task.createAfterSearchGrid();

            % create tree
            task.generateTree();

            % create metadata preview
            task.createScrollableMetadataLabel();

            % subsettingUIDict contains an entry for each non-scalar variable
            numNonScalarVariables = task.subsettingUIDict.numEntries;

            % create Specify Subsetting Options for Datasets/Variables accordion section
            [task.subsettingOptionsPanel, task.subsettingOptionsGrid] = task.createAccordionPanel( ...
                accordionParent, ...
                string(getString(message(task.subsettingOptionsHeaderMessageID))), ...
                {'fit'}, ...
                numNonScalarVariables); % Number of rows needed for subsetting UIs
                                        % is at most the total number of
                                        % non-scalar variables

            task.subsettingOptionsPanel.collapse() % collapsed by default

            % create radio buttons for choosing high- or low-level codegen
            task.createCodeGenerationChoiceButtons(accordionParent);

            % Refresh the screen as some visual "piece" of the UI is ready
            % to be rendered. Do not wait for this call to be complete to
            % move on.
            matlab.graphics.internal.drawnow.startUpdate()

            % Create Display Results accordion section (if supported)
            if task.SupportsResultDisplay
                [task.ResultsPanel, resultsGrid] = task.createAccordionPanel( ...
                    accordionParent, ...
                    string(getString(message("MATLAB:datatools:importlivetask:DisplayResultsLabel"))), ...
                    {'fit'}, 1);
                task.ResultsPanel.collapse();
                task.addOutputSection(resultsGrid);
            end

        end

        % Create search grid for before a search is performed
        function createBeforeSearchGrid(task)

            task.searchGridBeforeLayout = uigridlayout(task.selectDataGrid);

            % 2 columns - for searchEditField (1x) and search button (fit)
            task.searchGridBeforeLayout.ColumnWidth = {'1x', 'fit'};
            task.searchGridBeforeLayout.RowHeight = {'1x'};
            task.searchGridBeforeLayout.Padding = 0;
            task.searchGridBeforeLayout.ColumnSpacing = 1;
            task.searchGridBeforeLayout.Layout.Row = 1;
            task.searchGridBeforeLayout.Layout.Column = 1;

            % Create searchEditField
            task.searchEditField = uieditfield(...,
                task.searchGridBeforeLayout, 'text');
            task.searchEditField.Layout.Row = 1;
            task.searchEditField.Layout.Column = 1;

            % Create searchButton
            task.searchButton = uibutton(task.searchGridBeforeLayout, 'push', ...
                'ButtonPushedFcn', @(btn,event) task.searchButtonPushedCallback());
            task.searchButton.Layout.Row = 1;
            task.searchButton.Layout.Column = 2;
            task.searchButton.Text = getString(... % button text is stored as character vector independent of input type
                message("import_sci_livetasks:messages:searchLabel"));
            task.searchButton.Tooltip = getString(... % tooltip text is stored as character vector independent of input type
                message(task.searchTooltipMessageID));

            % This callback executes when the user changes text in the
            % edit field and either presses Enter or clicks outside the
            % edit field. Make this equivalent to pressing Search Button.
            task.searchEditField.ValueChangedFcn = @(btn,event) task.searchButtonPushedCallback();
        end

        % Create a search grid for after the results are ready
        function createAfterSearchGrid(task)

            task.searchGridAfterLayout = uigridlayout(task.selectDataGrid);

            % 5 columns - for searchEditField, reset button, matchesLabel,
            % and up and down arrows
            task.searchGridAfterLayout.ColumnWidth = {'1x', 'fit', 'fit', 'fit', 'fit'};

            task.searchGridAfterLayout.RowHeight = {'1x'};
            task.searchGridAfterLayout.Padding = 0;
            task.searchGridAfterLayout.ColumnSpacing = 1;
            task.searchGridAfterLayout.Layout.Row = 2;
            task.searchGridAfterLayout.Layout.Column = 1;

            % Create resetButton
            task.resetButton = uibutton(task.searchGridAfterLayout, 'push',...
                'ButtonPushedFcn', @(btn,event) task.resetButtonPushedCallback());
            task.resetButton.Layout.Row = 1;
            task.resetButton.Layout.Column = 2;
            task.resetButton.Text = "";
            matlab.ui.control.internal.specifyIconID(task.resetButton, ...
                "deleteBorderlessUI", 12);

            % Create matchesLabel
            task.matchesLabel = uilabel(task.searchGridAfterLayout);
            task.matchesLabel.Layout.Row = 1;
            task.matchesLabel.Layout.Column = 3;

            % Create down button
            task.nextMatchButton = uibutton(task.searchGridAfterLayout, 'push', ...
                "ButtonPushedFcn", @(btn,event) task.nextButtonPushedCallback());
            task.nextMatchButton.Layout.Row = 1;
            task.nextMatchButton.Layout.Column = 4;
            task.nextMatchButton.Text = "";
            matlab.ui.control.internal.specifyIconID(task.nextMatchButton, ...
                "chevronSouthUI", 12);

            % Create up button
            task.prevMatchButton = uibutton(task.searchGridAfterLayout, 'push', ...
                "ButtonPushedFcn", @(btn,event) task.prevButtonPushedCallback());
            task.prevMatchButton.Layout.Row = 1;
            task.prevMatchButton.Layout.Column = 5;
            task.prevMatchButton.Text = "";
            matlab.ui.control.internal.specifyIconID(task.prevMatchButton, ...
                "chevronNorthUI", 12);
        end

        % Create metadata label (where information about selected node is
        % shown)
        function createScrollableMetadataLabel(task)

            % Create scrollable 1x1 grid layout (needed to make label
            % scrollable)
            scrollableGridLayout = uigridlayout(task.selectDataGrid);
            scrollableGridLayout.ColumnWidth = {'1x'}; % resize the only column of scrollableGridLayout with its parent container
            scrollableGridLayout.RowHeight = {'fit'}; % needs to be 'fit' for scrolling
            scrollableGridLayout.Layout.Row = 3; % third row in selectDataGrid
            scrollableGridLayout.Layout.Column = 2; % second column in selectDataGrid
            scrollableGridLayout.Scrollable = 'on';

            % Create metadata label
            task.metadataLabel = uilabel(scrollableGridLayout);
            task.metadataLabel.Interpreter = 'html'; % to allow bold header for the label
            task.metadataLabel.WordWrap = 'on';
            task.metadataLabel.VerticalAlignment = 'top';
            task.metadataLabel.Layout.Row = 1; % first row in scrollableGridLayout
            task.metadataLabel.Layout.Column = 1; % first column in scrollableGridLayout
            task.metadataLabel.Text = '';
        end

        % Create UI section with radio buttons for choosing code generation
        % type (high- or low-level)
        function createCodeGenerationChoiceButtons(task, accordionParent)

            % create Specify Code Generation Type accordion section
            [task.codegenTypePanel, codegenTypeGrid] = task.createAccordionPanel( ...
                accordionParent,...
                string(getString(message("import_sci_livetasks:messages:codegenTypeHeader"))),...
                {'fit'}, ... % one column with 'fit' width
                1, ... % one row
                {task.codegenLayoutRowHeight}); % need to hardcode the row height
            % of grid layout here to
            % control the height of
            % uibuttongroup

            codegenButtonGroup = uibuttongroup(codegenTypeGrid, ...
                'SelectionChangedFcn', ...
                @(source,event) task.codegenTypeChangedCallback(event));
            codegenButtonGroup.Layout.Row = 1;
            codegenButtonGroup.Layout.Column = 1;
            codegenButtonGroup.BorderType = 'none';

            % create button for high-level
            task.highlevelcodeButton = uiradiobutton(codegenButtonGroup);
            task.highlevelcodeButton.Text = getString(... % button text is stored as character vector independent of input type
                message("import_sci_livetasks:messages:highLevelLabel"));
            task.highlevelcodeButton.Value = true; % high-level by default
            % adding this boolean user data to know which button is which
            task.highlevelcodeButton.UserData.isLowLevelCode = false;
            task.highlevelcodeButton.Tooltip = getString(... % tooltip text is stored as character vector independent of input type
                message(task.highLevelTooltipMessageID));

            % create button for low-level
            task.lowlevelcodeButton = uiradiobutton(codegenButtonGroup);
            task.lowlevelcodeButton.Text = getString(... % button text is stored as character vector independent of input type
                message("import_sci_livetasks:messages:lowLevelLabel"));
            % adding this boolean user data to know which button is which
            task.lowlevelcodeButton.UserData.isLowLevelCode = true;
            task.lowlevelcodeButton.Tooltip = getString(... % tooltip text is stored as character vector independent of input type
                message(task.lowLevelTooltipMessageID));

            % uiradiobuttons cannot be positioned using a grid layout
            % (g1981566), so their positions need to be hardcoded.
            task.highlevelcodeButton.Position = task.highLevelButtonPos;
            task.lowlevelcodeButton.Position = task.lowLevelButtonPos;

            % collapsed by default
            task.codegenTypePanel.collapse()

        end

        % Update variables' subsetting options UI based on which variables
        % are selected
        function updateSubsettingOptionsUIs(task, uncheckedNodes)
            import matlab.internal.importsci.NodeType;

            % For each checked variable, make sure subsetting options UI is
            % there and visible
            for i=1:length(task.checkedNodes)
                checkedNode = task.checkedNodes(i);

                % Subsetting options UI is only for non-scalar variables - check if
                % this node is a variable node and if the variable has
                % dimensions
                if (checkedNode.NodeData.Type == NodeType.DatasetOrVariable) && ...
                        ~isempty(checkedNode.NodeData.Dimensions)

                    % info about this variable's subsetting UI (its row
                    % index and its subsetting grid if it has been generated)
                    varSubsettingUIInfo = task.subsettingUIDict(checkedNode.NodeData.LocationPath);

                    % if the variable already has a generated subsetting UI
                    if ~isempty(varSubsettingUIInfo.subsettingGrid)

                        % unhide the subsetting UI for this variable
                        task.subsettingOptionsGrid.RowHeight{varSubsettingUIInfo.rowInd} = 'fit';

                    else
                        % if the subsetting UI for this variable has not been
                        % generated yet

                        % generate subsetting UI for this variable
                        task.generateSubsettingAccordionforDatasetOrVariable(varSubsettingUIInfo.rowInd,...
                            checkedNode.NodeData.Dimensions,...
                            checkedNode.NodeData.LocationPath);
                    end

                end
            end

            % Hide subsetting UI for variable nodes that became unchecked
            for i=1:length(uncheckedNodes)
                uncheckedNode = uncheckedNodes(i);

                % if unchecked node is a non-scalar variable
                if (uncheckedNode.NodeData.Type == NodeType.DatasetOrVariable) && ...
                        ~isempty(uncheckedNode.NodeData.Dimensions)

                    % info about this variable's subsetting UI (its row
                    % index and its subsetting grid if it has been generated)
                    varSubsettingUIInfo = task.subsettingUIDict(uncheckedNode.NodeData.LocationPath);

                    % if this variable already has a generated subsetting UI
                    if ~isempty(varSubsettingUIInfo.subsettingGrid)

                        % hide the subsetting UI for this variable
                        task.subsettingOptionsGrid.RowHeight{varSubsettingUIInfo.rowInd} = '0x';

                        % if this variable's subsetting options have been
                        % modified
                        if task.subsettingOptionsDict.isKey(uncheckedNode.NodeData.LocationPath)

                            % remove the saved subsetting options for this variable
                            task.subsettingOptionsDict(uncheckedNode.NodeData.LocationPath) = [];

                            % reset the numeric fields of subsetting UI for this
                            % variable to default values
                            dimLengths = [uncheckedNode.NodeData.Dimensions.Length];
                            defaultSubsettingOptions = ...
                                task.generateDefaultSubsettingOptions(dimLengths);
                            task.restoreSubsettingFieldValuesForVariable(...
                                uncheckedNode.NodeData.LocationPath,...
                                defaultSubsettingOptions);
                        end
                    end

                end
            end

        end

        % Generate default subsetting options (as a struct) for a variable
        % given an array of that variable's dimension lengths
        function subsettingOptions = generateDefaultSubsettingOptions(~, dimensionLengths)

            % number of dimensions
            dimNum = length(dimensionLengths);

            % default values for Start and Stride are 1's
            subsettingOptions.Start = ones(1, dimNum);
            subsettingOptions.Stride = ones(1, dimNum);

            % default value for Count is dimension length
            subsettingOptions.Count = dimensionLengths;
        end

        % Create a collapsible section (accordion) to contain one
        % dataset's/variable's subsetting UI (a grid of numeric edit fields where
        % Start, Stride, Count can be specified for each of its
        % dimensions). This section is created in the rowInd row of the
        % parent grid layout; varLocationPath is used to label the section
        % and to identify the dataset/variable from each edit field's data; and
        % dimStruct contains info about dataset's/variable's dimensions and is needed
        % to correctly create and label the grid of edit fields.
        function generateSubsettingAccordionforDatasetOrVariable(task, rowInd, ...
                dimStruct, varLocationPath)

            % Create an accordion container in the subsettingOptionsGrid at
            % the row index corresponding to this variable
            accordionParent = matlab.ui.container.internal.Accordion('Parent', task.subsettingOptionsGrid);
            accordionParent.Layout.Row = rowInd;
            accordionParent.Layout.Column = 1; % all subsetting UIs are in the first (and only) column of the layout

            % Create an accordion panel in the accordion container - it
            % will contain the grid of edit fields for Start, Stride, Count
            % options and their labels. For example, for variable with two
            % dimensions (xtrack and atrack) where "------" represents a
            % numeric edit field:
            %
            %           xtrack      atrack
            % Start     ------      ------
            % Stride    ------      ------
            % Count     ------      ------
            %
            % 3 columns (numDims+1)
            % 4 rows (dimensions labels + Start/Stride/Count)

            numDims = length(dimStruct);

            % Number of columns is number of dimensions + 1 (+1 is for the
            % labels column)
            columnWidths = repmat({'fit'}, 1, numDims+1);
            [variableSubsettingOptionPanel, variableSubsettingOptionGrid] = task.createAccordionPanel( ...
                accordionParent, ...
                varLocationPath,...  % title for the panel
                columnWidths, ...
                4); % 4 rows for Start, Stride, Count, and dimensions labels

            % labels for start/stride/count options
            labels = [task.startLabelConst, task.strideLabelConst, task.countLabelConst];
            tooltips = {... % tooltip text is stored as character vector independent of input type
                getString(message("import_sci_livetasks:messages:startTooltip")), ...
                getString(message("import_sci_livetasks:messages:strideTooltip")), ...
                getString(message("import_sci_livetasks:messages:countTooltip"))};
            for labelInd = 1:length(labels) % looping over rows
                subsetOptionLabel = uilabel(variableSubsettingOptionGrid);
                % +1 to account for first row for dimensions labels
                subsetOptionLabel.Layout.Row = labelInd + 1;
                % "start/stride/count" labels take up the first column
                subsetOptionLabel.Layout.Column = 1;
                subsetOptionLabel.Text = labels(labelInd);
                subsetOptionLabel.Tooltip = tooltips{labelInd};
            end

            % labels for dimensions
            for dimInd = 1:numDims % looping over columns
                subsetDimLabel = uilabel(variableSubsettingOptionGrid);
                % dimension labels take up the first row
                subsetDimLabel.Layout.Row = 1;
                % +1 to account for first column for start/stride/count
                % labels
                subsetDimLabel.Layout.Column = dimInd + 1;
                subsetDimLabel.Text = dimStruct(dimInd).Name;
                subsetDimLabel.Tooltip = getString(... % tooltip text is stored as character vector independent of input type
                    message("import_sci_livetasks:messages:dimensionTooltip", ...
                    dimInd));
            end

            % numeric edit fields
            for labelInd = 1:length(labels) % looping over rows
                for dimInd = 1:numDims  % looping over columns

                    % create a numeric edit field
                    subsetField = uieditfield(variableSubsettingOptionGrid, ...
                        'numeric');
                    % allow only integers by rounding fractional inputs
                    subsetField.RoundFractionalValues = 'on';
                    % allow only values >= 1 and <= dimension length
                    subsetField.Limits = [1, dimStruct(dimInd).Length];

                    % +1 to account for dimensions label row:
                    subsetField.Layout.Row = labelInd + 1;
                    % +1 to account for start/stride/count label column:
                    subsetField.Layout.Column = dimInd + 1;

                    % set default values
                    switch labels(labelInd)
                        case {task.startLabelConst, task.strideLabelConst}
                            subsetField.Value = 1;
                        case task.countLabelConst
                            subsetField.Value = dimStruct(dimInd).Length;
                    end

                    % Each numeric edit field stores the following info in
                    % its UserData struct:
                    %
                    % subsetFieldData:
                    %   subsetOption    ("Start:"/"Stride:"/"Count:")
                    %   varLocationPath (to identify which variable this
                    %                    field is for, e.g. "/group1/var1")
                    %   dimInd          (index indicating which dimension
                    %                    of all variable's dimensions this
                    %                    field corresponds to)
                    %   dimLengths      (lengths of all variable's
                    %                    dimensions)
                    subsetField.UserData.subsetOption = labels(labelInd);
                    subsetField.UserData.varLocationPath = varLocationPath;
                    subsetField.UserData.dimInd = dimInd;
                    subsetField.UserData.dimLengths = [dimStruct.Length];

                    % assign callback for field's value changing
                    subsetField.ValueChangedFcn = ....
                        @(source, event) task.subsetFieldValueChangedCallback(event);

                end
            end

            % subsetting accordion sections should be collapsed by default
            variableSubsettingOptionPanel.collapse()

            % add the generated subsetting UI grid to dictionary
            task.subsettingUIDict(varLocationPath).subsettingGrid = variableSubsettingOptionGrid;

        end

        % Create the label text for attributes "cluster" nodes (e.g.
        % "Attributes (5)") given a struct containing attributes info
        % (portion of ncinfo/h5info output)
        function desc = createAttributesClusterNodePreview(task, attributesStruct, ...
                attText)
            % desc is a string array with each element of the array
            % representing a new line of text in the metadata label.

            % The number of lines consists of two lines per attribute (one
            % for content, one empty to separate it from the next
            % attribute) and two lines for the header (one for header, one
            % empty for space).
            numLines = (length(attributesStruct)+1) * 2; % +1 for header, *2 for empty lines
            desc = strings(numLines, 1);

            % First line is the header of the metadata label and it is made
            % bold using HTML formatting.
            desc(1) = ...
                matlab.internal.importsci.HierarchicalSciImportProvider.makeHTMLBoldText(...
                string(attText));

            for i = 1:length(attributesStruct)
                lineNumber = (2*i) + 1; % skipping header and empty lines
                desc(lineNumber) = string(attributesStruct(i).Name) + " = " + ...
                    task.attributeValueDisplay(attributesStruct(i));
            end
        end

        % Generate attributes "cluster" node (e.g. "Attributes (5)") and all the
        % nodes for individual attributes given a struct containing
        % attributes info (portion of ncinfo output)
        function generateAttributesClusterNodes(task, attStruct, parentNode, isGlobal)
            import matlab.internal.importsci.NodeType;

            numAtt = length(attStruct);

            % if there are no attributes, we are done
            if numAtt==0
                return
            end

            nodeLabelMessageID = "import_sci_livetasks:messages:attributesNodeLabel";
            if isGlobal
                nodeLabelMessageID = "import_sci_livetasks:messages:globalAttributesNodeLabel";
            end
            attText = getString(... % node text is stored as character vector independent of input type
                message(nodeLabelMessageID, numAtt));

            attributeClusterNode = task.addTreeNode(parentNode, attText);
            % generate node data
            attributeClusterNode.NodeData.Type = NodeType.AttributesCluster;
            attributeClusterNode.NodeData.Label = task.createAttributesClusterNodePreview(attStruct, attText);

            for i=1:numAtt
                attributeNode = task.addTreeNode(attributeClusterNode, attStruct(i).Name);
                % generate node data
                attributeNode.NodeData.Type = NodeType.Attribute;
                attributeNode.NodeData.LocationPath = task.locationPathFromNode(attributeNode);
                attributeNode.NodeData.Label = task.createAttNodePreview(...
                    attStruct(i), attributeNode.NodeData.LocationPath);
            end
        end

        % Generate datatypes "cluster" node (e.g. "Datatypes (2)" and all
        % the nodes for individual datatypes given a struct containing
        % datatype info (portion of h5info/ncinfo output)
        function generateDatatypesClusterNodes(task, datatypesStruct, parentNode)

            numDatatypes = length(datatypesStruct);

            % skip creating Datatypes nodes if there are no Datatypes
            if numDatatypes==0
                return
            end

            % node text is stored as character vector independent of input
            % type, so not converting it to string here
            datatypesText = getString(message(...
                "import_sci_livetasks:messages:datatypesNodeLabel", ...
                numDatatypes));
            datatypesNode = task.addTreeNode(parentNode, datatypesText);

            % generate node data for datatypes cluster node
            datatypesNode.NodeData.Type = ...
                matlab.internal.importsci.NodeType.DatatypesCluster;
            datatypesNode.NodeData.Label ...
                = task.createDatatypesClusterNodePreview(...
                datatypesStruct, datatypesText);

            % generate nodes for individual datatypes
            for i=1:numDatatypes
                task.generateDatatypeNode(datatypesStruct(i), datatypesNode);
            end
        end

        % Label text for the datatypes cluster node, i.e. "Datatypes (2)"
        function desc = createDatatypesClusterNodePreview(task, ...
                datatypesStruct, datatypesText)
            desc = ""; % no display for datatypes cluster node for now
        end

        % Generate datasets or variables "cluster" node (e.g., "Datasets
        % (3)" or "Variables (5)") and all the nodes for individual
        % datasets/variables given a struct containing datasets/variables
        % info (portion of ncinfo/h5info output)
        function generateDatasetsOrVariablesClusterNodes(task, varStruct, parentNode)
            import matlab.internal.importsci.NodeType;

            numVars = length(varStruct);
            if numVars==0
                return
            end

            % get the label for this node (can be "Variables" or "Datasets"
            % depending on the value of datasetOrVariableClusterNodeMessageID
            % property in the concrete child class)
            varText = getString(...
                message(task.datasetOrVariableClusterNodeMessageID, numVars));

            variablesNode = task.addTreeNode(parentNode, varText);

            % generate node data
            variablesNode.NodeData.Type = NodeType.DatasetsOrVariablesCluster;
            variablesNode.NodeData.Label = ""; % currently no preview for Variables/Datasets Cluster nodes

            % dataset/variable nodes can be of two types: "dataset/variable value"
            % (DatasetOrVariable) and "dataset/variable with attributes"
            % (DatasetOrVariableWithAtts). If a dataset/variable has associated
            % attributes, the node structure looks like this (e.g. for a
            % variable named obs_id):
            %
            % Variabes (1)
            %  |- obs_id     <-- "variable with attributes" node
            %    |- obs_id   <-- "variable value" node
            %    |- Attributes (2)
            %      |- units
            %      |- long_name
            %
            % If a variable has no associated attributes, it only has a
            % "variable value" node, e.g.:
            %
            % Variabes (1)
            %  |- obs_id     <-- "variable value" node
            %
            for i=1:numVars
                if isempty(varStruct(i).Attributes)
                    % only add node for dataset/variable value
                    task.generateDatasetOrVariableValueNode(varStruct(i), variablesNode)
                else
                    % create "dataset/variable with attributes" node that will have
                    % attributes node and dataset/variable value node as children
                    varNodeWithAtts = task.addTreeNode(variablesNode,...
                        varStruct(i).Name);
                    % generate node data
                    varNodeWithAtts.NodeData.Type = NodeType.DatasetOrVariableWithAtts;
                    varNodeWithAtts.NodeData.Label = ...
                        task.createDatasetOrVariableNodeWithAttsPreview(varStruct(i));
                    varNodeWithAtts.NodeData.LocationPath = task.locationPathFromNode(varNodeWithAtts);

                    % add node for dataset/variable value
                    task.generateDatasetOrVariableValueNode(varStruct(i), varNodeWithAtts)

                    % add attributes node
                    task.generateAttributesClusterNodes(varStruct(i).Attributes, ...
                        varNodeWithAtts, false)
                end
            end
        end

        % Create the label text for an individual "dataset/variable with
        % attributes" node given a struct containing info about that
        % individual dataset/variable (portion of ncinfo/h5info output). A "dataset/variable with
        % attributes" node is a parent to dataset/variable value node and its
        % attributes node (e.g. "Attributes (4)")
        function desc = createDatasetOrVariableNodeWithAttsPreview(task, varStruct)

            % desc is a string array with each element of the array
            % representing a new line of text in the metadata label. First
            % line is the header of the metadata label and it is made bold
            % using HTML formatting
            desc = string(getString(message(...
                "import_sci_livetasks:messages:varWithAttsMetadataLabel", ...
                varStruct.Name, length(varStruct.Attributes))));
            desc = matlab.internal.importsci.HierarchicalSciImportProvider.makeHTMLBoldText(desc);
        end

        % Add a node to the ui tree given its parent node and the text to
        % label it
        function node = addTreeNode(task, parentNode, nodeText)
            node = uitreenode(parentNode);
            node.Text = nodeText;

            % add node and node text to arrays for searching
            nextInd = length(task.treeNodes) + 1;
            task.treeNodesText(nextInd) =  string(nodeText);
            task.treeNodes(nextInd) = node;

            % add node's ID to node data
            node.NodeData.ID = nextInd;
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Callbacks
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        % Callback for selecting nodes in the uitree. It updates
        % the metadata label based on which node is selected
        function nodeSelectedCallback(task, event)
            node = event.SelectedNodes; % only one node can be selected
            task.updateMetadataLabel(node.NodeData.Label)
        end

        % Given a node label, set the metadata preview text to that label
        function updateMetadataLabel(task, nodeLabel)
            if isempty(nodeLabel)
                task.metadataLabel.Text = "";
            else
                task.metadataLabel.Text = nodeLabel;
            end
        end

        % Callback for Search Button, performs the search and updates the
        % UI to display and navigate between search results
        function searchButtonPushedCallback(task)

            % get text from the edit field to use as a search term
            searchTerm = task.searchEditField.Value;

            % do nothing if the search term is empty
            % (otherwise it will match all the nodes)
            if isempty(searchTerm)
                return
            end

            % turn off editability of searchEditField
            % and move it to search grid that shows results
            task.searchEditField.Editable = 'off';
            task.searchEditField.Parent = task.searchGridAfterLayout;

            % Hide the searchGridBeforeLayout and show searchGridAfterLayout
            task.selectDataGrid.RowHeight{1} = '0x';
            task.selectDataGrid.RowHeight{2} = 'fit';

            % perform search (case-insensitive)
            task.matchInds = contains(task.treeNodesText, searchTerm, ...
                'IgnoreCase', true);
            totalMatches = sum(task.matchInds);
            if totalMatches == 0
                % no matches, so the index of displayed match is 0
                task.dispCurrentMatchInd = 0;
            else
                % some matches, so display the first of the matches
                task.dispCurrentMatchInd = 1;
                task.scrollToCurrentMatch();
            end

            % update the matches label
            task.matchesLabel.Text = task.dispCurrentMatchInd + "/" + totalMatches;
        end

        % Callback for Reset Button, prepares for a new search
        function resetButtonPushedCallback(task)

            % turn on editability of searchEditField,
            % reset the value, and move it back to empty search grid
            task.searchEditField.Editable = 'on';
            task.searchEditField.Value = '';
            task.searchEditField.Parent = task.searchGridBeforeLayout;

            % switch focus to the edit field
            focus(task.searchEditField)

            % Hide the searchGridAfterLayout and show searchGridBeforeLayout
            task.selectDataGrid.RowHeight{1} = 'fit';
            task.selectDataGrid.RowHeight{2} = '0x';

        end

        % Callback for Next Button, updates the UI to show the next found
        % match
        function nextButtonPushedCallback(task)
            totalMatches = sum(task.matchInds);

            % if the search found nothing (0/0 results), it is a no-op
            if totalMatches == 0
                return
            end

            % increment current index of matched node
            % (making sure to wrap around when reaching the last match)
            if (task.dispCurrentMatchInd == totalMatches)
                task.dispCurrentMatchInd = 1;
            else
                task.dispCurrentMatchInd = task.dispCurrentMatchInd + 1;
            end

            % update the matches label
            task.matchesLabel.Text = task.dispCurrentMatchInd + "/" + totalMatches;

            % scroll to and select this mached node
            task.scrollToCurrentMatch()
        end

        % Callback for Previous Button, updates the UI to show the previous
        % found match
        function prevButtonPushedCallback(task)
            totalMatches = sum(task.matchInds);

            % if the search found nothing (0/0 results), it is a no-op
            if totalMatches == 0
                return
            end

            % decrement current index of matched node
            % (making sure to wrap around when reaching the first match)
            if (task.dispCurrentMatchInd == 1)
                task.dispCurrentMatchInd = totalMatches;
            else
                task.dispCurrentMatchInd = task.dispCurrentMatchInd - 1;
            end

            % update the matches label
            task.matchesLabel.Text = task.dispCurrentMatchInd + "/" + totalMatches;

            % scroll to and select this mached node
            task.scrollToCurrentMatch()

        end

        % Scroll to and select the node that is the current
        % match in the search results
        function scrollToCurrentMatch(task)

            % vector of matched nodes
            matchedNodes = task.treeNodes(task.matchInds);

            % scroll to current match
            matchedNode = matchedNodes(task.dispCurrentMatchInd);
            scroll(task.tree, matchedNode)

            % select this node
            task.tree.SelectedNodes = matchedNode;

            % update the metadata based on selected node
            task.updateMetadataLabel(matchedNode.NodeData.Label)
        end

        % Callback for when the nodes become checked/unchecked, it triggers
        % re-generation of code
        function checkedNodesChangedCallback(task, event)

            % update properties that keep track of node status
            task.checkedNodes = event.CheckedNodes;
            task.partiallyCheckedNodes = event.IndeterminateCheckedNodes;

            % Nodes that became unchecked on this update
            % (were checked before, but are not anymore)
            uncheckedNodes = setdiff(event.PreviousCheckedNodes, event.CheckedNodes);

            % Update subsetting options
            task.updateSubsettingOptionsUIs(uncheckedNodes)

            % re-generate and update generated code, update the state
            task.getImportCode();
            task.notifyChange();
        end

        % Callback for when the value of Start/Stride/Count fields is
        % changed. It updates the stored subsetting options
        % (subsettingOptionsDict) for the corresponding variable.
        function subsetFieldValueChangedCallback(task, event)
            
            % Each numeric edit field stores the following info in
            % its UserData struct:
            %
            % subsetFieldData:
            %   subsetOption    ("Start"/"Stride"/"Count")
            %   varLocationPath (to identify which variable this
            %                    field is for, e.g. "/group1/var1")
            %   dimInd          (index indicating which dimension
            %                    of all variable's dimensions this
            %                    field corresponds to)
            %   dimLengths      (lengths of all variable's
            %                    dimensions)
            subsetFieldData = event.Source.UserData;


            % does this variable already have subsetting options?
            if task.subsettingOptionsDict.isKey(subsetFieldData.varLocationPath)

                % get its subsetting option
                subsettingOptions = task.subsettingOptionsDict(subsetFieldData.varLocationPath);

            else
                % if the variable does not have any subsetting options yet,
                % generate the default subsetting options
                subsettingOptions = ...
                    task.generateDefaultSubsettingOptions(subsetFieldData.dimLengths);
            end

            % update the changed subsetting option
            switch subsetFieldData.subsetOption % which option do we need to update
                case task.startLabelConst
                    subsettingOptions.Start(subsetFieldData.dimInd) = event.Value;
                case task.strideLabelConst
                    subsettingOptions.Stride(subsetFieldData.dimInd) = event.Value;
                case task.countLabelConst
                    subsettingOptions.Count(subsetFieldData.dimInd) = event.Value;
            end

            % add/update the subsetting options in the dictionary
            task.subsettingOptionsDict(subsetFieldData.varLocationPath) = subsettingOptions;

            % re-generate and update generated code
            task.getImportCode();
            task.notifyChange();
        end

        % Callback for when the value of codegen type radio buttons is
        % toggled (between high- and low-level). It forces re-generation of
        % the code
        function codegenTypeChangedCallback(task, event)

            % update the task's property to the new value (high-level
            % radio button has this value as false, and low-level radio
            % button has it as true)
            task.isLowLevelCode = event.NewValue.UserData.isLowLevelCode;

            % re-generate and update generated code
            task.getImportCode();
            task.notifyChange();
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Methods for handling state
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        % Get the task state (when saving the task)
        function state = getTaskState(task)

            % Get state from base class
            state = getTaskState@matlab.internal.importdata.ImportProvider(task);

            % Get which code gen type is selected
            state.isLowLevelCode = task.isLowLevelCode;

            % Get which nodes are fully checked
            % (nodes are identified by their IDs)
            if isvalid(task.tree) % only if ui tree has already been created
                state.checkedNodesIDs = arrayfun(@(node) node.NodeData.ID, ...
                    task.tree.CheckedNodes);
            else
                state.checkedNodesIDs = [];
            end

            % Get variable's subsetting options which have been modified
            % (have to save keys and values separately because state struct
            % is saved as JSON and that cannot handle dictionaries, see g2782503)
            state.subsettingOptionsDictKeys = keys(task.subsettingOptionsDict);
            state.subsettingOptionsDictValues = values(task.subsettingOptionsDict);

        end

        % Set the task state (when loading/restoring the task)
        function setTaskState(task, state)

            % set the state for base class functionality
            setTaskState@matlab.internal.importdata.ImportProvider(task, state);

            % set which code gen type is selected
            if state.isLowLevelCode
                % if non-default option is selected (low-level), need to
                % update it in the task
                task.isLowLevelCode = state.isLowLevelCode;
                task.lowlevelcodeButton.Value = true;
            end

            % mark the nodes as checked based on the saved node IDs
            % (note that we don't need to worry about partially checked
            % nodes as they follow from the fully checked nodes)
            if ~isempty(state.checkedNodesIDs)
                % get the nodes that need to be checked using saved IDs
                nodesToCheck = task.treeNodes(state.checkedNodesIDs);
                % update task's properties
                task.tree.CheckedNodes = nodesToCheck;
                task.checkedNodes = task.tree.CheckedNodes;
            end

            % generate subsetting UIs for variables that are checked
            % (this will populate task.subsettingUIDict)
            uncheckedNodes = []; % in this update no nodes have become unchecked
            task.updateSubsettingOptionsUIs(uncheckedNodes);

            % restore the modified subsetting options

            % convert keys back to string array (they get changed to cell
            % array of chars after going through JSON encode/decode)
            state.subsettingOptionsDictKeys = string(state.subsettingOptionsDictKeys);

            % restore task's saved subsetting options
            task.subsettingOptionsDict = dictionary(...
                state.subsettingOptionsDictKeys, ...
                state.subsettingOptionsDictValues);

            % restore the modified numeric field values in subsetting options UI
            for i = 1:length(state.subsettingOptionsDictKeys) % loop over saved subsetting options

                varLocationPath = state.subsettingOptionsDictKeys(i);

                % subsetting options for this variable
                varSubsettingOptions = state.subsettingOptionsDictValues(i);

                task.restoreSubsettingFieldValuesForVariable(varLocationPath, varSubsettingOptions);
            end
        end

        % Given a location path to variable (e.g. "/grp1/var3") and its
        % saved subsetting options (struct with Start/Stride/Count
        % fields), restores the state of numeric edit fields in the
        % variable's subsetting UI to those saved values. Assumes the
        % variable's subsetting UI is already generated.
        function restoreSubsettingFieldValuesForVariable(task, varLocationPath, varSubsettingOptions)

            % grid layout for this variable's subsetting options
            % (children of this layout are Nx1 array of labels and
            % numeric edit fields that constitute the subsetting
            % options UI. Labels are all in the beginning)
            varGridLayout = task.subsettingUIDict(varLocationPath).subsettingGrid;

            % number of dimensions for this var
            varNumDim = length(varSubsettingOptions.Start);

            % This is the first index of a numeric edit field in the
            % children of varGridLayout. Before numeric exit fields
            % varGridLayout contains labels for Start, Stride, Count (3)
            % and labels for all the dimensions
            numericEditFieldInd = 3 + varNumDim + 1;

            % We loop over numeric edit fields in the same order as they
            % were created (start/stride/count for outer loop and
            % dimensions for inner loop)
            for field = ["Start", "Stride", "Count"] % loop over start/stride/count
                % settings for this option (Star or Stride or Count)
                dimSettings = varSubsettingOptions.(field);
                for dimInd = 1:varNumDim % loop over dimensions
                    % update the value of this numeric field
                    varGridLayout.Children(numericEditFieldInd).Value = dimSettings(dimInd);
                    % move over to the next numeric field
                    numericEditFieldInd = numericEditFieldInd + 1;
                end
            end

        end


        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Methods for Code Generation
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        % Return the import code to be executed. The code will create the
        % structure containing imported scientific (netCDF or HDF5) data
        % and will either use high- or low-level interfaces.
        function generatedCode = getImportCode(task)
            arguments
                task (1,1) matlab.internal.importsci.HierarchicalSciImportProvider
            end

            % Generate code to create an empty struct. If nothing is
            % checked in the tree, this is all of the code.
            [~, varName, ~] = fileparts(task.Filename);
            varName = task.getUniqueVarName(varName);

            generatedCode = ...
                "% " + string(getString(...
                message(task.createStructureCommentMessageID))) + ...
                newline + varName + " = struct();";

            % Reset code-generation helper dictionaries to empty,
            % configure them as string->double mapping
            task.countAtStructLevelDict = dictionary(string([]),double([]));
            task.structPathIndicesDict = dictionary(string([]),double([]));

            % Forget any temporary variables that might have been created to
            % store the substructures to manage the nested-ness level
            task.longStructPathWrangler.reset();

            % Determine the strategy for code generation (high- or
            % low-level)
            task.setCodeGenerationStrategy();

            % Add any set-up code as per code generation strategy
            % (e.g. low-level needs to open the file before any import)
            generatedCode = generatedCode + newline + ...
                task.nodeImportCodeGeneratorStrategy.generateSetUpCode();

            % Generate code to store names for partially checked nodes
            % (e.g. name of group when only some of datasets/variables in
            % it are checked)
            partiallyCheckedCode = "";
            for i=1:length(task.partiallyCheckedNodes)
                partChNode = task.partiallyCheckedNodes(i);
                partiallyCheckedCode = partiallyCheckedCode + ...
                    task.generateCodeForPartiallyCheckedNode(partChNode);
            end
            generatedCode = generatedCode + partiallyCheckedCode + newline;

            % Generate import code for each of checked importable nodes
            for i=1:length(task.checkedNodes)
                chNode = task.checkedNodes(i);
                if chNode.NodeData.Type.isImportable()
                    generatedCode = generatedCode + ...
                        task.generateImportCodeForNode(chNode);
                end
            end

            % Add any code needed to use and then clear from workspace the
            % temporary variables that were generated for nested
            % substructures
            generatedCode = generatedCode + ...
                task.longStructPathWrangler.useAndClearVariables();

            % Add any tear-down code as per code generation strategy
            % (e.g. low-level needs to close the file)
            generatedCode = generatedCode + ...
                task.nodeImportCodeGeneratorStrategy.generateTearDownCode();

            % Update the LastCode property
            task.LastCode = generatedCode;
        end

        % Generate code for a partially checked node (e.g. dataset/variable
        % or group node). This is needed to save the group or
        % dataset's/variable's name to the structure if some attributes
        % under this dataset/variable or some datasets/variables inside
        % this group are being imported. For example:
        %     file1.Variables(2).Name = "instrument_state";
        function importNameCode = generateCodeForPartiallyCheckedNode(task, node)

            import matlab.internal.importsci.NodeType;

            importNameCode = "";

            % 1) If some of the attributes of this dataset/variable are
            % being imported, its name should be saved to the struct.
            % (if the dataset/variable *value* is being imported, skip saving
            % the name - it will be saved when the value is saved)
            % 2) If some of the datasets/variables under a group are being
            % imported, its name should be saved to the struct.
            % 3) If some of the attributes under a datatype are being
            % imported, its name should be saved to the struct (datatype
            % node can only be partially checked if it has checked children
            % nodes, which can only happen if some of its attributes are
            % being imported)
            if (node.NodeData.Type == NodeType.DatasetOrVariableWithAtts && ...
                    ~task.isDatasetOrVariableValueBeingImported(node.Children)) || ...
                    node.NodeData.Type == NodeType.Group || ...
                    node.NodeData.Type == NodeType.Datatype
                [structPath, importNameCode] = task.getStructPathAndCode(node);
                importNameCode = importNameCode + newline + ...
                    structPath + ".Name = """ + node.Text + """;" + ...
                    newline;
            end

        end

        % Given an array of children nodes for a DatasetOrVariableWithAtts
        % node, returns true if we are importing the value of this
        % dataset/variable (if the child DatasetOrVariable node is fully
        % checked)
        function isValueBeingImported = isDatasetOrVariableValueBeingImported(task, childrenNodes)
            import matlab.internal.importsci.NodeType;

            isValueBeingImported = false;

            for i = 1:length(childrenNodes)
                node = childrenNodes(i);
                % if this node is a DatasetOrVariable value node and it is
                % checked for import, then we *are* importing the
                % dataset/variable value
                if node.NodeData.Type == NodeType.DatasetOrVariable && ...
                        ismember(node, task.checkedNodes)
                    isValueBeingImported = true;
                    return 
                end
            end
        end

        % Generate code for importing a given node
        function generatedCode = generateImportCodeForNode(task, node)

            import matlab.internal.importsci.NodeType;

            % Get the correct struct path for the node. If it is very
            % nested, there might be some additional code to create
            % temporary variables to store substructures.
            [structPath, generatedCode] = task.getStructPathAndCode(node);

            locationPath = node.NodeData.LocationPath;

            if node.NodeData.Type == NodeType.DatasetOrVariable
                % code for importing a dataset or a variable

                % save the name of the dataset/variable to the struct
                importNameCode = structPath + ".Name = """ + ...
                    node.Text + """;" + newline;

                % determine subsetting options (if any)
                subsettingOptions = struct([]);
                if task.subsettingOptionsDict.isKey(locationPath)
                    subsettingOptions = task.subsettingOptionsDict(locationPath);
                end

                % use the strategy nodeImportCodeGenerator to generate code
                % for this dataset/variable and add it to the code
                importValueCode = ...
                    task.nodeImportCodeGeneratorStrategy.generateImportCodeForVariable(...
                    structPath, locationPath, subsettingOptions);
                generatedCode = generatedCode + ...
                    importNameCode + importValueCode + newline;

            elseif node.NodeData.Type == NodeType.Link
                % code for importing a link (only exist in HDF5 files)

                % Save the name of the link to the struct
                importNameCode = structPath + ".Name = """ + ...
                    node.Text + """;" + newline;

                % Same import code as for a dataset (use the
                % nodeImportCodeGenerator strategy to generate the code)
                subsettingOptions = struct([]); % no subsetting for links
                importValueCode = ...
                    task.nodeImportCodeGeneratorStrategy.generateImportCodeForVariable(...
                    structPath, locationPath, subsettingOptions);
                generatedCode = generatedCode + ...
                    importNameCode + importValueCode + newline;

            elseif node.NodeData.Type == NodeType.Attribute
                % code for importing an attribute

                importNameCode = structPath + ".Name = """ + node.Text + """;" + newline;

                % determine if this is a variable attribute or
                % global/group attribute or datatype attribute
                if isa(node.Parent.Parent, "matlab.ui.container.CheckBoxTree") || ...
                        node.Parent.Parent.NodeData.Type == NodeType.Group
                    % It is a global or group attribute node if its grandparent
                    % is the root of the tree or a group
                    attributeParentType = ...
                        matlab.internal.importsci.AttributeParentType.GlobalOrGroup;
                elseif node.Parent.Parent.NodeData.Type == NodeType.DatasetOrVariableWithAtts
                    % It is a dataset/variable attribute if its grandparent
                    % is a dataset/variable
                    attributeParentType = ...
                        matlab.internal.importsci.AttributeParentType.DatasetOrVariable;
                elseif node.Parent.Parent.NodeData.Type == NodeType.Datatype
                    % It is a datatype attribute if its grandparent is a
                    % datatype (HDF5 supports attributes for
                    % named/committed datatypes)
                    attributeParentType = ...
                        matlab.internal.importsci.AttributeParentType.Datatype;
                end


                % extract attribute's parent location (variable or group)
                % from the complete attribute's location string. For example,
                % "/group1/var1" from  "/group1/var1/att1"
                endPosForVar = strlength(locationPath)-strlength(node.Text);
                parentLocation = extractBefore(locationPath, endPosForVar);

                % use the strategy nodeImportCodeGenerator to generate code
                % for this attribute and add it to the code
                importValueCode = ...
                    task.nodeImportCodeGeneratorStrategy.generateImportCodeForAttribute(...
                    structPath, parentLocation, node.Text, attributeParentType);
                generatedCode = generatedCode + ...
                    importNameCode + importValueCode + newline;

            elseif node.NodeData.Type == NodeType.Group
                % if entire group is being imported, its name should be
                % saved to the struct
                importNameCode = structPath + ".Name = """ + node.Text + """;" + newline;
                generatedCode = generatedCode + importNameCode + newline;

            elseif node.NodeData.Type == NodeType.Datatype
                % if the datatype has attributes and they are all being
                % imported, the datatype's name should be saved to the
                % struct. Only an AttributesCluster node can be a child to a
                % Datatype node.
                if ~isempty(node.Children) && ...
                        node.Children(1).NodeData.Type == NodeType.AttributesCluster
                    importNameCode = structPath + ".Name = """ + node.Text + """;" + newline;
                    generatedCode = generatedCode + importNameCode + newline;
                end
            end


        end

        % Get the struct path to use in the code. If the full path is
        % too nested, all or a part of it might be substituted by a
        % temporary variable. In that case, there might be some
        % additional code to manage the creation of temporary
        % variables.
        function [structPathForCode, generatedCode] = getStructPathAndCode(task, node)

            % get a full struct path
            fullStructPath = structPathFromNode(task, node);

            % if it is too nested, get a less nested struct path by using
            % temporary variables as well as the code needed for creation
            % of those temporary variables
            [structPathForCode, generatedCode] = ...
                task.longStructPathWrangler.generateStructPathAndCode(fullStructPath);
        end

        % Generate a full struct path given a node (e.g.
        % "file1.Variables(2).Attributes(5)"). This method works
        % recursively by going up the tree from a given uinode.
        function structPathString = structPathFromNode(task, node)
            import matlab.internal.importsci.NodeType;

            if isa(node, "matlab.ui.container.CheckBoxTree")
                % If we are at the root of the tree, start the struct path
                % string with the struct variable name (based on the
                % filename)
                [~, varName, ~] = fileparts(task.Filename);
                varName = task.getUniqueVarName(varName);
                structPathString = string(varName);

            elseif node.NodeData.Type == NodeType.AttributesCluster
                % If we are at an Attributes Cluster node, add
                % ".Attributes" to the struct path string
                structPathString = task.structPathFromNode(node.Parent) + ...
                    ".Attributes";

            elseif node.NodeData.Type == NodeType.DatasetsOrVariablesCluster
                % If we are at a Variable/Dataset Cluster node, add
                % ".Variables" or ".Datasets" to the struct path string
                structPathString = task.structPathFromNode(node.Parent) + ...
                    "." + task.datasetOrVariableStructPathField;

            elseif node.NodeData.Type == NodeType.LinksCluster
                % If we are at a Links Cluster node, add
                % ".Links" to the struct path string
                structPathString = task.structPathFromNode(node.Parent) + ...
                    ".Links";

            elseif node.NodeData.Type == NodeType.DatatypesCluster
                % If we are at a Datatypes Cluster node, add
                % ".Datatypes" to the struct path string
                structPathString = task.structPathFromNode(node.Parent) + ...
                    ".Datatypes";

            elseif node.NodeData.Type == NodeType.GroupsCluster
                % If we are at a Group Cluster node, add
                % ".Groups" to the struct path string
                structPathString = task.structPathFromNode(node.Parent) + ...
                    ".Groups";

            elseif (node.NodeData.Type == NodeType.DatasetOrVariable) && ...
                    (node.Parent.NodeData.Type == NodeType.DatasetOrVariableWithAtts)
                % If it is a variable value node with
                % DatasetOrVariableWithAtts as its parent, it has the same
                % struct path as its parent
                structPathString = task.structPathFromNode(node.Parent);

            else
                % It is a node for an individual attribute,
                % variable/dataset, group, or link. This means it needs an
                % index.

                % Get the struct path without the last index (e.g.
                % "file1.Variables(2).Attributes" for the final desired
                % result of "file1.Variables(2).Attributes(5)") by calling
                % the function on the parent node
                structPathStringWithoutIndex = task.structPathFromNode(node.Parent);

                % has it already come up and have an index?
                if task.structPathIndicesDict.isKey(node.NodeData.LocationPath)
                    % get the correct index from the dictionary
                    ind = task.structPathIndicesDict(node.NodeData.LocationPath);

                else % need a new index for this entry

                    % how many entries already at this level in struct?
                    if task.countAtStructLevelDict.isKey(structPathStringWithoutIndex)
                        currentCount = task.countAtStructLevelDict(structPathStringWithoutIndex);
                    else
                        % if this struct level is not in the dictionary, there are no
                        % entries at this level yet
                        currentCount = 0;
                    end

                    % get the correct index by incrementing the current count
                    ind = currentCount + 1;

                    % update count at this level
                    task.countAtStructLevelDict(structPathStringWithoutIndex) = ind;

                    % create a new index entry for this location
                    task.structPathIndicesDict(node.NodeData.LocationPath) = ind;
                end

                % add the index to the end of the struct path string
                % for this node
                structPathString = structPathStringWithoutIndex + "(" + ind + ")";
            end
        end

        % Generate location path given a node (e.g.
        % "/instrument_state/description" for a "description" attribute
        % under an "instrument_state" variable in a root group). This
        % method works recursively.
        function locationString = locationPathFromNode(task, node)

            import matlab.internal.importsci.NodeType;

            if isa(node, "matlab.ui.container.CheckBoxTree")
                % if we are at the root of the tree, start the location string
                locationString = "";

            elseif node.NodeData.Type.isClusterNode()
                % cluster nodes do not add anything to location string
                locationString = task.locationPathFromNode(node.Parent);

            elseif (node.NodeData.Type == NodeType.DatasetOrVariable) && ...
                    (node.Parent.NodeData.Type == NodeType.DatasetOrVariableWithAtts)
                % if it is a variable value node that is a child of
                % "variable with attributes" node, it does not need to add
                % anything to the string (because "variable with
                % attributes" node would have already added the variable
                % name to the location string)
                locationString = task.locationPathFromNode(node.Parent);

            else
                % it is a node for an individual attribute or group
                % or a "Variables with attributes" node or a variable value
                % node for variable without any attributes, add its name to
                % the location string
                locationString = task.locationPathFromNode(node.Parent) + ...
                    "/" + node.Text;
            end
        end

    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Misc Static Helper Functions
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    methods (Static)

        % Take text and surround it in HTML tags to make it bold
        function boldedText = makeHTMLBoldText(normalText)
            arguments
                normalText {mustBeTextScalar}
            end

            if ischar(normalText)
                boldedText = ['<strong>', normalText, '</strong>'];
            elseif isstring(normalText)
                boldedText = "<strong>" + normalText + "</strong>";
            end
        end

    end

end


