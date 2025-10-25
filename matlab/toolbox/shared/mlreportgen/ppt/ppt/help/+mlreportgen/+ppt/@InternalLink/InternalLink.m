% mlreportgen.ppt.InternalLink Hyperlink to a slide in presentation
%     internalLinkObj = InternalLink() creates an empty internal link
%     object.
%
%     internalLinkObj = InternalLink(targetSlideName,linkText) creates a
%     hyperlink to the slide specified by the target slide name and having
%     the specified link text.
%
%     internalLinkObj = InternalLink(targetSlideIdx,linkText) creates a
%     hyperlink to the slide specified by the target slide index and having
%     the specified link text.
%
%    InternalLink methods:
%      clone                - Copy internal link
%
%    InternalLink properties:
%      Target               - Target slide
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
%    Example 1:
%       % Example to create an internal link to a slide based on the target
%       % slide name in the presentation.
%
%       % Create a presentation
%       import mlreportgen.ppt.*
%       ppt = Presentation("myInternalLinkPresentation1.pptx");
%       open(ppt);
%
%       % Add first slide to the presentation
%       slide1 = add(ppt,"Title and Content");
%
%       % Specify a target slide name which will be used to create an
%       % internal link to that slide
%       targetSlideName = "myTargetSlide";
%
%       % Create a paragraph and add an internal link to it. Clicking on
%       % the link should navigate to the slide with the specified target
%       % slidename.
%       p = Paragraph("This is a link to the slide with name ");
%       link = InternalLink(targetSlideName,targetSlideName);
%       append(p,link);
%
%       % Add the title and content to the slide
%       replace(slide1,"Title","First slide");
%       replace(slide1,"Content",p);
%
%       % Add second slide to the presentation
%       slide2 = add(ppt,"Title and Content");
%       replace(slide2,"Title","Second slide");
%
%       % Add third slide to the presentation and specify its name
%       slide3 = add(ppt,"Title and Content");
%       slide3.Name = targetSlideName;
%       replace(slide3,"Title","Third slide");
%       content = strcat("This is the target slide with name: ",targetSlideName);
%       replace(slide3,"Content",content);
%
%       % Close and view the presentation
%       close(ppt);
%       rptview(ppt);
%
%
%    Example 2:
%       % Example to create an internal link to a slide based on the target
%       % slide index in the presentation
%
%       % Create a presentation
%       import mlreportgen.ppt.*
%       ppt = Presentation("myInternalLinkPresentation2.pptx");
%       open(ppt);
%
%       % Add first slide to the presentation
%       slide1 = add(ppt,"Title and Content");
%
%       % Create a paragraph and add an internal link to it. Clicking on
%       % the link should navigate to the third slide in the presentation.
%       p = Paragraph("This is a link to the ");
%       link = InternalLink(3,"slide 3");
%       append(p,link);
%
%       % Add the title and content to the slide
%       replace(slide1,"Title","First slide");
%       replace(slide1,"Content",p);
%
%       % Add second slide to the presentation
%       slide2 = add(ppt,"Title and Content");
%       replace(slide2,"Title","Second slide");
%
%       % Add third slide to the presentation
%       slide3 = add(ppt,"Title and Content");
%       replace(slide3,"Title","Third slide");
%       replace(slide3,"Content","This is the target slide");
%
%       % Close and view the presentation
%       close(ppt);
%       rptview(ppt);
%
%    See also mlreportgen.ppt.Paragraph, mlreportgen.ppt.Text,
%    mlreportgen.ppt.ExternalLink, mlreportgen.ppt.Slide.Name

%    Copyright 2020-2021 The MathWorks, Inc.
%    Built-in class

%{
properties

     %Target Target slide
     %  Target slide of the hyperlink that can be specified as the name or
     %  index of the slide in the presentation. Target slide name can be
     %  specified as a character vector or a string scalar. Target slide
     %  index can be specified as an integer value.
     Target;

end
%}
