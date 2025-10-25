function layout(this, Position)
%LAYOUT   Positions axes in axis grid.
%                   |---------------|
%                   |---------------|
%                   |---------------|
%
%           |-----| |---------------| |-----|
%           |-----| |---------------| |-----|
%           |-----| |---------------| |-----|
%           |-----| |---------------| |-----|
%           |-----| |---------------| |-----|
%           |-----| |---------------| |-----|
%
%                   |---------------|
%                   |---------------|
%                   |---------------|
%

%   Copyright 2015-2020 The MathWorks, Inc.

% Normalize horizontal and verical gap

% Get figure width and height in pixels (As gap is specified in
% pixels)

% REVISIT - Use hgConvertUnits?
if nargin == 1
    Position = this.Position;
end

CurrentUnits = get(this.AxesGrid.Parent, 'Units');
set(this.AxesGrid.Parent,'Units','Pixels');
FigPos = this.AxesGrid.Parent.Position;
FigW = FigPos(3);
FigH = FigPos(4);
set(this.AxesGrid.Parent,'Units',CurrentUnits)

% Normalize horizontal and verical gap
NormHGap = this.Geometry.HorizontalGap / FigW;
NormVGap = this.Geometry.VerticalGap / FigH;
HGap = 2.5*NormHGap;
VGap = 2.5*NormVGap;

% Get the handles to all valid axesgrids
AGrid{1,2} = getPeripheralAxesGrid(this, 'Bottom');
AGrid{2,1} = getPeripheralAxesGrid(this, 'Left');
AGrid{2,2} = this.AxesGrid;
AGrid{2,3} = getPeripheralAxesGrid(this, 'Right');
AGrid{3,2} = getPeripheralAxesGrid(this, 'Top');

% BUSINESS RULES
NumVGap = 0;
if isempty(AGrid{1,2})
    % Bottom is empty
    HRatio(1) = 0;
else
    HRatio(1) = .2;
    NumVGap = NumVGap+1;
end

if isempty(AGrid{3,2})
    % Top is empty
    HRatio(3) = 0;
else
    HRatio(3) = 0.2;
    NumVGap = NumVGap+1;
end

% Remaining ratio for core axes grid height
HRatio(2) = 1 - (HRatio(1)+HRatio(3));

NumHGap = 0;
if isempty(AGrid{2,1})
    % Left is empty
    WRatio(1) = 0;
else
    WRatio(1) = .2;
    NumHGap = NumHGap+1;
end

if isempty(AGrid{2,3})
    % Right is empty
    WRatio(3) = 0;
else
    WRatio(3) = 0.2;
    NumHGap = NumHGap+1;
end

% Remaining ratio for core axes grid width
WRatio(2) = 1 - (WRatio(1)+WRatio(3));

% if isempty(this.Position)
%     Position = this.AxesGrid.BackgroundAxes.Position;
% end
% Subtract gap from height and width available for the axes
% grids
WAvail = Position(3) - NumHGap*HGap;
HAvail = Position(4) - NumVGap*VGap;

% Determine the height and width of each axesgrid
H = HRatio*HAvail;
W = WRatio*WAvail;

% Ensure that the width and height of an individual axes in the
% periphary does not exceed the width and height of an
% individual axes in the core axes grid.
[nR,nC] = size(this);
CoreAxesHeight = (H(2) - NormHGap*(nC-1))/nC;
CoreAxesWidth = (W(2) - NormVGap*(nR-1))/nR;

H(1) = min(H(1), CoreAxesHeight);
H(3) = min(H(3), CoreAxesHeight);

W(1) = min(W(1), CoreAxesWidth);
W(3) = min(W(3), CoreAxesWidth);

H(2) = HAvail-(H(1)+H(3));
W(2) = WAvail-(W(1)+W(3));

% Set histogram axes positions too
XvsX = ~isempty(this.HistogramAxes);

% Iterate through the axes grids to set position
X0_init = Position(1);
Y0 = Position(2);
for ct1 = 1:size(AGrid,1)
    X0 = X0_init;
    for ct2 = 1:size(AGrid,2)
        % If there is an axes grid at the given index, set the
        % position
        if ~isempty(AGrid{ct1,ct2}) && strcmpi(AGrid{ct1,ct2}.Visible, 'on')
            % Position is calculated in normalized units
            Units = AGrid{ct1,ct2}.BackgroundAxes.Units;
            AGrid{ct1,ct2}.BackgroundAxes.Units = 'normalized';
            AGrid{ct1,ct2}.Position = [X0, Y0, W(ct2), H(ct1)];
            AGrid{ct1,ct2}.BackgroundAxes.Units = Units;
        end
        
        % Next Column: Increment X0 by approrpiate width and gap
        X0 = X0 + W(ct2) + (W(ct2)~=0)*HGap;
    end
    
    %Next Row: Increment Y0 by appropriate height and gap
    Y0 = Y0 + H(ct1) + (H(ct1)~=0)*VGap;
    
end
if XvsX
    Ax = getaxes(this.AxesGrid);
    for ct = 1:nR
        % Create axes
        Position = get(Ax(ct,ct),'Position');
        this.HistogramAxes(ct).Position = Position;
    end
end

setTickMarks(this);
end
