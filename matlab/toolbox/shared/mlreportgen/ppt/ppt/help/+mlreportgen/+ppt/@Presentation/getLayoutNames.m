%getLayoutNames Get names of layouts for presentation slide master
%   layoutNames = getLayoutNames(presentation,slideMaster) returns the
%   names of layouts for a presentation slide master.
%
%  Example:
%
%  % Import the PPT package so that you do not have to use long, fully
%  % qualified names for the PPT API classes
%  import mlreportgen.ppt.*
%
%  % Create a presentation
%  ppt = Presentation("myPresentation.pptx");
%  open(ppt);
%
%  % Get the names of the slide masters in the presentation. The default
%  % PPT API template has only one slide master.
%  mNames = getMasterNames(ppt);
%
%  % Get the names of the layouts in the slide master
%  layouts = getLayoutNames(ppt,mNames{1});
%
%  % Add a title slide to the presentation, using the "Title Slide" layout,
%  % and replace the title in the slide.
%  slide = add(ppt,"Title Slide");
%  replace(slide,"Title","My Title");
%
%  % Close and view the presentation
%  close(ppt);
%  rptview(ppt);
%
%  See also getMasterNames

%  Copyright 2022 The MathWorks, Inc.
%  Built-in function.
