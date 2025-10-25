function th = plot(ax, layout, args, props, th)
% This internal helper function may be removed in a future release.

%PLOT Plot wordcloud data
%   TH = PLOT(AX, LAYOUT,ARGS,PROPS,TH) makes or updates text objects with
%   positions given in LAYOUT, data in ARGS, text properties in PROPS, and
%   existing text handles in TH.

% Copyright 2016-2023 The MathWorks, Inc.

if nargin < 5
  th = [];
end
num_words = length(args.words);
layoutSize = layout.layoutSize;
ax.XLim = [-layoutSize(1) layoutSize(1)]/2;
ax.YLim = [-layoutSize(2) layoutSize(2)]/2;

colors = args.colorData;
th = preallocate(th, num_words, ax);
for k=1:num_words
  fsize = layout.fontsize(k);
  xy = layout.pos(:,k);
  if fsize > 0
    set(th(k),'Position',xy,...
       'String', char(args.words(k)),...
       'FontUnits_I', 'pixels',...
       'FontSize', fsize, props);
    c = colors(k,:);
    if ~all(isfinite(c))
      th(k).Visible = 'off';
    else
      th(k).Visible = 'on';
      th(k).Color = c;
    end
  end
end
end

function th = preallocate(th, n, parent)
% preallocate n text objects
len = length(th);
if len == 0
  z = zeros(n,1);
  th = text(z,z,strings(n,1),Parent=parent);
elseif n > len
  th = [th; preallocate([],n-len,parent)];
end
end
