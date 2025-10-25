%mlreportgen.dom.Link Base class for ExternalLink and InternalLink classes.
%
%    Link properties:
%        Target            - Target of this hyperlink
%        TargetSite        - Location to open a target
%        StyleName         - Name of element's stylesheet-defined style
%        Style             - Formats that define this element's style
%        Parent            - Parent of this element
%        Children          - Children of this element
%        CustomAttributes  - Custom element attributes
%        Tag               - Tag of this element
%        Id                - Id of this element
%
%    See also mlreportgen.dom.ExternalLink, mlreportgen.dom.InternalLink

%    Copyright 2022 The MathWorks, Inc.
%    Built-in class

%{
properties

     %Target Name of this hyperlink target (read-only)
     Target;

     %TargetSite Location to open a target
     %      The value of this property is a string scalar or a character
     %      vector that specifies where to open a target.
     %
     %      Valid values:
     %
     %      samewindow - (default) opens a target in the same window
     %      newwindow -  opens a target in a new window
     %
     % Note: This property applies only to HTML output-type reports.
     TargetSite;

end
%}