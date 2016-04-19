%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
close all
clc
clear all
 
 
bit_width_with_sign = 16;
bit_width = bit_width_with_sign - 1;
out_bit_width = 16;
DIGITAL_GAIN = round(2^bit_width/3.75); 
bandwith = 5;   % in MHz
check_sims_results = 0; % 1 gdy dane dla wyj?cia, 0 gdy tylko dla wejscia
 
% OFDM params %%%%%%%%%%%%%%%%%%%%%%%%%%
% MOD mode, 0,1,2 QPSK,16QAM,64QAM, random data used
for i=0:1
    MODULATION_MODE = 0;
    USE_RAND=1;
    N_FFT=2048;
    fs = bandwith/20 * 30.72e6
    sfo = 0; % sampling frequency offset [Hz]
    RATIO=1; % oversampling
    OFDM_N=floor(N_FFT); % full spectrum
    distance = 1;
    seed = i;
 
    ofdm_time_sym = zeros(1, N_FFT);
    [ofdm_time_sym rand2] = create_ofdm_sym(USE_RAND, N_FFT, RATIO, OFDM_N, MODULATION_MODE,distance,fs, seed);
    x=ofdm_time_sym;
    gain=DIGITAL_GAIN/max(abs(x));
    iqdata_out=round(gain.*x);
 
 
    iqdata_out=repmat(iqdata_out,1,50);
    if i == 0
        fid=fopen('ofdm_in_data_main.txt','w+');
    else 
        fid=fopen('ofdm_in_data_div.txt','w+');
    end
 
    for k=1:length(iqdata_out)
      fprintf(fid, '%d %d\n',real(iqdata_out(k)),imag(iqdata_out(k)));  
    end
    fclose(fid);
 
 
    figure(1+2*i);
    l1 = 1:length(iqdata_out);
    plot(l1, real(iqdata_out), 'r', l1, imag(iqdata_out), 'b');
 
    % rms1 = sqrt(mean(abs(iqdata_out).^2));
    % peak1 = max(abs(iqdata_out));
    % PAR1 = 20*log10(peak1/rms1);
    % fprintf('INPUT>> RMS = %2.1f dBFs, Crest factor = %2.2f dB, Peak = %2.1f dBFS\n', 20*log10(rms1/2^15), PAR1, 20*log10(peak1/2^15));
 
    %%%%%%%%%%%%%%%%%%%%
    %linespec = {'b.', 'r-', 'g--o'}; % define your ten linespecs in a cell array
    figure(2+2*i);
    %win1 = (blackman(length(iqdata_out)).');
    samples = 2048;
    l1 = 1:samples;
    win1 = ones(1,length(iqdata_out(l1)));
    fftr0 = fft(iqdata_out(l1)/2^bit_width.*win1)/length(iqdata_out(l1));
    fftra0 = 20*log10(abs(fftshift(fftr0)));
    faxis = (-samples/2:samples/2-1)*(fs/samples);
    plot(faxis,fftra0, 'r');
 
    if check_sims_results
        if i == 0
            fid=fopen('xil2_ul_ch_fir.sim\sim_1\behav\ofdm_out_data_main.txt','r+');
        else 
            fid=fopen('xil2_ul_ch_fir.sim\sim_1\behav\ofdm_out_data_div.txt','r+');
        end
        vec_mat = fscanf(fid, '%d %d', [2 Inf]);
        vecz = vec_mat(1,:)+1i.*vec_mat(2,:);
        vecz = vecz(500:end);
        fclose(fid);
 
        figure(5+2*i);
        l1 = 1:length(vecz);
        plot(l1, real(vecz), 'r', l1, imag(vecz), 'b');
 
        % rms1 = sqrt(mean(abs(vecz).^2));
        % peak1 = max(abs(vecz));
        % PAR1 = 20*log10(peak1/rms1);
        % fprintf('OUTPUT>> RMS = %2.1f dBFs, Crest factor = %2.2f dB, Peak = %2.1f dBFS\n', 20*log10(rms1/2^15), PAR1, 20*log10(peak1/2^15));
 
        %%%%%%%%%%%%%%%%%%%%
        %linespec = {'b.', 'r-', 'g--o'}; % define your ten linespecs in a cell array
        figure(6+2*i);
        %win1 = (blackman(length(vecz)).');
        samples = 2048;
        l1 = 1:samples;
        win1 = ones(1,length(vecz(l1)));
        fftr0 = fft(vecz(l1)/2^out_bit_width.*win1)/length(vecz(l1));
        fftra0 = 20*log10(abs(fftshift(fftr0)));
        faxis = (-samples/2:samples/2-1)*(fs/samples);
        plot(faxis,fftra0, 'r');
 
 
 
 
    end
end
 