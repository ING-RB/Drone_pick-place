% mlreportgen.ppt.TextBox Text box to include in a presentation
%     textBoxObj = TextBox() creates an empty text box object.
%
%    TextBox methods:
%        add                - Add content to text box
%        replace            - Replace text box content
%        clone              - Copy text box
%
%    TextBox properties:
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
%      BackgroundColor      - Text box background color
%      VAlign               - Vertical alignment of text
%      Name                 - Text box name
%      X                    - Upper-left x-coordinate position of text box
%      Y                    - Upper-left y-coordinate position of text box
%      Width                - Width of text box
%      Height               - Height of text box
%      Style                - Array of PPT API formats
%      Children             - Children of this PPT API object
%      Parent               - Parent of this PPT API object
%      Tag                  - Tag for this PPT API object
%      Id                   - ID for this PPT API object
%
%    Example:
%
%    % Create a presentation
%    import mlreportgen.ppt.*
%    ppt = Presentation("myTextBoxPresentation.pptx");
%    open(ppt);
%
%    % Add a blank slide to the presentation
%    slide = add(ppt,"Blank");
%
%    % Create a TextBox object and define its location and size
%    textBoxObj = TextBox();
%    textBoxObj.X = "1in";
%    textBoxObj.Y = "1in";
%    textBoxObj.Width = "8in";
%    textBoxObj.Height = "0.5in";
%
%    % Add text to the text box
%    add(textBoxObj,"This is the title of my blank slide");
%
%    % Add text box to the slide
%    add(slide,textBoxObj);
%
%    % Close and view the presentation
%    close(ppt);
%    rptview(ppt);
%
%    See also mlreportgen.ppt.Paragraph, mlreportgen.ppt.Text,
%    mlreportgen.ppt.TextBoxPlaceholder

%    Copyright 2020-2021 The MathWorks, Inc.
%    Built-in class

