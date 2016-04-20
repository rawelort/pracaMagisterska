%%%% model symulacyjny kompresji danych
%% inicjalizacja parametr�w
close all
clc
clear all
format long eng

TEST_VECTOR_SIZE = 32; % rozmiar wektora danych testowych
BLOCK_SIZE = 4; % rozmiar blok�w danych do skalowania
Qs = 5; % szeroko�� bitowa danych wej�ciowych
Qq = 3; % szeroko�� bitowa danych przeskalowanych
%% inicjalizacja wektora danych
testVector = rand(1,TEST_VECTOR_SIZE).*(2^Qs-1); % wektor losowych danych o warto�ci nie wi�kszej ni� najwi�ksza pr�bka IQ
numOfReadSamples = 1;
readBlock = zeros(TEST_VECTOR_SIZE/BLOCK_SIZE,BLOCK_SIZE);
%% dzielenie na bloki
disp('-------')
disp('dzielenie na bloki')
disp('-------')
for i = 1:(TEST_VECTOR_SIZE/BLOCK_SIZE)
    while numOfReadSamples <= BLOCK_SIZE
        readBlock(i,numOfReadSamples) = testVector((i-1)*BLOCK_SIZE + numOfReadSamples);
        numOfReadSamples = numOfReadSamples + 1;
    end
    disp(readBlock(i,:));
    numOfReadSamples = 1;
end
%% skalowanie
disp('-------')
disp('skalowanie')
disp('-------')
scaledVector = zeros(TEST_VECTOR_SIZE/BLOCK_SIZE,BLOCK_SIZE);
for i = 1:(TEST_VECTOR_SIZE/BLOCK_SIZE)
    scalar = ((2^Qs)-1)/max(abs(readBlock(i,:)));
    fprintf('Blok %d, Wsp�lczynnik skalowania: %d\nPrzeskalowane dane:\n',i,scalar);
    scaledVector(i,1:BLOCK_SIZE) = testVector(1+(i-1)*BLOCK_SIZE:(i*BLOCK_SIZE))./scalar;
    disp(scaledVector(i,:));
end
%% odtwarzanie danych
disp('-------')
disp('odtwarzanie')
disp('-------')
reScaledVector = zeros(TEST_VECTOR_SIZE/BLOCK_SIZE,BLOCK_SIZE);
for i = 1:(TEST_VECTOR_SIZE/BLOCK_SIZE)
    scalar = ((2^Qs)-1)/max(abs(readBlock(i,:)));
    fprintf('Blok %d, Wsp�lczynnik skalowania: %d\nOdtworzone dane:\n',i,scalar);
    reScaledVector(i,1:BLOCK_SIZE) = scaledVector(i,:).*scalar;
    disp(reScaledVector(i,:));
end
%% por�wnanie danych �r�d�owych i odtworzonych
disp('-------')
disp('jako�� odtworzenia')
disp('-------')
endDelta = (reScaledVector./readBlock)*100;
disp(endDelta)
disp('-------')
disp('koniec')
disp('-------')