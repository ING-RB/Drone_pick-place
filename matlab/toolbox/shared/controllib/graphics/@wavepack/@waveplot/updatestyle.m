function updatestyle(this,varargin)
%UPDATESTYLE  Updates wave styles when style preferences change.

%  Copyright 1986-2004 The MathWorks, Inc.

% RE: PostSet listener for @stylemanager's list of styles (Styles property)
Styles = this.StyleManager.Styles;
Nr = length(this.Waves);
Ns = length(Styles);
for ct=1:Nr
   this.Waves(ct).applystyle(Styles(1+rem(ct-1,Ns)))
end