function [FullID,MatchData] = resolveSignalPath(ID,SignalPaths)
% Resolve identifiers against list of full signal paths.
%
%   ID is a list of signal identifiers, and SIGNALPATHS is a list of
%   signal paths assumed to contain a mix of signal names (from MATLAB 
%   or Simulink) and full Simulink signal paths of the form
%       BlockPath/PortNumber
%       BlockPath/PortNumber[SignalName]
%       BlockPath/PortNumber[BusElement]
%       BlockPath/PortNumber[<BusElement>]  <> added for inherited names
%
%   Assumptions:
%     * ID and SIGNALPATHS ar eof type char, string, or cellstr 
%     * SIGNALPATHS has no duplicated entries
%     * No indices in either ID or SIGNALPATHS
%
%   The second output MATCHDATA contains the identifier and matching
%   indices for the first mismatch or the last match when there are no
%   unresolved identifiers. The outputs are of type STRING.

%   Copyright 1986-2014 The MathWorks, Inc.
ID = string(ID);
SignalPaths = string(SignalPaths);
FullID = ID;
MatchData = struct('ID',[],'iMatch',[]);

% Get tokens
Tokens = regexp(SignalPaths,'(.*)/(\d+)(\[(.*)\])?','tokens','once','forceCellOutput');
iSL = find(~cellfun(@isempty,Tokens));
if isempty(iSL)
   % No strings matches "signal path" template
   return
end
Tokens = cat(1,Tokens{iSL});
BlockPath = Tokens(:,1);
PortNum = Tokens(:,2);
SigName = Tokens(:,3);
SignalPaths = SignalPaths(iSL,:);

% Handle case where Simulink adds brackets around signal name for
% busses with inherited names, e.g. <signame>
% NOTE: Do not modify SIGNALPATHS or FULLID won't match signal paths in caller
ID = regexprep(ID,{'<','>'},'');
SigName = regexprep(SigName,{'<','>','[',']'},'');

% Build templates
BlockPort = BlockPath + "/" + PortNum;
BlockSignal = BlockPath + "/" + SigName;

% Resolve identifiers
nPortNum = strlength(PortNum);
nSigName = strlength(SigName);
for ct=1:numel(ID)
   % Look for matches against SignalName, BlockPath/PortNumber,
   % BlockPath/SignalName, and BlockPath/PortNumber[SignalName]
   % REVISIT: Do more for buses, e.g., "leaf" matches root.node.leaf?
   strID = ID(ct);
   isMatch = (strID==SigName);
   ix = find(strlength(strID)>=nPortNum+2); % min number of char to match
   isMatch(ix) = isMatch(ix) | endsWith(BlockPort(ix),strID);
   ix = find(strlength(strID)>=nSigName+2);
   isMatch(ix) = isMatch(ix) | endsWith(BlockSignal(ix),strID);
   
   % Last resort: try matching against BlockPath making sure the only
   % match is a single port block (BlockPath/1)
   if ~any(isMatch)
      isM = endsWith(BlockPath,strID);
      if all(strcmp(PortNum(isM),'1'))
         % ID only matches BLOCKPATH/1
         isMatch = isM;
      end
   end
   
   % Last last resort: partial string match
   if ~any(isMatch)
      isMatch = contains(SignalPaths,strID);
   end
   
   iMatch = find(isMatch);
   MatchData.ID = strID;
   MatchData.iMatch = iSL(iMatch,:);
   if isscalar(iMatch)
      % Single match
      FullID(ct) = SignalPaths(iMatch);
   else
      % Stop at first unmatched ID
      return
   end
end