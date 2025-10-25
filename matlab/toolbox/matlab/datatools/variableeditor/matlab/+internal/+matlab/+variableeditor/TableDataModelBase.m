classdef TableDataModelBase < handle
    %TABLEDATAMODELBASE
    %   Table Data Model Base

    % Copyright 2022 The MathWorks, Inc.
    methods(Access='protected')
        function lhs=getLHS(this,idx,columnIndex, valLength, newVal)
            arguments
                this
                idx
                columnIndex = 1;
                valLength = 1;
                newVal = [];
            end            
            if contains(idx, ',')
                vals = strsplit(idx, ',');
                row = str2double(vals{1});
                column = str2double(vals{2});
            else
                row = sscanf(idx,'%d');
                column = 1;
            end

            % Support infinite grid
            s = size(this.Data);
            [classType, column] = getDataClassType(this, s, idx, row, column);

            if strcmpi(classType,'cell')
                lhs = sprintf('%s{%d,%d}',generateDotSubscp(this,column,''),row,columnIndex);
            elseif strcmpi(classType, 'char')
                lhs = sprintf('%s(%d,%d:%d)',generateDotSubscp(this,column,''),row,columnIndex, valLength);
            elseif ismember(classType, ["categorical", "ordinal", "nominal"])
                lhs = sprintf('%s(%d,%d)',generateDotSubscp(this,column,''),row,columnIndex);
            else
                if isscalar(newVal) 
                    lhs = sprintf('%s(%d,%d)',generateDotSubscp(this,column,''),row,columnIndex);
                else
                    lhs = sprintf('%s{%d,%d}',generateDotSubscp(this,column,''),row,columnIndex);
                end
            end
        end
    end

    methods(Access='public')
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
                        rhs = [rhs ';'];
                    end
                    for j=1:size(data,2)
                        rhs = [rhs mat2str(data(i,j)) ' '];
                    end
                    %rhs = [rhs ';'];
                end
                rhs = [rhs ')'];
            end
        end
    end

    methods(Access='protected',Abstract=true)
        [classType, column] = getDataClassType(this, size, idx, row, column);
        subsExpr = generateDotSubscp(this, column, tname, forceNumericIndex);
    end

    
end