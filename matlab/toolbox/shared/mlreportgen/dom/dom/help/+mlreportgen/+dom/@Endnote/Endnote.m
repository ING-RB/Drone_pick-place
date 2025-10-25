%mlreportgen.dom.Endnote Create an endnote.
%     endnoteObj = Endnote() creates an empty endnote.
%
%     endnoteObj = Endnote(string) creates an endnote that contains the
%     specified string.
%
%     endnoteObj = Endnote(number) creates an endnote that contains the
%     specified floating-point or integer number.
%
%     endnoteObj = Endnote(domObj) creates an endnote that contains the
%     specified object where the object can be any of the following
%     mlreportgen.dom types:
%
%        * Paragraph
%        * Text
%        * Number
%        * OrderedList
%        * UnorderedList
%        * Image
%        * FormalImage
%        * ExternalLink
%        * InternalLink
%        * LinkTarget
%        * Table
%        * FormalTable
%        * MATLABTable
%
%     endnoteObj = Endnote(string,customMark) creates an endnote that 
%     contains the specified string and custom mark.
%
%     endnoteObj = Endnote(number,customMark) creates an endnote that 
%     contains the specified floating-point or integer number and custom mark.
%
%     endnoteObj = Endnote(domObj,customMark) creates an endnote that contains 
%     the specified object and custom mark. 
%
%    Endnote methods:
%        append         - Append content to this endnote
%        clone          - Clone this endnote
%
%    Endnote properties:
%        CustomMark        - Custom mark of this endnote
%        Style             - Formats that define this endnote mark's style
%        StyleName         - Name of endnote mark's stylesheet-defined style
%        Children          - Children of this endnote. Contains content of
%                            the endnote. DOM objects appended to the endnote 
%                            using append method are added here.
%        Parent            - Parent of this endnote. Endnote can only be 
%                            appended to a Paragraph.
%        Id                - Id of this endnote                            
%        Tag               - Tag of this endnote
%
%    Note: Endnote is only applicable to DOCX and PDF report types.
%
%    Example:
%
%        % Import the DOM API package
%        import mlreportgen.dom.*;
%         
%        % Create a document
%        d = Document("report","docx");
%         
%        % Open the document
%        open(d);
%         
%        para = Paragraph("When work began on the Parthenon");
%        % Create endnote and append it to the paragraph
%        endnote = Endnote("The temple of Athena Parthenos, completed in 438 B.C., regarded as finest Doric temple");
%        append(para,endnote);
%        append(para,", the Athenian empire was at the height of its power.");
%        append(d,para);
%         
%        para = Paragraph("Second paragraph begins here");
%        % Create endnote with custom mark and append it to the paragraph
%        endnote = Endnote("Second endnote text","A");
%        append(para,endnote);
%        append(para,", some more text.");
%        append(d,para);
%       
%        % Add a page break to the document
%        append(d,PageBreak);
%
%        % Close and view the report
%        close(d);
%        rptview(d);
%
%    See also mlreportgen.dom.Footnote

%    Copyright 2023 MathWorks, Inc.
%    Built-in class