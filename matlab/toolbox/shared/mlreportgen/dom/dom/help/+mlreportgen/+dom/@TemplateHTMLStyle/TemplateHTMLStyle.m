%mlreportgen.dom.TemplateHTMLStyle Style parsed from an HTML template
%    This class represents an HTML style defined by an HTML template
%    (.htmtx or .htmt) file. Opening an HTML template creates an array
%    containing an instance of this class for each style defined by the
%    template file. You can access the styles via the TemplateStyles
%    property of the template's Stylesheet property. Use this class to view
%    and modify the CSS selector and formats for an HTML style. You can
%    remove or replace HTML styles using the removeStyle and replaceStyle
%    methods of the template's stylesheet.
%
%    style = TemplateHTMLStyle(selector,rawFormats) creates an HTML style
%    and sets the Selector and RawFormats properties to the specified
%    values. Use this constructor to define HTML styles that use more
%    complex CSS selectors or formats that do not have equivalent DOM
%    classes. For example, to create a style that applies to all unordered
%    lists inside a table with stylename "myTableStyle", use the selector
%    "table.myTableStyle ul".
%
%    TemplateHTMLStyle properties:
%        Name                   - Name of this style
%        Selector               - CSS selector used by this style
%        RawFormats             - CSS formats that define this style
%        Formats                - (Ignored)
%        Id                     - Id of this style
%        Tag                    - Tag of this style
%
%    Example:
%
%    import mlreportgen.dom.*
%    % Create a Template using the default HTML template
%    t = Template("myTemplate","html");
% 
%    % Open the template and get the stylesheet
%    open(t);
%    stylesheet = t.Stylesheet;
% 
%    % Modify the table of contents styles so that they use Roman numerals to
%    % list sections
% 
%    % Get the styles with stylename "toc" and replace "list-style-type:
%    % none" and "list-style: none" with "list-style-type: upper-roman"
%    tocStyles = getStyle(stylesheet,"toc");
%    % This pattern matches rules that start with "list-style" and end with
%    % "none;".
%    pat = "list-style" + wildcardPattern("Except", ";") + "none;";
%    for tocStyle = tocStyles
%        tocStyle.RawFormats = replace(tocStyle.RawFormats, pat, "list-style-type:upper-roman;");
%    end
% 
%    % Create a new style that sets the font used by the table of contents to
%    % Courier New
%    newHTMLStyle = TemplateHTMLStyle("ol.toc a", "font-family:""Courier New"";");
%    addStyle(stylesheet,newHTMLStyle);
% 
%    % Close the template
%    close(t);
%
%     See also mlreportgen.dom.Template, mlreportgen.dom.TemplateStylesheet 

%    Copyright 2023 The MathWorks, Inc.
%    Built-in class

%{
properties

    %Name Name of this style
    %     Name of the style, specified as a string. This property is
    %     read-only. The name is automatically parsed from the value of the
    %     Selector property.
    Name;

    %Selector CSS selector used by this style
    %     CSS selector for the style, specified as a string. This value
    %     includes the class name, element name, and other selector
    %     patterns such as "nth-child". For example, a table style
    %     "exampleTable" that formats even rows of the table would have a
    %     Selector property of "table.exampleTable tr:nth-child(even)".
    Selector;

    %RawFormats CSS formats that define this style
    %     String containing the CSS properties and values that define this
    %     style. Each CSS property and value pair is separated by a
    %     semicolon. For example, the Selector property for an HTML style
    %     that formats color and font weight would be:
    %
    %       "color:blue; font-weight:bold;"
    RawFormats;

    %Formats
    %     The Formats property is not used by the TemplateHTMLStylesheet
    %     class and does not indicate which formats define the HTML style.
    %     Any formats added to this property programmatically are ignored
    %     when generating the template. Use the RawFormats property of a
    %     TemplateHTMLStyle to view and modify the CSS formats that define
    %     the style.
    Formats;

end
%}