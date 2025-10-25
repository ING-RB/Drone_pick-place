classdef BookmarkTable < handle
    %This function is for internal use only. It may be removed in the future.

    %BookmarkTable stores the bookmark data in database(table)

    %   Copyright 2023 The MathWorks, Inc.
    properties
        BookmarkTableList
        % Bydefault Timestamp data is set to view
        IsElapseTimeFormat(1,1) logical = true
    end

    methods
        function obj = BookmarkTable(obj) %#ok<CTOINW>
            %BOOKMARKTABLE Construct an instance of this class

            % This creates a empty table

            % uncomment line 22 when new slider is used
            %obj.BookmarkTableList = table(Label, Starttime, Duration, Showontimeline, Delete);
            obj.BookmarkTableList = table();
        end

        function appendToBookmarkTable(obj, starttime, duration, label)
            %appendToBookmarkTable appends a new item to the table

            %obj.BookmarkTableList(end+1,:) = {label,starttime, duration, false, ''};
            % uncomment line 27 when new slider is used
            obj.BookmarkTableList(end+1,:) = {label,starttime, duration, ''};
            if any(strcmp(obj.BookmarkTableList.Properties.VariableNames, {'Var1', 'Var2', 'Var3','Var4'}))
                obj.BookmarkTableList.Properties.VariableNames = ["Label","Starttime","Duration","Delete"];

            end

        end

        function removeFromBookmarkTable(obj, index)
            %removeFromBookmarkTable remove a row from the table

            obj.BookmarkTableList(index,:) = [];
        end

        function updateBookmarkTable(obj, row, col, val)
            %updateBookmarkTable update the cell in the table
            if strcmp(obj.BookmarkTableList(row,col).Properties.VariableNames, {'Label'})
                obj.BookmarkTableList(row,col).Variables = {val};
            else
                obj.BookmarkTableList(row,col).Variables = val;
            end
        end

        function resetTable(obj)
            Label = {''};
            Starttime = 0;
            Duration = 0;
            Delete = {''};
            obj.BookmarkTableList = table(Label, Starttime, Duration, Delete);
        end
    end
end

