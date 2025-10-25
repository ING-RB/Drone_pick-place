% mlreportgen.ppt.PicturePlaceholder Slide placeholder to replace with picture
%     Slide placeholder to replace with picture. You can create a picture
%     placeholder using a layout slide. In the default PPT API, when you
%     add a "Title and Picture" layout slide to a presentation, the API
%     creates a PicturePlaceholder object. Use the find method with the
%     slide object to find the picture placeholder. You can then set
%     properties for that PicturePlaceholder object.
%
%    PicturePlaceholder methods:
%      replace              - Replace picture placeholder with picture
%
%    PicturePlaceholder properties:
%      Bold                 - Option to use bold for text
%      Font                 - Font family for text
%      ComplexScriptFont    - Font family for complex scripts
%      FontColor            - Font color for text
%      FontSize             - Font size for text
%      Italic               - Option to use italic for text
%      Strike               - Text strikethrough style
%      Subscript            - Option to display text as a subscript
%      Superscript          - Option to display text as a superscript
%      Underline            - Text underline style
%      BackgroundColor      - Placeholder background color
%      VAlign               - Vertical alignment of text
%      Name                 - Picture placeholder name
%      X                    - Upper-left x-coordinate position of placeholder
%      Y                    - Upper-left y-coordinate position of placeholder
%      Width                - Width of placeholder
%      Height               - Height of placeholder
%      Style                - Array of PPT API formats
%      Children             - Children of this PPT API object
%      Parent               - Parent of this PPT API object
%      Tag                  - Tag for this PPT API object
%      Id                   - ID for this PPT API object
%
%    Note: Some formatting properties do not apply to a picture and are
%    ignored. See the documentation page of this class for more
%    information.
%
%    Example:
%
%    % Create a presentation
%    import mlreportgen.ppt.*
%    ppt = Presentation("myPicturePlaceholderPresentation.pptx");
%    open(ppt);
%
%    % Add a slide with "Title and Picture" layout to the presentation
%    slide = add(ppt,"Title and Picture");
%
%    % The "Title and Picture" layout includes a PicturePlaceholder object
%    % with name "Picture". Use the slide's find method to find the object.
%    contents = find(slide,"Picture");
%
%    % Replace the placeholder with the picture
%    replace(contents(1),Picture(which("b747.jpg")));
%
%    % Close and view the presentation
%    close(ppt);
%    rptview(ppt);
%
%    See also mlreportgen.ppt.Picture, mlreportgen.ppt.TemplatePicture

%    Copyright 2020 The MathWorks, Inc.
%    Built-in class

