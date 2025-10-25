%find Search presentation
%   searchResults = find(presentation,objectName) searches the specified
%   presentation for the content or slide objects whose Name property value
%   matches objectName. The objectName can be specified as a character
%   vector or string scalar.
%
%  Example:
%
%  % Import the PPT package so that you do not have to use long, fully
%  % qualified names for the PPT API classes
%  import mlreportgen.ppt.*
%
%  % Create a presentation. Add two slides that have titles.
%  ppt = Presentation("myPresentation.pptx");
%  open(ppt);
%  add(ppt,"Title Slide");
%  add(ppt,"Title and Content");
%
%  % Find presentation objects whose Name property is "Title"
%  contents = find(ppt,"Title");
%
%  % Replace the title in the first slide with "My Presentation Title"
%  para = Paragraph("My Presentation Title");
%  replace(contents(1),para);
%
%  % Close and view the presentation
%  close(ppt);
%  rptview(ppt);
%
%  See also replace

%  Copyright 2015-2022 The MathWorks, Inc.
%  Built-in function.
