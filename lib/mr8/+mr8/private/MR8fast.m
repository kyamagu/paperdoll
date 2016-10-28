function [featvec] = MR8fast(im)
%computes MR8 filterbank using recursive Gaussian filters
%input: intensity image
%output: MR8 feature vector

in = double(im) - mean(mean(im));
in = in ./ sqrt(mean(mean(in .^ 2)));

ims = cell(1, 8);
i=1;

sfac = 1.0;
mulfac = 2.0;

s1 = 3*sfac; s2 = 1*sfac;
for j=0:2,
    for k=0:5,
        phi = (k/6.0)*180.0;
        
        im1 = anigauss(in, s1, s2, phi, 0, 1);
        im2 = anigauss(in, s1, s2, phi, 0, 2);

        % take max of abs response for first order derivative
        % Varma&Zisserman also take abs max of second order...
        im1 = abs(im1);
        %im2 = abs(im2);
        if (k==0)
            maxim1 = im1;
            maxim2 = im2;
        else
            maxim1 = max(maxim1, im1);
            maxim2 = max(maxim2, im2);
        end
    end

    ims{i} = maxim1; i=i+1;
    ims{i} = maxim2; i=i+1;

    % next octave
    s1 = s1*mulfac; s2 = s2*mulfac;
end

sigma = 10.0*sfac;

im1 = anigauss(in, sigma, sigma, 0.0, 2, 0);
im2 = anigauss(in, sigma, sigma, 0.0, 0, 2);
ims{i} = (im1+im2);
i=i+1;
ims{i} = anigauss(in, sigma, sigma);

% just throw away 25 pixel border...(half support of sigma=10 filter)
[R,C] = size(ims{1});
for j=1:i,
    ims{j} = ims{j}(26:R-25,26:C-25);
end

featvec = [ims{8}(:) ims{7}(:) ims{1}(:) ims{3}(:) ims{5}(:) ims{2}(:) ims{4}(:) ims{6}(:)]';
