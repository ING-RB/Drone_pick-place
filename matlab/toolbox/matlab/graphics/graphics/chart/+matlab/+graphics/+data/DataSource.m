classdef (Hidden) DataSource < matlab.graphics.data.AbstractDataSource
    %
    
    %   Copyright 2021 The MathWorks, Inc.
    
    properties (SetAccess=protected, GetAccess=public)
        Table tabular = table()
    end
    methods
        function obj=DataSource(varargin)
            obj@matlab.graphics.data.AbstractDataSource(varargin{:});
        end
        
        function setData(obj, tbl)
            arguments
                obj matlab.graphics.data.AbstractDataSource
                tbl tabular
            end

            varNames = [tbl.Properties.DimensionNames(1) tbl.Properties.VariableNames];
            varData = [{tbl.(varNames{1})} getVars(tbl,false)];
            if width(tbl) > 0 || ~isempty(varData{1})
                setData@matlab.graphics.data.AbstractDataSource(obj, ...
                    varData, varNames);
            end
            obj.Table = tbl;
        end
        
        function inds=subscriptToIndex(obj,varargin)
            args = varargin;
            if nargin>1
                subs = args{1};
                args(1) = [];

                if islogical(subs)
                    subs = find(subs);
                elseif isa(subs, 'vartype') || isa(subs, 'pattern')
                    ind = 1:width(obj.Table);
                    vars = obj.getData(ind);
                    names = obj.getVarNames(ind);
                    tbl=table(vars{:}, 'VariableNames', names);
                    
                    subs_varnames = tbl(:,subs).Properties.VariableNames;
                    all_varnames = tbl.Properties.VariableNames;
                    subs = find(ismember(all_varnames,subs_varnames));
                end
                inds=subscriptToIndex@matlab.graphics.data.AbstractDataSource(obj, subs, args{:});
            else
                inds=subscriptToIndex@matlab.graphics.data.AbstractDataSource(obj);
            end
        end
    end
end
