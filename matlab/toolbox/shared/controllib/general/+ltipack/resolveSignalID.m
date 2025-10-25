function [iSel,MisMatch,IDSel] = resolveSignalID(ID,SignalList,SimulinkFlag)
% Resolves signal identifiers against a list of signal names or paths.
%
%    [ISEL,MISMATCH,IDSEL] = ltipack.resolveSignalID(IDS,SIGNALS) resolves the
%    list IDS of signal identifiers against the list SIGNALS of signal names.
%    A particular name <signame> matches itself or the indexed expression
%    <signame>(index). If a signal appears multiple times in the signal
%    list, only the first occurrence is selected. The selected signals are
%    SIGNALS(ISEL) and their identifiers are IDSEL (same as IDS except 
%    for resolved indices). If some identifier has zero or multiple matches, 
%    ISEL and IDSEL are empty and the MISMATCH structure contains info
%    about the mismatch (mismatched identifier and matching indices).
%
%    [ISEL,MISMATCH,IDSEL] = ltipack.resolveSignalID(IDS,SIGNALS,SLFLAG) 
%    supports abbreviated references to slTuner-generated signal names when 
%    SLFLAG=true (default is false). Entries of SIGNALS can be of the form
%       SignalName
%       BlockPath/PortNumber
%       BlockPath/PortNumber[SignalName]
%       BlockPath/PortNumber[BusElement]
%       BlockPath/PortNumber[<BusElement>]  <> added for inherited names
%    An identifier in IDS to match an entry of SIGNALS, it must either
%       1) Match the full signal path
%       2) Match SignalName or BusElement
%       3) Be of the form xxx/PortNumber, xxx/SignalName, or 
%          xxx/BusElement where xxx is a partial block path (matches 
%          the end of BlockPath)
%       4) Match the end of BlockPath for single-port blocks
%       5) Match a portion of the signal name or path.
%    Note that 4) and 5) are applied in this order only when all else
%    failed. 
%
%    IDS and SIGNALS can be of type char, string, or cellstr and the 
%    outputs are always of type STRING. Both the identifiers and full 
%    signal paths can be followed by an index, and it is assumed that 
%    vector-valued signals xxx are fully expanded into xxx(1),xxx(2),... 
%    in the SIGNALS list. An index-free identifier ID matches the entire 
%    set of indexed signals ID(*). 
%
%    This function supports name matching for connect, getIOTransfer, 
%    getLoopTransfer, and the TuningGoal requirements. 

%   Copyright 1986-2016 The MathWorks, Inc.
ID = string(ID);
SignalList = string(SignalList);
if isempty(SignalList)
   MisMatch = struct('ID',ID(1),'iMatch',zeros(0,1));
   iSel = [];  IDSel = [];  return
elseif isempty(ID)
   iSel = zeros(0,1);  IDSel = cell(0,1);  MisMatch = [];  return
end
if nargin<3
   SimulinkFlag = false;
end
ID = ID(:);
[SignalList,iu] = unique(SignalList(:),'stable');

% Separate name and index
IDN = regexprep(ID,'(\(\d+\))?$','');
IDX = extractAfter(ID,strlength(IDN));
SigN = regexprep(SignalList,'(\(\d+\))?$','');
SigX = extractAfter(SignalList,strlength(SigN));
[USigN,iuN] = unique(SigN,'stable');

% Add (1) index to reference names so that 'a(1)' matches single 'a'
ix = find(SigX=="");
SignalList(ix) = SignalList(ix) + "(1)";

% If SimulinkFlag=true, try resolving unmatched IDs into full signal paths
FullID = IDN;
if SimulinkFlag
   iNOT = find(~ismember(IDN,USigN));  % IDs with no exact match
   [FullID(iNOT),MatchData] = ltipack.resolveSignalPath(IDN(iNOT),USigN);
   if ~(isempty(MatchData.ID) || isscalar(MatchData.iMatch))
      % There are unresolved IDs
      iSel = [];  IDSel = [];  
      MisMatch = MatchData;  
      MisMatch.iMatch = iu(iuN(MatchData.iMatch)); % map indices to original list
      return
   end
end

% Match IDs against signal names
nID = numel(ID);
SelectedIndex = cell(nID,1);
SelectedID = cell(nID,1);
for ct=1:nID
   if IDX(ct)==""
      % Look for exact match(es) of <fullID> in list of signal names
      % (<fullID> matches <fullID>(index1),<fullID>(index2),...)
      iM = find(FullID(ct) == SigN);
   else
      % Look for exact match of <fullID>(index) in indexed signal list
      iM = find(FullID(ct) + IDX(ct) == SignalList);
   end
   if isempty(iM)
      MisMatch = struct('ID',ID(ct),'iMatch',zeros(0,1));
      iSel = [];  IDSel = [];  return
   else
      if ~isscalar(iM)
         % Sort by increasing index into vector signal
         iStr = SigX(iM);
         [~,is] = sort(double(extractBetween(iStr,2,strlength(iStr)-1)));
         iM = iM(is);
      end
      SelectedIndex{ct} = iM;
      SelectedID{ct} = IDN(ct) + SigX(iM);  % append indices
   end
end
      
% Make index relative to original list (picks first occurrence of each match)
iSel = iu(cat(1,SelectedIndex{:}));
IDSel = cat(1,SelectedID{:});
MisMatch = [];