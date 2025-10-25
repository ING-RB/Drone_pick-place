% mlreportgen.ppt.ExternalLink Hyperlink to location outside of presentation
%     externalLinkObj = ExternalLink() creates an empty external link
%     object.
%
%     externalLinkObj = ExternalLink(target,linkText) creates a hyperlink
%     to the specified target and having the specified link text.
%
%    ExternalLink methods:
%      clone                - Copy external link
%
%    ExternalLink properties:
%      Target               - URL of link target
%      Content              - Link text
%      Bold                 - Option to use bold for link text
%      Font                 - Font family for link text
%      ComplexScriptFont    - Font family for complex scripts
%      FontColor            - Font color for link text
%      FontSize             - Font size for link text
%      Italic               - Option to use italic for link text
%      Strike               - Link text strikethrough style
%      Subscript            - Option to display link text as a subscript
%      Superscript          - Option to display link text as a superscript
%      Underline            - Link text underline style
%      Style                - Array of PPT API formats
%      Children             - Children of this PPT API object
%      Parent               - Parent of this PPT API object
%      Id                   - ID for this PPT API object
%      Tag                  - Tag for this PPT API object
%
%    Example:
%
%    % Create a presentation
%    import mlreportgen.ppt.*
%    ppt = Presentation("myExternalLinkPresentation.pptx");
%    open(ppt);
%
%    % Add a slide to the presentation
%    slide = add(ppt,"Title and Content");
%
%    % Create a Paragraph object
%    p = Paragraph("This is a link to the ");
%
%    % Create an ExternalLink object and append it to the paragraph
%    link = ExternalLink("https://www.mathworks.com","MathWorks site");
%    append(p,link);
%
%    % Replace the content for the slide with the paragraph
%    replace(slide,"Content",p);
%
%    % Close and view the presentation
%    close(ppt);
%    rptview(ppt);
%
%    See also mlreportgen.ppt.Paragraph, mlreportgen.ppt.Text,
%    mlreportgen.ppt.InternalLink

%    Copyright 2020-2021 The MathWorks, Inc.
%    Built-in class

%{
properties

     %Target URL of link target
     %  URL of link target, specified as a character vector or a string
     %  scalar. Specify the full URL (for example, include http://).
     Target;

end
%}
