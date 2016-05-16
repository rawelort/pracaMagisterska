%%%% model symulacyjny kompresji danych %%%%
%% inicjalizacja parametrów
close all
clc
clear all
format short% eng
% parametry sta³e
TEST_DATA_BITWIDTH = 16; % szerokoœæ bitowa próbek testowych (sign int)
TEST_VECTOR_LENGTH = 32; % iloœæ próbek w wektorze danych testowych
% parametry testowane 
blockSize = 1; % rozmiar bloków danych do skalowania
Qs = 16; % szerokoœæ bitowa wspó³czynika skalowania
Qq = 16; % szerokoœæ bitowa kwantyzacji
% Zmienne pomocnocze zale¿ne od testowanych parametrów
NUM_OF_BLOCKS = TEST_VECTOR_LENGTH/blockSize;

%% inicjalizacja wektora danych testowych
testData = randi([-(2^(TEST_DATA_BITWIDTH-1)) (2^(TEST_DATA_BITWIDTH-1))],1,TEST_VECTOR_LENGTH); % wektor losowych integerów nie wiekszych ni¿ 2^TEST_DATA_BITWIDTH
%testData = (rand(1,TEST_VECTOR_LENGTH)-0.5).*(2^TEST_DATA_BITWIDTH-1); %wektor losowych danych o wartoœci nie wiêkszej ni¿ 2^TEST_DATA_BITWIDTH
%testData = linspace(1,(2^TEST_DATA_BITWIDTH-1),TEST_VECTOR_LENGTH); % wektor wartoœci stale rosnacych
numOfReadSamples = 1;
readBlock = zeros(NUM_OF_BLOCKS,blockSize);

%% podzia³ na bloki
% disp('-------')
% disp('dzielenie na bloki')
% disp('-------')
for currentBlock = 1:(NUM_OF_BLOCKS)
    while numOfReadSamples <= blockSize
        readBlock(currentBlock,numOfReadSamples) = testData((currentBlock-1)*blockSize + numOfReadSamples);
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
scalingFactor = ones(NUM_OF_BLOCKS,blockSize);
for currentBlock = 1:(NUM_OF_BLOCKS)
    % maxSample - A(k), próbka o najwiêkszej wartoœci bezwzglêdnej w bloku
    maxSample = max(abs(readBlock(currentBlock,:)));
    % scalingFactor - S(k), scaling factor ograniczony przez szerokoœæ bitow¹ podczas wysy³ania
    %scalar = ((2^Qs)-1)/maxSample;
    %scalar = ((2^Qs)-1)/max(abs(readBlock(currentBlock,:)));
    if ceil(maxSample) > ((2^Qs)-1)
        scalingFactor(currentBlock) = ((2^Qs)-1);
    else
        scalingFactor(currentBlock) = ceil(maxSample);
    end
    fprintf('Blok %d, Wspólczynnik skalowania: %d\nPrzeskalowane dane:\n',currentBlock,scalingFactor(currentBlock));
    %scaledBlockData(currentBlock,1:blockSize) = (testData(1+(currentBlock-1)*blockSize:(currentBlock*blockSize)).*((2^Qq)-1))./scalingFactor(currentBlock);
    scaledBlockData(currentBlock,:) = readBlock(currentBlock,:).*(2^(Qq-1)-1)./scalingFactor(currentBlock);
    %disp(scaledBlockData(currentBlock,:));
end

%% kwantyzacja
%quant = QUANTIZER('Roundmode',round,'Overflowmode',saturate,'Format',[wordlength exponentlength]);
%quantizedBlockData = scaledBlockData;
quantizedBlockData = zeros(NUM_OF_BLOCKS,blockSize);
quantizationIndexes = zeros(NUM_OF_BLOCKS,blockSize);
quantizationPoints = -(2^(Qq-1)):(2^(Qq-1));
for currentBlock = 1:(NUM_OF_BLOCKS)
    quantizationIndexes(currentBlock,:) = quantiz(scaledBlockData(currentBlock,:),quantizationPoints);
    %sample=1;
    for j=quantizationIndexes(currentBlock)
        quantizedBlockData(currentBlock,:)=quantizationPoints(j+1);
        %sample = sample + 1;
    end
    fprintf('Quantized data for block %d:\n',currentBlock);
    disp(quantizedBlockData(currentBlock,:));
end

%% odtwarzanie danych
% disp('-------')
% disp('odtwarzanie')
% disp('-------')
rescaledBlockData = zeros(NUM_OF_BLOCKS,blockSize);
for currentBlock = 1:(NUM_OF_BLOCKS)
    %scalar = ((2^Qs)-1)/max(abs(readBlock(currentBlock,:)));
%     fprintf('Blok %d, Wspólczynnik skalowania: %d\nOdtworzone dane:\n',currentBlock,scalingFactor(currentBlock));
    rescaledBlockData(currentBlock,1:blockSize) = (quantizedBlockData(currentBlock,:).*scalingFactor(currentBlock))./((2^(Qq-1))-1);
    %disp(rescaledBlockData(currentBlock,:));
end

%% porównanie danych Ÿród³owych i odtworzonych
disp('-------')
disp('EVM')
disp('-------')
EVM = ones(1,NUM_OF_BLOCKS);
for currentBlock = 1:(NUM_OF_BLOCKS)
    EVM(currentBlock) = sqrt( sum( (readBlock(currentBlock,:)-rescaledBlockData(currentBlock,:)).^2 )/sum( readBlock(currentBlock,:).^2 ) )*100;
end
disp(EVM)
disp('Mean EVM')
disp(mean(EVM))
% disp('-------')
% disp('koniec')
% disp('-------')