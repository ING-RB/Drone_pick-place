%replace Replace text, tables, or pictures in presentation
%   replace(presentation,contentName,content) replaces existing content in
%   a presentation content object with the specified content which can be
%   one or more paragraphs, a table, or a picture. If the type of content
%   that you specify in the content argument is not valid for the content
%   object identified by contentName, the replace method has no effect.
%
%  Example:
%
%  % Import the PPT package so that you do not have to use long, fully
%  % qualified names for the PPT API classes
%  import mlreportgen.ppt.*
%
%  % Create a presentation and add two slides that have titles
%  ppt = Presentation("myPresentation.pptx");
%  open(ppt);
%  add(ppt,"Title Slide");
%  add(ppt,"Title and Content");
%
%  % Replace all the titles in presentation with title "My Slide Title"
%  replace(ppt,"Title","My Slide Title");
%
%  % Close and view the presentation
%  close(ppt);
%  rptview(ppt);
%
%  See also find, add

%  Copyright 2022 The MathWorks, Inc.
%  Built-in function.
