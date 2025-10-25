%replaceStyle Replace an existing style in this stylesheet
%    replacedStyles = replaceStyle(this,style) adds a style to this
%    stylesheet and removes redefinitions of the added style. For DOCX
%    templates, if a style of the same name exists, it is replaced by the
%    new style regardless of type. For HTML and PDF, if a style with the
%    same type and name exists, it is replaced by the new style. This
%    method is particularly useful for redefining TemplateDOCXStyle objects
%    created from the styles in an input DOCX template, but it also
%    replaces styles added to the stylesheet programmatically. The added
%    style must be an instance of one of the following style classes that
%    work with all template output types:
%
%       - mlreportgen.dom.TemplateLinkedStyle
%       - mlreportgen.dom.TemplateOrderedListStyle
%       - mlreportgen.dom.TemplateParagraphStyle
%       - mlreportgen.dom.TemplateTableStyle
%       - mlreportgen.dom.TemplateTextStyle
%       - mlreportgen.dom.TemplateUnorderedListStyle
%       - mlreportgen.dom.TemplateHTMLStyle (HTML only)
%       - mlreportgen.dom.TemplatePDFStyle (PDF only)
%
%    Note: You cannot create and add a new TemplateDOCXStyle to a
%    stylesheet. Use the text, paragraph, linked, table, and list style
%    classes to define new styles in a DOCX template.
% 
%    This method returns the replaced style objects, if any were
%    replaced.
%
%    Example:
%
%    import mlreportgen.dom.*
%    % Create a Template using the default DOCX template
%    t = Template("myTemplate","docx");
%
%    % Open the template and get the stylesheet
%    open(t);
%    stylesheet = t.Stylesheet;
%
%    % Create a new table style named "rgMATLABTABLE". Set it to be similar to the
%    % source template's "rgMATLABTABLE" style but have a blue border
%    newTableStyle = TemplateTableStyle("rgMATLABTABLE");
%
%    % Define formats similar to source template's style
%    % Set font size, color, and line spacing
%    oldFormats = [LineSpacing(1), FontFamily("Calibri"), WidowOrphanControl()];
%    % Leave a 10pt space after the table
%    om = OuterMargin();
%    om.Bottom = "15pt";
%    oldFormats(end+1) = om;
%
%    % Define format that gives the table a solid border
%    newFormat = Border("solid", "blue");
%
%    % Set the formats of the new style
%    newTableStyle.Formats = [oldFormats, newFormat];
%    % Replace the old style with the new style
%    replaceStyle(stylesheet,newTableStyle);
%
%    % Close the template
%    close(t);

%    Copyright 2023 MathWorks, Inc.
%    Built-in function.
