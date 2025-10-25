classdef CellArrayDataModel < internal.matlab.variableeditor.ArrayDataModel
    %CellARRAYDATAMODEL 
    %   Cell Array Data Model

    % Copyright 2014-2025 The MathWorks, Inc.

    properties (Constant)
        Type = 'CellArray';
        ClassType = 'cell';
    end

    properties (SetObservable=true, SetAccess='public', GetAccess='public', Dependent=false, Hidden=false)
        Data
    end

    methods
        function storedValue = get.Data(this)
            storedValue = this.Data;
        end
        
        function set.Data(this, newData)
            if ~isa(newData,'cell') || length(size(newData))~=2
                error(message('MATLAB:codetools:variableeditor:NotAnMxNCellArray'));
            end

            this.Data = newData;
        end
    end

    methods(Access='protected')    
        function lhs=getLHS(this,idx)
            dims = str2num(idx);
            subIdx = '';
            % If this cell is currently a datetime, use indexer to keep the
            % datetime format
            sz = this.getSize();
            % Check if dims is within size to subIndex. This need not be
            % accounted for in Infinite Grid edits
            if (sz(1) >= dims(1) && sz(2) >= dims(2))
                classType = class(this.Data{dims(1), dims(2)});
                if any(strcmp(classType, ["datetime","categorical","nominal","ordinal"]))
                    subIdx = '(1)';
                end
            end
            lhs = sprintf('{%s}%s',idx, subIdx);
        end
    end
    
    methods(Access='public')
        function rhs=getRHS(~,data)
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
    end
end

