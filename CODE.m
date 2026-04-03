% Amplitude Modulation - Super Heterodyne Receiver
% Author : Marwan Mobarak
% Date   : 4/3/2026

%% ====================== File Processing ================================
[y_t, Fs1] = audioread("Short_BBCArabic2.wav");
m_t = y_t(:,1) + y_t(:,2);                     % Stereo → Mono

[z_t, Fs2] = audioread("Short_FM9090.wav");
a_t = z_t(:,1) + z_t(:,2);                     % Stereo → Mono

Fs = max(Fs1, Fs2);                             % Use higher sampling rate
Ts = 1/Fs;

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
Fc_1 = 100000;                                  % Station 1: 100 kHz
Fc_2 = 130000;                                  % Station 2: 130 kHz
Bw_1 = 5000;                                    % Baseband BW station 1
Bw_2 = 5000;                                    % Baseband BW station 2


t    = (0 : max_length-1) * Ts;                 % Time vector

S1_t = m_t' .* cos(2*pi*Fc_1*t);               % DSB-SC: BBC @ 100 kHz
S2_t = a_t' .* cos(2*pi*Fc_2*t);               % DSB-SC: FM  @ 130 kHz
S_t  = S1_t + S2_t;                             % FDM composite signal

%% ======================== RF Stage =====================================
Fc_desired  = Fc_2;                             % Tune to Station 1
Bw_desired  = Bw_2;

fpass_RF    = [Fc_desired - Bw_desired, ...
               Fc_desired + Bw_desired];        % [92000, 108000] Hz
S_RF        = bandpass(S_t, fpass_RF, Fs);      % RF filtered signal

%% ======================== Mixer ========================================
F_IF        = 15000;                            % IF frequency: 15 kHz
F_osc       = Fc_desired + F_IF;               % Oscillator: 115 kHz
S_mixed     = S_RF .* cos(2*pi*F_osc*t);       % Shift 100kHz → 15kHz

%% ======================== IF Stage =====================================
fpass_IF    = [F_IF - Bw_desired, ...
               F_IF + Bw_desired];              % [7000, 23000] Hz
S_IF        = bandpass(S_mixed, fpass_IF, Fs); % ← FIXED: was fpass, now fpass_IF

%% ======================== Baseband Detection ===========================
S_BB        = S_IF .* cos(2*pi*F_IF*t);        % Shift 15kHz → 0Hz

d_lpf       = fdesign.lowpass(    ...
    'N,F3dB'          ,           ...           % Spec: order + 3dB cutoff
    6                 ,           ...           % Filter order
    Bw_desired/(Fs/2)             );            % Normalized cutoff

hLPF        = design(d_lpf, 'butter');          % Butterworth LPF
m_recovered = filter(hLPF, S_BB);              % Recovered message

%% ======================== Listen & Plot ================================
% Downsample to playable rate before sound()
Fs_play     = 44100;                            % Standard audio rate
m_play      = m_recovered(1:upsample_factor:end); % Decimate by 10
sound(m_play, Fs_play);                         % Play recovered audio

% Plot recovered signal spectrum
figure('Name','Recovered Signal','NumberTitle','off');
N   = length(m_recovered);
f   = (-N/2 : N/2-1) * (Fs/N);
plot(f, abs(fftshift(fft(m_recovered)))/N, 'g', 'LineWidth', 1.2);
xlabel('Frequency (Hz)'); ylabel('Magnitude');
title('Recovered Baseband Signal - BBC Arabic');
xlim([-15000 15000]); grid on;