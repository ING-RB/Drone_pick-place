classdef TabularWrapper < matlab.mixin.Scalar &...
        matlab.mixin.indexing.RedefinesDot
%TABULARWRAPPER A thin wrapper around a column vector cell array of tabular
%data.
%
% This object lets us avoid vertically concatenating many tables or many
% timetables together. This is particulary useful when tables in a cell
% array have RowNames. The RowNames values of a table must be unique. This
% means attempting to vertically combine tables in a cell array may result
% in an error if a row name is present in multiple tables.
%
%   Example 1:
%
%       >> import matlab.io.internal.arrow.list.TabularWrapper
%
%       >> t1 = table((65:67)', string(char((65:67)')), VariableNames=["Number", "Letter"]);
%       >> t2 = table((68:72)', string(char((68:72)')), VariableNames=["Number", "Letter"]);
%
%       >> C = {t1; t2};
%
%       >> wrapper = TabularWrapper(C);
%
%       % Returns a double vector equivalent to [t1.Number; t2.Number]
%       >> wrapper.(1)
%
%       % Returns a string vector equivalent to [t1.Letter; t2.Letter]
%       >> wrapper.(2)
%
%   Example 2:
%
%       >> import matlab.io.internal.arrow.list.TabularWrapper
%
%       >> t1 = table(1, "A", RowNames="Row1");
%       >> t2 = table(2, "B", RowNames="Row1");
%       >> C = {t1; t2};
%
%       % vertcat errors because there is a duplciate row name: Row1
%       >> vertcat(C{:})
%
%       >> wrapper = TabularWrapper(C);
%       >> getRowLabels(C)
%
%       ans =
%
%         2×1 string array
%
%           "Row1"
%           "Row1"
%
% Assumptions:
%
%       1. TabularData contains either only tables or only
%       timetables.
%
%       2. TabularData is not empty.
%
%       3. The tables or timetables within TabularData have
%       consistent "schema". This means they have the same number of
%       variables, the same variable names in the same order,
%       and their corresponding variables have the same class type.
%
%       Example: Suppose variable A in the first table is an int8. Variable
%                A in the other tables must be an int8 arrray.
%
%       Example: Suppose variable B in the first table is a datetime with a
%                timezone. Variable B in the other tables must be an
%                datetime with a timezone as well. Note: the timezones
%                don't have to be the same .
%
%       Example: Suppose the first table has row names associated with it.
%                The other tables must also have row names as well.
%
% NOTE: No validation is done to ensure these assumptions are correct.

% Copyright 2022 The MathWorks, Inc.

    properties(SetAccess = private)
        TabularData(:, 1) cell
    end

    methods
        function obj = TabularWrapper(tabularData)
            obj.TabularData = tabularData;
        end

        function tf = istabular(obj) %#ok<MANU>
        % Always returns true because TabularWrapper contains only
        % timetables or tables.
            tf = true;
        end

        function tf = istable(obj)
        % Only check the first element in TabularData because we
        % assume the cell array contains either all tables or all
        % timetables.
            tf = istable(obj.TabularData{1});
        end

        function tf = istimetable(obj)
        % Only check the first element in TabularData because we
        % assume the cell array contains either all tables or all
        % timetables.
            tf = istimetable(obj.TabularData{1});
        end

        function numvars = width(obj)
        % Return the width of the first table/timetable. We assume the
        % rest of the tables/timetables in TabularData have the
        % same width.
            numvars = width(obj.TabularData{1});
        end

        function tf = hasRowLabels(obj)
            tf = false;
            if istimetable(obj)
                % All timetables have RowLabels, i.e. RowTimes.
                tf = true;
            elseif ~isempty(obj.TabularData{1}.Properties.RowNames)
                % If the first table's RowNames propery is not empty, we
                % assume the rest of the tables also have non-empty vectors
                % for their RowNames property.
                tf = true;
            end
        end

        function name = getRowLabelName(obj)
            name = obj.TabularData{1}.Properties.DimensionNames{1};
        end

        function labels = getRowLabels(obj)
        % Returns RowNames if TabularWrapper contains tables. Otherwise
        % TabularWrapper contains timetables, so getRowLabels returns
        % RowTimes.
            if istimetable(obj)
                labels = getRowTimes(obj);
            else
                labels = getRowNames(obj);
            end
        end

        function varNames = getVariableNames(obj)
            varNames = obj.TabularData{1}.Properties.VariableNames;
        end
    end

    methods(Access=protected)
        function n = dotListLength(~,~,~)
            n = 1;
        end

        function obj = dotAssign(~,~,varargin) %#ok<STOUT>
            assert(false);
        end

        function varargout = dotReference(obj, indexOp)
            import matlab.io.internal.arrow.list.TabularWrapper

            assert(numel(indexOp) == 1);

            numTabular = numel(obj.TabularData);
            temp = cell([numTabular 1]);
            for ii = 1:numTabular
                % Forward the indexOp to each individual table/timetable
                % within the TabularData cell array. Store the result
                % as element in the the cell array named temp.
                temp{ii} = obj.TabularData{ii}.(indexOp);
            end

            if numel(temp) > 0 && istabular(temp{1})
                % If the variable is a nested table, return a
                % TabularWrapper to avoid vertically combining the
                % tables/timetables together. This simulates extracting a
                % nested table variable from a table/timetable.
                [varargout{1:nargout}] = TabularWrapper(temp);
            else
                % temp does not contain tabular data, so vertically combine
                % the elements together. This simulates extracting a
                % variable from a table/timetable.
                [varargout{1:nargout}] = vertcat(temp{:});
            end
        end
    end

    methods(Access = private)
        function rowNames = getRowNames(obj)
        % Only call getRowNames if TabularWrapper contains tables.
            numTabular = numel(obj.TabularData);
            temp = cell([numTabular 1]);
            for ii = 1:numTabular
                % Convert the RowNames to a string array. It's easier to
                % convert string arrays to Arrow StringArrays than it is to
                % convert cellstrs to Arrow StringArrays.
                temp{ii} = string(obj.TabularData{ii}.Properties.RowNames);
            end
            rowNames = vertcat(temp{:});
        end

        function rowTimes = getRowTimes(obj)
        % Only call getRowTimes if TabularWrapper contains timetables.
            numTabular = numel(obj.TabularData);
            temp = cell([numTabular 1]);
            for ii = 1:numTabular
                temp{ii} = obj.TabularData{ii}.Properties.RowTimes;
            end
            rowTimes = vertcat(temp{:});
        end
    end
end
