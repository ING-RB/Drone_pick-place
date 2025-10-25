classdef TimeTableDataModel < internal.matlab.variableeditor.ArrayDataModel
    %TimeTableDataModel 
    %   TimeTable Data Model

    % Copyright 2013-2024 The MathWorks, Inc.

    % Type
    properties (Constant)
        % Type Property
        Type = 'TimeTable';
        
        ClassType = 'timetable';
    end %properties

    properties (SetObservable=false, SetAccess='protected', GetAccess='public', Dependent=false, Hidden=true)
    % Data Property
    Data_I% Timetable version of the data
    TableData_I
    end %properties

    % Data
    properties (SetObservable=true, SetAccess='public', GetAccess='public', Dependent=true, Hidden=false)
        % Data Property
        Data = timetable;
    end %properties
    methods
        function storedValue = get.Data(this)
            storedValue = this.TableData_I;
        end
        
        function set.Data(this, newValue)
            if ~istabular(newValue) || length(size(newValue))~=2
                error(message('MATLAB:codetools:variableeditor:NotATable'));
            end
            if istimetable(newValue)
                this.Data_I = newValue;
                this.TableData_I = timetable2table(newValue);
            else
                this.TableData_I = newValue;
                % Re-attach events when we are constructing the timetable
                % back from table data (For e.g when table is internally sorted etc.)
                events = [];
                if (isprop(this.Data_I, 'Events') && ~isempty(this.Data_I.Properties.Events))
                    events = this.Data_I.Properties.Events;
                end
                this.Data_I = table2timetable(newValue);
                if ~isempty(events)
                    this.Data_I.Properties.Events = events;
                    % RowMetaData is changing on dataset, emit RowMetaDataChanged event
                    this.handleRowMetaDataUpdate(this.Data_I);
                end
            end
        end
        
        function ttData = getCloneData(this)
            ttData = this.Data_I;
        end
    end

    methods(Access='protected')
        % For char type columns, we need to specify startIndex:valLength in
        % LHS, take in additional valLength which is the length of cell
        % contents.
        function lhs=getLHS(this,idx,columnIndex, valLength, newVal)
            arguments
                this
                idx
                columnIndex = 1;
                valLength = 1;
                newVal = [];
            end
            rowcol = str2num(idx);
            row = rowcol(1);
            col = rowcol(2);

            s = size(this.Data);
            isNewCol = false;
            if col > s(2)
                % Support infinite grid
                varName = matlab.internal.tabular.defaultVariableNames(s(2));
                isNewCol = true;
            else
                varName = eval(sprintf('this.Data(%s).Properties.VariableNames{1}',idx));
            end
            
            % Determine how to index into the table variable.  We can't use the
            % table function matlab.internal.tabular.generateDotSubscripting
            % here, like TableDataModel, because of how timetables are stored as
            % tables internally.
            if isvarname(varName)
                % This is a valid variable name, index like:  t.A
                varIndex = varName;
            elseif isempty(find((char(varName)<=31 | char(varName)==127), 1))
                % This is an arbitrary variable name, but has printable
                % characters, so index like:  t.('#')
                varIndex = "('" + varName + "')";
            else
                % This is an arbitrary variable name, but has unprintable
                % characters.  Index like:  t.(2)
                col = col - 1;
                varIndex = "(" + col + ")";
            end
            
            % Check to see if this is the time column
            if strcmp(varName, this.Data.Properties.VariableNames{1})
                if isvarname(varName)
                    lhs = sprintf('.%s(%d)',varName,row);
                else
                    lhs = sprintf('.%s(%d)', varIndex, row);
                end
            else
                if  ~isNewCol && iscell(this.Data.(varName))
                    lhs = sprintf('.%s{%d,%d}', varIndex, row, columnIndex);
                 elseif ~isNewCol && isa(this.Data.(varName), 'char')
                    lhs = sprintf('.%s(%d,%d:%d)', varIndex, row, columnIndex, valLength);
                else
                    % g2643676: Categoricals variables should be not be
                    % indexed as a cell.
                    if isscalar(newVal) || (~isNewCol && iscategorical(this.Data.(varName)))
                        lhs = sprintf('.%s(%d,%d)', varIndex, row, columnIndex);
                    else
                        lhs = sprintf('.%s{%d,%d}', varIndex, row, columnIndex);
                    end
                end
            end
        end
    end
    
    methods(Access='public')
         % getSize
        % Returns the size of the timetable data as table (with timestamp
        % included in the data size)
        function s = getSize(this)
            s = size(this.Data_I);
            s(2) = s(2) + 1;
        end 

        function lhs=getLHSGrouped(this,idx,columnIndex, valLength, newVal)
            arguments
                this
                idx
                columnIndex
                valLength = 1
                newVal = 0
            end
            lhs = this.getLHS(idx,columnIndex, valLength, newVal);
        end
        
        function rhs=getRHS(~,data)
            if (size(data,1)==1)
                rhs = data;
            else
                rhs = '(';
                for i=1:size(data,1)
                    if i > 1
                        rhs = [rhs ';']; %#ok<*AGROW>
                    end
                    for j=1:size(data,2)
                        rhs = [rhs mat2str(data(i,j)) ' '];
                    end
                    %rhs = [rhs ';'];
                end
                rhs = [rhs ')'];
            end
        end

        function textEvents = getTextEvents(this, data)
            arguments
                this
                data = this.getCloneData
            end
            textEvents = data.rowDim.textEvents;
        end
    end
end

