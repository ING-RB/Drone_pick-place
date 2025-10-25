classdef MLArrayDataModel < internal.matlab.variableeditor.ArrayDataModel & internal.matlab.variableeditor.MLNamedVariableObserver
    %MLARRAYDATAMODEL
    %   MATLAB Array Data Model

    % Copyright 2013-2024 The MathWorks, Inc. 
    properties(Constant,Hidden)
        % This is the user context for JSD/MOL
        MAIN_VE_USER_CONTEXT = 'MOTW';
    end

    properties
        CodePublishingDataModelChannel;
    end

    methods(Access='public')
        % Constructor
        function this = MLArrayDataModel(name, workspace)
            this@internal.matlab.variableeditor.MLNamedVariableObserver(name, workspace);
            this.Name = name;            
        end

        function setCodePublishingChannel(this, channel)
            arguments
                this
                channel (1,1) string
            end
            this.CodePublishingDataModelChannel = channel;
        end
        
        % setData
        % Sets a block of values.
        % If only one paramter is specified that parameter is assumed to be
        % the data and all of the data is replaced by that value.
        % If three paramters are passed in the the first value is assumed
        % to be the data and the second is the row and third the column.
        % Otherwise users can specify value index pairings in the form
        % setData('value', index1, 'value2', index2, ...)
        %
        %  The return values from this method are the formatted command
        %  string to be executed to make the change in the variable.
        function varargout = setData(this,varargin)
            [errorMsg, c] = this.getSetDataParams(varargin);
            setStrings = this.setData@internal.matlab.variableeditor.ArrayDataModel(c{:});
            setCmd = this.setCommand(setStrings, errorMsg);
            if ~isempty(setCmd)
                varargout{1} = setCmd;
            end
        end
        
        function [errorMsg, varargout] = getSetDataParams(~, varargin)
            ip = varargin{:};
            errorMsg = [];            
			% The last argument we will be expecting is an error command that gets the current document
			% and send a dataChange error message back to the client. The errormessage should start 
			% with 'internal.matlab.desktop_variableeditor'. We strip this off because the ArrayDataModel
			% setData function does not need it and cannot handle the extra input argument
            if strfind(ip{end}, 'internal.matlab.desktop_variableeditor') == 1
                errorMsg = ip{end};
                ip(end) = [];
            end
            varargout = {ip};
        end
        
        function setCmd = setCommand(this, setStrings, errorMsg)
             % Evaluate any MATLAB changes (TODO: Remove when LXE is in)             
            setCmd = '';
            if ~isempty(setStrings)
                setCommands = cell(1,length(setStrings));
                for i=1:length(setStrings)
                    if ~isempty(errorMsg)
                        setCommands{i} = this.executeSetCommand(setStrings{i}, errorMsg);                        
                    else
                        setCommands{i} = this.executeSetCommand(setStrings{i});                        
                    end
                end
                setCmd = setCommands;
            end
        end        
        
        % Executes a matlab command in the correct workspace when MATLAB is
        % available
        function evalStr = executeSetCommand(this, setCommand, varargin)
            evalStr = this.assignNameToCommand(setCommand);
            isUsingPublicWorkspace = ischar(this.Workspace);

            if isUsingPublicWorkspace % 'base', 'caller', 'debug'
                % If this is the primary Variable Editor, only then execute
                % code. All other instances have their own code execution mechanisms.
                if strcmp(this.userContext, this.MAIN_VE_USER_CONTEXT)
                    codePublishService = internal.matlab.datatoolsservices.CodePublishingService.getInstance;
                    codePublishService.publishCode(this.CodePublishingDataModelChannel, evalStr, varargin{:});
                end
            else
                % At this point, we know the Variable Editor is using a private/
                % custom workspace.
                % For example, Live Script filtering & categorical filtering
                % generate code through this else block.

                origData = this.getCloneData;
                evalin(this.Workspace, evalStr);
                newData = evalin(this.Workspace, this.Name);

                % Because the change is internal to a workspace a workspace
                % event may not fire, so we must trigger the update ourselves.
                eventdata = this.generateDataDiffsEventData(origData, newData);
                this.Data = newData;
                this.notify('DataChange',eventdata);
            end
        end
        
        % updateData
        function data = updateData(this, varargin)
            newData = varargin{1};
            origData = this.getCloneData;
            % superclass implementations could have updated the datamodel
            % while publishing metadata/data changes. For those cases,
            % varargin{4} will have the old data to compare against for
            % updates.

            if (nargin == 5)
               origData = varargin{4};
            elseif (nargin == 3)
                % In some cases only 2 arguments are sent, this condition
                % deals with the said case and fetches oldData
                % 1. varargin{1} has newData
                % 2. varargin{2} has currentData
                origData = varargin{2};
            end

            dataEqual = this.equalityCheck(origData, newData);
            % Fix eventData
            if ~dataEqual
                [eventdata, I, J] = this.generateDataDiffsEventData(origData, newData);
                                
                % Set the new data
                try
                    % Data could've changed to a different type and data
                    % model may error.  Ignore this because this data model
                    % will soon be deleted.
                    this.Data = newData;
                    this.handleMetaDataUpdate(newData, origData, eventdata.SizeChanged, I, J);
                catch e
                    internal.matlab.datatoolsservices.logDebug('variableeditor::mlarraydatamodel', e.message);
                end

                % The eventData Values property should represent the data
                % that has changed within the cached this.Data block as it 
                % is rendered. Currently the cached data may be huge, so
                % Do not specify a range. No range will just cause the
                % viewport to be refreshed.
                this.notify('DataChange',eventdata);
            end
            data = this.getCloneData;
        end

        function [eventdata, rowDiff, colDiff] = generateDataDiffsEventData(this, origData, newData)
            origSize = this.getDataSize(origData);
            newSize = this.getDataSize(newData);
            sizeEqual = isequal(origSize, newSize);
            eventdata = internal.matlab.datatoolsservices.data.DataChangeEventData;
            eventdata.SizeChanged = ~sizeEqual;
            if sizeEqual && ~this.ForceUpdate
                % If the sizes are the same, call doCompare to find out
                % which entries actually changed
                % ForceUpdate will be used for Handle Objects/ObjectArrays
                % since the value would've already changed and a comparison
                % will fail to find any differences.
                [rowDiff, colDiff] = this.doCompare(newData);
            else
                % Otherwise:
                % g3293637: we create 2x2 matrices and take note of them.
                % There's a lot of history behind why we use meshgrid; in
                % short, the values within the meshgrid outputs are not
                % important, but rather, the size of the outputs do. Them
                % being greater than 1x1 indicates that more than one
                % cell's value has changed, and that all of the data should
                % be updated.
                %
                % TODO: Find a cleaner solution indicating that multiple
                % cells have changed. This will require a thorough
                % reassessment of the architecture.
                [rowDiff, colDiff] = meshgrid(1:2, 1:2);
            end

            rowDiff = rowDiff(:)'; % Flatten to a row vector
            colDiff = colDiff(:)'; % Flatten to a row vector

            rangeToUpdate = [rowDiff; colDiff];
            if size(rangeToUpdate, 2) == 1
                % Refresh data for single cell
                eventdata.StartRow = rangeToUpdate(1,1);
                eventdata.EndRow = rangeToUpdate(1,1);
                eventdata.StartColumn = rangeToUpdate(2,1);
                eventdata.EndColumn = rangeToUpdate(2,1);
            end
        end

        function data = variableChanged(this, options)
            % variableChanged() is called by the MLNamedVariableObserver
            % workspaceUpdated() method in response to workskpace updates from the
            % WebWorkspaceListener to track changes in the data. However,
            % this method will also be called when the class of the
            % variable changes, which causes the MLDocument
            % variableChanged() method to replace this MLArrayDataModel by
            % a new one to represent the new class. Detect this case and
            % return early to avoid calling updateData on this about to be
            % deleted MLArrayDataModel
            arguments
                this
            	options.newData = [];
            	options.newSize = 0;
            	options.newClass = '';
            	options.eventType = internal.matlab.datatoolsservices.WorkspaceEventType.UNDEFINED;
                options.forceUpdate (1,1) logical = false;
                options.varNames = [];
            end
            newData = options.newData;
            newSize = options.newSize;
            newClass = options.newClass;

            oldClass = this.getClassType;
            
%             there are some datatypes which have the same class but have
%             different view (documentTypes). Ex: scalar structurea, 1xn or
%             nx1 structure arrays and mxn structure arrays. For this
%             reason we derive the class from the adapter
             if ~isempty(newClass) && ~isa(this, 'internal.matlab.workspace.MLWorkspaceDataModel')
                adapterClassName = internal.matlab.variableeditor.MLManager.getAdapterClassNameHelper(newClass, newSize, newData);
                newClass = internal.matlab.variableeditor.MLManager.getVariableAdapterClassTypeHelper(newClass, adapterClassName);
             end 
            currentData = this.getCloneData;
            if ~isempty(newClass) &&...
                    ... % If we are looking at string arrays don't do this check
                    ~(internal.matlab.datatoolsservices.FormatDataUtils.checkIsString(currentData) && internal.matlab.datatoolsservices.FormatDataUtils.checkIsString(newData)) &&...
                    (...
                        (... % The type has changed and we're not looking at objects and numerics(that could also be objects)
                            (~any(strcmp(newClass,oldClass)) && ...
                            ~(isobject(currentData) && isobject(newData))) && ...
                            ~(isnumeric(currentData) && isnumeric(newData)) ...
                        ) ||...
                        (... % We've gone from a scalar to non-scalar or vice-versa
                            (this.adapterChangeForSameClass(newData, newSize, newClass))...
                        )...
                    )
                data = [];
                return
            end
            oldForceUpdate = this.ForceUpdate;
            if (options.forceUpdate)
                this.ForceUpdate = true;
            end
            data = this.updateData(newData, newSize, newClass);
            this.ForceUpdate = oldForceUpdate;
        end

        function comp = adapterChangeForSameClass(this, varargin)
            currentData = this.getCloneData;
            
            % The getAdapterClassNameForData function takes the class, size and data as the input args and returns the
            % adapter class name.
            % varargin{3}: class of new data
            % varargin{2}: size of the new data
            % varargin{1}: the new data
            newAdapterName = internal.matlab.variableeditor.MLManager.getAdapterClassNameHelper(varargin{3}, varargin{2}, varargin{1});

            currAdapterName = internal.matlab.variableeditor.MLManager.getAdapterClassNameHelper(class(currentData), size(currentData), currentData);
            % If the adapters are different, use want to return true so that we continue to the MLManager and destroy
            % The ViewModel. If they are the same, return false and call updateData.
            comp = ~strcmp(newAdapterName, currAdapterName);           
        end

        function dims = getDataSize(~, data)
            dims = size(data);
        end
        
        function eq = equalityCheck(this, oldData, newData)
            eq = internal.matlab.variableeditor.areVariablesEqual(oldData, newData);
            if (eq)
                % Force an update by causing the equality check to fails 
                % even if variables are equal
                eq = ~this.ForceUpdate;
            end
        end
        
        function delete(this)
            if ~isempty(this.CodePublishingDataModelChannel) && ischar(this.Workspace)
                % Discard any generated code for the variable
                c = internal.matlab.datatoolsservices.CodePublishingService.getInstance;
                c.discardCode(this.CodePublishingDataModelChannel);
            end
        end
    end %methods 
    
    methods(Access='protected')
        % NOOP on handling metadata when data updates. To be overridden by 
        % classes that have metadata updates when data changes.
        function handleMetaDataUpdate(this, newData, currentData, sizeChanged, rowDiff, columnDiff) %#ok<INUSD> 
        end

        function codeToExecute = assignNameToCommand(this, setCommand)
             codeToExecute = sprintf('%s%s',this.Name, setCommand);
        end
    end
        
    
    methods(Access='protected',Abstract=true)
        [I,J]=doCompare(this, newData);
    end
end

