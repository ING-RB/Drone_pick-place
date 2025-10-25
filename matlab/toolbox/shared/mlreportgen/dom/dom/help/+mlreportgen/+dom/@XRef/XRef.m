%mlreportgen.dom.XRef Creates a cross-reference in a DOCX or PDF report.
%    xref = XRef(target) creates a cross-reference element in a Word or PDF
%    document output file (docx for Word output, fo for PDF output).
%    The element references a link target element in the same file where
%    the link target is specified by the targetName argument. Opening a
%    docx file containing an xref element causes Word to replace the xref
%    element with the text of the specified link target element. The DOM
%    API's FO processor similarly replaces the xref element with the target
%    text. Use XRef objects with PageRef objects to create cross-references
%    in printed reports.
%
%    xref = XRef() creates an empty cross-reference object. Use its
%    property to specify a target name.
%
%    XRef methods:
%        clone             - Clone this cross-reference object
%
%    XRef properties:
%        Target            - Name of the target of the reference
%        StyleName         - Name of this cross-reference object's stylesheet-defined style
%        Style             - Formats that define this cross-reference object's style
%        Parent            - Parent of this cross-reference object
%        Children          - Children of this cross reference object
%        CustomAttributes  - Custom element attributes
%        Tag               - Tag of this cross-reference object
%        Id                - Id of this cross-reference object
%
%    Example:
%
%    % Import the Report API and DOM API packages
%    import mlreportgen.dom.*;
%    import mlreportgen.report.*;
%
%    % Create and open a report
%    rpt = Report("output","pdf");
%    open(rpt);
%
%    % Create a chapter with the title "Introduction"
%    chapter1 = Chapter(Title="Introduction");
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
%    xrefObj = XRef(linkID);
%    xrefObj.Style = [xrefObj.Style,{Italic(true)}];
%    append(p,xrefObj);
%
%    % Append text to the paragraph
%    append(p," on page ");
%
%    % Create a PageRef object that refers to the specified link target ID
%    % object and append it to the paragraph
%    append(p,PageRef(linkID));
%
%    % Append paragraph to the chapter and chapter to the report
%    append(chapter1,p);
%    append(rpt,chapter1);
%
%    % Create a LinkTarget object with the specified link target ID
%    lt = LinkTarget(linkID);
%
%    % Set the IsXRefTarget property to true so that this link target
%    % object is referenced by the XRef object
%    lt.IsXRefTarget = true;
%
%    % Append content to the link target object
%    append(lt,"Information");
%
%    % Create a chapter and set LinkTarget object as chapter title
%    chapter2 = Chapter(Title=lt);
%
%    % Append chapter to the report
%    append(rpt,chapter2);
%
%    % Close and view the output report
%    close(rpt);
%    rptview(rpt);
%
%    See also mlreportgen.dom.PageRef, mlreportgen.dom.LinkTarget,
%    mlreportgen.utils.normalizeLinkID

%    Copyright 2021 The MathWorks, Inc.
%    Built-in class