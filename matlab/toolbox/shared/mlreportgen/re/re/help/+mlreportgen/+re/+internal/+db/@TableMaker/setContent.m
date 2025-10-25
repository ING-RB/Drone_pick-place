%setContent Specify the content of the table to be made.
%  setContent(tm,entries) sets the content of the table to be
%  made. Entries can be any of the following:
%
%   * Vector of mlreportgen.re.internal.db.CALSEntry objects
%   * Vector of matlab.io.xml.dom.Node objects
%   * Vector of strings
%   * Cell vector containing any of the following types of cells:
%     - string
%     - character vector
%     - mlreportgen.re.internal.db.CALSEntry object
%     - matlab.io.xml.dom.Node object
%
%   The size of the content vector should be 1xN or Nx1 where
%       N = R*C
%       C = number of table columns
%       R = number of table rows, including head, body, and foot
%           sections.
%
%  See also mlreportgen.re.internal.db.CALSEntry

% Copyright 2021 MathWorks, Inc.