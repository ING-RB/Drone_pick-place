%mlreportgen.dom.Collapsible Collapsible table row
%     collapsibleObj = Collapsible() creates an empty format object that
%     can be used to make a table row collapsible. Use its Value property
%     to specify the number of rows to collapse. When this format is
%     applied to a DOM TableRow, that row can be clicked to collapse (hide)
%     or expand (show) the following specified number of rows. If any of
%     the rows being collapsed is also collapsible, that row will also be
%     recursively collapsed.
%
%     collapsibleObj = Collapsible(value) creates a format object to make
%     a table row collapsible, clicking on which will collapse the
%     following specified number of rows.
%
%    Collapsible properties:
%        Value      - Number of rows to collapse
%        Tag        - Tag of this object
%        Id         - Id of this object
%
%    Note: This format applies only to the DOM TableRow objects in the HTML
%    output type reports.
%
%    Example:
%
%        % Import the DOM API package
%        import mlreportgen.dom.*
%
%        % Create an HTML document
%        d = Document("myreport","html");
%        open(d);
%
%        % Specify table data
%        collapsibleTableData = { ...
%            "Parent Row: Click to expand next 2 rows"; ...
%            "  Collapsible Content for Parent Row"; ...
%            "  More Collapsible Content for Parent Row"; ...
%            "Static Row" ...
%            };
%
%        % Create the table
%        tbl = Table(collapsibleTableData);
%        tbl.Border = "solid";
%        tbl.RowSep = "solid";
%        tbl.ColSep = "solid";
%        tbl.Style = [tbl.Style {WhiteSpace("preserve")}];
%
%        % Make the first row of the table to be collapsible, such that
%        % clicking on it will collapse the next 2 rows.
%        row1 = tbl.row(1);
%        row1.Style = [row1.Style {Collapsible(2)}];
%
%        % Append table to the document
%        append(d,tbl);
%
%        % Close and view the report
%        close(d);
%        rptview(d);
%
%    See also mlreportgen.dom.TableRow

%    Copyright 2024 The MathWorks, Inc.
%    Built-in class

%{
properties

     %Value Number of rows to collapse
     %    Number of rows to collapse, specified as an integer value. The
     %    default value is 1, which denotes that clicking on the row to
     %    which this format is applied, will collapse the following one
     %    row. Use this property to customize the number of rows to
     %    collapse.
     Value;

end
%}