classdef TableDataModel < internal.matlab.variableeditor.ArrayDataModel & internal.matlab.variableeditor.TableDataModelBase
    %TABLEDATAMODEL 
    %   Table Data Model

    % Copyright 2013-2023 The MathWorks, Inc.

    % Type
    properties (Constant) 
        % Type Property
        Type = 'Table';
        
        ClassType = 'table';
    end %properties

    % Data
    properties (SetObservable=true, SetAccess='public', GetAccess='public', Dependent=false, Hidden=false)
        % Data Property
        Data
    end %properties

    properties (SetAccess='protected', GetAccess='public', Hidden=true)        
        CachedSize = [0 0]; %
        GroupedColumnStartIndices = []
    end %properties
    
    methods
        function storedValue = get.Data(this)
            storedValue = this.Data;
        end
        
        function set.Data(this, newValue)
            if ~istabular(newValue) || length(size(newValue))~=2
                error(message('MATLAB:codetools:variableeditor:NotATable'));
            end
            % Commenting out the isequal check for tables because it does
            % not work if there is a type change.
            reallyDoCopy = true; %~isequal(this.Data, newValue);
            if reallyDoCopy
                this.Data = newValue;
            end
        end
    end

    methods(Access='protected')
        
        function [classType, column] = getDataClassType(this, s, idx, row, column)
            % within the data range so you know the type for this cell
            if row <= s(1) && column <= s(2)
                classType = eval(sprintf('class(this.Data{%s})',idx));
            % within a column so you can tell what the type is
            elseif column <= s(2)
                classType = eval(sprintf('class(this.Data.(%d))',column));
            % outside the row and column where we have to examine the data
            % to know its type
            else
                classType = '';
                column = width(this.Data) + 1;
            end
        end

        function subsExpr = generateDotSubscp(this, column, tname, forceNumericIndex)
            if nargin < 4 || isempty(forceNumericIndex)
                subsExpr = matlab.internal.tabular.generateDotSubscripting(this.Data, column, tname);
            else
                subsExpr = matlab.internal.tabular.generateDotSubscripting(this.Data, column, tname, forceNumericIndex);
            end
        end
    end

     methods(Access='public')
        function rhs=getRHS(this,data)
            rhs = getRHS@internal.matlab.variableeditor.TableDataModelBase(this, data);
        end
    end
end

