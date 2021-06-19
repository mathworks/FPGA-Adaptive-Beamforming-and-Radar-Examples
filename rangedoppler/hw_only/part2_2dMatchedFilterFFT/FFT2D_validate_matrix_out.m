%% Run this after reading matrix value out
Valid = out.rdValid(:);
rdMat = out.rdMat(:);
rdMat = rdMat(Valid);
iter = length(rdMat)/(nRows*nCols);


%% check intermediate results of transpose
fft1_out=getLogged(out.logsout,'fft1_out');
fft1_valid=getLogged(out.logsout,'mm2s_tvalid');
fft1_out = fft1_out(fft1_valid);
fft1_out = fft1_out((1:nRows*nCols)');

input_matrix_2 = getLogged(out.logsout,'input_matrix_2');
input_valid_2=getLogged(out.logsout,'input_valid_2');
input_matrix_2 = input_matrix_2(input_valid_2);

input_matrix_2 = input_matrix_2(1:nRows*nCols);
tiledlayout('flow')

nexttile; imagesc(db(double(reshape(fft1_out,nRows,nCols)))); title('Matched Filter - Before transposed'); colorbar;

nexttile; imagesc(db(double(reshape(input_matrix_2,nCols,nRows)))); title('Matched Filter - After Transposed')



%% check range-doppler with fft-shift
Valid = out.rdValid(:);
rdMat = out.rdMat(:);
rdMat = rdMat(Valid);
rdMat = rdMat((1:nRows*nCols)');
 
img = reshape(rdMat,nCols,nRows);
 
cubeOutput = fftshift(transpose(img),2);
cubeOutput = 20*log10(abs(cubeOutput));

nexttile([1,2]);
imagesc([-VelMax VelMax],[RngMin RngMax],cubeOutput);
title('Range-Doppler');
xlabel('Velocity');
ylabel('Range');
colorbar;


