 %% Run this after reading matrix value out

Valid = out.rdValid(:);
rdMat = out.rdMat(:);

rdMat = rdMat(Valid);

iter = length(rdMat)/(nRows*nCols);

for ii = 1:iter
    range = (1:nRows*nCols) + (ii-1)*(nRows*nCols);
    rdOut = reshape(rdMat(range),[nCols,nRows]);
    compare = MatrixOutput;
    disp(['Iteration ' num2str(ii) ', max diff = ' num2str(max(abs(rdOut(:)-compare(:))))]);
end

%% check intermediate results
input_matrix=getLogged(out.logsout,'input_matrix');
input_valid=getLogged(out.logsout,'<mm2s_tvalid>');
line_start=getLogged(out.logsout,'line_start_marker');
input_matrix = input_matrix(input_valid);
line_start = line_start(input_valid);

% take the 1st nRows*nCols - looks ok
input_matrix = input_matrix(1:nRows*nCols);
disp(['Input check: ' num2str(max(abs(input_matrix - matrixInFixedPoint(:))))]);
line_start = reshape(line_start(1:nRows*nCols),nRows,nCols);

tiledlayout('flow')
nexttile; imagesc(line_start); title('line start marker')

fft1_out=getLogged(out.logsout,'fft1_out');
fft1_valid=getLogged(out.logsout,'mm2s_tvalid');
fft1_out = fft1_out(fft1_valid);

fft1_out = fft1_out((1:nRows*nCols)');
disp(['Taper&FFT1 check: ' num2str(max(abs(fft1_out-matrixTaperAndFFT(:))))]);
nexttile; imagesc(db(double(matrixTaperAndFFT))); title('Taper&FFT1 - expected'); colorbar;
nexttile; imagesc(db(double(reshape(fft1_out,nRows,nCols)))); title('Taper&FFT1 - actual'); colorbar;

input_matrix_2 = getLogged(out.logsout,'input_matrix_2');
input_valid_2=getLogged(out.logsout,'input_valid_2');
input_matrix_2 = input_matrix_2(input_valid_2);

input_matrix_2 = input_matrix_2(1:nRows*nCols);
nexttile; imagesc(db(double(reshape(input_matrix_2,nCols,nRows)))); title('Taper,FFT1,Transpose')

%%
Valid = out.rdValid(:);
rdMat = out.rdMat(:);
rdMat = rdMat(Valid);
rdMat = rdMat((1:nRows*nCols)');
disp(['FFT2D check: ' num2str(max(abs(rdMat-reshape(matrix2DFFT,nRows*nCols,1))))]);
nexttile; imagesc(db(double(matrix2DFFT))); title('2DFFT&transpose - expected'); colorbar;
nexttile; imagesc(db(double(reshape(rdMat,nCols,nRows)))); title('2DFFT &transpose - actual'); colorbar;
