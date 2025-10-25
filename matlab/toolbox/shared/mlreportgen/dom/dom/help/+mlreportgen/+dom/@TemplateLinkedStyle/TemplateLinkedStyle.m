%mlreportgen.dom.TemplateLinkedStyle Style that formats paragraph and text content
%    style = TemplateLinkedStyle() creates a linked style object with
%    default property values. You must set the object's Name property to
%    use this style.
%
%    style = TemplateLinkedStyle(name) creates a linked style and sets its
%    Name property to name. Add an instance of this object to a template
%    object's Stylesheet property to generate a corresponding style in a
%    template document file. Set the StyleName property of a Text or
%    Paragraph object to the name of this style to apply its formats to the
%    text or paragraph object. In the case of Text objects, the generated
%    Word, HTML, or PDF document ignores formats that apply only to
%    paragraph objects.
%
%    TemplateLinkedStyle properties:
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
%     % Create a linked style
%     linkedStyle = TemplateLinkedStyle("myLinkedStyle");
%     % Define formats for the linked style
%     linkedStyle.Formats = [Bold, Color("blue")];
%     % Add style to the stylesheet
%     addStyle(t.Stylesheet,linkedStyle);
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
%     para.StyleName = "myLinkedStyle";
%
%     % Create a text object
%     txt = Text("example text");
%     % Set the style name
%     txt.StyleName = "myLinkedStyle";
%
%     % Add the paragraph and text to the document
%     append(d,para);
%     append(d,txt);
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