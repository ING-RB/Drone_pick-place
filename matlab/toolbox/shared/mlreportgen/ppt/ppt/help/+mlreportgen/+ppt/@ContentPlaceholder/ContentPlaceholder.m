% mlreportgen.ppt.ContentPlaceholder Slide placeholder to replace with content
%     Slide placeholder to replace with content such as a paragraph,
%     picture, or table. You can create a content placeholder using a
%     layout slide. In the default PPT API, when you add a "Title and
%     Content" layout slide to a presentation, the API creates a
%     ContentPlaceholder object. Use the find method with the slide object,
%     to find the content placeholder. You can then set properties for
%     that ContentPlaceholder object.
%
%    ContentPlaceholder methods:
%      add                  - Add content to the placeholder
%      replace              - Replace placeholder content
%
%    ContentPlaceholder properties:
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
%      BackgroundColor      - Content placeholder background color
%      VAlign               - Vertical alignment of text
%      Name                 - Content placeholder name
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
%    Example 1:
%    % Replace content placeholder with a list
%
%    % Create a presentation
%    import mlreportgen.ppt.*
%    ppt = Presentation("myContentPlaceholderPresentation1.pptx");
%    open(ppt);
%
%    % Add a slide with "Title and Content" layout to the presentation
%    slide = add(ppt,"Title and Content");
%
%    % The "Title and Content" layout includes a ContentPlaceholder object
%    % with name "Content". Use the slide's find method to find the object.
%    contents = find(slide,"Content");
%
%    % Replace the placeholder with the content
%    replace(contents(1),{'Subject 1','Subject 2','Subject 3'});
%
%    % Close and view the presentation
%    close(ppt);
%    rptview(ppt);
%
%
%    Example 2:
%    % Replace content placeholder with a multilevel list
%
%    % Create a presentation
%    import mlreportgen.ppt.*
%    ppt = Presentation("myContentPlaceholderPresentation2.pptx");
%    open(ppt);
%
%    % Add a slide with "Title and Content" layout to the presentation
%    slide = add(ppt,"Title and Content");
%
%    % Create multilevel list content. A multilevel list can be represented
%    % as a cell array where one or more of its elements are cells. Use the
%    % Paragraph object to format any item in the list.
%    greenTea = Paragraph("Green Tea");
%    greenTea.FontColor = "green";
%
%    multilevelContent = { ...
%        "Coffee", ...
%        "Tea", ...
%        { ...
%            "Black Tea", ...
%            greenTea, ...
%        }, ...
%        "Milk", ...
%        };
%
%    % Replace the Content placeholder with the multilevel list content
%    replace(slide,"Content",multilevelContent);
%
%    % Close and view the presentation
%    close(ppt);
%    rptview(ppt);
%
%    See also mlreportgen.ppt.Paragraph, mlreportgen.ppt.Table,
%    mlreportgen.ppt.Picture

%    Copyright 2020 The MathWorks, Inc.
%    Built-in class

