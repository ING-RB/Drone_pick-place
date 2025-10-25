%PPTVIEW opens a PowerPoint file in a PowerPoint viewer.
%    PPTVIEW(FILENAME) opens the specified file in a PowerPoint file
%    viewer.
%
%    [STATUS,MESSAGE]=PPTVIEW(FILENAME) returns a STATUS of 1 if the file
%    viewer opened; otherwise, a STATUS of 0 and an error message in
%    MESSAGE.
%
%    PPTVIEW(FILENAME,COMMAND1,COMMAND2, ...) executes the following
%    commands on Windows systems containing PowerPoint:
%
%      'converttopdf' - convert a PowerPoint file to pdf
%      'showaspdf'    - convert a PowerPoint file to pdf and displays it
%      'closedoc'     - close FILENAME in PowerPoint
%
%    See also RPTVIEWFILE

     
    %   Copyright 2015-2024 The MathWorks, Inc.

