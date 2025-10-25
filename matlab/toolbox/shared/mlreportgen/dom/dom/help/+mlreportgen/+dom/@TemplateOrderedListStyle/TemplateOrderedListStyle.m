%mlreportgen.dom.TemplateOrderedListStyle Style that formats ordered lists
%    style = TemplateOrderedListStyle() creates a list style object with
%    default property values. You must set the object's Name property to
%    use this style.
%
%    style = TemplateOrderedListStyle(name) creates a list style and sets
%    its Name property to name. Add an instance of this object to the
%    stylesheet specified by a template's Stylesheet property to use this
%    style to format lists based on the template. Set an ordered lists's
%    StyleName property to the name of this style to format the list as
%    defined by the style.
%
%    TemplateOrderedListStyle properties:
%        Name                   - Name of this style
%        Formats                - DOM formatting objects that are applied to all list levels
%        LevelStyles            - DOM style objects that define formats for specific list levels
%        Id                     - Id of this style
%        Tag                    - Tag of this style
%
%    Example:
%
%     import mlreportgen.dom.*;
%     t = Template("myTemplate","pdf");
%     open(t);
%
%     % Create a list style
%     listStyle = TemplateOrderedListStyle("myOrderedListStyle");
%     % Define formats for the list style
%     listStyle.Formats = [Bold, Color("blue")];
%     % Add style to the stylesheet
%     addStyle(t.Stylesheet,listStyle);
%
%     % Close the template
%     close(t);
%
%     % Use the style from the template
%
%     % Create a document using the generated template
%     d = Document("myDoc","pdf","myTemplate");
%     open(d);
%
%     % Create a list object
%     list = OrderedList(["item 1", "item 2"]);
%     % Set the style name
%     list.StyleName = "myOrderedListStyle";
%
%     % Add the list to the document
%     append(d,list);
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

    %LevelStyles DOM style objects that define formats for specific list levels
    %     Array of nine mlreportgen.dom.TemplateOrderedListLevelStyle
    %     objects that specify formats for specific list levels. Word only
    %     supports nine levels of list formatting. To format more list
    %     levels in HTML and PDF templates, create custom TemplateHTMLStyle
    %     or TemplatePDFStyle objects that use CSS selectors for the
    %     desired levels.
    LevelStyles;

end
%}