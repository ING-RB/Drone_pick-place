classdef StructureTreeDataModel < internal.matlab.variableeditor.StructureDataModel
    %StructureTreeDataModel 
    %   Structure Tree Data Model

    % Copyright 2022-2024 The MathWorks, Inc.

    properties(Hidden)
        CacheSizeUpdated (1,1) logical = false;
    end
          
    methods
        % On expansion, 'childrenCount' containing size of children to be expanded under rowId
        % is added to currentSize. 
        function updateSizeOnExpand(this, rowId, childrenCount)
            currSize = this.getSize();
            if childrenCount == 0
                childrenCount = this.getFieldCountByRow(rowId);
            end
            currSize(1) = currSize(1) + childrenCount;
            this.setCachedSize(currSize);
        end

        % On Collapse, 'childrenCount' containing size of children currently expanded under rowId
        % is subtracted to currentSize. 
        function updateSizeOnCollapse(this, childrenCount)
            currSize = this.getSize();
            currSize(1) = currSize(1) - childrenCount;
            this.setCachedSize(currSize);
        end

        % Sets CachedSize property
        function setCachedSize(this, sz)
            arguments
                this
                sz double
            end
            this.CachedSize = sz;
        end

        function sz = getCachedSize(this)
            sz = this.CachedSize;
        end

        % Updates CahcedSize. Called when variable changes from the
        % workspace and a change is detected.
        function updateCachedSize(this)
            this.CacheSizeUpdated = true;
            fn = fieldnames(this.Data_I);
            % Cache the size because calling fieldnames can be expensive
            % if there are lots of fields
            if isempty(fn)
                % Empty struct should still have the correct number of
                % columns
                this.CachedSize = [0, this.NumberOfColumns];
            else
                % If struct has fields, then preserve row count from
                % currently cached size as struct could be in an expanded
                % state
                rowSize = this.CachedSize(1);
                if (rowSize == 0)
                    rowSize = length(fn);
                end
                this.CachedSize = [rowSize this.NumberOfColumns];
            end
        end

        % setData - Sets a block of values.
        %
        % If only one paramter is specified that parameter is assumed to be
        % the data and all of the data is replaced by that value.
        %
        % Otherwise, the parameters must be in groups of three.  These
        % quadruplets must be in the form:  newValue, row, column, rowId
        %
        %  The return values from this method are the formatted command
        %  string to be executed to make the change in the variable.
        function varargout = setData(this,varargin)
            newValue = varargin{1};

            % Simple case, all of data replaced
            if nargin == 2
                setCommands{1} = sprintf(' = %s;', this.getRHS(newValue));
                varargout{1} = setCommands;
                return;
            end

            % Check for paired values
            if rem(nargin-1, 4)~=0
                error('Use name/row/col/rowID arguments to specify values');
            end

            % Range(s) specified (value-range pairs)
            outputCounter = 1;
            setCommands = cell(1,round((nargin-1)/4));

            % Generate the command to be executed.
            for i=4:4:nargin
                newValue = varargin{i-3};
                row = varargin{i-2};
                column = varargin{i-1};
                rowID = varargin{i};

                if (this.isFieldNameColumn(column))
                    % Variable setup
                    getExecutableIDForm = false;
                    originalLhs = this.getLHS(rowID, getExecutableIDForm); % Strips parent name from LHS

                    splitFields = internal.matlab.variableeditor.VEUtils.splitRowId(originalLhs);
                    relativeLHS = char(internal.matlab.variableeditor.VEUtils.joinRowId(splitFields(1:end-1)));
                    oldFieldName = splitFields(end);
                    parentName = [this.Name relativeLHS]; % Delimited version of current parent name.

                    % Now that we've set up all our row ID variables, we can
                    % transform some of them to "code executable" form, i.e.,
                    % set the ID delimiter to ".".
                    relativeLHS = internal.matlab.variableeditor.VEUtils.getExecutableRowIdVersion(relativeLHS);

                    rhs = internal.matlab.variableeditor.VEUtils.getExecutableRowIdVersion(rowID);

                    % Continue variable setup; we extract the struct field/table
                    % variable names.
                    if isempty(relativeLHS)
                        parentFieldData = struct;
                        fieldData = this.Data;
                    else
                        parentFieldData = this.getFieldData(parentName);
                        fieldData = parentFieldData;
                    end

                    if isstruct(parentFieldData)
                        fnames = fieldnames(fieldData);
                        numFields = length(fnames);

                        % Start generating code.
                        % relativeLHS is already dot sepatated, just join newValue to create dot separated lhs
                        assignmentLHS = internal.matlab.variableeditor.VEUtils.joinRowIdWithDotSeparator([relativeLHS newValue]);
                        assignmentCmd = sprintf('%s = %s; ', assignmentLHS, rhs);
                        parentName = internal.matlab.variableeditor.VEUtils.getExecutableRowIdVersion(parentName);

                        % Do not generate orderFields for last fname edit or if
                        % this is a duplicate field name.
                        relativeRow = find(matches(fnames, oldFieldName));
                        if (relativeRow == numFields) || any(ismember(fnames, newValue))
                            orderFieldsCmd = '';
                        else
                            orderFieldsCmd = sprintf('%s = orderfields(%s, [1:%d, %d, %d:%d]); ', ...
                            parentName, parentName, relativeRow, numFields +1 , relativeRow + 1, numFields);
                        end
                        deletionCmd = sprintf('%s = rmfield(%s, "%s");', parentName, parentName, oldFieldName);
                        setCommand = sprintf('%s%s%s', assignmentCmd, orderFieldsCmd, deletionCmd);
                    elseif istabular(parentFieldData)
                        fieldIsTimeCol = strcmp(parentFieldData.Properties.DimensionNames{1}, oldFieldName);

                        % Generate code; code changes if we're renaming a timetable time column.
                        if ~fieldIsTimeCol
                            parentName = internal.matlab.variableeditor.VEUtils.getExecutableRowIdVersion(parentName);
                            setCommand = sprintf('%s = renamevars(%s, "%s", "%s");', relativeLHS, parentName, oldFieldName, newValue);
                        else
                            % When setting the time column name, we must use single quotes; quotes cause an error.
                            setCommand = sprintf('%s.Properties.DimensionNames{1} = ''%s'';', relativeLHS, newValue);
                        end
                    end
                else
                    lhs = this.getLHS(rowID);
                    rhs = this.getRHS(newValue);
                    setCommand = sprintf('%s = %s;', lhs, rhs);
                end                
                setCommands{outputCounter} = setCommand;
                outputCounter = outputCounter+1;
            end            
            varargout{1} = setCommands;
        end

        function fieldDataTabular = fieldDataIsTabular(this, nestedFieldName)
            parentFieldId = internal.matlab.variableeditor.VEUtils.getParentFieldIds(nestedFieldName);
            fieldDataTabular = istabular(this.getFieldData(parentFieldId));
        end
    end

    methods(Access=protected)
        function fieldData = getFieldData(this, nestedFieldName)
            % We first determine if the given field is at the top level.
            % The way we get the field data depends whether it's at the top level.
            %
            % Refer to this example:
            % VariableEditorStruct <-- Top level field
            % |- DataParent        <-- Regular field
            %    |- Data
            fieldIsTopLevel = strcmp(nestedFieldName, this.Name);

            % If the field is the top level, grab all the data we have.
            if fieldIsTopLevel
                fieldData = this.Data;
            else % Otherwise, use "getfield()".
                rootName = internal.matlab.variableeditor.VEUtils.appendRowDelimiter(this.Name);
                nestedFieldName = extractAfter(nestedFieldName, rootName);
                fieldVals = internal.matlab.variableeditor.VEUtils.splitRowId(nestedFieldName);
                fieldData = getfield(this.Data, fieldVals{:});
            end
        end

        function fieldLen = getFieldCountByRow(this, rowId)
            currData = this.Data;
            fieldVals = internal.matlab.variableeditor.VEUtils.splitRowId(rowId);
            collapsedData = getfield(currData, fieldVals{:});
            fieldLen = length(fieldnames(collapsedData));
        end
    end
end
