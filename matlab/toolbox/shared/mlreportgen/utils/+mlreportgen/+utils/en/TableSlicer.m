classdef TableSlicer< handle
%mlreportgen.utils.TableSlicer Creates sliced DOM/Formal tables.
%    slicer = TableSlicer() creates an empty table slicer object. You
%    can use its properties to specify an input table and maximum number
%    of columns that can be present per table slice.
%
%    slicer = TableSlicer('p1', v1, 'p2', v2, 'p3', v3)
%    creates a table slicer object and sets its properties (p1, p2, p3)
%    to the specified values (v1, v2, v3).
%
%    TableSlicer properties:
%      Table         - Input DOM/Formal table that needs to be sliced
%      MaxCols       - Maximum table columns to display per table slice
%      RepeatCols    - Number of initial columns to repeat per slice
%
%    TableSlicer methods:
%      Slice        - Slices the input table into multiple slices
%
%    Example
%
%    import mlreportgen.report.*
%    import mlreportgen.dom.*
%    import mlreportgen.utils.*
%    rpt = mlreportgen.report.Report("UseCase1", 'pdf');
%    open(rpt);
%    chapter = Chapter("Title", 'Magic(100)');
%    table = Table(magic(100));
%    table.Border = 'Solid';
%    table.RowSep = 'Solid';
%    table.ColSep = 'Solid';
%    slicer = TableSlicer("Table", table,"MaxCols",10);
%    slices = slicer.slice();
%    for slice=slices
%        str = sprintf('From column %d to column %d', slice.StartCol, slice.EndCol);
%        para = Paragraph(str);
%        para.Bold = true;
%        add(chapter, para);
%        add(chapter, slice.Table);
%    end
%    add(rpt, chapter);
%    close(rpt);
%    rptview(rpt);

     
    %   Copyright 2018 The MathWorks, Inc.

    methods
        function out=TableSlicer
        end

        function out=slice(~) %#ok<STOUT>
            %slices = slice(slicer) returns an array of
            %  mlreportgen.utils.TableSlice objects containing a table slice
            %  along with the start column and the end column values for each slice.
            %  The start and end column values refers to the column index of the original input
            %  table and those columns from the original table are sliced
            %
            %  See mlreportgen.utils.TableSlice
        end

    end
    properties
        %MaxCols  Maximum table columns to display per table slice
        %   Specifies the maximum number of table columns per table slice that
        %   this slicer uses to slice the input table. If the actual number
        %   of columns of the original data is greater than the value of
        %   this property, the data is sliced vertically (column wise) into
        %   multiple slices and generated as multiple tables. The default
        %   value of this property is Inf, which generates a single table
        %   regardless of the data array size. This may result in some tables
        %   being illegible, depending on the size of the data being displayed.
        %   To avoid creation of illegible tables, change the default setting
        %   of the property to a value small enough to fit legibly on a page.
        %   You may have to experiment to determine the optimum values of
        %   the maximum column size.
        MaxCols;

        %RepeatCols  Number of initial columns to repeat per slice
        %   Specifies the number of initial columns to repeat per table slice.
        %   For example, RepeatCols=2 repeats the first two columns of the
        %   original table in each slice. The default value of this property is 0,
        %   which specifies no repeating columns. The MaxCols value should include this value.
        %   For example, RepeatCols=2 and MaxCols=4 generates 4-column slices
        %   with the first two columns repeating the first two columns of the original table.
        RepeatCols;

        %Table  Input table that needs to be sliced.
        %   The input table object that needs to be sliced. Valid values are
        %       -  DOM Table
        %       -  Formal Table
        %   The input DOM table that needs to be sliced should have same number
        %   of columns in each row with rowspan,colspan value not greater than 1.
        %   Similarly, for the formal table input, the table body should have same number
        %   of columns for all the rows and if there are headers/footers,
        %   the number of columns in table header/footer should 
        %   match the number of columns in table body with rowspan,
        %   colspan value not greater than 1.
        Table;

    end
end
