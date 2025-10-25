classdef ObjectArrayDataModel < internal.matlab.variableeditor.ArrayDataModel
    %OBJECTARRAYDATAMODEL 
    % Object Array Data Model

    % Copyright 2015-2023 The MathWorks, Inc.

    % Type
    properties (Constant)
        % Type Property
        Type = 'ObjectArray';
        
        ClassType = 'objectarray';
    end

    % Data
    properties (SetObservable = true)
        % Data Property
        Data
    end
    
    properties (SetAccess='protected', GetAccess='public')
        DataAsCell;   % Cached cell representation of data
        ClassList;    % Cached class list
    end

    properties (SetAccess='protected', GetAccess='public', Dependent)
        PropertyList; % Cached property list
    end

    properties (Access=protected)
        PropertyListI; % Cached property list
    end

    methods
        function val = get.PropertyList(this)
            val = this.getProperties();
        end
    end

    properties(SetObservable = true)
        ShowAllProperties (1,1) logical = true;
    end

    methods
        function set.ShowAllProperties(this, newValue)
            oldValue = this.ShowAllProperties;
            this.ShowAllProperties = newValue;
            this.updateCaches(this.Data); %#ok<MCSUP>

            % Both Meta Data and Data Changed Events Need to Fire
            metaDataEvent = internal.matlab.datatoolsservices.data.ModelChangeEventData;
            metaDataEvent.Row = 1;
            metaDataEvent.Column = 1:length(this.getProperties());
            metaDataEvent.Key = 'ShowAllProperties';
            metaDataEvent.OldValue = oldValue;
            metaDataEvent.NewValue = newValue;
            this.notify('CellMetaDataChanged', metaDataEvent);

            eventdata = internal.matlab.datatoolsservices.data.DataChangeEventData;
            eventdata.SizeChanged = true;
            eventdata.EventSource = 'InternalDmUpdate';
            this.notify('DataChange', eventdata);  
        end
    end
    
    methods
        function storedValue = get.Data(this)
            storedValue = this.Data;
        end
        
        function set.Data(this, newValue)
            if ~(isobject(newValue) || all(all(ishandle(newValue)))) || ~isvector(newValue)
                error(message('MATLAB:codetools:variableeditor:NotAnObjectVector'));
            end
            this.Data = newValue;
            this.updateCaches(newValue);
        end
    end

    methods (Access = protected)
        function updateCaches(this, newValue)
            this.PropertyListI = string.empty;
            props = this.getProperties();
            if ~isempty(props) && ...
                    (~ismethod(newValue, 'isvalid') || all(isvalid(newValue), 'all'))
                dac = internal.matlab.datatoolsservices.FormatDataUtils.convertObjectArrayToCell(newValue, props);
                this.DataAsCell = dac;
                this.ClassList = string(arrayfun(@class, this.Data, 'UniformOutput', false));
            else
                this.DataAsCell = {};
                this.ClassList = string(arrayfun(@class, this.Data, 'UniformOutput', false));
            end
        end

        function lhs = getLHS(this, idx)
            props = this.getProperties();
            idxs = str2num(idx);
            propIdx = idxs(2);
            colName = props{propIdx};
            colClass = class(this.Data(idxs(1)).(colName));
            subIdx = '';
            % For any categorical types, subindex using (1) to assign
            % values. This is not needed for datetime values.
            if any(strcmp(colClass, ["categorical","nominal","ordinal"]))
                subIdx = '(1)';
            end
            lhs = sprintf('(%d).%s%s', idxs(1), colName, subIdx);
        end
    end

    methods(Access='public')
        function varargout = getData(this,varargin)
            if nargin>=5 && ~isempty(this.Data)
                % Fetch a block of data using startrow, endrow, startcol,
                % endcol
                [startRow, endRow, startColumn, endColumn] = internal.matlab.datatoolsservices.FormatDataUtils.resolveRequestSizeWithObj(...
                    varargin{1}, varargin{2}, varargin{3}, varargin{4}, size(this.DataAsCell));
                % Indexing will not work for types like curve-fitting objects
                % that cannot be concatenated. Fallback to returning entire Data (g2032641).
                try
                    varargout{1} = this.DataAsCell{startRow:endRow,startColumn:endColumn};
                catch
                    varargout{1} = this.Data;
                end
            else
                % Otherwise return all data
               varargout{1} = this.Data;
            end
        end

        function rhs=getRHS(this, data)
            if (size(data,1)==1)
                rhs = data;
            else
                rhs = '{';
                for i=1:size(data,1)
                    for j=1:size(data,2)
                        rhs = [rhs mat2str(data{i,j}) ' '];
                    end
                    rhs = [rhs ';'];
                end
                rhs = [rhs '}'];
            end
        end

        function props = getProperties(this, data, showAllProperties)
            arguments
                this
                data = this.Data
                showAllProperties = this.ShowAllProperties
            end

            if isequaln(data, this.Data) && showAllProperties == this.ShowAllProperties && isempty(this.PropertyListI)
                this.PropertyListI = internal.matlab.variableeditor.ObjectArrayDataModel.GetObjectArrayProperties(data, showAllProperties);
                props = this.PropertyListI;
            else
                props = internal.matlab.variableeditor.ObjectArrayDataModel.GetObjectArrayProperties(data, showAllProperties);
            end

        end
    end

    methods(Static)
        function props = GetObjectArrayProperties(data, showAllProperties, classList)
            arguments
                data {mustBeVector}
                showAllProperties (1,1) logical = true
                classList string = string.empty;
            end

            props = properties(data);
            if (~showAllProperties)
                 % Trim the list of properties
                 % TODO: replace with MCOS APIs
                 % This is a total hack
                 if isempty(classList)
                     classList = string(arrayfun(@class, data, 'UniformOutput', false));
                 end
                 if length(unique(classList)) > 1
                     for i=1:length(data)
                        p = parseObjectDispForProperties(data(i));
                        props = intersect(p, props, "stable");
                     end
                 else
                    p = parseObjectDispForProperties(data(1));
                    props = intersect(p, props, "stable");
                 end
            end
        end
    end
end

function props = parseObjectDispForProperties(obj) %#ok<INUSD>
    % Parse disp output to get list of curated properties
    % TODO: Replace.  This is temporary until we get the APIs from the MCOS team
    d = evalc("disp(obj)");
    ro = regexp(d, "(?m)^\s+(?<property>[A-Za-z0-9\_\-]*?):\s+(?<value>.*)$", "dotexceptnewline", "names");
    props = {ro.property}';
end
