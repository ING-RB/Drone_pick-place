%mlreportgen.dom.EndnoteOptions Specify endnote options
%
%    EndnoteOptions properties:
%        NumberingType        - Numbering type of endnote marks
%        NumberingStartValue  - Start value of endnote mark numbering
%        NumberingRestart     - Specifies where endnote numbering should restart
%        Location             - Specifies the location of endnotes
%        Id                   - Id of this endnote option
%        Tag                  - Tag of this endnote option
%
%    Usage: The DOM API uses instances of this class as the default values of 
%    the EndnoteOptions properties of document and page layout objects. 
%    Set the properties of those EndnoteOptions objects to specify the 
%    endnote options of documents and document page layout sections. 
%    You do not need to create instances of this class yourself.
%
%    Note: EndnoteOptions apply only to DOCX and PDF documents.
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
%        % Set document-wide endnote options
%        d.EndnoteOptions.NumberingType = "upperLetter";
%        d.EndnoteOptions.NumberingStartValue = 2;
%         
%        para = Paragraph("When work began on the Parthenon");
%        % Create endnote and append it to the paragraph
%        endnote = Endnote("The temple of Athena Parthenos, completed in 438 B.C., regarded as finest Doric temple");
%        append(para,endnote);
%        append(para,", the Athenian empire was at the height of its power.");
%        append(d,para);
%         
%        para = Paragraph("Second paragraph begins here");
%        % Create a second endnote and append it to the paragraph
%        endnote = Endnote("Second endnote text");
%        append(para,endnote);
%        append(para,", some more text.");
%        append(d,para);
%         
%        % Close and view the report
%        close(d);
%        rptview(d);
%
%    See also mlreportgen.dom.Document.EndnoteOptions, mlreportgen.dom.DOCXPageLayout.EndnoteOptions, 
%    mlreportgen.dom.PDFPageLayout.EndnoteOptions

%    Copyright 2023 MathWorks, Inc.
%    Built-in class