function magphaseresp(this, r, frStruct)
%MAGPHASERESP  Updates magnitude and phase data of @magphasedata objects.
% frStruct: A cell array of structs, one for each I/O signal.

%  Copyright 2013-2016 The MathWorks, Inc.

N = numel(frStruct);
mag = cell(1,N); phase = cell(1,N); w = cell(1,N); Ts = cell(1,N);
Focus = [Inf -Inf];
d = r.Data;
for ct = 1:N
   % Each signal is an @frd with 1 or more outputs, 1 input
   %sig = getPlotLTIData(frStruct{ct});
   sig = frStruct{ct};
   TimeUnits = sig.TimeUnit;
   Fac = funitconv(sig.FrequencyUnit,'rad/s',TimeUnits);
   [mag_,phase_,w_,FocusInfo] = localfreqresp(sig);
   phase_(~isfinite(mag_) | mag_==0) = NaN;  % phase of 0 or Inf undefined
   w{ct} = w_*Fac;
   mag{ct} = mag_;
   phase{ct} = phase_;
   Focus_ = FocusInfo.Focus*Fac;
   Focus = [min(Focus(1), min(Focus_)), max(Focus(2), max(Focus_))];
   Ts{ct} = sig.Ts*tunitconv(TimeUnits,'seconds');
end

if Focus(1)==0 && strcmp(r.View.AxesGrid.XScale{1},'log')
   I = cellfun(@(x)find(x>0,1),w,'uni',0);
   Ie = cellfun(@(x)isempty(x),I);
   I(Ie) = {inf}; I = cell2mat(I);
   [~,J] = min(I);
   if ~isinf(I(J))
      Focus(1) = w{J}(I(J));
   end
end

d.Focus = Focus;
d.Frequency = w;
d.Magnitude = mag;
d.Phase = phase;
d.Ts = Ts;
d.FreqUnits = 'rad/s';
d.IOSize = this.IOSize;
d.SoftFocus = false;
end

%--------------------------------------------------------------------------
function [mag,ph,w,FocusInfo] = localfreqresp(D)

w = D.Frequency;
%w = w(w>=0,:);
Focus = [w(find(w>=0,1)), max(w)];
h = D.Response; % N-by-SigDim matrix

mag = abs(h);
ph = angle(h);
ph(~isfinite(mag)) = NaN;
ph = unwrap(ph,[],1);

[w,is] = sort(w);
mag = mag(is,:);
ph = ph(is,:);

FocusInfo = localSetFreqFocus(Focus);

end

%--------------------------------------------------------------------------
function FocusInfo = localSetFreqFocus(focus)
% Creates focus information consumed by frequency response functions.

if focus(1)>focus(2)
   % No data in [w(1),w(end)]: use arbitrary focus
   focus = [.1 1];
   soft = true;
else
   if focus(1)==focus(2)
      % single data point: focus around it
      df = 10^.5;
      focus = [focus(1)/df,focus(1)*df];
   end
   soft = false;
end
FocusInfo = struct('Focus',focus,'DynRange',focus,'Soft',soft);
end
