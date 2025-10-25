%mlreportgen.dom.BaseRef Base class for PageRef and XRef classes.
%
%    BaseRef properties:
%        Target            - Name of the reference target
%        StyleName         - Name of element's stylesheet-defined style
%        Style             - Formats that define this element's style
%        Parent            - Parent of this element
%        Children          - Children of this element
%        CustomAttributes  - Custom element attributes
%        Tag               - Tag of this element
%        Id                - Id of this element
%
%
%    See also mlreportgen.dom.XRef, mlreportgen.dom.PageRef,
%    mlreportgen.dom.LinkTarget, mlreportgen.utils.normalizeLinkID

%    Copyright 2021 The MathWorks, Inc.
%    Built-in class

%{
properties

     %Target Name of this reference target.
     %
     %    The value of this property is a string scalar or character
     %    vector.
     %
     %    Note: To generate a link target name that is valid for docx and
     %    pdf reports, use mlreportgen.utils.normalizeLinkID. The generated
     %    name conforms to the Microsoft® Word limitation on ID length and
     %    the PDF requirement that an ID begin with an alphabetic
     %    character. Word replaces spaces in link target names with
     %    underscore characters. Avoid spaces in link target names in Word
     %    and PDF reports.
     Target;
 
end
%}