%mlreportgen.dom.LinkTarget Create a target for a hyperlink.
%    targetObj = LinkTarget(targetName) creates a link target object.
%
%    LinkTarget methods:
%        append         - Append content to this target
%        clone          - Clone this target
%
%    LinkTarget properties:
%        Name              - Name of this target
%        IsXRefTarget      - Whether this target is targeted by an XRef object
%        StyleName         - Name of this target's stylesheet-defined style
%        Style             - Formats that define this target's style
%        CustomAttributes  - Custom element attributes
%        Parent            - Parent of this target
%        Children          - Children of this target
%        Tag               - Tag of this target
%        Id                - Id of this target
%
%    See also mlreportgen.dom.PageRef, mlreportgen.dom.InternalLink,
%    mlreportgen.utils.normalizeLinkID, mlreportgen.dom.ExternalLink,
%    mlreportgen.dom.XRef

%    Copyright 2014-2021 MathWorks, Inc.
%    Built-in class

%{
properties

     %Name Name of this hyperlink target.
     %
     %    Note: Word replaces spaces in link targets with underscore 
     %    characters. Hence, you should avoid spaces in link targets
     %    if your report targets Word or both HTML and Word.
     %
     %    Note: Word does not allow link target names greater than 40
     %    characters. PDF documents require link target names to begin
     %    with an alphabetic character. You can use
     %    mlreportgen.utils.normalizeLinkID(Name) to ensure that the link 
     %    target conforms to both DOCX and PDF requirements.
     %
     Name;

     %IsXRefTarget Whether this target is targeted by an XRef object.
     %    This property specifies whether this link target object is
     %    targeted by an xref object. The default value is false. If this
     %    property is set to true, this link target object is referenced by
     %    an XRef object in the same report and the DOM API's FO processor
     %    replaces the xref object with the text of the specified link
     %    target element.
     %
     %    Note: This property applies only to PDF output reports.
     %    See also mlreportgen.dom.XRef
     IsXRefTarget;
 
end
%}