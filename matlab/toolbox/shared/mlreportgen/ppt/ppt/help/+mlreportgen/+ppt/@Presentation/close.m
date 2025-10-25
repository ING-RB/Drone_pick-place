%close Close presentation
%   close(presentation) closes the specified mlreportgen.ppt.Presentation
%   object and generates the associated Microsoft PowerPoint presentation
%   file.
%
%  Example:
%
%  % Import the PPT package so that you do not have to use long, fully
%  % qualified names for the PPT API classes
%  import mlreportgen.ppt.*
%
%  % Create a presentation and add a title slide
%  ppt = Presentation("myPresentation.pptx");
%  open(ppt);
%  slide = add(ppt,"Title Slide");
%  replace(slide,"Title","My Title");
%
%  % Close and view the presentation
%  close(ppt);
%  rptview(ppt);
%
%  See also open, find, replace

%  Copyright 2022 The MathWorks, Inc.
%  Built-in function.
