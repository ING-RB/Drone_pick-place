%mlreportgen.dom.ExternalLink Creates a hyperlink to an external target
%
%    linkObj = ExternalLink() creates a link with an empty target and
%    empty link text.
%
%    linkObj = ExternalLink('target','text') creates a link to the specified 
%    external target with link text that contains the specified text.
%
%    linkObj = ExternalLink('target',number) creates a link to the specified
%    external target with link text that contains the specified floating-point 
%    or integer number.
%
%    linkObj = ExternalLink('target','text','styleName') creates a link to  
%    the specified external target with the specified link text and style.
%
%    linkObj = ExternalLink('target',obj) creates a link to the specified external
%    target with the link text specified by obj, which can be an mlreportgen.dom.Text, 
%    mlreportgen.dom.Number, or mlreportgen.dom.CharEntity object.
%
%    ExternalLink methods:
%        append         - Append text, number, and images to this link
%        clone          - Clone this target
%
%    ExternalLink properties:
%        Target            - External target of this hyperlink
%        TargetSite        - Location to open a target
%        Children          - Children of this external link
%        CustomAttributes  - Custom element attributes
%        Id                - Id of this text
%        Parent            - Parent of this link
%        Tag               - Tag of this text
%
%    Example:
%
%    import mlreportgen.dom.*
%    d = Document("mydoc","html");
%    append(d,ExternalLink("http://www.mathworks.com/","MathWorks"));
%    close(d);
%    rptview(d);
%
%    See also mlreportgen.dom.InternalLink, mlreportgen.dom.LinkTarget,
%    mlreportgen.dom.EmbeddedObject, mlreportgen.dom.Text,
%    mlreportgen.dom.Number, mlreportgen.dom.CharEntity

%    Copyright 2014-2023 The MathWorks, Inc.
%    Built-in class