%mlreportgen.dom.TemplateTableStyle Style that formats table content
%    style = TemplateTableStyle() creates a table style object with an empty
%    name. You must set the object's Name property to use the style.
%
%    style = TemplateTableStyle(name) creates a table style and sets its
%    Name property to name. Add an instance of this object to the
%    stylesheet specified by a template's Stylesheet property to use this
%    style to format tables based on the template. Set a table's StyleName
%    property to the name of this style to format the table as defined by
%    the style.
%
%    TemplateTableStyle properties:
%        Name                    - Name of this style
%        Formats                 - DOM formatting objects that define this style
%        TableEntriesFormats     - DOM formatting objects that apply to table entries
%        HeaderFormats           - DOM formatting objects that apply to table header
%        FooterFormats           - DOM formatting objects that apply to table footer
%        FirstColumnFormats      - DOM formatting objects that apply to the first column of a table
%        LastColumnFormats       - DOM formatting objects that apply to the last column of a table
%        OddRowFormats           - DOM formatting objects that apply to the odd rows of a table
%        EvenRowFormats          - DOM formatting objects that apply to the even rows of a table
%        OddColumnFormats        - DOM formatting objects that apply to the odd columns of a table
%        EvenColumnFormats       - DOM formatting objects that apply to the even columns of a table
%        TopLeftEntryFormats     - DOM formatting objects that apply to the top left entry of a table
%        TopRightEntryFormats    - DOM formatting objects that apply to the top right entry of a table
%        BottomLeftEntryFormats  - DOM formatting objects that apply to the bottom left entry of a table
%        BottomRightEntryFormats - DOM formatting objects that apply to the bottom right entry of a table
%        Id                      - Id of this style
%        Tag                     - Tag of this style
%
%    Example:
%
%     import mlreportgen.dom.*;
%     t = Template("myTemplate","html");
%     open(t);
%
%     % Create a table style
%     tableStyle = TemplateTableStyle("myTableStyle");
%     % Define formats for the table style
%     tableStyle.Formats = [Border("solid"), ColSep("solid"), RowSep("solid")];
%     tableStyle.OddRowFormats = [BackgroundColor("lightblue")];
%     % Add style to the stylesheet
%     addStyle(t.Stylesheet,tableStyle);
%
%     % Close the template
%     close(t);
%
%     % Use the style from the template
%
%     % Create a document using the generated template
%     d = Document("myDoc","html","myTemplate");
%     open(d);
%
%     % Create a table object
%     tbl = Table(randi(10,[4,4]));
%     % Set the style name
%     tbl.StyleName = "myTableStyle";
%
%     % Add the table to the document
%     append(d,tbl);
%
%     % Close and view the document
%     close(d);
%     rptview(d);
%
%     See also mlreportgen.dom.Template, mlreportgen.dom.TemplateStylesheet 

%    Copyright 2023 The MathWorks, Inc.
%    Built-in class

%{
properties

    %Name Name of this style
    %     Name of the style, specified as a string. The name may only 
    %     include alphanumerics, "-", or "_" characters.
    Name;

    %TableEntriesFormats DOM formatting objects that apply to table entries
    %     Array of DOM formatting objects that are applied to every table
    %     entry of tables that use this style.
    TableEntriesFormats;

    %HeaderFormats DOM formatting objects that apply to table header
    %     Array of DOM formatting objects that are applied to the header
    %     section of tables that use this style.
    HeaderFormats;

    %FooterFormats DOM formatting objects that apply to table footer
    %     Array of DOM formatting objects that are applied to the footer
    %     section of tables that use this style.
    FooterFormats;

    %FirstColumnFormats DOM formatting objects that apply to the first column of a table
    %     Array of DOM formatting objects that are applied to the first
    %     column of tables that use this style. This property is ignored for
    %     PDF template output.
    FirstColumnFormats;

    %LastColumnFormats DOM formatting objects that apply to the last column of a table
    %     Array of DOM formatting objects that are applied to the last
    %     column of tables that use this style. This property is ignored for
    %     PDF template output.
    LastColumnFormats;

    %OddRowFormats DOM formatting objects that apply to the odd rows of a table
    %     Array of DOM formatting objects that are applied to the odd rows
    %     of tables that use this style. This property is ignored for
    %     PDF template output.
    OddRowFormats;

    %EvenRowFormats DOM formatting objects that apply to the even rows of a table
    %     Array of DOM formatting objects that are applied to the even rows
    %     of tables that use this style. This property is ignored for
    %     PDF template output.
    EvenRowFormats;

    %OddColumnFormats DOM formatting objects that apply to the odd columns of a table
    %     Array of DOM formatting objects that are applied to the odd
    %     columns of tables that use this style. This property is ignored for
    %     PDF template output.
    OddColumnFormats;

    %EvenColumnFormats DOM formatting objects that apply to the even columns of a table
    %     Array of DOM formatting objects that are applied to the even
    %     columns of tables that use this style. This property is ignored for
    %     PDF template output.
    EvenColumnFormats;

    %TopLeftEntryFormats DOM formatting objects that apply to the top left entry of a table
    %     Array of DOM formatting objects that are applied to the top left
    %     entry of tables that use this style. This property is ignored for
    %     PDF template output.
    TopLeftEntryFormats;

    %TopRightEntryFormats DOM formatting objects that apply to the top right entry of a table
    %     Array of DOM formatting objects that are applied to the top right
    %     entry of tables that use this style.
    TopRightEntryFormats;

    %BottomLeftEntryFormats DOM formatting objects that apply to the bottom left entry of a table
    %     Array of DOM formatting objects that are applied to the bottom
    %     left entry of tables that use this style.
    BottomLeftEntryFormats;

    %BottomRightEntryFormats DOM formatting objects that apply to the bottom right entry of a table
    %     Array of DOM formatting objects that are applied to the bottom
    %     right entry of tables that use this style.
    BottomRightEntryFormats;

end
%}