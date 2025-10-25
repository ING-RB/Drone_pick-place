%mlreportgen.dom.FootnoteOptions Specify footnote options
%
%    FootnoteOptions properties:
%
%        NumberingType        - Numbering type of footnote marks
%        NumberingStartValue  - Start value of footnote mark numbering
%        NumberingRestart     - Specifies where footnote numbering should restart
%        Location             - Specifies the location of footnotes
%        Id                   - Id of this footnote option
%        Tag                  - Tag of this footnote option
%
%    Usage: The DOM API uses instances of this class as the default values of 
%    the FootnoteOptions properties of document and page layout objects. 
%    Set the properties of those FootnoteOptions objects to specify the 
%    footnote options of documents and document page layout sections. 
%    You do not need to create instances of this class yourself.
% 
%    Note: FootnoteOptions apply only to DOCX and PDF documents.
%
%    Example:
%
%        %Import the DOM API package
%        import mlreportgen.dom.*;
%         
%        % Create a document
%        d = Document("report","docx");
%         
%        % Open the document
%        open(d);
%
%        % Set document-wide footnote options
%        d.FootnoteOptions.NumberingType = "lowerRoman";
%        d.FootnoteOptions.NumberingStartValue = 2;
%         
%        para = Paragraph("When work began on the Parthenon");
%        % Create footnote and append it to the paragraph
%        footnote = Footnote("The temple of Athena Parthenos, completed in 438 B.C., regarded as finest Doric temple");
%        append(para,footnote);
%        append(para,", the Athenian empire was at the height of its power.");
%        append(d,para);
%         
%        para = Paragraph("Second paragraph begins here");
%        % Create a second footnote and append it to the paragraph
%        footnote = Footnote("Second footnote text");
%        append(para,footnote);
%        append(para,", some more text.");
%        append(d,para);
%         
%        % Close and view the report
%        close(d);
%        rptview(d);
%
%    See also mlreportgen.dom.Document.FootnoteOptions, mlreportgen.dom.DOCXPageLayout.FootnoteOptions, 
%    mlreportgen.dom.PDFPageLayout.FootnoteOptions

%    Copyright 2023 MathWorks, Inc.
%    Built-in class