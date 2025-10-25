%mlreportgen.dom.InternalLink Creates a hyperlink to a target in this
%  document
%
%    linkObj = InternalLink() creates a link with an empty target and
%    empty link text.
%
%    linkObj = InternalLink('target','text') creates a link to the specified 
%    internal target with link text that contains the specified text.
%
%    linkObj = InternalLink('target',number) creates a link to the specified 
%    internal target with link text that contains the specified floating-point
%    or integer number.
%
%    linkObj = InternalLink('target','text','styleName') creates a link to  
%    the specified internal target with the specified link text and style.
%
%    linkObj = InternalLink('target',obj) creates a link to the specified
%    internal target with the link text specified by obj, which can be an  
%    mlreportgen.dom.Text, mlreportgen.dom.Number, or
%    mlreportgen.dom.CharEntity object.
%
%    InternalLink methods:
%        append         - Append text and images to this link
%        clone          - Clone this target
%
%    InternalLink properties:
%        Target            - Internal target of this hyperlink
%        TargetSite        - Location to open a target
%        Children          - Children of this internal link
%        CustomAttributes  - Custom element attributes
%        Id                - Id of this text
%        Parent            - Parent of this link
%        Tag               - Tag of this text
%
%    Example:
%
%    import mlreportgen.dom.*
%    d = Document("mydoc","html");
%    append(d,InternalLink("bio","Author's Bio"));
%    h = Heading(1,LinkTarget("bio"));
%    append(h,"Author's Bio");
%    append(d,h);
%    close(d);
%    rptview(d);
%
%    See also mlreportgen.dom.ExternalLink, mlreportgen.dom.LinkTarget,
%    mlreportgen.dom.EmbeddedObject, mlreportgen.dom.Text,
%    mlreportgen.dom.Number, mlreportgen.dom.CharEntity

%    Copyright 2014-2023 The MathWorks, Inc.
%    Built-in class