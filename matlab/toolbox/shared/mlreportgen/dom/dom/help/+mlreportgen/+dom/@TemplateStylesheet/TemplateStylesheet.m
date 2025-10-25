%mlreportgen.dom.TemplateStylesheet Stylesheet object for a template
%    This class contains the styles for an mlreportgen.dom.Template. An
%    instance of this class is created when an mlreportgen.dom.Template is
%    opened. The TemplateStyles property is automatically populated with
%    the styles already present in the source template document upon which
%    the mlreportgen.dom.Template object is based. Use the methods of this
%    class to add, remove, or replace styles. All styles in this
%    TemplateStylesheet are generated in the resulting template document
%    when the parent mlreportgen.dom.Template object is closed.
%
%    Note: Formatting for new styles is defined by DOM format classes such
%    as mlreportgen.dom.Bold and mlreportgen.dom.Color. The following DOM
%    format classes are not supported for use with DOM template style
%    classes and are ignored:
%       - ListStyleType
%       - NumberFormat
%       - OutlineLevel
%       - ScaleToFit
%
%    The following DOM format classes are not supported for use with DOM
%    template style classes for DOCX template output:
%       - CounterInc
%       - CounterReset
%       - FlowDirection (supported for TemplateParagraphStyle only)
%       - Height
%       - ResizeToFitContents
%       - RowHeight
%       - TextOrientation
%       - Width
%       - WhiteSpace
%
%    TemplateStylesheet methods:
%        getStyleNames  - List the names of all styles in this stylesheet
%        getStyle       - Find styles in this stylesheet by name
%        addStyle       - Add a style to this stylesheet
%        replaceStyle   - Replace an existing style in this stylesheet
%        removeStyle    - Remove styles in this stylesheet
%
%    TemplateStylesheet properties:
%        TextStyles         - Styles that format text elements
%        ParagraphStyles    - Styles that format paragraph elements
%        LinkedStyles       - Styles that format both text and paragraph elements
%        TableStyles        - Styles that format table elements
%        ListStyles         - Styles that format list elements
%        TemplateStyles     - Styles defined by template document
%        Id                 - Id of this object
%        Tag                - Tag of this object
%
%    Example:
%
%   import mlreportgen.dom.*
% 
%   % Create a DOCX template
%   t = Template("bookReportTemplate","docx");
%   open(t);
% 
%   % Create a text style
%   textStyle = TemplateTextStyle("exampleTextStyle");
%
%   % Format the text style
%   textStyle.Formats = [Bold(true), Color("red")];
% 
%   % Add the text style to the stylesheet
%   stylesheet = t.Stylesheet;
%   addStyle(stylesheet, textStyle);
% 
%   close(t);
%
%     See also mlreportgen.dom.Template, mlreportgen.dom.TemplateTextStyle,
%     mlreportgen.dom.TemplateParagraphStyle,
%     mlreportgen.dom.TemplateLinkedStyle,
%     mlreportgen.dom.TemplateTableStyle,
%     mlreportgen.dom.TemplateOrderedListStyle,
%     mlreportgen.dom.TemplateUnorderedListStyle

%    Copyright 2023 The MathWorks, Inc.
%    Built-in class

%{
properties

     %TextStyles Styles that format text elements
     %      Array of DOM TemplateTextStyle objects representing the text
     %      styles defined in this stylesheet. This property is read-only,
     %      but the styles contained in the property can be modified. To
     %      add or remove styles, use the addStyle, removeStyle, or
     %      replaceStyle methods of this Stylesheet.
     TextStyles;

     %ParagraphStyles Styles that format paragraph elements
     %      Array of DOM TemplateParagraphStyle objects representing the
     %      paragraph styles defined in this stylesheet. This property is
     %      read-only, but the styles contained in the property can be
     %      modified. To add or remove styles, use the addStyle,
     %      removeStyle, or replaceStyle methods of this Stylesheet.
     ParagraphStyles;

     %LinkedStyles Styles that format both text and paragraph elements
     %      Array of DOM TemplateLinkedStyle objects representing the
     %      linked styles, i.e., styles that can be applied to both text
     %      and paragraph elements, defined in this stylesheet. This
     %      property is read-only, but the styles contained in the property
     %      can be modified. To add or remove styles, use the addStyle,
     %      removeStyle, or replaceStyle methods of this Stylesheet.
     LinkedStyles;

     %TableStyles Styles that format table elements
     %      Array of DOM TemplateTableStyle objects representing  the table
     %      styles defined in this stylesheet. This property is read-only,
     %      but the styles contained in the property can be modified. To
     %      add or remove styles, use the addStyle, removeStyle, or
     %      replaceStyle methods of this Stylesheet.
     TableStyles;

     %ListStyles Styles that format list elements
     %      Array of DOM TemplateListStyle objects representing the list
     %      styles defined in this stylesheet.  This property is read-only,
     %      but the styles contained in the property can be modified. To
     %      add or remove styles, use the addStyle, removeStyle, or
     %      replaceStyle methods of this Stylesheet.
     ListStyles;

     %TemplateStyles Styles defined by template document
     %      Array of styles defined by the template document used to create
     %      this template object. The styles are represented by objects
     %      whose type depends on the template document type, i.e.,
     %          - TemplateDOCXStyle
     %          - TemplateHTMLStyle
     %          - TemplatePDFStyle
     %
     %      Closing a template causes these styles to be included in the
     %      generated template document. Use the removeStyle or
     %      replaceStyle method to remove or replace styles in this array.
     TemplateStyles;

end
%}