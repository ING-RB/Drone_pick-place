function focus = mrgfocus(Ranges,SoftFlags)
%MRGFOCUS  Merges time or frequency ranges into single focus.
%
%  FOCUS = ltipack.mrgfocus(RANGES) merges a list of time intervals into
%  a single range.
%
%  FOCUS = ltipack.mrgfocus(RANGES,SOFTFLAGS) merges a list of frequency
%  ranges into a single range. The logical vector SOFTFLAGS signals which
%  ranges are soft and can be  ignored when well separated from 
%  the remaining dynamics (these correspond to pseudo integrators 
%  or derivators, or response w/o dynamics)

%  Copyright 1986-2021 The MathWorks, Inc.
if nargin==1
   focus = LocalMergeRange(Ranges);
else
   % Merge well-defined ranges (SOFTFLAG=0)
   focus = LocalMergeRange(Ranges(~SoftFlags,:));
   % Discard soft ranges separated by at least 2 decades from remaining dynamics
   for ct=1:numel(SoftFlags)
      if SoftFlags(ct) && (Ranges(ct,1)>100*focus(2) || Ranges(ct,2)<focus(1)/100)
         SoftFlags(ct) = false;
      end
   end
   % Incorporate soft range contribution (SOFTFLAG=1)
   focus = LocalMergeRange([focus;Ranges(SoftFlags,:)]);
end

%--------------- Local Functions ----------------------------

function focus = LocalMergeRange(Ranges)
% Take the union of a list of ranges
if isempty(Ranges)
   focus = NaN(1,2);
else
   focus = [min(Ranges(:,1)),max(Ranges(:,2))];
end