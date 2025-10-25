% This class is unsupported and might change or be removed without notice in a
% future version.

classdef LowLevelHDF5CodeGenerator < matlab.internal.importsci.AbstractNodeImportCodeGenerator
    %LOWLEVELHDF5CODEGENERATOR
    %   Strategy class for generating low-level code for importing
    %   HDF5 datasets and attributes

    % Copyright 2023 The MathWorks, Inc.

    properties (Hidden)

        % Dictionary of dataset IDs. This dictionary keeps track of the
        % HDF5 datasets which have already been opened. The dictionary maps
        % the full dataset location path to the corresponding identifier
        % variable in MATLAB. For example:
        %     "/g4/lat" -> "dsID1"
        dsIDsDict = dictionary(string([]), string([]));

        % Dictionary of group IDs. This dictionary keeps track of the HDF5
        % groups which have already been opened. The dictionary maps the
        % full group location path to the corresponding identifier variable
        % in MATLAB. For example:
        %     "/g1/g1.1" -> "groupID2"
        groupIDsDict = dictionary(string([]), string([]));

        % Dictionary of datatype IDs. This dictionary keeps track of the
        % HDF5 committed/named datatypes which have already been opened.
        % The dictionary maps the full datatype location path to the
        % corresponding identifier variable in MATLAB. For example:
        %     "/MyGroup/MyDoubleDatatype" -> "typeID2"
        typeIDsDict = dictionary(string([]), string([]));

        % number of attribute IDs; it is needed to number the MATLAB variables
        % that store attribute IDs (i.e., "attrID1", "attrID2", etc.)
        numAtts = 0;

        % number of memory dataspace IDs; it is needed to number the MATLAB variables
        % that store memspace IDs (i.e., "memSpaceID1", "memSpaceID2", etc.)
        % Memory dataspace identifier describes how the data is to be
        % arranged in memory and is needed for reading a hyperslab from a
        % dataset.
        numMemSpaces = 0;

        % number of file dataspace IDs; it is needed to number the MATLAB variables
        % that store filespace IDs (i.e., "fileSpaceID1", "fileSpaceID2", etc.)
        % File dataspace identifier describes how the data is to be
        % selected from the file and is needed for reading a hyperslab from
        % a dataset.
        numFileSpaces = 0;

    end

    methods (Access=public)

        % Create an instance of a LowLevelHDF5CodeGenerator
        function this = LowLevelHDF5CodeGenerator(filename)
            arguments
                filename (1,1) string
            end

            this.Filename = filename;
        end

        % Method to generate any set up code
        % (implementation for the abstract method of parent class)
        function code = generateSetUpCode(obj)
            arguments
                obj matlab.internal.importsci.LowLevelHDF5CodeGenerator
            end

            % for low-level code, need to open the file before doing
            % anything else
            code = newline + ...
                "% " + string(getString(...
                message("import_sci_livetasks:messages:openFileCommentHDF5"))) + ...
                newline + "fileID = H5F.open(""" + obj.Filename + """);" + ...
                newline;

        end

        % Method to generate any tear down code
        % (implementation for the abstract method of parent class)
        function code = generateTearDownCode(obj)
            arguments
                obj matlab.internal.importsci.LowLevelHDF5CodeGenerator
            end

            code = "";

            % generate code to close group IDs and clear the MATLAB
            % variables storing those IDs
            extraLine = "";
            if obj.groupIDsDict.numEntries ~= 0
                code = code + newline + ...
                    "% " + string(getString(...
                    message("import_sci_livetasks:messages:clearGroupsCommentHDF5")));
                extraLine = newline;
            end
            for groupID = (obj.groupIDsDict.values')
                code = code + newline + "H5G.close(" + groupID + ")" + ...
                    newline + "clear " + groupID;
            end

            % generate code to close dataset IDs and clear the MATLAB
            % variables storing those IDs
            if obj.dsIDsDict.numEntries ~= 0
                code = code + newline + extraLine + ...
                    "% " + string(getString(...
                    message("import_sci_livetasks:messages:clearDatasetsCommentHDF5")));
                extraLine = newline;
            end
            for dsID = (obj.dsIDsDict.values')
                code = code + newline + "H5D.close(" + dsID + ")" + ...
                    newline + "clear " + dsID;
            end

            % generate code to close datatype IDs and clear the MATLAB
            % variables storing those IDs
            if obj.typeIDsDict.numEntries ~= 0
                code = code + newline + extraLine + ...
                    "% " + string(getString(...
                    message("import_sci_livetasks:messages:clearDatatypesCommentHDF5")));
                extraLine = newline;
            end
            for typeID = (obj.typeIDsDict.values')
                code = code + newline + "H5T.close(" + typeID + ")" + ...
                    newline + "clear " + typeID;
            end

            % generate code to close the file and clear the file ID
            % MATLAB variable
            code = code + newline + extraLine + ...
                "% " + string(getString(message(...
                "import_sci_livetasks:messages:closeFileCommentHDF5"))) + ...
                newline + "H5F.close(fileID)" + newline + ...
                "clear fileID" + newline;
            
        end
    end

    % Implementation of the abstract helper strategy methods which are not
    % part of the public interface. They are called by the abstract
    % superclass' public template method.
    methods (Access=protected)

        % Method to generate code for importing variable/dataset value
        % (implementation for the abstract method of parent class)
        function importCode = generateImportCodeForVariableStrategy(obj,...
                structPath, locationPath, subsettingOptions)

            importCode = "";

            % determine the dataset ID for this dataset and add code for
            % getting that dataset ID
            [dsID, dsIDCode] = obj.getDatasetID(locationPath);
            importCode = importCode + dsIDCode;

            % Does this dataset have any subsetting options?
            if isempty(subsettingOptions) 
                % code to get the full dataset value (without subsetting)
                % For example:
                %      file1.Groups(1).Groups(1).Datasets(1).Value = H5D.read(dsID2);
                % 
                importCode = importCode + ...
                    structPath + ".Value = H5D.read(" + dsID + ");" + newline;

            else
                % code to read dataset value with hyperslab/subsetting options
                % For example 
                % (with start = [3 1], stride = [1 2], count = [7 5]):
                %
                % dsID2 = H5D.open(fileID, "/g1/g1.1/dset1.1.1");
                % start = fliplr([3 1]) - 1; % C-style (row-major) dimension order, 0-based indexing
                % stride = fliplr([1 2]);    % C-style (row-major) dimension order
                % count = fliplr([7 5]);     % C-style (row-major) dimension order
                % memSpaceID1 = H5S.create_simple(length(count), count, []);
                % fileSpaceID1 = H5D.get_space(dsID2);
                % H5S.select_hyperslab(fileSpaceID1, "H5S_SELECT_SET", start, stride, count, [])
                % example.Groups(1).Groups(1).Datasets(2).Value = H5D.read(dsID2, "H5ML_DEFAULT", memSpaceID1, fileSpaceID1, "H5P_DEFAULT");
                % H5S.close(fileSpaceID1)
                % clear fileSpaceID1
                % H5S.close(memSpaceID1)
                % clear memSpaceID1
                % clear start
                % clear stride
                % clear count

                % format the subsetting options into strings
                % (in the format like "[2 5]")
                startString = "[" + join(string(subsettingOptions.Start)) + "]";
                countString = "[" + join(string(subsettingOptions.Count)) + "]";
                strideString = "[" + join(string(subsettingOptions.Stride)) + "]";

                % code lines to create temporary variables for subsetting
                % options
                startLine = "start = fliplr(" + startString + ") - 1;";
                strideLine = "stride = fliplr(" + strideString + ");";
                countLine = "count = fliplr("+ countString +");";

                % pad the code lines to correctly align inline
                % comments
                subsetTempVarLines = pad([startLine, strideLine, countLine]);

                % putting together code and comments for temporary
                % start/stride/count variables
                subsettingVarsCode = ...
                    subsetTempVarLines(1) + " % " + string(getString(message(...
                    "import_sci_livetasks:messages:subsettingRowMajorComment"))) + ...
                    ", " + string(getString(message(...
                    "import_sci_livetasks:messages:subsettingZeroBasedComment"))) + ...
                    newline + ... % start
                    subsetTempVarLines(2) + " % " + string(getString(message(...
                    "import_sci_livetasks:messages:subsettingRowMajorComment"))) + ...
                    newline + ... % stride
                    subsetTempVarLines(3) + " % " + string(getString(message(...
                    "import_sci_livetasks:messages:subsettingRowMajorComment"))) + ...
                    newline; % count

                % create MATLAB variable name for memory dataspace ID (they
                % are in the form of "memSpaceID1", "memSpaceID2", etc.)
                % Memory dataspace identifier describes how the data is to
                % be arranged in memory.
                obj.numMemSpaces = obj.numMemSpaces + 1; % increment the count
                memSpaceID = "memSpaceID" + obj.numMemSpaces;

                % code to create memory dataspace
                % Example of syntax:
                %     spaceID = H5S.create_simple(rank,dims,maxdims)
                memSpaceCode = memSpaceID + ...
                    " = H5S.create_simple(length(count), count, []);" + ...
                    newline;

                % create MATLAB variable name for file dataspace ID (they
                % are in the form of "fileSpaceID1", "fileSpaceID2", etc.)
                % File dataspace identifier describes how the data is to be
                % selected from the file.
                obj.numFileSpaces = obj.numFileSpaces + 1; % increment the count
                fileSpaceID = "fileSpaceID" + obj.numFileSpaces;

                % code to create file dataspace
                % Example of syntax:
                %     dspaceID = H5D.get_space(dsID);
                fileSpaceCode = fileSpaceID + ...
                    " = H5D.get_space(" + dsID + ");" + newline;

                % code to select hyperslab
                % Example of syntax:
                %    H5S.select_hyperslab(spaceID,op,start,stride,count,block)
                % We are using [] for block to set the block size to a
                % single element in each dimension. This way "count" means
                % the number of elements (count more generally is defined
                % as the number of blocks)
                blockString = "[]";  
                hyperslabCode = "H5S.select_hyperslab(" + fileSpaceID + ...
                    ", ""H5S_SELECT_SET"", " + ...
                    "start, stride, count, " + ...
                    blockString + ")" + newline;

                % code to read the dataset
                % Example of syntax:
                %    data = H5D.read(dsID,memtypeID,memspaceID,filespaceID,dxplID)
                readCode = structPath + ".Value = H5D.read(" + dsID + ...
                    ", ""H5ML_DEFAULT"", " + ...
                    memSpaceID + ", " + ...
                    fileSpaceID + ", " + ...
                    """H5P_DEFAULT"");" + newline;

                % code to close and clear dataspace IDs
                % (we can do this here because we will not need the same
                % dataspaces again)
                closeSpacesCode = "H5S.close(" + fileSpaceID + ")" + newline + ...
                    "clear " + fileSpaceID + newline + ...
                    "H5S.close(" + memSpaceID + ")" + newline + ...
                    "clear " + memSpaceID + newline;

                % code to clear temporary subsetting variables
                clearSubsettingVarsCode = "clear start" + newline + ...
                    "clear stride" + newline + ...
                    "clear count" + newline;

                % assemble all the code for reading a hyperslab from the
                % dataset
                importCode = importCode + ...
                    subsettingVarsCode + ...
                    memSpaceCode + ...
                    fileSpaceCode + ...
                    hyperslabCode + ...
                    readCode + ...
                    closeSpacesCode + ...
                    clearSubsettingVarsCode;
            end

        end

        % Method to generate code for importing attribute value
        % (implementation for the abstract method of parent class)
        function importCode = generateImportCodeForAttributeStrategy(obj,...
                structPath, parentLocationPath, attName, parentType)

            import matlab.internal.importsci.AttributeParentType

            % Reading an attribute in HDF5 means getting the parent's ID,
            % opening the attribute ID, reading the attribute value, and
            % closing and clearing the attribute ID.
            % For example:
            %
            % dsID2 = H5D.open(fileID, "/g1/g1.1/dset1.1.1");
            % attrID1 = H5A.open(dsID2, "attr1");
            % example.Groups(1).Groups(1).Datasets(1).Attributes(1).Value = H5A.read(attrID1);
            % H5A.close(attrID1);
            % clear attrID1

           importCode = "";

           % create MATLAB variable name for attribute ID
           % (they are in the form of attrID1, attrID2, etc.)
           obj.numAtts = obj.numAtts + 1; % increment the count
           attrID = "attrID" + obj.numAtts;

           % determine MATLAB variable for attribute's parent ID
           % (i.e., HDF5 ID for a group or a dataset)
           switch(parentType)
               case AttributeParentType.DatasetOrVariable
                   % it is a dataset attribute, so get dataset's ID

                   % get dataset ID and add code for getting that dataset ID
                   [parentID, dsIDCode] = obj.getDatasetID(parentLocationPath);
                   importCode = importCode + dsIDCode;

               case AttributeParentType.GlobalOrGroup
                   % it is a root-level or a group attribute, so get group ID

                   % get group ID and add code for getting that group ID
                   [parentID, groupIDCode] = obj.getGroupID(parentLocationPath);
                   importCode = importCode + groupIDCode;

               case AttributeParentType.Datatype
                   % it is an attribute for an HDF5 named/committed datatype,
                   % so get datatype ID

                   % get datatype ID and add code for getting that datatype ID
                   [parentID, datatypeIDCode] = obj.getDatatypeID(parentLocationPath);
                   importCode = importCode + datatypeIDCode;
           end

            % Code to open the attribute
            attrOpenCode = attrID + " = H5A.open(" + parentID + ", """ + ...
                attName + """);" + newline;

            % Code to read the attribute
            attrReadCode = structPath + ".Value = H5A.read(" + attrID + ...
                ");" + newline;

            % Code to close the attribute (we don't need to keep the
            % attribute open as it will not be needed for reading any other
            % data in the HDF5 file, unlike groups and datasets)
            attrCloseCode = "H5A.close(" + attrID + ")" + newline + ...
                "clear " + attrID + newline;
       
            % assemble the code together
            importCode = importCode + ...
                attrOpenCode + attrReadCode + attrCloseCode;
        end

    end

    % Private helper methods
    methods (Access=private)

        function [groupID, groupIDCode] = getGroupID(obj, groupLocationPath)
            % Given the full location path to the group, return name for
            % MATLAB variable containing the corresponding group ID and
            % code needed to create that MATLAB variable (if needed)

            arguments (Input)
                obj  matlab.internal.importsci.LowLevelHDF5CodeGenerator

                % full path to the group, e.g., "/g1/g1.2/g1.2.1"
                groupLocationPath (1,1) string
            end

            arguments (Output)
                % name of MATLAB variable containing the group ID, e.g.
                % "groupID4"
                groupID (1,1) string

                % code to create group ID MATLAB variable (if needed), e.g.
                % "groupID1 = H5G.open(fileID, "/g1/g1.2/g1.2.1"");"
                % Can be empty if code for getting this group ID was
                % already generated
                groupIDCode (1,1) string
            end

            % will stay empty if code for getting this group ID is
            % already in the generated code
            groupIDCode = "";
            
            % if asking for root group
            if groupLocationPath == ""
                groupID = "fileID";
                return
            end

            if obj.groupIDsDict.isKey(groupLocationPath)
                % if we already have a MATLAB variable containing this
                % group ID, use this MATLAB variable
                groupID = obj.groupIDsDict(groupLocationPath);
            else
                % if we haven't yet generated code to get this group ID,
                % need to do so

                % come up with unique variable name to store the group ID
                % (basically groupID1, groupID2, groupID3, etc.)
                groupID = "groupID" + num2str(obj.groupIDsDict.numEntries+1);

                % add code for getting the group ID, e.g.
                %    groupID2 =
                %    H5G.open(fileID1,"/integerSequences/powerSequences");
                groupIDCode = groupID + " = H5G.open(fileID, """ + ...
                    groupLocationPath + """);" + newline;

                % add the new groupID variable name to the dictionary so we
                % know we already have it for this group
                obj.groupIDsDict(groupLocationPath) = groupID;

            end

        end

        function [dsID, dsIDCode] = getDatasetID(obj, locationPath)
            % Given dataset's location path, return name for MATLAB
            % variable containing this dataset ID and code needed to create
            % that MATLAB variable (if needed).

            arguments (Input)
                obj  matlab.internal.importsci.LowLevelHDF5CodeGenerator

                % location path to this HDF5 dataset, e.g.
                % "/g1/g1.1/dset1.1.1"
                locationPath (1,1) string
            end

            arguments (Output)
                % name of MATLAB variable containing dataset ID for this
                % HDF5 dataset, e.g. "dsID1"
                dsID (1,1) string

                % code to create MATLAB variable for dataset ID (if needed), e.g.
                % "dsID = H5D.open(groupID3,"myDataset")"
                % Can be empty if code for getting this dataset ID was
                % already generated
                dsIDCode (1,1) string
            end

            % will stay empty if code for getting this dataset ID is
            % already in the generated code
            dsIDCode = "";

            % does dataset ID already exist for this dataset? if it
            % doesn't, we need to generate code to get it
            if obj.dsIDsDict.isKey(locationPath)
                % if dataset ID was already found out, use it
                dsID = obj.dsIDsDict(locationPath);

            else
                % if we haven't found it out yet, need to do so

                % come up with unique variable name to store the ID
                % (basically dsID1, dsID2, dsID3, etc.)
                dsID = "dsID" + num2str(obj.dsIDsDict.numEntries+1);

                % generate code for getting the dataset ID, e.g.:
                %   dsID = H5D.open(groupID, "/integerSequences/powerSequences/powersOfTwo")
                dsIDCode = dsID + " = H5D.open(fileID, """ + ...
                    locationPath + """);" + newline;

                % add the new dataset ID's MATLAB variable name to the
                % dictionary so we know we already have it for this dataset
                obj.dsIDsDict(locationPath) = dsID;
            end
        end

        function [typeID, typeIDCode] = getDatatypeID(obj, locationPath)
            % Given datatype's location path, return name for MATLAB
            % variable containing this datatype ID and code needed to
            % create that MATLAB variable (if it doesn't exist yet).

            arguments (Input)
                obj  matlab.internal.importsci.LowLevelHDF5CodeGenerator

                % location path to this HDF5 datatype, e.g.
                % "/MyGroup/MyDoubleDatatype"
                locationPath (1,1) string
            end

            arguments (Output)
                % name of MATLAB variable containing datatype ID for this
                % HDF5 named/committed datatype, e.g. "typeID1"
                typeID (1,1) string

                % code to create MATLAB variable for datatype ID (if needed), e.g.
                % "dsID = H5D.open(groupID3,"myDataset")"
                % Can be empty if code for getting this datatype ID was
                % already generated
                typeIDCode (1,1) string
            end

            % will stay empty if code for getting this datatype ID is
            % already in the generated code
            typeIDCode = "";

            % does datatype ID already exist for this datatype? if it
            % doesn't, we need to generate code to get it
            if obj.typeIDsDict.isKey(locationPath)
                % if datatype ID was already found out, use it
                typeID = obj.typeIDsDict(locationPath);

            else
                % if we haven't found it out yet, need to do so

                % come up with unique variable name to store the ID
                % (basically typeID1, typeID2, typeID3, etc.)
                typeID = "typeID" + num2str(obj.typeIDsDict.numEntries+1);

                % generate code for getting the datatype ID, e.g.:
                %   typeID1 = H5T.open(fileID, "/MyGroup/MyDoubleDatatype");
                typeIDCode = typeID + " = H5T.open(fileID, """ + ...
                    locationPath + """);" + newline;

                % add the new datatype ID's MATLAB variable name to the
                % dictionary so we know we already have it for this
                % datatype
                obj.typeIDsDict(locationPath) = typeID;
            end

        end

    end

end