% This class is unsupported and might change or be removed without notice in a
% future version.


classdef LowLevelNetCDFCodeGenerator < matlab.internal.importsci.AbstractNodeImportCodeGenerator
    %LOWLEVELNETCDFCODEGENERATOR
    %   Strategy class for generating low-level code for importing
    %   netCDF variables and attributes

    % Copyright 2022 The MathWorks, Inc.

    properties (Hidden)
        % Dictionary of variable IDs. This keeps track of which variables
        % already have MATLAB variables keeping their variable IDs and what
        % these MATLAB variables are. It maps full location path of netCDF
        % variable to the MATLAB variable name, for example:
        %     "/aux/rad_imag_sw" -> "varid0"
        varIDsDict = dictionary(string([]), string([]));

        % Dictionary of group IDs. This keeps track of which groups already
        % have MATLAB variables keeping their group IDs and what these
        % MATLAB variables are. It maps full location path of netCDF group
        % to the MATLAB variable name, for example:
        %     "/aux/ExtraRecords" -> "gid1"
        groupIDsDict = dictionary(string([]), string([]));
    end

    methods (Access=public)
        
        % Create an instance of a LowLevelNetCDFCodeGenerator
        function this = LowLevelNetCDFCodeGenerator(filename)
            arguments
                filename (1,1) string
            end

            this.Filename = filename;
        end

        % Method to generate any set up code
        % (implementation for the abstract method of parent class)
        function code = generateSetUpCode(obj)
            arguments
                obj matlab.internal.importsci.LowLevelNetCDFCodeGenerator
            end

            % for low-level code, need to open the file before doing
            % anything else
            code = newline + ...
                "% " + string(getString(...
                message("import_sci_livetasks:messages:openFileCommentNetCDF"))) + ...
                newline + "ncid = netcdf.open(""" + obj.Filename + """);" + ...
                newline;
        end

        % Method to generate any tear down code
        % (implementation for the abstract method of parent class)
        function code = generateTearDownCode(obj)
            arguments
                obj matlab.internal.importsci.LowLevelNetCDFCodeGenerator
            end

            % for low-level code, need to close the file after all the
            % import code
            code = newline + ...
                "% " + string(getString(...
                message("import_sci_livetasks:messages:closeFileCommentNetCDF"))) + ...
                newline + "netcdf.close(ncid)";

            % generate code to clear all the extra variables: file ID,
            % group IDs, and variable IDs
            code = code + newline + newline + ...
                "% " + string(getString(...
                message("import_sci_livetasks:messages:clearVariablesCommentNetCDF"))) + ...
                newline + "clear ncid";
            for varid = (obj.varIDsDict.values')
                code = code + newline + "clear " + varid;
            end
            for gid = (obj.groupIDsDict.values')
                code = code + newline + "clear " + gid;
            end
            code = code + newline;
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

            % determine the group ID for this variable and add code for
            % getting that group ID
            [groupID, groupIDCode, varName] = obj.getGroupIDForVariable(locationPath);
            importCode = importCode + groupIDCode;

            % determine the variable ID for this variable and add code for
            % getting that variable ID
            [varID, varIDCode] = obj.getVariableID(locationPath,...
                groupID, varName);
            importCode = importCode + varIDCode;

            % code to get the variable's value
            % For example:
            %      file1.Groups(1).Groups(1).Variables(1).Value = netcdf.getVar(gid1, varid0);
            % or
            %     file1.Variables(1).Value = netcdf.getVar(ncid, varid0, [0 0 4], [5 6 40], [1 5 1]);

            % start of variable import line of code
            importCode = importCode + ...
                structPath + ".Value = netcdf.getVar(" + groupID + ", " + varID;

            % Does this variable have any subsetting options?
            % If it does, add Start, Stride, Count options to the
            % generated code. The netcdf.getVar syntax is
            %    data = netcdf.getVar(ncid,varid,start,count,stride)
            if ~isempty(subsettingOptions)

                % format the subsetting options into strings
                % (low-level interface is zero-based, so need to adjust
                % "start")
                startString = "[" + join(string(subsettingOptions.Start)) + "] - 1";
                countString = "[" + join(string(subsettingOptions.Count)) + "]";
                strideString = "[" + join(string(subsettingOptions.Stride)) + "]";
                % add subsetting options to the line of code
                importCode = importCode + ", " + ...
                    startString + ", " + ...
                    countString + ", " + ...
                    strideString;
            end

            % end of variable import line of code
            importCode = importCode + ");" + newline;

        end

        % Method to generate code for importing attribute value
        % (implementation for the abstract method of parent class)
        function importCode = generateImportCodeForAttributeStrategy(obj,...
                structPath, parentLocationPath, attName, parentType)

            import matlab.internal.importsci.AttributeParentType

            importCode = "";

            if parentType == AttributeParentType.DatasetOrVariable
                % it is a variable attribute

                % determine the group ID for this attribute's variable and
                % add code for getting that group ID
                [groupID, groupIDCode, varName] = obj.getGroupIDForVariable(parentLocationPath);
                importCode = importCode + groupIDCode;


                % determine the variable ID for this attribute's variable
                % and add code for getting that variable ID
                [varID, varIDCode] = obj.getVariableID(parentLocationPath,...
                    groupID, varName);
                importCode = importCode + varIDCode;

            elseif parentType == AttributeParentType.GlobalOrGroup
                % it is a global/group attribute, so varID should be the NC_GLOBAL constant
                varID = "netcdf.getConstant(""NC_GLOBAL"")";

                % determine group id
                if parentLocationPath == ""
                    % this is a global attribute, group ID is ncid
                    groupID = "ncid";

                else % it is a group attribute

                    % Create a list of nested groups based on this
                    % attribute's location path (e.g.: for attribute for
                    % group "/Colours/Reds/Crimson", the list of groups
                    % would be ["Colours", "Reds", "Crimson"])
                    groups = split(parentLocationPath, "/");

                    % The first element is going to be empty (as all
                    % location paths start with "/")
                    groups = groups(2:end);

                    [groupID, groupIDCode] = obj.getGroupID(groups);
                    importCode = importCode + groupIDCode;

                end

            end

            % Code to get the attribute's value. The netcdf.getAtt() syntax
            % is: attrvalue = netcdf.getAtt(ncid, varid, attname)
            % For example:
            %    file1.Attributes(1).Value = netcdf.getAtt(ncid, netcdf.getConstant("NC_GLOBAL"), "keywords");
            % or
            %    file1.Groups(1).Variables(1).Attributes(1).Value = netcdf.getAtt(gid0, varid1, "units");

            attributeValueCode = structPath + ".Value = netcdf.getAtt(" + ...
                groupID + ", " + varID + ", """ + attName + """);" + newline;

            importCode = importCode + attributeValueCode;

        end

    end

    % Private helper methods
    methods (Access=private)

        function [groupID, groupIDCode, varName] = getGroupIDForVariable(obj, variableLocationPath)
            % Given variable's location path, return name for MATLAB
            % variable containing group ID for this netcdf variable, code
            % needed to create that MATLAB variable (if needed), and this
            % netCDF variable's name.

            arguments (Input)
                obj  matlab.internal.importsci.LowLevelNetCDFCodeGenerator

                % location path to the variable, e.g. "/aux/neon_wlen"
                variableLocationPath (1,1) string
            end

            arguments (Output)
                % name of MATLAB variable containing group ID for the group
                % containing this netCDF variable, e.g. "gid0"
                % Will be file ID (ncid) for a root level variable
                groupID (1,1) string

                % code to create group ID MATLAB variables (if needed), e.g.
                % "gid0 = netcdf.inqNcid(ncid, ""aux"");"
                % Can be empty if code for getting this group ID was
                % already generated
                groupIDCode (1,1) string

                % name of this netCDF variable, e.g. "neon_wlen"
                varName (1,1) string
            end

            % determine the groups this variable is in based on location
            % path (according to unidata, "/" may not appear in a group or
            % variable name:
            % https://docs.unidata.ucar.edu/netcdf-c/current/programming_notes.html#autotoc_md176 )
            groups = split(variableLocationPath, "/");

            % The first element is going to be empty (as all location paths
            % start with "/", and the last element is going to be variable
            % name itself. There are always at least those two elements.
            varName = groups(end);
            groups = groups(2:end-1);

            [groupID, groupIDCode] = obj.getGroupID(groups);

        end


        function [groupID, groupIDCode] = getGroupID(obj, groups)
            % Given a string array of groups (with first one being the most
            % parent/outer group, and last one being the most nested
            % group), return name for MATLAB variable containing group ID
            % for the last group in the list and code needed to create that
            % MATLAB variable (if needed)

            arguments (Input)
                obj  matlab.internal.importsci.LowLevelNetCDFCodeGenerator

                % 1D vector of group names specifying a path to the most
                % nested group. E.g. for a group "/Plants/Flowering
                % Plants/Woody Flowering Plants", it would be:
                % ["Plants", "Flowering Plants", "Woody Flowering Plants"]
                groups (1,:) string
            end

            arguments (Output)
                % name of MATLAB variable containing group ID for the most
                % nested group in the list, e.g. "gid3"
                groupID (1,1) string

                % code to create group ID MATLAB variables (if needed), e.g.
                % "gid1 = netcdf.inqNcid(ncid, ""Plants"");
                %  gid2 = netcdf.inqNcid(gid0, ""Flowering Plants"");
                %  gid3 = netcdf.inqNcid(gid1, ""Woody Flowering Plants"");"
                % Can be empty if code for getting this group ID was
                % already generated
                groupIDCode (1,1) string
            end

            % will stay empty if code for getting this group ID is
            % already in the generated code
            groupIDCode = "";

            groupPath = "/";
            groupID = "ncid";

            % loop through groups and add code to get group IDs
            for i=1:length(groups)

                groupName = groups(i);

                % location path for this group
                groupPath = groupPath + groupName;

                if obj.groupIDsDict.isKey(groupPath)
                    % if group ID was already found out for this group, use
                    % it
                    gid = obj.groupIDsDict(groupPath);
                else
                    % if we haven't found it out yet, need to do so

                    % come up with unique variable name to store the ID
                    % (basically gid1, gid2, gid3, etc.)
                    gid = "gid" + num2str(obj.groupIDsDict.numEntries+1);

                    % add code for getting the group ID, e.g.
                    %    gid2 = netcdf.inqNcid(gid1, "ExtraRecords");
                    thisGroupIDCode = gid + " = netcdf.inqNcid(" + ...
                        groupID + ", """ + ...
                        groupName + """);" + newline;
                    groupIDCode = groupIDCode + thisGroupIDCode;

                    % add the new gid variable name to the dictionary so we
                    % know we already have it for this group
                    obj.groupIDsDict(groupPath) = gid;

                end

                % this will now be the id for the parent group for the next
                % group or for the variable
                groupID = gid;
            end

        end

        function [varID, varIDCode] = getVariableID(obj, locationPath,...
                parentGroupID, varName)
            % Given variable's location path and name, and name for MATLAB
            % variable containing parent group's ID, return name for MATLAB
            % variable containing variable ID and code needed to create
            % that MATLAB variable (if needed).

            arguments (Input)
                obj  matlab.internal.importsci.LowLevelNetCDFCodeGenerator

                % location path to this netCDF variable, e.g.
                % "/aux/neon_wlen"
                locationPath (1,1) string

                % MATLAB variable name for the group ID for the group that
                % contains this netCDF variable, e.g. "gid1"
                parentGroupID

                % netCDF variable name, e.g. "neon_wlen"
                varName
            end

            arguments (Output)
                % name of MATLAB variable containing variable ID for this
                % netCDF variable, e.g. "varid1"
                varID (1,1) string

                % code to create MATLAB variables for variable ID (if needed), e.g.
                % "varid1 = netcdf.inqVarID(gid0, ""neon_wlen"");"
                % Can be empty if code for getting this variable ID was
                % already generated
                varIDCode (1,1) string
            end

            % will stay empty if code for getting this variable ID is
            % already in the generated code
            varIDCode = "";

            % does varid already exist for this variable? if it doesn't, we
            % need to generate code to get varid
            if obj.varIDsDict.isKey(locationPath)
                % if variable ID was already found out, use it
                varID = obj.varIDsDict(locationPath);

            else
                % if we haven't found it out yet, need to do so

                % come up with unique variable name to store the ID
                % (basically varid1, varid2, varid3, etc.)
                varID = "varid" + num2str(obj.varIDsDict.numEntries+1);

                % generate code for getting the variable ID, e.g.:
                %   varid1 = netcdf.inqVarID(gid2, "wind_records");
                varIDCode = varID + " = netcdf.inqVarID(" + parentGroupID + ...
                    ", """ + varName + ...
                    """);" + newline;

                % add the new varid variable name to the dictionary so we
                % know we already have it for this variable
                obj.varIDsDict(locationPath) = varID;
            end

        end

    end

end