%mlreportgen.dom.PageRef Create a reference to a page in the generated document.
%    pageRef = PageRef(targetName) generates a page reference element in a
%    Word or PDF document file. The element references the link target
%    element specified by targetName in the same output file. If the output
%    file is a Word (docx) file, opening the file in Word causes Word to
%    replace the page reference by the number of the page containing the
%    link target. If the output file is an XSL-FO file, the DOM API's FO
%    processor (fop) replaces the page reference with the link target page
%    number in the output PDF. Use this object and XRef objects to create
%    cross references in printed documents.
%    
%    Example:
%
%    See "Introduction" on page 2 for more information.
%
%    PageRef methods:
%        clone             - Clone this page reference object
%
%    PageRef properties:
%        Target            - Name of the target of the reference
%        StyleName         - Name of this page reference object's stylesheet-defined style
%        Style             - Formats that define this page reference object's style
%        Parent            - Parent of this page reference object
%        Children          - Children of this page reference object
%        CustomAttributes  - Custom element attributes
%        Tag               - Tag of this page reference object
%        Id                - Id of this page reference object
%
%    Example:
%
%    % Import the DOM API package
%    import mlreportgen.dom.*;
%
%    % Create and open a document
%    d = Document("output","pdf");
%    open(d);
%
%    % Create a heading
%    heading = Heading1("Chapter 1. Introduction");
%
%    % Append heading to the document
%    append(d,heading);
%
%    % Convert the input link target ID to an ID that is valid for
%    % Microsoft® Word, and PDF reports
%    linkID = mlreportgen.utils.normalizeLinkID("Info");
%
%    % Create a paragraph and append text to it
%    p = Paragraph("For more information, see ");
%    p.WhiteSpace = "preserve";
%
%    % Create an XRef object that refers to the specified link target ID
%    % and append it to the paragraph
%    xref = XRef(linkID);
%    xref.Style = {Italic};
%    append(p,xref);
%
%    % Append text to the paragraph.
%    append(p," on page ");
%
%    % Create a PageRef object that refers to the specified link target ID
%    % object and append it to the paragraph
%    append(p,PageRef(linkID));
%
%    % Append paragraph to the document
%    append(d,p);
%
%    % Create and insert a PageBreak to the document
%    append(d,PageBreak());
%
%    % Create a LinkTarget object with the specified link target ID
%    lt = LinkTarget(linkID);
%    % Set the IsXRefTarget property to true so that this link target
%    % object is referenced by the XRef object
%    lt.IsXRefTarget = true;
%    % Append content to the link target object
%    append(lt,"Information");
%
%    % Create a heading
%    heading = Heading1("Chapter 2. ");
%    heading.WhiteSpace = "preserve";
%    % Append link target object to heading
%    append(heading,lt);
%
%    % Append heading to the document
%    append(d,heading);
%
%    % Close and view the output report
%    close(d);
%    rptview(d);
%
%    See also mlreportgen.dom.XRef, mlreportgen.dom.LinkTarget, 
%    mlreportgen.utils.normalizeLinkID

%    Copyright 2015-2021 MathWorks, Inc.
%    Built-in class