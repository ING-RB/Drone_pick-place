classdef StructureArrayDataModel < internal.matlab.variableeditor.ArrayDataModel
    %STRUCTUREARRAYDATAMODEL 
    %   Structure Array Data Model

    % Copyright 2015-2023 The MathWorks, Inc.

    % Type
    properties (Constant)
        % Type Property
        Type = 'StructureArray';
        
        ClassType = 'struct';
    end %properties

    % Data
    properties (SetObservable=true, SetAccess='public', GetAccess='public', Dependent=false, Hidden=false)
        % Data Property
        Data
    end %properties
    
    properties (SetAccess='protected', GetAccess='public')
        DataAsCell;
    end
    
    methods
        function storedValue = get.Data(this)
            storedValue = this.Data;
        end
        
        function set.Data(this, newValue)
            if ~isa(newValue,'struct') || length(size(newValue))~=2
                error(message('MATLAB:codetools:variableeditor:NotAnMxNCellArray'));
            end
            this.Data = newValue;
            this.updateDataAsCell(newValue);
        end
    end
    
    methods(Access='protected')
        
        function updateDataAsCell(this, newValue)
            this.DataAsCell = internal.matlab.datatoolsservices.FormatDataUtils.convertStructToCell(newValue);
        end
        
        function lhs=getLHS(this,idx)
            dims = str2num(idx);
            columns = fields(this.Data);
            if dims(2) <= length(columns)
                selectedColumnName = columns{dims(2)};
            else
                % New Column (infinite grid), generate a unique name
                selectedColumnName = internal.matlab.datatoolsservices.VariableUtils.generateUniqueName('unnamed', columns);
            end
            % If this cell is currently a datetime or of categorical types, use indexer to keep the datetime/categorical format
            classType = class(this.DataAsCell{dims(1), dims(2)});
            subIdx = '';
            if any(strcmp(classType, ["datetime","categorical","nominal","ordinal"]))
                subIdx = '(1)';
            end
            lhs = sprintf('(%d).%s%s',dims(1),selectedColumnName, subIdx);
        end
    end
    
    methods(Access='public')
        function rhs=getRHS(~,data)
            if (size(data,1)==1)
                rhs = data;
            else
                rhs = '{';
                for i=1:size(data,2)
                    if i>1
                        rhs = [rhs ';'];
                    end
                    for j=1:size(data,1)
                        if j>1
                            rhs = [rhs ','];
                        end
                        rhs = [rhs mat2str(data(i,j))];
                    end
                end
                rhs = [rhs '}'];
            end
        end
        
        function eq = equalityCheck(this, oldData, newData)
            eq = internal.matlab.variableeditor.areVariablesEqual(oldData, newData);
            if (eq)
                % Force an update by causing the equality check to fails 
                % even if variables are equal
                eq = ~this.ForceUpdate;
            end
        end
    end
end



