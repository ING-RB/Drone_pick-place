function dataTipTextRow = dataTipTextRow(varargin)

%   dataTipTextRow creates a new data tip row with a label, source, and format
%
%     r = dataTipTextRow(label,value) creates a new data tip row that uses 
%     the specified label and value source.
%
%     r = dataTipTextRow(label,value,format) additionally specifies the format
%     for the displayed values.
%
%   Example:
%     load('accidents.mat','hwydata','statelabel')
%     s = scatter(hwydata(:,14),hwydata(:,4));
%     row = dataTipTextRow('State',statelabel);
%     s.DataTipTemplate.DataTipRows(end+1) = row;

% Copyright 2018-2019 The MathWorks, Inc.

% Make sure the inputs are valid
narginchk(2,3);

args = matlab.graphics.internal.convertStringToCharArgs(varargin(1:end));

if ~ischar(args{1})
    me = MException(message('MATLAB:graphics:datatip:InvalidLabelProperty'));
    throwAsCaller(me);
end

if nargin > 2 && ~ischar(args{3})
    me = MException(message('MATLAB:graphics:datatip:InvalidFormatProperty'));
    throwAsCaller(me);
end

if isempty(args{1}) && isempty(args{2})
    me = MException(message('MATLAB:graphics:datatip:CannotCreateEmptyRow'));
    throwAsCaller(me);
end

dataTipTextRow = matlab.graphics.datatip.DataTipTextRow(varargin{:});
% Set LabelMode to 'manual' when user calls this dataTipTextRow function.
dataTipTextRow.LabelMode = 'manual';
end