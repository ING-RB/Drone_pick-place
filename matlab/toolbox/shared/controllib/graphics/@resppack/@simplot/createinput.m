function createinput(this)
% Creates @siminput object for storing input data

%  Author(s): P. Gahinet
%   Copyright 1986-2008 The MathWorks, Inc.
rInput = resppack.siminput;

rInput.Parent = this;
rInput.RowIndex = 1:length(this.OutputName);
rInput.ColumnIndex = 1;
rInput.Visible = 'off';
rInput.Name = 'Driving inputs';
rInput.ChannelName = {''};  % tracks input names

% Create one data/view pair (single input)
[rInput.Data, rInput.View] = createinputview(this, 1);

% Initialize HGGroup for each axes
Axes = getaxes(rInput);
for ct = 1:numel(Axes)
    rInput.Group(ct) = handle(hggroup('parent',Axes(ct)));
    hasbehavior(rInput.Group(ct),'legend',false)
end

initialize(rInput.View,reshape(rInput.Group,size(Axes)))

% Add listeners
addlisteners(rInput)


% Line styles
LineStyles = {'-';'--';':';'-.'};
Style = wavepack.wavestyle;
Style.Colors = {[.6 .6 .6]};  % gray
Style.LineStyles = reshape(LineStyles,[1 1 4]);
Style.Markers = {'none'};
% Legend info for groups
LegendInfoVector.type = 'line';
LegendInfoVector.props =  {'Color', Style.Colors{1}, ...
        'LineStyle', LineStyles{1}};
Style.GroupLegendInfo = LegendInfoVector;

rInput.Style = Style;


% Install tips
addtip(rInput)

this.Input = rInput;

