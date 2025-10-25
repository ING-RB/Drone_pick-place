% mlreportgen.ppt.TextBoxPlaceholder Slide placeholder to replace with text
%     Slide placeholder to replace with text. You can create a text box
%     placeholder using a layout slide. In the default PPT API, when you
%     add a slide with a title to a presentation, the API creates a
%     TextBoxPlaceholder object. Use the find method with the slide object,
%     to find the text box placeholder. You can then set properties for
%     that TextBoxPlaceholder object.
%
%    TextBoxPlaceholder methods:
%        add                - Add content to text box placeholder
%        replace            - Replace text box placeholder content
%
%    TextBoxPlaceholder properties:
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
%      BackgroundColor      - Text box placeholder background color
%      VAlign               - Vertical alignment of text
%      Name                 - Text box placeholder name
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
%    Example:
%
%    % Create a presentation
%    import mlreportgen.ppt.*
%    ppt = Presentation("myTextBoxPlaceholderPresentation.pptx");
%    open(ppt);
%
%    % Add a slide with "Title Slide" layout to the presentation
%    slide = add(ppt,"Title Slide");
%
%    % The "Title Slide" layout includes a TextBoxPlaceholder object with
%    % name "Title". Use the slide's find method to find the object.
%    contents = find(slide,"Title");
%
%    % Replace the placeholder with the paragraph
%    para = Paragraph("My Presentation Title");
%    replace(contents(1),para);
%
%    % Close and view the presentation
%    close(ppt);
%    rptview(ppt);
%
%    See also mlreportgen.ppt.Paragraph, mlreportgen.ppt.Text,
%    mlreportgen.ppt.TextBox

%    Copyright 2020 The MathWorks, Inc.
%    Built-in class

