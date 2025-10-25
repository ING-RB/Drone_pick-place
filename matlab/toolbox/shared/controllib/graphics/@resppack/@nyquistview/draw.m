function draw(this, Data,~)
%DRAW  Draws Nyquist response curves.
%
%  DRAW(VIEW,DATA) maps the response data in DATA to the curves in VIEW.

%  Copyright 1986-2021 The MathWorks, Inc.
Curves = this.Curves;
if isempty(Data.Response)
   set(Curves(:), 'XData', [], 'YData', [])
else
   [Ny, Nu] = size(Curves);
   % Prepare data
   % Note: Data object only stores w>=0 for real systems
   F = Data.Frequency;
   H = Data.Response;
   if Data.Real
      % Only storing positive frequencies. Populate w<=0 by symmetry using
      % w=NaN as separator
      if this.ShowFullContour
         F = [-flipud(F) ; NaN ; F];
         cNaN = complex(NaN(1,Ny,Nu),NaN(1,Ny,Nu));
         H = cat(1,conj(flipud(H)),cNaN,H);
      end
   else
      in = find(F<=0);
      ip = find(F>=0);
      if this.ShowFullContour
         % Insert NaN separator to handle possible singularity at w=0
         F = [F(in,:) ; NaN ; F(ip,:)];
         cNaN = complex(NaN(1,Ny,Nu),NaN(1,Ny,Nu));
         H = cat(1,H(in,:,:),cNaN,H(ip,:,:));
      else
         % Show only w>=0
         F = F(ip,:);  H = H(ip,:,:);
      end
   end
   % Plot data
   for ct=1:Ny*Nu
      set(double(Curves(ct)), 'XData', real(H(:,ct)), 'YData', imag(H(:,ct)));
   end
   % Store frequency vector corresponding to plotted data
   this.Frequency = F;
end