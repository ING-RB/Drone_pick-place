%mlreportgen.dom.TemplateDocumentPart Create a template for a document part.
%    This class defines a document part template object that can be added
%    to an mlreportgen.dom.Template object's TemplateDocumentPart property.
%    When the Template object is closed, these document part templates are
%    written to the output template package (HTML, HTML-MULTIPAGE, PDF,
%    DOCX) or template document (HTML-FILE) as document parts. You can then
%    create DocumentPart objects based on the document part templates in
%    the generated template.
%
%    part = TemplateDocumentPart(name) creates a document part template
%    with the Name property set to name.
%
%
%    TemplateDocumentPart methods:
%        clone  - Creates a copy of this document part template
%        append - Append a DOM object to this document part template
%
%    TemplateDocumentPart properties:
%        Name      - Name of this document part template
%        Id        - Id of this group object
%        Children  - Children of this group
%        HTMLTag   - HTML tag name of this document part template (ignored)
%        Parent    - Parent of this group
%        StyleName - Style name of this document part template
%        Style     - Formats to be applied to this document part template
%        Tag       - Tag of this group object
%
%    Example:
%
%   import mlreportgen.dom.*
% 
%   % Create a DOCX template
%   t = Template("bookReportTemplate","docx");
%   open(t);
% 
%   % Create a document part template
%   dpt = TemplateDocumentPart("bookRatingPart");
% 
%   % Create a hole for a book title
%   title = Heading1();
%   append(title,TemplateHole("Title","Title of the book"));
%   append(dpt,title);
% 
%   % Create a hole for a book author
%   author = Heading2();
%   append(author,TemplateHole("Author","Author of the book"));
%   append(dpt,author);
% 
%   % Create a hole for a book rating
%   rating = Paragraph("I rate this book: ");
%   rating.WhiteSpace = "preserve";
%   append(rating,TemplateHole("Rating", "Rating of the book"));
%   append(rating," out of 5 stars.");
%   append(dpt,rating);
% 
%   % Add the document part to the template
%   t.TemplateDocumentParts(end+1) = dpt;
% 
%   close(t);

%    Copyright 2022-2023 The MathWorks, Inc.
%    Built-in class

%{
properties
     %Name Name of this document part template
     %      Name of this document part template. The name is used to 
     %      identify and access the document part in the generated
     %      template.
     Name;
end
%}