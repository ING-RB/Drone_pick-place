classdef StructureDataModel < internal.matlab.variableeditor.ArrayDataModel & internal.matlab.variableeditor.EditableVariable
    %StructureDataModel 
    %   Structure Data Model

    % Copyright 2013-2023 The MathWorks, Inc.
        % Type Property
        
    properties(Constant)
        Type = 'Structure';        
        ClassType = 'struct';
    end    
    
    properties
        NumberOfColumns; % Update cached size whenever this is set.       
    end
    
    % Type
    properties (SetObservable=false, SetAccess='protected', GetAccess='public', Dependent=false, Hidden=true)        
        CachedSize = [0 0]; %
    end %properties

    properties (SetObservable=true, SetAccess='public', GetAccess='public', Dependent=false, Hidden=true)
        % Data_I Property
        Data_I = struct();
    end %properties
    
    methods
        function storedValue = get.Data_I(this)
            storedValue = this.Data_I;
        end
        
        function set.Data_I(this, newValue)
            this.Data_I = newValue;
        end
    end

    % Data
    properties (SetObservable=true, SetAccess='public', GetAccess='public', Dependent=true, Hidden=false)
        % Data Property
        Data;
    end %properties
    
    methods
        function storedValue = get.Data(this)
            storedValue = this.Data_I;
        end
        
        % setData - Sets a block of values.
        %
        % If only one paramter is specified that parameter is assumed to be
        % the data and all of the data is replaced by that value.
        %
        % Otherwise, the parameters must be in groups of three.  These
        % triplets must be in the form:  newValue, row column.
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
            if rem(nargin-1, 3)~=0
                error(message('MATLAB:codetools:variableeditor:UseNameRowColTriplets'));
            end

            % Range(s) specified (value-range pairs)
            outputCounter = 1;
            setCommands = cell(1,round((nargin-1)/3));
            for i=3:3:nargin
                newValue = varargin{i-2};
                row = varargin{i-1};
                column = varargin{i};
                if (this.isFieldNameColumn(column))
                    fnames = fieldnames(this.Data);
                    numFields = length(fnames);
                    originalLhs = this.getLHS(sprintf('%d,%d',row,column));
                    rhs = sprintf('%s%s', this.Name, originalLhs);
                    assignmentCmd = sprintf('%s = %s; ', ['.' newValue], rhs);
                    % Do not generate orderFields for last fname edit or if
                    % this is a duplicate field name.
                    if (row == numFields) || any(ismember(fnames, newValue))
                        orderFieldsCmd = '';
                    else
                        orderFieldsCmd = sprintf('%s = orderfields(%s, [1:%d, %d, %d:%d]); ', ...
                        this.Name, this.Name, row, numFields +1 , row + 1, numFields);
                    end
                    deletionCmd = sprintf('%s = rmfield(%s, "%s");', this.Name, this.Name, originalLhs(2:end));
                    setCommand = sprintf('%s%s%s', assignmentCmd, orderFieldsCmd, deletionCmd);
                else
                    lhs = this.getLHS(sprintf('%d,%d',row,column));
                    rhs = this.getRHS(newValue);
                    setCommand = sprintf('%s = %s;', lhs, rhs);
                end                
                setCommands{outputCounter} = setCommand;
                outputCounter = outputCounter+1;
            end            
            varargout{1} = setCommands;
        end
        
        function set.Data(this, newValue)
            this.Data_I = newValue;
        end

        % Sets CachedSize property
        function setCachedSize(this, sz)
            arguments
                this
                sz double
            end
            this.CachedSize = sz;
        end

        function updateCachedSize(this)
            fn = fieldnames(this.Data_I);
            % Cache the size because calling fieldnames can be expensive
            % if there are lots of fields
            if isempty(fn)
                % Empty struct should still have the correct number of
                % columns
                this.CachedSize = [0, this.NumberOfColumns];
            else
                this.CachedSize = [length(fn) this.NumberOfColumns];
            end
        end
    end

    methods(Access='public')
        % getSize
        function s = getSize(this)
            s = this.CachedSize;
        end %getSize
        
        % For now, assume that column 1 is Field column. This will be
        % refactored when we add support for column re-ordering.
        function isField = isFieldNameColumn(~, columnNumber)
             isField = false;
            if columnNumber == 1
                isField = true;
            end
        end
        
    end %methods   
end

