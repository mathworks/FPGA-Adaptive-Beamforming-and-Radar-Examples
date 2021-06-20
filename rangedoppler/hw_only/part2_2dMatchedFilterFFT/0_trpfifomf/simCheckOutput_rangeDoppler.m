%% Run this after reading matrix value out
Valid = out.rdValid(:);
rdMat = out.rdMat(:);
rdMat = rdMat(Valid);
iter = floor(length(rdMat)/(N1*N2));



%% check range-doppler with fft-shift
Valid = out.rdValid(:);
rdMat = out.rdMat(:);
rdMat = rdMat(Valid);
% rdMat = rdMat((1:N1*N2)');
 
img = reshape(rdMat(1:N1*N2*iter),N2,N1,iter);
 
for ii = 1:iter
    cubeOutput = fftshift(transpose(img(:,:,ii)),2);
    cubeOutput = 20*log10(abs(cubeOutput));

%     nexttile([1,2]);
    imagesc([-VelMax VelMax],[RngMin RngMax],cubeOutput);
    title('Range-Doppler');
    xlabel('Velocity');
    ylabel('Range');
    colorbar;
end

