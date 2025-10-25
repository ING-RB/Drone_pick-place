%mlreportgen.dom.Footnote Create a footnote.
%     footnoteObj = Footnote() creates an empty footnote.
%
%     footnoteObj = Footnote(string) creates a footnote that contains the
%     specified string.
%
%     footnoteObj = Footnote(number) creates a footnote that contains the
%     specified floating-point or integer number.
%
%     footnoteObj = Footnote(domObj) creates a footnote that contains the
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
%     footnoteObj = Footnote(string,customMark) creates a footnote that 
%     contains the specified string and custom mark.
%
%     footnoteObj = Footnote(number,customMark) creates a footnote that 
%     contains the specified floating-point or integer number and custom mark.
%
%     footnoteObj = Footnote(domObj,customMark) creates a footnote that contains 
%     the specified object and custom mark.
%
%    Footnote methods:
%        append         - Append content to this footnote
%        clone          - Clone this footnote
%
%    Footnote properties:
%        CustomMark        - Custom mark of this footnote
%        Style             - Formats that define this footnote mark's style
%        StyleName         - Name of footnote mark's stylesheet-defined style
%        Children          - Children of this footnote. Contains content of
%                            the footnote. DOM objects appended to the footnote 
%                            using append method are added here.
%        Parent            - Parent of this footnote. Footnote can only be
%                            appended to a Paragraph.
%        Id                - Id of this footnote
%        Tag               - Tag of this footnote
%
%    Note: Footnote is only applicable to DOCX and PDF report types.
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
%        % Create footnote and append it to the paragraph
%        footnote = Footnote("The temple of Athena Parthenos, completed in 438 B.C., regarded as finest Doric temple");
%        append(para,footnote);
%        append(para,", the Athenian empire was at the height of its power.");
%        append(d,para);
%         
%        para = Paragraph("Second paragraph begins here");
%        % Create footnote with custom mark and append it to the paragraph
%        footnote = Footnote("Second footnote text","A");
%        append(para,footnote);
%        append(para,", some more text.");
%        append(d,para);
%         
%        % Close and view the report
%        close(d);
%        rptview(d);
%
%    See also mlreportgen.dom.Endnote

%    Copyright 2023 MathWorks, Inc.
%    Built-in class