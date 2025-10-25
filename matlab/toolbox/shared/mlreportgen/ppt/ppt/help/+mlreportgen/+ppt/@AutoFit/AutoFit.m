%mlreportgen.ppt.AutoFit Scale text to fit placeholder or text box
%    autoFitObj = AutoFit() scales the text by scaling its font to fit a
%    placeholder or a text box. Use the FontScale property to specify the
%    text font scaling value.
%
%    autoFitObj = AutoFit(tf) scales the text by scaling its font to fit a
%    placeholder or a text box if the specified tf value is true. Use the
%    FontScale property to specify the text font scaling value.
%
%    autoFitObj = AutoFit(tf,fontScale) scales the text by scaling its
%    font to fit a placeholder or a text box if the specified tf value is
%    true. The text font is scaled to the specified fontScale value.
%
%    AutoFit properties:
%       Value       - Option to scale text
%       FontScale   - Text font scaling value
%       Id          - ID for this PPT API object
%       Tag         - Tag for this PPT API object
%
%    Example:
%    In a presentation, add one slide that does not scale the text to fit
%    and one slide that scales the text to fit.
%
%    % Create a presentation
%    import mlreportgen.ppt.*
%    ppt = Presentation("myAutoFitPresentation.pptx");
%    open(ppt);
%
%    % Add first slide to the presentation.
%    % The content placeholder in this slide does not scale text to fit.
%    slide1 = add(ppt,"Title and Content");
%    contentPlaceholder = find(slide1,"Content");
%    replace(contentPlaceholder,Paragraph(char(randi(25,1,1000)+97)));
%    contentPlaceholder.Style = [contentPlaceholder.Style {AutoFit(false)}];
%
%    % Add second slide to the presentation.
%    % The content placeholder in this slide scales text to fit.
%    slide2 = add(ppt,"Title and Content");
%    contentPlaceholder = find(slide2,"Content");
%    replace(contentPlaceholder(1),Paragraph(char(randi(25,1,1000)+97)));
%    contentPlaceholder.Style = [contentPlaceholder.Style {AutoFit(true)}];
%
%    % Close and view the presentation
%    close(ppt);
%    rptview(ppt);

%    Copyright 2019 The MathWorks, Inc.
%    Built-in class

%{
properties

     %Value Option to scale text
     %  Option to scale text to fit a placeholder or a text box, specified
     %  as a logical value:
     %
     %      true    - scales text to fit
     %      false   - does not scale text to fit
     Value;

     %FontScale Text font scaling value
     %  Text font scaling value, specified as a character vector or a
     %  string scalar. This property specifies the percentage value by
     %  which the text font size is to be scaled to fit a placeholder or a
     %  text box. By default, the text is scaled to 92.5%. A higher value
     %  of this property may cause the text to overflow because the text
     %  font size is not reduced beyond the specified value. For example, a
     %  value of 100% scales the text to 100% which means that the size is
     %  not reduced at all to fit.
     FontScale;

end
%}