% Amplitude Modulation - Super Heterodyne Receiver
% Author : Marwan Mobarak
% Date   : 4/3/2026
%% ====================== File Processing ================================
[y_t, Fs1] = audioread("Short_BBCArabic2.wav");
m_t = y_t(:,1) + y_t(:,2);                     % Stereo → Mono
[z_t, Fs2] = audioread("Short_FM9090.wav");
a_t = z_t(:,1) + z_t(:,2);                     % Stereo → Mono
Fs = max(Fs1, Fs2);                             % Use higher sampling rate
clear y_t z_t Fs1 Fs2;
%% ====================== Zero Padding ===================================
max_length = max(length(m_t), length(a_t));
m_t = [m_t; zeros(max_length - length(m_t), 1)];  
a_t = [a_t; zeros(max_length - length(a_t), 1)];  
%% ====================== Upsampling =====================================
upsample_factor = 10;
m_t        = interp(m_t, upsample_factor);
a_t        = interp(a_t, upsample_factor);
Fs         = Fs * upsample_factor;              % 441000 Hz
Ts         = 1/Fs;
max_length = length(m_t);
%% =============== Plot Signals in Frequency Domain ======================
figure('Name','Frequency Domain - Messages','NumberTitle','off');
subplot(2,1,1);
N1 = length(m_t);
f1 = (0:N1-1) * (Fs/N1);
plot(f1(1:floor(N1/2)), abs(fft(m_t(1:floor(N1/2))))/N1, 'b', 'LineWidth', 1.2);
xlabel('Frequency (Hz)'); ylabel('Magnitude');
title(sprintf('BBC Arabic - Baseband Spectrum (Fs = %d Hz)', Fs));
xlim([0 10000]); grid on;
subplot(2,1,2);
N2 = length(a_t);
f2 = (0:N2-1) * (Fs/N2);
plot(f2(1:floor(N2/2)), abs(fft(a_t(1:floor(N2/2))))/N2, 'r', 'LineWidth', 1.2);
xlabel('Frequency (Hz)'); ylabel('Magnitude');
title(sprintf('FM 90.90 - Baseband Spectrum (Fs = %d Hz)', Fs));
xlim([0 10000]); grid on;
%% ======================== AM Modulator (DSB-SC) ========================
Fc_1 = 100000;                                  
Fc_2 = 130000;                                  
Bw_1 = 5000;                                    
Bw_2 = 5000;                                    
t    = (0 : max_length-1) * Ts;                 
S1_t = m_t' .* cos(2*pi*Fc_1*t);               
S2_t = a_t' .* cos(2*pi*Fc_2*t);               
S_t  = S1_t + S2_t;                             
%% ====================== initializing the loop ==========================
Freq_offset_LIST = [0, 0, 100, 1000];
Titles = {'1. Ideal Receiver', '2. No RF Stage (Image Interference)', ...
          '3. Freq Offset (0.1 kHz)', '4. Freq Offset (1 kHz)'};
for i = 1 : 4
    Freq_offset = Freq_offset_LIST(i);
    
    %% ======================== RF Stage =================================
    Fc_desired  = Fc_1;                             
    Bw_desired  = Bw_1;
    fpass_RF    = [Fc_desired - Bw_desired, Fc_desired + Bw_desired];        
    
    if i ~= 2  % If it's NOT the 2nd iteration, use the filter
        S_RF = bandpass(S_t, fpass_RF, Fs);  
    else       % If it IS the 2nd iteration, BYPASS the filter
        S_RF = S_t; 
    end
    %% ======================== Mixer ====================================
    F_IF        = 15000;                            
    F_osc       = Fc_desired + F_IF + Freq_offset;              
    S_mixed     = S_RF .* cos(2*pi*F_osc*t);       
    %% ======================== IF Stage ==================================
    fpass_IF    = [F_IF - Bw_desired, F_IF + Bw_desired];              
    S_IF        = bandpass(S_mixed, fpass_IF, Fs); 
    %% ======================== Baseband Detection ======================
    S_BB        = S_IF .* (2 * cos(2*pi*F_IF*t));        
    
    d_lpf       = fdesign.lowpass('N,F3dB', 6, Bw_desired/(Fs/2));
    hLPF        = design(d_lpf, 'butter');          
    m_recovered = filter(hLPF, S_BB);              
%% ======================== Listen & Plot ============================
    figure('Name', Titles{i}, 'NumberTitle', 'off'); % Dynamic Window Title
    
    % Setup frequency axis for all plots
    N   = length(m_recovered);
    f   = (-N/2 : N/2-1) * (Fs/N);
    
    % 1. Plot RF Stage Output (Centered at 100 kHz)
    subplot(3,1,1);
    plot(f, abs(fftshift(fft(S_RF)))/N, 'b', 'LineWidth', 1.2, 'DisplayName', 'RF Output');
    hold on;
    xline(Fc_desired, '--b', 'LineWidth', 1.2, 'DisplayName', 'RF center frequency');
    xline(-Fc_desired, '--b', 'LineWidth', 1.2, 'HandleVisibility', 'off'); % Hide from legend
    hold off;
    xlabel('Frequency (Hz)'); ylabel('Magnitude');
    title(['RF Stage Output - ', Titles{i}]);
    xlim([-150000 150000]); % Zoomed out to see the 100kHz and 130kHz carriers
    grid on; legend('show');
    
    % 2. Plot IF Stage Output (Centered at 15 kHz)
    subplot(3,1,2);
    plot(f, abs(fftshift(fft(S_IF)))/N, 'r', 'LineWidth', 1.2, 'DisplayName', 'IF Output');
    hold on;
    xline(F_IF, '--b', 'LineWidth', 1.2, 'DisplayName', 'IF center frequency');
    xline(-F_IF, '--b', 'LineWidth', 1.2, 'HandleVisibility', 'off'); % Hide from legend
    hold off;
    xlabel('Frequency (Hz)'); ylabel('Magnitude');
    title(['IF Stage Output - ', Titles{i}]);
    xlim([-30000 30000]); % Zoomed in to see the 15kHz IF signal
    grid on; legend('show');
    
    % 3. Plot Baseband Output (Centered at 0 Hz)
    subplot(3,1,3);
    plot(f, abs(fftshift(fft(m_recovered)))/N, 'g', 'LineWidth', 1.2, 'DisplayName', 'BB Output');
    hold on;
    xline(0, '--b', 'LineWidth', 1.2, 'DisplayName', 'BB center frequency (0 Hz)');
    hold off;
    xlabel('Frequency (Hz)'); ylabel('Magnitude');
    title(['Baseband Output - ', Titles{i}]);
    xlim([-15000 15000]); % Zoomed in to see the baseband audio
    grid on; legend('show');
    
    % Audio Playback
    Fs_play     = 44100;                            
    m_play      = m_recovered(1:upsample_factor:end); 
    
    disp(['Playing: ', Titles{i}]);
    sound(m_play, Fs_play);
    pause(length(m_play)/Fs_play + 1);
end