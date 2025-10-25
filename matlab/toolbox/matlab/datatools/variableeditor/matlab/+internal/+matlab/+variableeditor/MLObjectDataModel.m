classdef MLObjectDataModel < internal.matlab.variableeditor.MLArrayDataModel ...
        & internal.matlab.variableeditor.ObjectDataModel
    % MLOBJECTDATAMODEL MATLAB Object Data Model

    % Copyright 2013-2023 The MathWorks, Inc.

    properties
        % Whether the object is virtual or not.  Virtual objects implement the
        % internal.matlab.variableeditor.VariableEditorPropertyProvider
        % interface, in which they can specify certain properties as virtual,
        % meaning the VE shouldn't access them directly.  (This is used by some
        % objects where accessing the property may take a long time to compute,
        % and they don't want just opening it in the VE to trigger it).
        IsVirtual logical = false;
        VirtualPropIndices double = [];
    end

    properties(Access=private)
        VirtualPropCheckDone (1,1) logical = false;
    end

    methods(Access = public)
        % Constructor
        function this = MLObjectDataModel(name, workspace)
            this@internal.matlab.variableeditor.MLArrayDataModel(name, workspace);
            this.Name = name;
        end

        function varargout = getData(this, varargin)
            % getData(this, startRow, endRow) returns a cell array with the
            % values of the fields between the start row and end rows with
            % ordering as given by fieldsnames function. If these are not
            % passed in, then all data is returned instead. This is the
            % usual use case.

            % Special handling for classes which have virtual properties.  This
            % can be checked one time, since this only applies to value objects,
            % and the list of virtual properties cannot be changed on the fly.
            this.IsVirtual = isa(this.Data, "internal.matlab.variableeditor.VariableEditorPropertyProvider");
            if this.IsVirtual && isempty(this.VirtualPropIndices) && ~this.VirtualPropCheckDone
                % Initialize the virtual properties indices
                propNames = properties(this.Data);
                for idx = 1:length(propNames)
                    try
                        if isVariableEditorVirtualProp(this.Data, propNames(idx))
                            this.VirtualPropIndices(end+1) = idx;
                        end
                    catch
                        % Ignore exceptions, may happen when object class
                        % definitions go out of scope
                    end
                end
                this.VirtualPropCheckDone = true;
            end

            if nargin>=3 && ~internal.matlab.datatoolsservices.FormatDataUtils.isVarEmpty(this.Data)
                if this.objectBeingDebugged()
                    fieldNames = fieldnames(this.Data);
                else
                    fieldNames = properties(this.Data);
                end
                % Fetch a block of data using startRow and endRow.  The
                % columns are not used, because Objects always display a
                % fixed number of columns.
                startRow = min(max(1, varargin{1}), size(fieldNames, 1));
                endRow = min(max(1, varargin{2}), size(fieldNames, 1));

                selectionSize = abs(endRow-startRow)+1;
                values = cell(selectionSize, 1);

                % iterate using two indices at same time
                for i=[startRow:endRow; 1:selectionSize]
                    field = fieldNames{i(1)};

                    if this.IsVirtual && any(i(1) == this.VirtualPropIndices)
                        % Get the data for the virtual property
                        values{i(2)} = internal.matlab.datatoolsservices.FormatDataUtils.getVirtualObjPropValue(this.Data, field);
                    else
                        values{i(2)} = this.Data.(field);
                    end
                end

                varargout{1} = values;
            else
                % Otherwise return all data
                varargout{1} = this.Data;
            end
        end

        % setData: Sets a block of values. If three paramters are passed in
        % the the first value is assumed to be the data and the second is
        % the row and third the column.
        %
        % The return values from this method are the formatted command
        % string to be executed to make the change in the variable.
        %
        % Note - this is overriden here because the super method does row
        % and column indexing, while for objects assigns by property name.
        function varargout = setData(this,varargin)
            if nargin < 3
                varargout{1}='';
                return;
            end
            errorMsg = [];
            % The last argument we will be expecting is an error command that gets the current document
            % and send a dataChange error message back to the client. The errormessage should start
            % with 'internal.matlab.variableeditor'. We strip this off because the ArrayDataModel
            % setData function does not need it and cannot handle the extra input argument
            % This logic is similar to that of MLArrayDataModel
            if strfind(varargin{end}, 'internal.matlab.variableeditor') == 1
                errorMsg = varargin{end};
                varargin(end) = [];
            end

            lhs = this.getLHS(varargin{:});
            rhs = this.getRHS(varargin{1});
            setStrings = {sprintf('%s = %s;', lhs, rhs)};
            % Evaluate any MATLAB changes (TODO: Remove when LXE is in)
            if ~isempty(setStrings)
                setCommands = cell(1,length(setStrings));
                for i=1:length(setStrings)
                    if ~isempty(errorMsg)
                        setCommands{i} = this.executeSetCommand(setStrings{i}, errorMsg);
                    else
                        setCommands{i} = this.executeSetCommand(setStrings{i});
                    end

                end
                varargout{1} = setCommands;
            end
        end

        % updateData
        function data = updateData(this, varargin)
            currentData = this.Data;
            newData = varargin{1};            
            s = warning('off', 'all');
            c = onCleanup(@() warning(s));
            if ~isequaln(struct(currentData), struct(newData))
                % if not equal, then could not be a handle staying the same
                eventdata = internal.matlab.datatoolsservices.data.DataChangeEventData;

                currentPropCount = length(properties(currentData));
                newPropCount = length(properties(newData));

                if ~isequal(class(currentData), class(newData)) || ...
                        ~isequal(currentPropCount, newPropCount)
                    % if change in type, do full refresh
                else
                    % Same data type, and not a handle.  Use doCompare to
                    % find where data changed from old to new data.
                    [I,J] = this.doCompare(newData);
                    if size(I, 1) == 1 && size(J ,1) == 1
                        fieldNames = fields(currentData);
                        fieldName = fieldNames{I(1)};
                    end
                    % TODO: The results of the comparison/meshgrid are currently not
                    % being used.  Need to add the logic back in to update a single
                    % cell on the client if only a single cell has changed.(Otherwise
                    % the entire viewport will be updated)
                end
                this.Data = newData;
                this.notify('DataChange', eventdata);
            end

            data = newData;
        end
    end %methods

    methods(Access = protected)
        function [I,J] = doCompare(this, newData)
            % Performs a field by field comparison and returns a map of
            % where every change that occurs to any fields

            % Could be sped up by stopping after 2 changes since the
            % function that uses this just does a full reload of data if
            % more then 1 change occurs
            oldData = this.Data;

            propNames = properties(oldData);
            numProps = length(propNames);

            I = [];

            for i=1:numProps
                propName = propNames{i};
                if isprop(newData, propName)
                    try
                        if ~isequaln(oldData.(propName), newData.(propName))
                            I = [I; i]; %#ok<AGROW>
                        end
                    catch
                        % Errors can occur with dependent properties (if
                        % the new value causes the dependent property to
                        % error when evaluated).  Consider this a change.
                        I = [I; i]; %#ok<AGROW>
                    end
                else
                    % The property doesn't exist in the new object.  For
                    % value objects, this can happen if the class object
                    % definition changes.  Need to do a full refresh.
                    I = [];
                    break;
                end
            end

            J = ones(length(I), 1)*2;
        end
    end
end
