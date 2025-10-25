classdef ParamTableTC < ctrluis.component.AbstractTC
    %PARAMTABLETC -- Tool component for paramater table editor
    %   Manages data for parameter table editor
    
    % Copyright 2014-2023 The MathWorks, Inc.
    
    properties
        ParameterData
        ParentTab
        NumberRandomValuesGenerate
    end
    
    properties(GetAccess = public, SetAccess = protected, SetObservable = true)
        SelectedRow
    end
    
    properties (Dependent)
        Wksp
        VarName
    end
    
    properties (Access = protected)
        ChangeSet    % Uncommitted data changes
        DataType     % type of data used to store parameter values
        PlotListener % Listener for plot selections
    end
    
    methods
        function this = ParamTableTC(params,parent)
            % PARAMTABLETC Construct ParamTableTC object
            this = this@ctrluis.component.AbstractTC;
            this.ChangeSet = [];
            this.ParameterData = params;
            this.ParentTab = parent;
            this.NumberRandomValuesGenerate = 10;
            % Record type of data used to store parameter values
            if isa(params, 'sldodialogs.data.SampleSet')
                this.DataType = 'SampleSet';
            else
                this.DataType = 'struct';   % default, for struct or []
            end
            % Update tool component
            update(this);
        end
        
        % Property methods
        function dType = getDataType(this)
            % GETDATATYPE Get data type
            %
            dType = this.DataType;
        end
        
        function data = getParameterData(this, varargin)
            % GETPARAMETERDATA Get parameter data
            %    data = getParameterData(this)
            %    data = getParameterData(this, outputType)
            %
            %    "outputType" may be 'values' (default) or 'SampleSet'
            %
            if isempty(varargin)
                outputType = 'values';   % default
            else
                outputType = validatestring(varargin{1}, {'values', 'SampleSet'});
            end
            
            switch this.DataType
                case 'struct'
                    switch outputType
                        case 'values'
                            % Return parameter names/values
                            data = this.ParameterData;
                        otherwise
                            error(message('Controllib:gui:errUnexpected', ...
                            'If the "DataType" is ''struct'' the "outputType" must be ''values'' '));
                    end
                    
                case 'SampleSet'
                    switch outputType
                        case 'values'
                            % Return parameter names/values
                            data = ssetToStruct(this.ParameterData);
                        case 'SampleSet'
                            % Return SampleSet object
                            data = this.ParameterData;
                        otherwise
                            data = [];
                    end
            end
        end
        function setParameterData(this, data, varargin)
            % SETPARAMETERDATA Set parameter data
            %    setParameterData(this, data)
            %    setParameterData(this, data, inputType)
            %
            %    "inputType" may be 'values' (default) or 'SampleSet'
            %
            if isempty(varargin)
                inputType = 'values';   % default
            else
                inputType = validatestring(varargin{1}, {'values', 'SampleSet'});
            end
            
            switch this.DataType
                case 'struct'
                    switch inputType
                        case 'values'
                            % Input parameters contain names/values
                            if isempty(data)
                                this.SelectedRow = [];
                            elseif ~isempty(this.SelectedRow)  && ...
                                    (max(this.SelectedRow) > numel(data(1).Value))
                                %Make sure selected row is valid
                                this.SelectedRow = [];
                            end
                            this.ParameterData = data;
                        otherwise
                            error(message('Controllib:gui:errUnexpected', ...
                            'If the "DataType" is ''struct'' the "inputType" must be ''values'' '));
                    end
                
                case 'SampleSet'
                    switch inputType
                        case 'values'
                            % Input parameters contain names/values
                            if isempty(data)
                                this.SelectedRow = [];
                            elseif ~isempty(this.SelectedRow)  && ...
                                    (max(this.SelectedRow) > numel(data(1).Value))
                                %Make sure selected row is valid
                                this.SelectedRow = [];
                            end
                            structToSset(this.ParameterData, data);
                        case 'SampleSet'
                            % Input is a sample set
                            if ~isempty(this.SelectedRow)  && ...
                                    (max(this.SelectedRow) > getDataSize(data, 1))
                                %Make sure selected row is valid
                                this.SelectedRow = [];
                            end
                            this.ParameterData = data;
                    end
            end
            % Update tool component
            update(this);
        end
        
        function ws = get.Wksp(this)
            ws = this.ParentTab.ParamWks;
        end
        
        function vn = get.VarName(this)
            vn = getVarName(this);
        end
        
        function varargout = modifyCorrelationMatrix(this, type, varargin)
            % MODIFYCORRELATIONMATRIX Modify correlation matrix
            %
            if ~strcmp('SampleSet', this.DataType)
                error(message('Controllib:gui:errUnexpected', ...
                    'The "DataType" must be ''SampleSet'' to modify the correlation matrix'));
            end
            if nargout == 0
                modifyCorrelationMatrix(this.ParameterData, type, varargin{:} );
            else
                varargout{1} = modifyCorrelationMatrix(this.ParameterData, type, varargin{:} );
            end
            update(this);
        end

        % Regular methods

        function ps = getParameterSpace(this)
            % GETPARAMETERSPACE Get ParameterSpace
            %    Applicable if the data type is SampleSet
            if ~strcmp('SampleSet', this.DataType)
                error(message('Controllib:gui:errUnexpected', ...
                    'The "DataType" must be ''SampleSet'' to get the ParameterSpace'));
            end
            ps = this.ParameterData.ParameterSpace;
        end
        
        function ps = setParameterSpace(this, ps)
            % SETPARAMETERSPACE Set ParameterSpace
            %    Applicable if the data type is SampleSet
            if ~strcmp('SampleSet', this.DataType)
                error(message('Controllib:gui:errUnexpected', ...
                    'The "DataType" must be ''SampleSet'' to get the ParameterSpace'));
            end
            this.ParameterData.ParameterSpace = ps;
            update(this);
        end
        
        function applyParameterData(this,params)
            setParameterData(this, params);
        end
        function appendParameterData(this,params)
            oldparams = getParameterData(this);
            oldparamnames = {oldparams.Name};
            newparamnames = {params.Name};
            for ct = 1:numel(newparamnames)
                ind = find(strcmp(newparamnames{ct},oldparamnames));
                oldparams(ind).Value = vertcat(oldparams(ind).Value(:),...
                    params(ct).Value(:));
            end
            setParameterData(this, oldparams);
        end
        function setSelectedRow(this,r)
            
            if any(r < 0) || any(r > getDataSize(this,1))
                error(message('Controllib:gui:errUnexpected','Invalid row index'))
            end
            this.SelectedRow = double(r)+1; %MATLAB indexing
            
            %Update any views
            update(this);
        end
        function updateTableForNewParameters(this,param2remove,param2add,newdata)
            if isa(newdata, 'sldodialogs.data.SampleSet')
                % Update parameters in sample set handle object
                setParameterData(this, newdata, 'SampleSet');
            else
                % Add/remove parameters as needed to value object
                if isempty(newdata)
                    % Case of going back to zero parameters
                    params = [];
                elseif isempty(getParameterData(this))  &&  ~isempty(param2add)
                    % First new set of parameters - Generate a few samples
                    for ct = numel(param2add):-1:1
                        thisname = param2add{ct};
                        % Find it inside parameter array
                        ind = strcmp(thisname,{newdata.Name});
                        val = newdata(ind).Value;
                        params(ct).Name = thisname;
                        params(ct).Value =  repmat(val(:),2,1);
                    end
                else
                    % Add the ones to be added
                    params = getParameterData(this);
                    if ~isempty(param2add)
                        N = numel(params.Value);
                        for ct = 1:numel(param2add)
                            thisname = param2add{ct};
                            % Find it inside parameter array
                            ind = strcmp(thisname,{newdata.Name});
                            val = newdata(ind).Value;
                            params(end+1).Name = thisname; %#ok<AGROW>
                            params(end).Value = repmat(val(:),N,1);
                        end
                    end
                    % Remove the ones to be removed
                    if ~isempty(param2remove)
                        ind2del = [];
                        for ct = numel(param2remove):-1:1
                            thisname = param2remove{ct};
                            % Find it inside parameter array
                            ind2del(ct) = find(strcmp(thisname,{params.Name}));
                        end
                        params(ind2del) = [];
                    end
                end
                setParameterData(this,params);
            end
            if isempty(this.SelectedRow)
                setSelectedRow(this, 0);   % Java indexing
            end
            updateGenerateParamTable(this);
        end
        function deleteRow(this)
            r = this.SelectedRow;
            if isempty(r) || any(r < 1) || any(r>getDataSize(this,1))
                error(message('Controllib:gui:AddParamTable_ErrorSelectRow'));
            end
            params = getParameterData(this);
            for ct = 1:numel(params)
                params(ct).Value(r) = [];
            end
            
            %Reset selected row before deleting, since number of rows will
            %be reduced
            nSelected = numel(r);
            nRowsAfter = getDataSize(this, 1) - nSelected;
            if nRowsAfter < 1
                %No more rows after deletion
                newSel = [];
            else
                %After deletion, the selected row will be the row after the
                %last deleted row
                newSel = r(end) - nSelected + 1;
                newSel = min(newSel, nRowsAfter);
            end
            setSelectedRow(this, newSel-1);   % Java indexing
            
            %Set the data
            setParameterData(this,params);
            
        end
        function insertRow(this,above)
            
            %Common items
            r = this.SelectedRow;
            nRows = getDataSize(this,1);
            
            %If there are no rows of data, insert using values from the
            %model
            if nRows == 0
                mdl = this.ParentTab.Model;
                params = getParameterData(this);
                for ct = 1:numel(params)
                    val = sdo.getValueFromModel(mdl, params(ct).Name);
                    params(ct).Value = val;
                end
                setParameterData(this,params);
                % Early return, rest of function handles selected rows
                return
            end
            
            %Make sure selected rows are valid
            if isempty(r)  ||  any(r < 1)  ||  any(r > getDataSize(this,1))
                error(message('Controllib:gui:AddParamTable_ErrorSelectRow'));
            end
            
            %There are rows of data.  Organize information about row
            %selections in a table.  Each table row represents blocks of
            %contiguous rows, whether selected or not.  The table columns
            %are: {i1, i2, selected}. In each table row, column "selected"
            %indicates whether data(i1:i2) are selected.
            blocks = table(nan(nRows,1), nan(nRows,1), false(nRows,1), ...
                'VariableNames', {'i1','i2','selected'});
            %Start making settings in first block
            blocks{1,'i1'}       = 1;
            blocks{1,'i2'}       = 1;
            blocks{1,'selected'} = ismember(1, r);
            %Continue setting rest of block info
            ctB = 1;   % index over blocks
            for ctD = 2:nRows   % index over original data
                sPrev = ismember(ctD-1, r);
                sThis = ismember(ctD,   r);
                if sPrev == sThis
                    %Still in same block
                    blocks{ctB,'i2'} = ctD;
                else
                    %In a different block
                    ctB = ctB + 1;
                    blocks{ctB,'selected'} = sThis;
                    blocks{ctB,'i1'} = ctD;
                    blocks{ctB,'i2'} = ctD;
                end
            end
            %Remove extra rows
            bIdx = isnan(blocks.i1);
            blocks(bIdx,:) = [];
            
            %Copy data, duplicating values in selected rows
            params = getParameterData(this);
            for ctP = 1:numel(params)
                oldVal = params(ctP).Value;
                oldVal = oldVal(:);   % ensure column
                newVal = nan(nRows + numel(r), 1);
                i3 = 1;
                for ctB = 1:height(blocks)
                    i1 = blocks{ctB,'i1'};
                    i2 = blocks{ctB,'i2'};
                    data = oldVal(i1:i2);
                    if blocks{ctB,'selected'}
                        %Duplicate values in selected rows/blocks
                        data = [data ; data]; %#ok<AGROW>
                    end
                    i4 = i3 + numel(data) - 1;
                    newVal(i3:i4) = data;
                    %Set up for next iteration
                    i3 = i4 + 1;
                end
                params(ctP).Value = newVal;
            end
            
            %Set the data
            setParameterData(this,params);
            
            %Reset selected row after inserting, since the number of rows
            %will be increased.  If inserting above selected rows, the
            %row selections shift down.
            rNew = [];
            i3 = 1;
            for ctB = 1:height(blocks)
                i1 = blocks{ctB,'i1'};
                i2 = blocks{ctB,'i2'};
                nrb  = i2 - i1 + 1;   % number of rows in block
                i4 = i3 + nrb - 1;
                if blocks{ctB,'selected'}
                    if above
                        i3 = i4+1;
                        i4 = i3 + nrb - 1;
                        rNew = [rNew ; (i3:i4)']; %#ok<AGROW>
                    else
                        rNew = [rNew ; (i3:i4)']; %#ok<AGROW>
                        %Move i4 ahead since data is duplicated due to
                        %insertion
                        i4 = i4 + nrb;
                    end
                end
                %Set up for next iteration
                i3 = i4 + 1;
            end
            
            %Set the selected rows
            setSelectedRow(this, rNew-1);   % Java indexing
        end
        
        function updateGenerateParamTable(this)
            updateGenerateParamTable(this.ParentTab);
        end
        
        % View
        function view = createView(this)
            view = ctrluis.paramtable.ParamTableGC(this);
        end
        function name = getVarName(this)
            % GETVARNAME Get name of variable this tool component manages
            %
            name = this.ParentTab.ParamVarName;
        end
        function setVarName(this, newValue)
            % SETVARNAME Set name of variable this tool component manages
            %
            this.ParentTab.ParamVarName = newValue;
        end
        
        function linkToPlot(this,hPlot)
            %LINKTOPLOT
            %
            %    Create listeners to a scatter pairs plot so that the table
            %    row selection can update when the table row selections
            %    change.
            %
            
            if ~strcmp(hPlot.DataSrc.Name,this.VarName)
                error(message('sldo:general:errUnexpected','Table and plot must show the same variable'))
            end
            
            if ~isempty(this.PlotListener) && isvalid(this.PlotListener)
                delete(this.PlotListener)
            end
            
            hPlotMatrix = getPlot(hPlot);
            this.PlotListener = event.proplistener(hPlotMatrix,findprop(hPlotMatrix,'BrushedIndex'),...
                'PostSet', @(es,ed) cbPlotBrushSelection(this,ed));
        end
        function sz = getDataSize(this,dim)
            %GETDATASIZE
            %
            
            switch this.DataType
                case 'struct'
                    if isempty(this.ParameterData)
                        sz = [0 0];
                    else
                        sz = [numel(this.ParameterData(1).Value), numel(this.ParameterData)];
                    end
                case 'SampleSet'
                    sz = size(this.ParameterData.Values);                    
            end
            if nargin > 1
                sz = sz(dim);
            end
        end
    end
    
    methods  (Access = protected)
        function props = getIndependentVariables(this) %#ok<MANU>
            % Model is not here because it cannot be modified
            props = {''};
        end
        function mUpdate(this)
            % Synchronize independent properties
            props = getIndependentVariables(this);
            for k = 1:length(props)
                p = props{k};
                if isfield(this.ChangeSet, p)
                    this.Database.(p) = this.ChangeSet.(p);
                end
            end
            %Update the view
            update(this.ParentTab);
        end
        function cbPlotBrushSelection(this,ed)
            %CBPLOTBRUSHSELECTION Manage plot brushing events
            %
            idx = ed.AffectedObject.BrushedIndex;
            setSelectedRow(this,find(idx)-1); %Java indexing
        end
    end
    
    methods (Sealed, Access = protected)
        function setChangeSetProperty(this, varname, varvalue)
            props = this.getIndependentVariables;
            if isempty(props) || ~any( strcmp(varname, props) )
                ctrlMsgUtils.error('Controllib:toolpack:NotAnIndependentProperty', varname)
            end
            this.ChangeSet.(varname) = varvalue;
        end
    end
    
end
