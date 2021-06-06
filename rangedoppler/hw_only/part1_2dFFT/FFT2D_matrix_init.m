%% Model setup

nRows = 64;
nCols = 64;

% create an input matrix 
rowWindowFun = taylorwin(nRows,10,-35);%.*(-1.^(1:nRows)'); 
% window function for the 2nd FFT
columnWindowFun = taylorwin(nCols,10,-40);%.*(-1.^(1:nCols)');

DTWindowFun = numerictype(1,16+4,13+4);
DTsig_in = numerictype(1,16,12);
DToutput = numerictype(1,32,22);

rVals = [12  50  25];
cVals = [15  25   60];
Avals = [1   0.5*1i  -0.1];
noiseSig = 0.1;
iqRaw = noiseSig/sqrt(2)*(randn(nRows,nCols)+1i*randn(nRows,nCols));
for n = 1:length(rVals)
    iqRaw = iqRaw+Avals(n)*exp(2*pi*1i*rVals(n)*(0:(nRows-1))'/nRows)*exp(2*pi*1i*cVals(n)*(0:(nCols-1))/nCols);
end

MatrixInput = iqRaw;

%% compute expected output
matrixInFixedPoint = fi(MatrixInput,DTsig_in);
matrixTaperedRow = matrixInFixedPoint.*repmat(fi(rowWindowFun(:),DTWindowFun),1,nCols);
matrixTaperAndFFT = cast(fft(double(matrixTaperedRow),[],1)/nRows,'like',matrixTaperedRow(1));
matrixTaperFFTandTranspose = fi(matrixTaperAndFFT,1,32,25).';
matrix2DFFT = fi(fft(double(matrixTaperFFTandTranspose.*repmat(fi(columnWindowFun(:),DTWindowFun),1,nRows)),[],1)/nCols,DToutput);
MatrixOutput = matrix2DFFT;