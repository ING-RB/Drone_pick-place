classdef TimeTableDataModel < internal.matlab.legacyvariableeditor.ArrayDataModel
    %TimeTableDataModel 
    %   TimeTable Data Model

    % Copyright 2013-2023 The MathWorks, Inc.

    % Type
    properties (Constant)
        % Type Property
        Type = 'TimeTable';
        
        ClassType = 'timetable';
    end %properties

    properties (SetObservable=false, SetAccess='protected', GetAccess='public', Dependent=false, Hidden=true)
    % Data Property
    Data_I
    end %properties

    % Data
    properties (SetObservable=true, SetAccess='public', GetAccess='public', Dependent=true, Hidden=false)
        % Data Property
        Data = timetable;
    end %properties
    methods
        function storedValue = get.Data(this)
            storedValue = timetable2table(this.Data_I);
        end
        
        function set.Data(this, newValue)
            if ~istabular(newValue) || length(size(newValue))~=2
                error(message('MATLAB:codetools:variableeditor:NotATable'));
            end
            if istimetable(newValue)
                this.Data_I = newValue;
            else
                this.Data_I = table2timetable(newValue);
            end
        end
        
        function ttData = getCloneData(this)
            ttData = this.Data_I;
        end
    end

    methods(Access='protected')
        function lhs=getLHS(this,idx,columnIndex)
            if nargin<3
                columnIndex = 1;
            end
            
            row = sscanf(idx,'%d');
            varName = eval(sprintf('this.Data(%s).Properties.VariableNames{1}',idx));

            % Check to see if this is the time column
            if strcmp(varName, this.Data.Properties.VariableNames{1})
               lhs = sprintf('.%s(%d)',varName,row);
            else
                if iscell(this.Data.(varName))
                    lhs = sprintf('.%s{%d,%d}',varName,row,columnIndex);
                else
                   lhs = sprintf('.%s(%d,%d)',varName,row,columnIndex);
                end
            end
        end
    end
    
    methods(Access='public')
        function lhs=getLHSGrouped(this,idx,columnIndex)
            lhs = this.getLHS(idx,columnIndex);
        end
        
        function rhs=getRHS(this,data)
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
end

