%mlreportgen.dom.TemplateParagraphStyle Style that formats paragraph content
%    style = TemplateParagraphStyle() creates a paragraph style object with
%    default property values. You must set the object's Name property to
%    use this style.
%
%    style = TemplateParagraphStyle(name) creates a paragraph style and
%    sets its Name property to name. Add an instance of this object to the
%    stylesheet specified by a template's Stylesheet property to use this
%    style to format paragraphs based on the template. Set a paragraph's
%    StyleName property to the name of this style to format the paragraph
%    as defined by the style.
%
%    TemplateParagraphStyle properties:
%        Name                   - Name of this style
%        Formats                - DOM formatting objects that define this style
%        Id                     - Id of this style
%        Tag                    - Tag of this style
%
%    Example:
%
%     import mlreportgen.dom.*;
%     t = Template("myTemplate","pdf");
%     open(t);
%
%     % Create a paragraph style
%     paragraphStyle = TemplateParagraphStyle("myParagraphStyle");
%     % Define formats for the paragraph style
%     paragraphStyle.Formats = [Bold, Color("blue")];
%     % Add style to the stylesheet
%     addStyle(t.Stylesheet,paragraphStyle);
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
%     % Create a paragraph object
%     para = Paragraph("example paragraph");
%     % Set the style name
%     para.StyleName = "myParagraphStyle";
%
%     % Add the paragraph to the document
%     append(d,para);
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

end
%}