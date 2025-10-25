function h = plotrows(rlen,hndl)
% Returns instance of @plotarray class
%
%   H = PLOTROWS([N1 N2 N3 ...],AXHANDLE) creates an array of N rows of
%   axes where N = numel([N1 N2 N3...]) and first row has N1 visible axes,
%   second one had N2 visible axes and so on. H contains a 2D axes grid of
%   size N-by-max([N1 N2 N3 ...]).

%   Copyright 2013-2015 The MathWorks, Inc.

if numel(rlen)<3
   arraysize = [sum(rlen), 1, 1, 1];
else
   sz = rlen(3:end); if isscalar(sz), sz = [sz 1 1]; end
   arraysize = [sum(rlen(1:2)), sz];
   rlen = rlen(1:2);
end
h = iodatapack.plotrows;
s = arraysize(1:2);
hndl = handle(hndl);
% Position in Normalized units
Position = hgconvertunits(ancestor(hndl(1),'figure'), ...
    hndl(1).Position, hndl(1).Units, 'normalized', hndl(1).Parent); % RE: may be changed by @plotrows constructor!

% Create missing axes
nax = prod(arraysize);
ParentFig = hndl(1).Parent;
for ct=length(hndl)+1:nax,
   % RE: Confine all new axes to space allocated to entire plot or plot cell 
   %     (subplot may delete invisible axes that stretch outside allocated space)
   hndl(ct) = handle(axes('Parent',ParentFig,...
      'units', 'normalized', 'Position',Position,...
      'Visible','off','ContentsVisible','off'));
   % Disable Default Interactions
   disableDefaultInteractivity(hndl(ct));
end

% Recursively build nested plot array
nsub = prod(arraysize(3:end));
if nsub==1
   h.Axes = hndl(1:min(nax,end));
elseif nsub==2 && arraysize(3)==2
   % Special case for 2x1 terminal node
   for ct=prod(s):-1:1
      pax(ct) = ctrluis.plotpair(hndl(2*ct-1:2*ct));
   end
   h.Axes = pax;
else 
   assert(false, 'Nested axes beyond 2-by-1 (bode type) are not supported.')
end

h.Axes = reshape(h.Axes,s);
h.Position = Position;
h.RowLen = rlen;
