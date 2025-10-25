% This class is unsupported and might change or be removed without notice in a
% future version.

% This class provides functionality for NetCDF file import.

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

% Copyright 2022-2023 The MathWorks, Inc.

classdef NetCDFImportProvider < matlab.internal.importsci.HierarchicalSciImportProvider

    properties (Hidden)

        % message ID to create label for variables or datasets cluster nodes
        % (netCDF term is "variables", so e.g., "Variables (5)")
        datasetOrVariableClusterNodeMessageID = "import_sci_livetasks:messages:variablesNodeLabel";

        % message ID for the header for the subsetting options accordion
        % panel
        subsettingOptionsHeaderMessageID = ...
            "import_sci_livetasks:messages:subsettingOptionsHeaderNetCDF";

        % message ID for the high-level code generation radio button
        % tooltip
        highLevelTooltipMessageID = ...
            "import_sci_livetasks:messages:highLevelTooltipNetCDF";

        % message ID for the low-level code generation radio button
        % tooltip
        lowLevelTooltipMessageID = ...
            "import_sci_livetasks:messages:lowLevelTooltipNetCDF";

        % message ID for the search button tooltip
        searchTooltipMessageID = ...
            "import_sci_livetasks:messages:searchTooltipNetCDF"

        % message ID for the code comment about creating the structure
        createStructureCommentMessageID = ...
            "import_sci_livetasks:messages:createStructureCommentNetCDF";

        % part of the struct path that should be "Variables" for netCDF
        % (e.g., in "example.Groups(1).Variables(2).Attributes(1)")
        datasetOrVariableStructPathField = "Variables";

        % --- Code-Generation-related properties

        % high- or low-level code generator strategy
        % (high-level by default)
        nodeImportCodeGeneratorStrategy = matlab.internal.importsci.HighLevelNetCDFCodeGenerator("")

        % An object that helps manage the nested-ness level of struct paths
        % by generating code to store substructures in temporary variables
        longStructPathWrangler = matlab.internal.importsci.LongStructPathWrangler(...
            10, ... % maximum allowed nested-ness level
            "struct"); % base name for generated temporary variables

    end

    methods

        % Create an instance of a NetCDFImportProvider
        function this = NetCDFImportProvider(filename)
            arguments
                filename (1,1) string = "";
            end

            this = this@matlab.internal.importsci.HierarchicalSciImportProvider(filename);
            this.FileType = "nc";
        end

        % Return supported file extensions
        function lst = getSupportedFileExtensions(task)
            lst = "nc";
        end

        % Return task summary
        function summary = getTaskSummary(task)
            if isempty(task.Filename) || strlength(task.Filename) == 0
                summary = "";
            else
                summary = string(getString(...
                    message("import_sci_livetasks:messages:taskSummaryLabelNetCDF", ...
                    "`" + task.Filename + "`")));
            end
        end

        % Overriding the BaseImportTask's method to display the netCDF
        % file's "flavor" rather than just the file extension (e.g.
        % 'netcdf4' or 'classic', etc.)
        function filetype = getFormatForFile(task, filename)

            % If we haven't yet, get information about netCDF file structure
            if isempty(task.fileInfo)
                task.fileInfo = ncinfo(filename);
            end

            filetype = task.fileInfo.Format;
        end


        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Methods for building UI interface
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        % Generate the UI tree based on file structure
        function generateTree(task)

            % Reset array of Nodes and Node names to empty
            task.treeNodes = matlab.ui.container.TreeNode.empty();
            task.treeNodesText = string.empty();

            % If we haven't yet, get information about netCDF file structure
            if isempty(task.fileInfo)
                task.fileInfo = ncinfo(task.getFullFilename());
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

            % Create Global Attributes nodes
            task.generateAttributesClusterNodes(task.fileInfo.Attributes, ...
                task.tree, true);

            % Create Dimensions nodes
            task.generateDimensionsClusterNodes(task.fileInfo.Dimensions, ...
                task.tree);

            % Create Datatypes nodes (for User-Defined Datatypes)
            task.generateDatatypesClusterNodes(task.fileInfo.Datatypes, ...
                task.tree);

            % Refresh the screen as some visual "piece" of the UI is ready
            % to be rendered. Do not wait for this call to be complete to
            % move on.
            matlab.graphics.internal.drawnow.startUpdate()

            % Create Variables nodes
            task.generateDatasetsOrVariablesClusterNodes(task.fileInfo.Variables, ...
                task.tree);

            % Refresh the screen as some visual "piece" of the UI is ready
            % to be rendered. Do not wait for this call to be complete to
            % move on.
            matlab.graphics.internal.drawnow.startUpdate()

            % Create Groups nodes
            task.generateGroupsClusterNodes(task.fileInfo.Groups, ...
                task.tree);

            % Add tooltip to the tree
            task.tree.Tooltip = getString(... % tooltip text is stored as character vector independent of input type
                message("import_sci_livetasks:messages:treeTooltipNetCDF"));
            
            % Refresh the screen as some visual "piece" of the UI is ready
            % to be rendered. Do not wait for this call to be complete to
            % move on.
            matlab.graphics.internal.drawnow.startUpdate()
        end


        % Create the label text for individual attribute nodes given a
        % struct containing info about that individual attribute
        % (portion of ncinfo output)
        function desc = createAttNodePreview(task, attStruct, locationPath)
            % desc is a string array with each element of the array
            % representing a new line of text in the metadata label. 
            desc = strings(3, 1); % one line for header, one empty for spacing, 
                                  % and one for attribute's value

            % First line is the header of the metadata label and it is made
            % bold using HTML formatting
            desc(1) = ...
                matlab.internal.importsci.NetCDFImportProvider.makeHTMLBoldText(...
                string(locationPath));

            % Third line is the attribute value
            desc(3) = task.attributeValueDisplay(attStruct);
        end


        % Crate text representation of attribute value
        function dispText = attributeValueDisplay(task, attStruct)
            % no extra identation for starting new lines in the display text 
            indentationSpace = ''; 
            dispText =  internal.matlab.imagesci.nc.dispStringAttValue(...
                attStruct.Value, indentationSpace);
        end

        % Generate node for an individual variable ("variable value" node)
        % given a struct containing that variable's info (portion of ncinfo
        % output)
        function generateDatasetOrVariableValueNode(task, varStruct, parentNode)
            varNode = task.addTreeNode(parentNode, varStruct.Name);
            % generate node data
            varNode.NodeData.Type = matlab.internal.importsci.NodeType.DatasetOrVariable;
            varNode.NodeData.LocationPath = task.locationPathFromNode(varNode);
            varNode.NodeData.Label = task.createDatasetOrVariableNodePreview(varStruct, ...
                varNode.NodeData.LocationPath);
            varNode.NodeData.Dimensions = varStruct.Dimensions;

            % if it is a non-scalar variable (has dimensions), add it to
            % the subsetting UI dictionary (row index corresponds to the
            % depth-first order the variable nodes are added to the tree)
            if ~isempty(varNode.NodeData.Dimensions)
                varSubsettingUIInfo.rowInd = task.subsettingUIDict.numEntries + 1;
                varSubsettingUIInfo.subsettingGrid = []; % the subsetting UI is not generated yet
                task.subsettingUIDict(varNode.NodeData.LocationPath) = varSubsettingUIInfo;
            end
        end

        % Create the label text for an individual variable node given a
        % struct containing info about that individual variable
        % (portion of ncinfo output)
        function desc = createDatasetOrVariableNodePreview(task, varStruct, locationPath)
            % desc is a string array with each element of the array
            % representing a new line of text in the metadata label. 

            % 1 line for header, 1 empty line for spacing, 1 for size, 
            % 1 for dimensions, and 1 for datatype
            numLines = 5;
            desc = strings(numLines, 1);

            % First line is the header of the metadata label and it is made
            % bold using HTML formatting
            desc(1) = ...
                matlab.internal.importsci.NetCDFImportProvider.makeHTMLBoldText(...
                string(locationPath)); 

            % Third line is about variable's size
            sizeText = ...
                string(getString(message("import_sci_livetasks:messages:sizeMetadataLabel"))) + ...
                " " + join(string(varStruct.Size), "x");
            desc(3) = sizeText; % skipped 2nd line for spacing

            % Fourth line is about variable's dimensions
            dimText = ...
                string(getString(message("import_sci_livetasks:messages:dimensionsMetadataLabel"))) + ...
                " ";
            for i=1:length(varStruct.Dimensions)
                dimText = dimText + task.dimText(varStruct.Dimensions(i));
                if i ~= length(varStruct.Dimensions)
                    dimText = dimText + ", ";
                end
            end
            % add explanation for scalar variables (has no dimensions)
            if isempty(varStruct.Dimensions)
                dimText = dimText + ...
                    string(getString(message(...
                    "import_sci_livetasks:messages:scalarVarDimMetadataLabel")));
            end
            desc(4) = dimText;

            % Fifth line is about variable's datatype
            datatypeText = string(getString(message(...
                "import_sci_livetasks:messages:datatypeMetadataLabel"))) + ...
                " " + string(varStruct.Datatype);
            desc(5) = datatypeText;
        end

        % Create the label text for Dimensions "cluster" node (e.g.
        % "Dimensions (10)") given a struct containing info about
        % dimensions (portion of ncinfo output)
        function desc = createDimensionsClusterNodePreview(task, dimStruct, dimText)
            % desc is a string array with each element of the array
            % representing a new line of text in the metadata label. 
            numLines = length(dimStruct) + 2; % +2 for header line and the following empty line
            desc = strings(numLines, 1);

            % First line is the header of the metadata label and it is made
            % bold using HTML formatting
            desc(1) = ...
                matlab.internal.importsci.NetCDFImportProvider.makeHTMLBoldText(...
                string(dimText)); 

            for i=1:length(dimStruct)
                dimText = task.dimText(dimStruct(i));
                lineIndex = i + 2 ; % skip header line and empty line
                desc(lineIndex) = dimText;
            end

        end

        % Create the label text for an individual dimension node
        % given a struct containing info about that dimension
        % (portion of ncinfo output)
        % The label shows dimension name, its length and whether it is
        % UNLIMITED
        function desc = createDimNodePreview(task, dimStruct)

            % desc is a string array with each element of the array
            % representing a new line of text in the metadata label. 
            
            % One line for header, one empty for spacing, one for dimension
            % display
            desc = strings(3, 1); 

            % First line is the header of the metadata label and it is made
            % bold using HTML formatting
            desc(1) = ...
                matlab.internal.importsci.NetCDFImportProvider.makeHTMLBoldText(...
                string(dimStruct.Name));

            dispText = string(dimStruct.Length);
            if dimStruct.Unlimited == 1
                dispText = dispText + ", " + ...
                    string(getString(message(...
                    "import_sci_livetasks:messages:unlimitedDimMetadataLabel")));
            end
            desc(3) = dispText;
        end

        % Generate text about an individual dimension including its size
        % info given a struct containing info about that dimension
        % (portion of ncinfo output). For example
        %   atrack (45)
        % or
        %   xtrack (30, UNLIMITED)
        function dispText = dimText(~, dimStruct)
            dispText = string(dimStruct.Name) + " (" + string(dimStruct.Length);
            if dimStruct.Unlimited == 1
                dispText = dispText + ", " + ...
                    string(getString(message(...
                    "import_sci_livetasks:messages:unlimitedDimMetadataLabel")));
            end
            dispText = dispText + ")";
        end

        % Generate dimensions "cluster" node (e.g. "Dimensions (5)") and all the
        % nodes for individual dimensions given a struct containing
        % dimension info (portion of ncinfo output)
        function generateDimensionsClusterNodes(task, dimsStruct, parentNode)
            numDims = length(dimsStruct);
            
            % skip creating Dimensions node if there are no dimensions
            if numDims==0
                return
            end

            dimText = getString(... % node text is stored as character vector independent of input type
                message("import_sci_livetasks:messages:dimensionsNodeLabel", numDims));
            dimensionsNode = task.addTreeNode(parentNode, dimText);
            % generate node data
            dimensionsNode.NodeData.Type = ...
                matlab.internal.importsci.NodeType.DimensionsCluster;
            dimensionsNode.NodeData.Label ...
                = createDimensionsClusterNodePreview(task, dimsStruct, dimText);

            % Generate nodes for individual dimensions
            for i=1:numDims
                dimNode = task.addTreeNode(dimensionsNode,...
                    dimsStruct(i).Name);
                % generate node data
                dimNode.NodeData.Type = matlab.internal.importsci.NodeType.Dimension;
                dimNode.NodeData.Label = task.createDimNodePreview(dimsStruct(i));
            end
        end

        % Generate groups "cluster" node (e.g. "Groups (5)") and all the
        % nodes for individual groups given a struct containing
        % group info (portion of ncinfo output)
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
                groupNode = task.addTreeNode(groupsNode, groupsStruct(i).Name);
                % generate node data
                groupNode.NodeData.Type = NodeType.Group;
                groupNode.NodeData.Label = ""; % currently no preview for group nodes
                groupNode.NodeData.LocationPath = task.locationPathFromNode(groupNode);

                % Groups can have associated Dimensions, Attributes,
                % Variables or nested groups
                task.generateDimensionsClusterNodes(groupsStruct(i).Dimensions,...
                    groupNode)
                task.generateAttributesClusterNodes(groupsStruct(i).Attributes, ...
                    groupNode, false);
                task.generateDatasetsOrVariablesClusterNodes(groupsStruct(i).Variables, ...
                    groupNode);
                task.generateGroupsClusterNodes(groupsStruct(i).Groups, groupNode);
            end
        end

        % Generate node for an individual datatype given a struct
        % containing that datatype's info (portion of ncinfo output)
        function generateDatatypeNode(task, datatypeStruct, parentNode)

            % add datatype node
            datatypeNode = task.addTreeNode(parentNode, ...
                datatypeStruct.Name);

            % generate node data
            datatypeNode.NodeData.Type = matlab.internal.importsci.NodeType.Datatype;
            datatypeNode.NodeData.Label = ...
                task.createDatatypeNodePreview(datatypeStruct, ...
                datatypeStruct.Name);
            datatypeNode.NodeData.LocationPath = ...
                task.locationPathFromNode(datatypeNode);

        end

        % Create the label text for an individual datatype node given a struct
        % containing info about that datatype (portion of ncinfo output) The
        % label shows datatypes's Class, Type, and ByteSize
        function desc = createDatatypeNodePreview(task, datatypeStruct, datatypeName)

            % desc is a string array with each element of the array
            % representing a new line of text in the metadata label. 

            % name will be already part of the display - prepare the
            % remaining information
            remainingInfo = rmfield(datatypeStruct, 'Name');
            fields = fieldnames(remainingInfo);
            numFields = length(fields);
            
            % One line for header, one empty for spacing, and the rest for
            % remaining info (one for Class, one for Type, and one for
            % ByteSize)
            desc = strings(2 + numFields, 1); 

            % First line is the header of the metadata label and it is made
            % bold using HTML formatting. 
            % It is the name of the datatype.
            desc(1) = ...
                matlab.internal.importsci.NetCDFImportProvider.makeHTMLBoldText(...
                string(datatypeName));

            % add the remaining fields to the display text starting from
            % the third line
            for i = 1:numFields
                fieldName = string(fields{i});
                desc(2+i) = fieldName + ": " + remainingInfo.(fieldName);
            end
            
        end


        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Methods for Code Generation
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        % Set nodeImportCodeGeneratorStrategy property which controls how
        % the code is generated (using high- or low-level netCDF
        % interfaces)
        function setCodeGenerationStrategy(task)
            % Determine the strategy for code generation (high- or
            % low-level)
            if task.isLowLevelCode
                task.nodeImportCodeGeneratorStrategy = ...
                    matlab.internal.importsci.LowLevelNetCDFCodeGenerator(task.getFullFilename());
            else
                task.nodeImportCodeGeneratorStrategy = ...
                    matlab.internal.importsci.HighLevelNetCDFCodeGenerator(task.getFullFilename());
            end
        end

    end

end


