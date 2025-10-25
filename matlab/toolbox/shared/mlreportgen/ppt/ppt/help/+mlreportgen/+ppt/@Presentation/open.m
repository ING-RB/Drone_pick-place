%open Open presentation
%   open(presentation) opens a presentation and parses the template.
%
%  Example:
%
%  % Import the PPT package so that you do not have to use long, fully
%  % qualified names for the PPT API classes
%  import mlreportgen.ppt.*
%
%  % Create a presentation
%  ppt = Presentation("myPresentation.pptx");
%
%  % Open the presentation
%  open(ppt);
%
%  % Add a title slide to the presentation
%  slide = add(ppt,"Title Slide");
%  replace(slide,"Title","My Title");
%
%  % Close and view the presentation
%  close(ppt);
%  rptview(ppt);
%
%  See also close, find, replace

%  Copyright 2022 The MathWorks, Inc.
%  Built-in function.
