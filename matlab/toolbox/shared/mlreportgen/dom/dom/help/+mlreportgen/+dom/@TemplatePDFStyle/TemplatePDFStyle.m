%mlreportgen.dom.TemplatePDFStyle Style parsed from a PDF template
%    This class represents a PDF style defined by a PDF template (.pdftx)
%    file. Opening a PDF template creates an array containing an instance
%    of this class for each style defined by the template file. You can
%    access the styles via the TemplateStyles property of the template's
%    Stylesheet property. Use this class to view and modify the CSS
%    selector and formats for a PDF style. You can remove or replace PDF
%    styles using the removeStyle and replaceStyle methods of the
%    template's stylesheet.
%
%    style = TemplatePDFStyle(selector,rawFormats) creates a PDF style and
%    sets the Selector and RawFormats properties to the specified values.
%    Use this constructor to define PDF styles that use more complex CSS
%    selectors or formats that do not have equivalent DOM classes. For
%    example, to create a style that applies to all unordered lists inside
%    a table with stylename "myTableStyle", use the selector
%    "table.myTableStyle ul"
%
%    TemplatePDFStyle properties:
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
%    % Create a Template using the default PDF template
%    t = Template("myTemplate","pdf");
% 
%    % Open the template and get the stylesheet
%    open(t);
%    stylesheet = t.Stylesheet;
% 
%    % Modify the table of contents styles so that they use the Courier New font
% 
%    % Get the styles with stylename "toc" and replace "list-style-type:
%    % none" and "list-style: none" with "list-style-type: upper-roman"
%    tocStyles = getStyle(stylesheet,"toc");
%    % This pattern matches rules that start with "font-family" and end with
%    % a semicolon.
%    pat = "font-family:" + wildcardPattern("Except", ";") + ";";
%    for style = stylesheet.TemplateStyles
%        if startsWith(style.Name, "TOC")
%            style.RawFormats = replace(style.RawFormats, pat, "font-family:""Courier New"";");
%        end
%    end
% 
%    % Create a new style that sets links in title paragraphs to be bold
%    newPDFStyle = TemplatePDFStyle("p.Title a", "font-weight:bold;");
%    addStyle(stylesheet,newPDFStyle);
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
    %     includes the class name and element name. For example, a style
    %     that formats link elements "exampleLink" would set the Selector
    %     property to "a.exampleLink". PDF stylesheets support only a
    %     limited set of selectors. An error is thrown if the selector is
    %     not supported.
    Selector;

    %RawFormats CSS formats that define this style
    %     String containing the CSS properties and values that define this
    %     style. Each CSS property and value pair is separated by a
    %     semicolon. For example, the Selector property for a PDF style
    %     that formats color and font weight would be:
    %
    %       "color:blue; font-weight:bold;"
    RawFormats;

    %Formats
    %     The Formats property is not used by the TemplatePDFStylesheet
    %     class and does not indicate which formats define the PDF style.
    %     Any formats added to this property programmatically are ignored
    %     when generating the template. Use the RawFormats property of a
    %     TemplatePDFStyle to view and modify the CSS formats that define
    %     the style.
    Formats;

end
%}