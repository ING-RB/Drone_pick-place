% This class is unsupported and might change or be removed without notice in a
% future version.

% This class provides functionality for HDF5 file import.

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

classdef HDF5ImportProvider < matlab.internal.importsci.HierarchicalSciImportProvider

    properties (Hidden)

        % message ID to create label for datasets or variables cluster nodes
        % (HDF5 term is "datasets", so e.g., "Datasets (5)")
        datasetOrVariableClusterNodeMessageID = "import_sci_livetasks:messages:datasetsNodeLabel";

        % message ID for the header for the subsetting options accordion
        % panel
        subsettingOptionsHeaderMessageID = ...
            "import_sci_livetasks:messages:subsettingOptionsHeaderHDF5";

        % message ID for the high-level code generation radio button
        % tooltip
        highLevelTooltipMessageID = ...
            "import_sci_livetasks:messages:highLevelTooltipHDF5";

        % message ID for the low-level code generation radio button
        % tooltip
        lowLevelTooltipMessageID = ...
            "import_sci_livetasks:messages:lowLevelTooltipHDF5";

        % message ID for the search button tooltip
        searchTooltipMessageID = ...
            "import_sci_livetasks:messages:searchTooltipHDF5";

        % message ID for the code comment about creating the structure
        createStructureCommentMessageID = ...
            "import_sci_livetasks:messages:createStructureCommentHDF5"

        % part of the struct path that should be "Datasets" for HDF5 (e.g.,
        % in "example.Groups(1).Datasets(2).Attributes(1)")
        datasetOrVariableStructPathField = "Datasets";

        % --- Code-Generation-related properties

        % high- or low-level code generator strategy
        % (high-level by default)
        nodeImportCodeGeneratorStrategy = matlab.internal.importsci.HighLevelHDF5CodeGenerator("")

        % An object that helps manage the nested-ness level of struct paths
        % by generating code to store substructures in temporary variables
        longStructPathWrangler = matlab.internal.importsci.LongStructPathWrangler(...
            10, ... % maximum allowed nested-ness level
            "struct"); % base name for generated temporary variables
    end

    methods

        % Create an instance of a HDF5ImportProvider
        function this = HDF5ImportProvider(filename)
            arguments
                filename (1,1) string = "";
            end

            this = this@matlab.internal.importsci.HierarchicalSciImportProvider(filename);
            this.FileType = "h5";
        end

        % Return supported file extensions
        function lst = getSupportedFileExtensions(task)
            lst = ["h5", "hdf5"];
        end

        % Return task summary
        function summary = getTaskSummary(task)
            if isempty(task.Filename) || strlength(task.Filename) == 0
                summary = "";
            else
                summary = string(getString(...
                    message("import_sci_livetasks:messages:taskSummaryLabelHDF5", ...
                    "`" + task.Filename + "`")));
            end
        end

        % Overriding the BaseImportTask's method to display "HDF5" rather
        % than just the file extension, "H5"
        function filetype = getFormatForFile(task, filename)
            filetype = "HDF5";
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Methods for building UI interface
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        % Generate the UI tree based on file structure
        function generateTree(task)

            % Reset array of Nodes and Node names to empty
            task.treeNodes = matlab.ui.container.TreeNode.empty();
            task.treeNodesText = string.empty();

            % If we haven't yet, get information about HDF5 file structure
            if isempty(task.fileInfo)
                task.fileInfo = h5info(task.getFullFilename());
            end

            % Create Tree
            task.tree = uitree(task.selectDataGrid, 'checkbox');
            task.tree.Layout.Row = 3; % third row of selectDataGrid
            task.tree.Layout.Column = 1; % first column of selectDataGrid

            % Assign callback in response to node selection
            task.tree.SelectionChangedFcn = ...
                @(source, event) task.nodeSelectedCallback(event);

            % Assign callback in response to nodes being checked/unchecked
            task.tree.CheckedNodesChangedFcn = ...
                @(source, event) task.checkedNodesChangedCallback(event);

            % Create root group Attributes nodes (don't label them as
            % "global" like in netCDF to match h5disp output)
            addGlobalToName = false;
            task.generateAttributesClusterNodes(task.fileInfo.Attributes, ...
                task.tree, addGlobalToName);

            % Create Datatypes nodes (for committed/named datatypes)
            task.generateDatatypesClusterNodes(task.fileInfo.Datatypes, ...
                task.tree);

            % Create Datasets nodes
            task.generateDatasetsOrVariablesClusterNodes(task.fileInfo.Datasets, ...
                task.tree);
            
            % Create Groups nodes
            task.generateGroupsClusterNodes(task.fileInfo.Groups, ...
                task.tree);

            % Create Links nodes
            task.generateLinksClusterNodes(task.fileInfo.Links, ...
                task.tree)

            % Add tooltip to the tree
            task.tree.Tooltip = getString(... 
                message("import_sci_livetasks:messages:treeTooltipHDF5"));

        end

        % Create the label text for individual attribute nodes given a
        % struct containing info about that individual attribute
        % (portion of h5info output)
        function desc = createAttNodePreview(task, attStruct, locationPath)

            % get attribute display text as it would be in h5disp
            dispText = matlab.io.internal.imagesci.HDF5DisplayUtils.displayAttributeValue(attStruct);
            dispText = strip(dispText);
            dispTextArray = splitlines(dispText);

            % desc is a string array with each element of the array
            % representing a new line of text in the metadata label. 
            numLines = 2 + length(dispTextArray); % one line for header, one empty for spacing, 
                                  % and the rest for attribute display
            desc = strings(numLines, 1); 

            % First line is the header of the metadata label and it is made
            % bold using HTML formatting
            desc(1) = ...
                matlab.internal.importsci.HierarchicalSciImportProvider.makeHTMLBoldText(...
                string(locationPath));

            % Starting from third line, show h5disp output
            desc(3:end) = dispTextArray;

        end

        % Crate text representation of attribute value
        function dispText = attributeValueDisplay(task, attStruct)
            % Get the attribute value display string as it is in h5disp
            dispText = matlab.io.internal.imagesci.HDF5DisplayUtils.displayAttributeValue(attStruct);
            dispText = strip(dispText);
        end

        % Generate node for an individual dataset ("dataset value" node)
        % given a struct containing that dataset's info (portion of h5info
        % output)
        function generateDatasetOrVariableValueNode(task, datasetStruct, parentNode)

            datasetNode = task.addTreeNode(parentNode, datasetStruct.Name);
            % generate node data
            datasetNode.NodeData.Type = matlab.internal.importsci.NodeType.DatasetOrVariable;
            datasetNode.NodeData.LocationPath = task.locationPathFromNode(datasetNode);
            datasetNode.NodeData.Label = task.createDatasetOrVariableNodePreview(datasetStruct, ...
                datasetNode.NodeData.LocationPath);

            % extract dimension info from dataspace
            datasetNode.NodeData.Dimensions = [];
            for dimInd = 1:length(datasetStruct.Dataspace.Size)
                % there are no named dimensions in HDF5, so the dimensions
                % (and the subsetting columns) are just named Dimension #1,
                % Dimension #2, etc.
                dimensionLabel = getString(... 
                    message("import_sci_livetasks:messages:dimensionLabelHDF5", ...
                    dimInd)); 
                datasetNode.NodeData.Dimensions(dimInd).Name = ...
                    string(dimensionLabel);
                datasetNode.NodeData.Dimensions(dimInd).Length = ...
                    datasetStruct.Dataspace.Size(dimInd);
            end
            
            % if it is a non-scalar dataset (has dimensions), add it to
            % the subsetting UI dictionary (row index corresponds to the
            % depth-first order the dataset nodes are added to the tree)
            if ~isempty(datasetNode.NodeData.Dimensions)
                datasetSubsettingUIInfo.rowInd = task.subsettingUIDict.numEntries + 1;
                datasetSubsettingUIInfo.subsettingGrid = []; % the subsetting UI is not generated yet
                task.subsettingUIDict(datasetNode.NodeData.LocationPath) = datasetSubsettingUIInfo;
            end
        end


        % Create the label text for an individual dataset node given a
        % struct containing info about that individual dataset
        % (portion of h5info output)
        function desc = createDatasetOrVariableNodePreview(task, datasetStruct, locationPath)
            % desc is a string array with each element of the array
            % representing a new line of text in the metadata label.

            % get dataset display text as it would be in h5disp
            context.source = 'dataset';
            context.mode = 'simple';
            indentLevel = 0;
            dispTxt = matlab.io.internal.imagesci.HDF5DisplayUtils.displayDataspace(datasetStruct.Dataspace, indentLevel);
            dispTxt = dispTxt + matlab.io.internal.imagesci.HDF5DisplayUtils.displayDatatype(datasetStruct.Datatype,context, indentLevel);
            dispTxt = dispTxt + matlab.io.internal.imagesci.HDF5DisplayUtils.displayChunking(datasetStruct.ChunkSize, indentLevel);
            dispTxt = dispTxt + matlab.io.internal.imagesci.HDF5DisplayUtils.displayFilters(datasetStruct.Filters, context, indentLevel);
            dispTxt = dispTxt + matlab.io.internal.imagesci.HDF5DisplayUtils.displayFillValue(datasetStruct, context, indentLevel);
           
            % convert it to string array
            dispTextArray = splitlines(dispTxt);

            % desc is a string array with each element of the array
            % representing a new line of text in the metadata label.
            numLines = 2 + length(dispTextArray); % one line for header, one empty for spacing,
            % and the rest is for h5disp text
            desc = strings(numLines, 1);

            % First line is the header of the metadata label and it is made
            % bold using HTML formatting
            desc(1) = ...
                matlab.internal.importsci.HierarchicalSciImportProvider.makeHTMLBoldText(...
                string(locationPath));

            % From line 3 it is the text from h5disp
            desc(3:end) = dispTextArray;
        end


        % Generate groups "cluster" node (e.g. "Groups (5)") and all the
        % nodes for individual groups given a struct containing
        % group info (portion of h5info output)
        function generateGroupsClusterNodes(task, groupsStruct, parentNode)

            import matlab.internal.importsci.NodeType;

            numGroups = length(groupsStruct);
            if numGroups==0
                return
            end
            groupText = getString(... % node text is stored as character vector independent of input type
                message("import_sci_livetasks:messages:groupsNodeLabel", ...
                numGroups));
            groupsNode = task.addTreeNode(parentNode, groupText);

            % generate node data
            groupsNode.NodeData.Type = NodeType.GroupsCluster;
            groupsNode.NodeData.Label = ""; % currently no preview for groups cluster nodes

            % Generate nodes for individual groups
            for i=1:numGroups
                % for HDF5, h5info output contains the group's full location path
                groupLocation = string(groupsStruct(i).Name);

                % determine group name by removing the rest of the path
                slashInds = strfind(groupLocation, "/");
                lastSlashInd = slashInds(end);
                groupName = extractAfter(groupLocation, lastSlashInd);

                % add group node to tree
                groupNode = task.addTreeNode(groupsNode, groupName);

                % generate node data
                groupNode.NodeData.Type = NodeType.Group;
                groupNode.NodeData.Label = ""; % currently no preview for group nodes
                groupNode.NodeData.LocationPath = groupLocation;

                % Groups can have associated Attributes, named Datatypes,
                % Datasets, nested Groups, or Links
                task.generateAttributesClusterNodes(groupsStruct(i).Attributes, ...
                    groupNode, false);
                task.generateDatatypesClusterNodes(groupsStruct(i).Datatypes, ...
                    groupNode);
                task.generateDatasetsOrVariablesClusterNodes(groupsStruct(i).Datasets, ...
                    groupNode);
                task.generateGroupsClusterNodes(groupsStruct(i).Groups, groupNode);
                task.generateLinksClusterNodes(groupsStruct(i).Links, groupNode)
            end

        end

        % Create a node representing a committed/named datatype given a
        % struct containing that datatype's info (portion of h5info output)
        function generateDatatypeNode(task, datatypeStruct, parentNode)

            % for HDF5, h5info output contains the datatypes's full location path
            datatypeLocation = string(datatypeStruct.Name);

            % determine datatype name by removing the rest of the path
            slashInds = strfind(datatypeLocation, "/");
            lastSlashInd = slashInds(end);
            datatypeName = extractAfter(datatypeLocation, lastSlashInd);

            % add datatype node
            datatypeNode = task.addTreeNode(parentNode, ...
                datatypeName);

            % generate node data
            datatypeNode.NodeData.Type = matlab.internal.importsci.NodeType.Datatype;
            datatypeNode.NodeData.LocationPath = datatypeLocation;
            datatypeNode.NodeData.Label = ...
                task.createDatatypeNodePreview(datatypeStruct, ...
                datatypeNode.NodeData.LocationPath);

            % named datatypes can have their own attributes - generate
            % attribute nodes if needed
            task.generateAttributesClusterNodes(datatypeStruct.Attributes, ...
                datatypeNode, false);
        end

        % Create the label text for an individual datatype node given a struct
        % containing info about that datatype (portion of h5info output) The
        % label shows named/committed datatypes's underlying datatype and
        % further details if the underlying datatype is complex (e.g.,
        % string length, padding, character set and type for H5T_STRING, or
        % details about members for H5T_COMPOUND).
        function desc = createDatatypeNodePreview(task, datatypeStruct, locationPath)

            % get datatype display text as it would be in h5disp
            indentLevel = 0;
            context.source = 'datatype';
            dispText = ...
                matlab.io.internal.imagesci.HDF5DisplayUtils.displayDatatypeByClass(...
                datatypeStruct, context, indentLevel);
            dispText = strip(dispText);
            dispTextArray = splitlines(dispText);

            % desc is a string array with each element of the array
            % representing a new line of text in the metadata label.
            numLines = 2 + length(dispTextArray); % one line for header, one empty for spacing,
            % and the rest for datatype display text
            desc = strings(numLines, 1);

            % First line is the header of the metadata label and it is made
            % bold using HTML formatting
            desc(1) = ...
                matlab.internal.importsci.HierarchicalSciImportProvider.makeHTMLBoldText(...
                locationPath);

            % Starting from third line, show h5disp output (first and
            % second lines are for the header and a blank line after it)
            desc(3:end) = dispTextArray;
        end

        % Generate links "cluster" node (e.g. "Links (5)") and all the
        % nodes for individual links given a struct containing
        % link info (portion of h5info output)
        function generateLinksClusterNodes(task, linksStruct, parentNode)

            numLinks = length(linksStruct);
            
            % skip creating Links node if there are no Links
            if numLinks==0
                return
            end

            % node text is stored as character vector independent of input
            % type, so not converting it to string here
            linksText = getString(... 
                message("import_sci_livetasks:messages:linksNodeLabel", numLinks));
            linksNode = task.addTreeNode(parentNode, linksText);

            % generate node data
            linksNode.NodeData.Type = ...
                matlab.internal.importsci.NodeType.LinksCluster;
            linksNode.NodeData.Label ...
                = task.createLinksClusterNodePreview(linksStruct, linksText);

            % Generate nodes for individual links
            for i=1:numLinks
                linkNode = task.addTreeNode(linksNode,...
                    linksStruct(i).Name);
                % generate node data
                linkNode.NodeData.Type = matlab.internal.importsci.NodeType.Link;
                linkNode.NodeData.LocationPath = task.locationPathFromNode(linkNode);
                linkNode.NodeData.Label = task.createLinkNodePreview(linksStruct(i), ...
                    linkNode.NodeData.LocationPath);
            end
        end


        % Label text for the links cluster node, i.e. "Links (5)"
        function desc = createLinksClusterNodePreview(task, linksStruct, linkText)
            desc = ""; % no display for links cluster node for now
        end


        % Create the label text for an individual link node given a struct
        % containing info about that link (portion of h5info output) The
        % label shows link's type and target.
        function desc = createLinkNodePreview(task, linkStruct, locationPath)

            % get link display text as it would be in h5disp
            indentLevel = 0;
            dispText = ...
                matlab.io.internal.imagesci.HDF5DisplayUtils.displayLinkMetadata(...
                linkStruct, indentLevel);
            dispText = strip(dispText);
            dispTextArray = splitlines(dispText);

            % desc is a string array with each element of the array
            % representing a new line of text in the metadata label. 
            numLines = 2 + length(dispTextArray); % one line for header, one empty for spacing, 
                                  % and the rest for link display text
            desc = strings(numLines, 1); 

            % First line is the header of the metadata label and it is made
            % bold using HTML formatting
            desc(1) = ...
                matlab.internal.importsci.HierarchicalSciImportProvider.makeHTMLBoldText(...
                locationPath);

            % Starting from third line, show h5disp output
            desc(3:end) = dispTextArray;
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Methods for Code Generation
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        % Set nodeImportCodeGeneratorStrategy property which controls how
        % the code is generated (using high- or low-level HDF5
        % interfaces)
        function setCodeGenerationStrategy(task)
            % Determine the strategy for code generation (high- or
            % low-level)
            if task.isLowLevelCode
                task.nodeImportCodeGeneratorStrategy = ...
                    matlab.internal.importsci.LowLevelHDF5CodeGenerator(task.getFullFilename());
            else
                task.nodeImportCodeGeneratorStrategy = ...
                    matlab.internal.importsci.HighLevelHDF5CodeGenerator(task.getFullFilename());
            end
        end

    end

end


