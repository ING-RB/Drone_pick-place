function layout(h)
%LAYOUT  Positions axes in axis grid.

%   Copyright 2013-2015 The MathWorks, Inc.

% Get visible portion of the grid
rlen = h.RowLen;
ax = h.Axes(h.RowVisible, h.ColumnVisible);
yVis = h.RowVisible(1:rlen(1));
uVis = h.RowVisible(rlen(1)+(1:rlen(2)));
n = [sum(yVis); sum(uVis)];

if ~h.Visible || numel(ax)==0
   return
end

% Get requested position in pixels
[FigW,FigH] = figsize(h,'pixel');
LM = h.Geometry.LeftMargin / FigW;  % normalized
TM = h.Geometry.TopMargin / FigH;
HGap = h.Geometry.HorizontalGap / FigW;
VGap = h.Geometry.VerticalGap / FigH;
HRatio = h.Geometry.HeightRatio;

% Adjust position to account for row and column labels
Position = h.Position + [LM 0 -LM -TM];  % normalized units

Or = h.Orientation;
switch h.Orientation
   case '2row' % this is the default
      if any(rlen==0)
         Or = '1row';
      elseif all(rlen==1)
         Or = '1col';
      end
   case '2col'
      if any(rlen==0) 
         Or = '1col';
      elseif all(rlen==1)
         Or = '1row';
      end
end
% if multi-column, the orientation is fixed to '1col'
nc = size(h.Axes,2);
if nc>1, Or = '1col'; end
h.Orientation = Or;

if nc>1
   % handle the special 2-column arrangement for complex TD iddata.   
   nr = sum(n); 
   if nr==0, return, end
   W = max(2/FigW,(Position(3)-(nc-1)*HGap)/nc);
   H = zeros(nr,1);
   if length(HRatio)==nr
      H = max(2/FigH,((Position(4)-(nr-1)*VGap)/sum(HRatio)) * HRatio);
   else
      H(:) = max(2/FigH,(Position(4)-(nr-1)*VGap)/nr);
   end
   
   % Position each sub-axes
   x0 = Position(1); Next_ = numel(ax); 
   ax = ax(end:-1:1); 
   for ic = nc:-1:1
      if nr==0, continue; end
      y0 = Position(2) + (VGap + H(end))*(nr-1);
      for ir = 1:nr
         thisax = ax(Next_);
         NormUnits = strcmp(get(thisax,'Units'),'normalized');
         if ~NormUnits
            Units = thisax.Units;
            thisax.Units = 'normalized';
         end
         thisax.Position = [x0 y0 W H(ir)]; % no listener...
         if ~NormUnits
            thisax.Units = Units;
         end
         y0 = y0 - H(ir) - VGap;
         Next_ = Next_-1;
      end      
      x0 = x0 + W + HGap;
   end
   return
end

% Width and height of individual sub-axes in grid (in normalized units)
switch Or
   case '2row'
      nr = any(yVis)+any(uVis); % number of rows
      H = zeros(nr,1);
      if length(HRatio)==nr
         H = max(2/FigH,((Position(4)-(nr-1)*VGap)/sum(HRatio)) * HRatio);
      else
         H(:) = max(2/FigH,(Position(4)-(nr-1)*VGap)/nr);
      end
      
      % Position each sub-axes
      y0 = Position(2); Next_ = numel(ax); iH = 1;
      for ir = numel(n):-1:1
         numcols = n(ir);
         if numcols==0, continue; end
         
         Wir = max(2/FigW,(Position(3)-(numcols-1)*HGap)/numcols);
         x0 = Position(1) + (HGap + Wir)*(numcols-1);
         for ic = 1:numcols
            thisax = ax(Next_);
            NormUnits = strcmp(get(thisax,'Units'),'normalized');
            if ~NormUnits
               Units = thisax.Units;
               thisax.Units = 'normalized';
            end
            thisax.Position = [x0 y0 Wir H(iH)]; % no listener...
            if ~NormUnits
               thisax.Units = Units;
            end
            x0 = x0 - Wir - HGap;
            Next_ = Next_-1;
         end
         
         y0 = y0 + H(iH) + VGap;
         iH = iH+1;
      end
   case '2col'
      nc = any(yVis)+any(uVis); % number of columns
      
      % Treat HRatio as width ratio between the 2 columns
      W = zeros(nc,1);
      if length(HRatio)==nc
         W = max(2/FigW,((Position(3)-(nc-1)*HGap)/sum(HRatio)) * HRatio);
      else
         W(:) = max(2/FigW,(Position(3)-(nc-1)*HGap)/nc);
      end
      
      % Position each sub-axes
      x0 = Position(1); Next_ = numel(ax); iW = 1;
      ax = ax(end:-1:1); n = n(end:-1:1);
      for ic = numel(n):-1:1
         numrows = n(ic);
         if numrows==0, continue; end
         Hic = max(2/FigH,(Position(4)-(numrows-1)*VGap)/numrows);
         y0 = Position(2) + (VGap + Hic)*(numrows-1);
         for ir = 1:numrows
            thisax = ax(Next_);
            NormUnits = strcmp(get(thisax,'Units'),'normalized');
            if ~NormUnits
               Units = thisax.Units;
               thisax.Units = 'normalized';
            end
            thisax.Position = [x0 y0 W(iW) Hic]; % no listener...
            if ~NormUnits
               thisax.Units = Units;
            end
            y0 = y0 - Hic - VGap;
            Next_ = Next_-1;
         end
         
         x0 = x0 + W(iW) + HGap;
         iW = iW+1;
      end
   case '1row'
      nc = sum(n);
      if nc==0, return, end
      H = max(2/FigH,(Position(4)));
      
      % Treat HRatio as width ratio between the various columns
      W = zeros(nc,1);
      if length(HRatio)==nc
         W = max(2/FigW,((Position(3)-(nc-1)*HGap)/sum(HRatio)) * HRatio);
      else
         W(:) = max(2/FigW,(Position(3)-(nc-1)*HGap)/nc);
      end
      x0 = Position(1); y0 = Position(2);
      for ic = 1:nc
         thisax = ax(ic);
         NormUnits = strcmp(get(thisax,'Units'),'normalized');
         if ~NormUnits
            Units = thisax.Units;
            thisax.Units = 'normalized';
         end
         thisax.Position = [x0 y0 W(ic) H]; % no listener...
         if ~NormUnits
            thisax.Units = Units;
         end
         x0 = x0 + W(ic) + HGap;
      end
   otherwise % 1 col
      nr = sum(n);
      if nr==0, return, end
      W = max(2/FigW,(Position(3)));
      H = zeros(nr,1);
      if length(HRatio)==nr
         H = max(2/FigH,((Position(4)-(nr-1)*VGap)/sum(HRatio)) * HRatio);
      else
         H(:) = max(2/FigH,(Position(4)-(nr-1)*VGap)/nr);
      end
      
      x0 = Position(1); y0 = Position(2); ax = ax(end:-1:1);
      for ir = 1:nr
         thisax = ax(ir);
         NormUnits = strcmp(get(thisax,'Units'),'normalized');
         if ~NormUnits
            Units = thisax.Units;
            thisax.Units = 'normalized';
         end
         thisax.Position = [x0 y0 W H(ir)]; % no listener...
         if ~NormUnits
            thisax.Units = Units;
         end
         y0 = y0 + H(ir) + VGap;
      end
end

