function F=makeSfilters
% Returns the S filter bank of size 49x49x13 in F. To convolve an
% image I with the filter bank you can either use the matlab function
% conv2, i.e. responses(:,:,i)=conv2(I,F(:,:,i),'valid'), or use the
% Fourier transform.

  NF=13;                        % Number of filters
  SUP=49;                       % Support of largest filter (must be odd)
  F=zeros(SUP,SUP,NF);
  
  F(:,:,1)=makefilter(SUP,2,1);
  F(:,:,2)=makefilter(SUP,4,1);
  F(:,:,3)=makefilter(SUP,4,2);
  F(:,:,4)=makefilter(SUP,6,1);
  F(:,:,5)=makefilter(SUP,6,2);
  F(:,:,6)=makefilter(SUP,6,3);
  F(:,:,7)=makefilter(SUP,8,1);
  F(:,:,8)=makefilter(SUP,8,2);
  F(:,:,9)=makefilter(SUP,8,3);
  F(:,:,10)=makefilter(SUP,10,1);
  F(:,:,11)=makefilter(SUP,10,2);
  F(:,:,12)=makefilter(SUP,10,3);
  F(:,:,13)=makefilter(SUP,10,4);
return

function f=makefilter(sup,sigma,tau)
  hsup=(sup-1)/2;
  [x,y]=meshgrid([-hsup:hsup]);
  r=(x.*x+y.*y).^0.5;
  f=cos(r*(pi*tau/sigma)).*exp(-(r.*r)/(2*sigma*sigma));
  f=f-mean(f(:));          % Pre-processing: zero mean
  f=f/sum(abs(f(:)));      % Pre-processing: L_{1} normalise
return
