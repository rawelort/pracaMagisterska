%%%% model symulacyjny kompresji danych %%%%
%% inicjalizacja parametrów
close all
clc
clear all
format long g % eng
%_ parametry sta³e
TEST_DATA_BITWIDTH = 16; % szerokoœæ bitowa próbek testowych (sign int)
TEST_VECTOR_LENGTH = 307200; % iloœæ próbek w wektorze danych testowych
%_ parametry testowane 
blockSize = 1024; % rozmiar bloków danych do skalowania
Qs = 16; % szerokoœæ bitowa wspó³czynika skalowania
Qq = 12; % szerokoœæ bitowa kwantyzacji
% Szerokoœæ bitowa wspó³czynnika skalowania musi byæ wiêksza od szerokoœci bitowej kwantyzacji!
%_ Zmienne pomocnocze zale¿ne od testowanych parametrów
NUM_OF_BLOCKS = TEST_VECTOR_LENGTH/blockSize;
%_ Obliczenie wspó³czynnika kompresji
IN_DATA_SIZE = TEST_VECTOR_LENGTH*TEST_DATA_BITWIDTH;
OUT_DATA_SIZE = NUM_OF_BLOCKS*Qs + TEST_VECTOR_LENGTH*Qq;
DATA_COMPRESSION_RATE = IN_DATA_SIZE/OUT_DATA_SIZE;

%% inicjalizacja wektora testowego
%& wektor LTE E_TM_3_1 20MHz
inFile = fopen('LteTestVector.txt','r');
samplesFromFile = fscanf(inFile,'%f	%f',[2,TEST_VECTOR_LENGTH]);
readDataVector = samplesFromFile';
testVector = readDataVector(:,1) + 1i*readDataVector(:,2);
%randomDataVector = fscanf(inFile,'%f %f',[307200,2]);
%& wektory zespolone
%randomDataVector = randn(1,TEST_VECTOR_LENGTH) + 1i.*randn(1,TEST_VECTOR_LENGTH); % wektor losowych danych
            % zespolonych o rozk³adzie normalnym
%randomDataVector = (1 + 1i).*randn(1,TEST_VECTOR_LENGTH); % wektor losowych danych zespolonych o rozk³adzie
            % normalnym, o równych sobie wspó³czynnikach rzeczywistych i urojonych
%randomDataVector = (1 + 1i).*linspace(1,TEST_VECTOR_LENGTH,TEST_VECTOR_LENGTH);
%_ skalowanie wektora testowego do wartoœci nie wiêkszych ni¿ 2^TEST_DATA_BITWIDTH
%maxRandomSample = max(max(abs(real(randomDataVector)),abs(imag(randomDataVector))));
%scaledRandomData = randomDataVector.*((2^(TEST_DATA_BITWIDTH-1))/maxRandomSample);
%_ konwersja wspó³czynników na integer
%testVector = int16(scaledRandomData);
%& wektory rzeczywiste
%testVector = randi([-(2^(TEST_DATA_BITWIDTH-1)) (2^(TEST_DATA_BITWIDTH-1))],1,TEST_VECTOR_LENGTH); % wektor
            % losowych integerów nie wiekszych ni¿ 2^TEST_DATA_BITWIDTH
%testVector = (rand(1,TEST_VECTOR_LENGTH)-0.5).*(2^TEST_DATA_BITWIDTH-1); %wektor losowych danych o wartoœci
            % nie wiêkszej ni¿ 2^TEST_DATA_BITWIDTH
%testVector = linspace(1,(2^TEST_DATA_BITWIDTH-1),TEST_VECTOR_LENGTH); % wektor wartoœci stale rosnacych

%% Pêtle automatyzuj¹ce symulacjê
minQs = 8;
maxQs = TEST_DATA_BITWIDTH;
minQq = 8;
maxQq = TEST_DATA_BITWIDTH;
minBlockSize = 64;
maxBlockSize = TEST_VECTOR_LENGTH;
outFile = fopen('simResults.ods','w');
fprintf(outFile,'Block size, Scaling factor bitwidth, Quantisation bitwidth, Mean EVM, Compression rate\n');
countDots = 0;
tic
for blockSize = minBlockSize:maxBlockSize
    if mod(TEST_VECTOR_LENGTH,blockSize) == 0
        for Qs = minQs:maxQs
           for Qq = minQq:maxQq
              if (Qq > Qs)
                  continue
              else
                  %_ Zmienne pomocnocze zale¿ne od testowanych parametrów
                  fprintf('*')
                  if countDots < 100
                    countDots = countDots + 1;
                  else
                     countDots = 0;
                     fprintf('\n')
                  end
                  NUM_OF_BLOCKS = TEST_VECTOR_LENGTH/blockSize;
                  %_ Obliczenie wspó³czynnika kompresji
                  IN_DATA_SIZE = TEST_VECTOR_LENGTH*TEST_DATA_BITWIDTH;
                  OUT_DATA_SIZE = NUM_OF_BLOCKS*Qs + TEST_VECTOR_LENGTH*Qq;
                  DATA_COMPRESSION_RATE = IN_DATA_SIZE/OUT_DATA_SIZE;

%% podzia³ na bloki
% disp('-------')
% disp('dzielenie na bloki')
% disp('-------')
numOfReadSamples = 1;
readBlock = zeros(NUM_OF_BLOCKS,blockSize);
for currentBlock = 1:(NUM_OF_BLOCKS)
    while numOfReadSamples <= blockSize
        readBlock(currentBlock,numOfReadSamples) = testVector((currentBlock-1)*blockSize + numOfReadSamples);
        numOfReadSamples = numOfReadSamples + 1;
    end
    %disp(readBlock(currentBlock,:));
    numOfReadSamples = 1;
end

%% skalowanie
% disp('-------')
% disp('skalowanie')
% disp('-------')
scaledBlockData = zeros(NUM_OF_BLOCKS,blockSize);
maxSample = 0;
scalingFactor = ones(NUM_OF_BLOCKS,1);
for currentBlock = 1:(NUM_OF_BLOCKS)
    %_ utworzenie wektorów wspó³czynników rzeczywistych i urojonych w bloku
    realCoefficients = real(readBlock(currentBlock,:));
    imagCoefficients = imag(readBlock(currentBlock,:));
    %_ wyci¹gniêcie wartoœci bezwzglêdnej z wspó³czynników 
    absRealCoeffs = abs(realCoefficients);
    absImagCoeffs = abs(imagCoefficients);
    %_ znalezienie najwiêkszego wspó³czynnika
    %_ maxSample - A(k), wartoœæ bezwzglêdna najwiêkszego wspó³czynnik poœród próbek w bloku
    maxSample = max(max(absRealCoeffs,absImagCoeffs)); % maxSample dla zespolonego wektora testowego
    %maxSample = max(abs(readBlock(currentBlock,:))); % maxSample dla rzeczywistego wektora testowego
    %_ scalingFactor - S(k), scaling factor ograniczony przez szerokoœæ bitow¹ podczas wysy³ania
    %scalar = ((2^Qs)-1)/maxSample;
    %scalar = ((2^Qs)-1)/max(abs(readBlock(currentBlock,:)));
    %_ obliczanie wspó³czynnka skalowania
    if ceil(maxSample) > ((2^Qs)-1)
        scalingFactor(currentBlock) = ((2^Qs)-1);
    else
        scalingFactor(currentBlock) = ceil(maxSample);
    end
    %fprintf('Blok %d, Wspólczynnik skalowania: %d,\nPocz¹tkowe dane:   ',currentBlock,scalingFactor(currentBlock));
    %disp(readBlock(currentBlock,:));
    %fprintf('Blok %d, Wspólczynnik skalowania: %d\n',currentBlock,scalingFactor(currentBlock));
    %scaledBlockData(currentBlock,1:blockSize) = (testData(1+(currentBlock-1)*blockSize:(currentBlock*blockSize)).*((2^Qq)-1))./scalingFactor(currentBlock);
    %_ mno¿enie próbek zespolonych przez wspó³czynnik skalowania (w³aœciwa czêœæ procesu skalowania)
    %fprintf('\nPrzeskalowane dane:');
    scalingFraction = (2^(Qq-1)-1)/scalingFactor(currentBlock);
    scaledBlockData(currentBlock,:) = readBlock(currentBlock,:)*scalingFraction;
    %disp(scaledBlockData(currentBlock,:));
end

%% kwantyzacja
%quant = QUANTIZER('Roundmode',round,'Overflowmode',saturate,'Format',[wordlength exponentlength]);
%quantizedBlockData = scaledBlockData;
quantizedBlockData = zeros(NUM_OF_BLOCKS,blockSize);
reQuantizedBlockData = zeros(NUM_OF_BLOCKS,blockSize);
imQuantizedBlockData = zeros(NUM_OF_BLOCKS,blockSize);
reQuantizationIndexes = zeros(NUM_OF_BLOCKS,blockSize);
imQuantizationIndexes = zeros(NUM_OF_BLOCKS,blockSize);
quantizationPoints = -(2^(TEST_DATA_BITWIDTH-1)):(2^(TEST_DATA_BITWIDTH-Qq)):(2^(TEST_DATA_BITWIDTH-1));
for currentBlock = 1:(NUM_OF_BLOCKS)
    reQuantizationIndexes(currentBlock,:) = quantiz(real(scaledBlockData(currentBlock,:)),quantizationPoints);
    imQuantizationIndexes(currentBlock,:) = quantiz(imag(scaledBlockData(currentBlock,:)),quantizationPoints);
    %sample=1;
    for iterator=1:blockSize
        j=reQuantizationIndexes(currentBlock,iterator);
        reQuantizedBlockData(currentBlock,iterator)=quantizationPoints(j+1);
        %sample = sample + 1;
    end
    for iterator = 1:blockSize
        j=imQuantizationIndexes(currentBlock,iterator);
        imQuantizedBlockData(currentBlock,iterator)=quantizationPoints(j+1);
        %sample = sample + 1;
    end
    quantizedBlockData = reQuantizedBlockData + 1j.*imQuantizedBlockData;
    %fprintf('Quantized data for block %d:\n',currentBlock);
    %disp(quantizedBlockData(currentBlock,:));
end

%% odtwarzanie danych
% disp('-------')
% disp('odtwarzanie')
% disp('-------')
rescaledBlockData = zeros(NUM_OF_BLOCKS,blockSize);
for currentBlock = 1:NUM_OF_BLOCKS
    %scalar = ((2^Qs)-1)/max(abs(readBlock(currentBlock,:)));
%     fprintf('Blok %d, Wspólczynnik skalowania: %d\nOdtworzone dane:\n',currentBlock,scalingFactor(currentBlock));
    rescaledBlockData(currentBlock,1:blockSize) = (quantizedBlockData(currentBlock,:).*scalingFactor(currentBlock))./((2^(Qq-1))-1);
    %disp(rescaledBlockData(currentBlock,:));
end

%% porównanie danych Ÿród³owych i odtworzonych
%disp('-------')
%disp('EVM')
%disp('-------')
EVM = ones(1,NUM_OF_BLOCKS);
for currentBlock = 1:NUM_OF_BLOCKS
    EVM(currentBlock) = sqrt( sum( abs(rescaledBlockData(currentBlock,:)-readBlock(currentBlock,:)).^2 )/sum( abs(readBlock(currentBlock,:)).^2 ) )*100;
end
%disp(EVM)
%disp('Mean EVM')
%disp(mean(EVM))
%disp('Compression rate')
%disp(DATA_COMPRESSION_RATE)
                  fprintf(outFile,'%d,%d,%d,%f,%f\n',blockSize,Qs,Qq,mean(EVM),DATA_COMPRESSION_RATE);
              end
           end
        end
    end
end
fprintf('\n')
fclose(outFile);
overallTime = toc
% disp('-------')
% disp('koniec')
% disp('-------')
