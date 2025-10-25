%addStyle Add a style to this stylesheet
%    style = addStyle(this,style) adds a style to this stylesheet. The
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
%    This method adds the style to the corresponding stylesheet styles
%    property. For styles that work with all output types, if a style with
%    the same type and name already exists, an error is thrown.
% 
%    Style names in a DOCX template must be unique across all styles. For
%    DOCX templates, if a style of the same name but different type exists,
%    an error is thrown.
%
%   See also mlreportgen.dom.TemplateDOCXStyle,
%   mlreportgen.dom.TemplateHTMLStyle, mlreportgen.dom.TemplatePDFStyle

%    Copyright 2023 MathWorks, Inc.
%    Built-in function.
