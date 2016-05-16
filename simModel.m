%%%% model symulacyjny kompresji danych %%%%
%% inicjalizacja parametr�w
close all
clc
clear all
format short% eng
% parametry sta�e
TEST_DATA_BITWIDTH = 16; % szeroko�� bitowa pr�bek testowych (sign int)
TEST_VECTOR_LENGTH = 32; % ilo�� pr�bek w wektorze danych testowych
% parametry testowane
blockSize = 1; % rozmiar blok�w danych do skalowania
Qs = 16; % szeroko�� bitowa wsp�czynika skalowania
Qq = 16; % szeroko�� bitowa kwantyzacji

%% inicjalizacja wektora danych testowych
testData = randi([-(2^(TEST_DATA_BITWIDTH-1)) (2^(TEST_DATA_BITWIDTH-1))],1,TEST_VECTOR_LENGTH); % wektor losowych integer�w nie wiekszych ni� 2^TEST_DATA_BITWIDTH
%testData = (rand(1,TEST_VECTOR_LENGTH)-0.5).*(2^TEST_DATA_BITWIDTH-1); %wektor losowych danych o warto�ci nie wi�kszej ni� 2^TEST_DATA_BITWIDTH
%testData = linspace(1,(2^TEST_DATA_BITWIDTH-1),TEST_VECTOR_LENGTH); % wektor warto�ci stale rosnacych
numOfReadSamples = 1;
readBlock = zeros(TEST_VECTOR_LENGTH/blockSize,blockSize);

%% podzia� na bloki
% disp('-------')
% disp('dzielenie na bloki')
% disp('-------')
for i = 1:(TEST_VECTOR_LENGTH/blockSize)
    while numOfReadSamples <= blockSize
        readBlock(i,numOfReadSamples) = testData((i-1)*blockSize + numOfReadSamples);
        numOfReadSamples = numOfReadSamples + 1;
    end
    %disp(readBlock(i,:));
    numOfReadSamples = 1;
end

%% skalowanie
% disp('-------')
% disp('skalowanie')
% disp('-------')
scaledBlockData = zeros(TEST_VECTOR_LENGTH/blockSize,blockSize);
maxSample = 0;
scalingFactor = ones(TEST_VECTOR_LENGTH/blockSize,blockSize);
for i = 1:(TEST_VECTOR_LENGTH/blockSize)
    % maxSample - A(k), pr�bka o najwi�kszej warto�ci bezwzgl�dnej w bloku
    maxSample = max(abs(readBlock(i,:)));
    % scalingFactor - S(k), scaling factor ograniczony przez szeroko�� bitow� podczas wysy�ania
    %scalar = ((2^Qs)-1)/maxSample;
    %scalar = ((2^Qs)-1)/max(abs(readBlock(i,:)));
    if ceil(maxSample) > ((2^Qs)-1)
        scalingFactor(i) = ((2^Qs)-1);
    else
        scalingFactor(i) = ceil(maxSample);
    end
    fprintf('Blok %d, Wsp�lczynnik skalowania: %d\nPrzeskalowane dane:\n',i,scalingFactor(i));
    %scaledBlockData(i,1:blockSize) = (testData(1+(i-1)*blockSize:(i*blockSize)).*((2^Qq)-1))./scalingFactor(i);
    scaledBlockData(i,:) = readBlock(i,:).*(2^(Qq-1)-1)./scalingFactor(i);
    %disp(scaledBlockData(i,:));
end

%% kwantyzacja
%quant = QUANTIZER('Roundmode',round,'Overflowmode',saturate,'Format',[wordlength exponentlength]);
%quantizedBlockData = scaledBlockData;
quantizedBlockData = zeros(TEST_VECTOR_LENGTH/blockSize,blockSize);
quantizationIndexes = zeros(TEST_VECTOR_LENGTH/blockSize,blockSize);
quantizationPoints = -(2^(Qq-1)):(2^(Qq-1));
for i = 1:(TEST_VECTOR_LENGTH/blockSize)
    quantizationIndexes(i,:) = quantiz(scaledBlockData(i,:),quantizationPoints);
    %sample=1;
    for j=quantizationIndexes(i)
        quantizedBlockData(i,:)=quantizationPoints(j+1);
        %sample = sample + 1;
    end
    fprintf('Quantized data for i=%d:\n',i);
    disp(quantizedBlockData(i,:));
end

%% odtwarzanie danych
% disp('-------')
% disp('odtwarzanie')
% disp('-------')
rescaledBlockData = zeros(TEST_VECTOR_LENGTH/blockSize,blockSize);
for i = 1:(TEST_VECTOR_LENGTH/blockSize)
    %scalar = ((2^Qs)-1)/max(abs(readBlock(i,:)));
%     fprintf('Blok %d, Wsp�lczynnik skalowania: %d\nOdtworzone dane:\n',i,scalingFactor(i));
    rescaledBlockData(i,1:blockSize) = (quantizedBlockData(i,:).*scalingFactor(i))./((2^(Qq-1))-1);
    %disp(rescaledBlockData(i,:));
end

%% por�wnanie danych �r�d�owych i odtworzonych
disp('-------')
disp('EVM')
disp('-------')
EVM = ones(1,TEST_VECTOR_LENGTH/blockSize);
for i = 1:(TEST_VECTOR_LENGTH/blockSize)
    EVM(i) = sqrt( sum( (readBlock(i,:)-rescaledBlockData(i,:)).^2 )/sum( readBlock(i,:).^2 ) )*100;
end
disp(EVM)
disp('Mean EVM')
disp(mean(EVM))
% disp('-------')
% disp('koniec')
% disp('-------')