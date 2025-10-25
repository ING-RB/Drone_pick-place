function r = addresponse(this, varargin)
%ADDRESPONSE  Adds a new response to a response plot.
%
%   R = ADDRESPONSE(RESPPLOT,ROWINDEX,COLINDEX,NRESP) adds a new response R
%   to the response plot RESPPLOT.  The index vectors ROWINDEX and COLINDEX
%   specify the response I/O sizes and position in the axes grid, and NRESP
%   is the number of individual responses in R (default = 1).
%
%   R = ADDRESPONSE(RESPPLOT,DATASRC) adds a response R that is linked to the 
%   data source DATASRC.
%
%   R = ADDRESPONSE(RESPPLOT,...,VIEWTYPE) sets the view object to be used specified
%   by VIEWTYPE

%  Author(s): Bora Eryilmaz, P. Gahinet
%  Copyright 1986-2012 The MathWorks, Inc.

if ~isempty(varargin) && isa(varargin{end},'char')
    vargcheck = varargin(1:end-1);
else
    vargcheck = varargin;
end

% Size checking
if length(vargcheck)>1 && ...
      (max(vargcheck{1})>this.AxesGrid.Size(1) || ...
      max(vargcheck{2})>this.AxesGrid.Size(2))
   ctrlMsgUtils.error('Controllib:plots:addresponse1')
end

if ~isempty(vargcheck)&& ~isnumeric(vargcheck{1})
    srcSize = getsize(varargin{1});
    if ~isequal(srcSize(1:2),this.AxesGrid.Size(1:2))
        this.AxesGrid.CheckForBlankAxes = true;
    end
end

% Add new response
try
   r = addwf(this,varargin{:});
catch ME
   throw(ME)
end

% Resolve unspecified name against all existing "untitledxxx" names
setDefaultName(r,this.Responses)

% Add to list of responses
this.Responses = [this.Responses ; r];