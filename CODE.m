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

%% ======================== AM Modulator (DSB-SC) ========================
Fc_1 = 100000;                                  % Station 1: 100 kHz
Fc_2 = 130000;                                  % Station 2: 130 kHz
Bw_1 = 8000;                                    % Baseband BW station 1
Bw_2 = 8000;                                    % Baseband BW station 2

t    = (0 : max_length-1) * Ts;                 % Time vector

modulated_signal_1 = m_t' .* cos(2*pi*Fc_1*t);               % DSB-SC: BBC @ 100 kHz
modulated_signal_2 = a_t' .* cos(2*pi*Fc_2*t);               % DSB-SC: FM  @ 130 kHz
Tx_signal          = modulated_signal_1 + modulated_signal_2;                             % FDM composite signal

%% ======================== RF Stage =====================================
Fc_desired           = Fc_1;                             % Tune to Station 1
Bw_desired           = Bw_1;

 fpass_RF            = [Fc_desired - Bw_desired Fc_desired + Bw_desired];        % [92000, 108000] Hz
 modulated_signal_RF = bandpass(Tx_signal, fpass_RF, Fs);     

%% ======================== Mixer ========================================
F_IF        = 15000;                            % IF frequency: 15 kHz
Offset      = 100 ;
F_lo        = Fc_desired + F_IF + Offset ;       % Oscillator: 115 kHz
S_mixed     = modulated_signal_RF .* cos(2*pi*F_lo*t);         % Shift 100kHz → 15kHz

%% ======================== IF Stage =====================================
fpass_IF            = [F_IF - Bw_desired, ...
                       F_IF + Bw_desired];              % [7000, 23000] Hz
modulated_signal_IF = bandpass(S_mixed, fpass_IF, Fs);

%% ======================== Baseband Detection ===========================
S_BB        = modulated_signal_IF .* cos(2*pi*F_IF*t);        % Shift 15kHz → 0Hz

d_lpf       = fdesign.lowpass(    ...
    'N,F3dB'          ,           ...           % Spec: order + 3dB cutoff
    6                 ,           ...           % Filter order
    Bw_desired/(Fs/2)             );            % Normalized cutoff

hLPF        = design(d_lpf, 'butter');          % Butterworth LPF
Rx_signal = filter(hLPF, S_BB);              % Recovered message

%% ======================== Listen & Plot ================================
% Downsample to playable rate before sound()
N1 = length(m_t);
f1 = (0:N1-1) * (Fs/N1);
N2 = length(a_t);
f2 = (0:N2-1) * (Fs/N2);
Fs_play     = 44100;                            % Standard audio rate
m_play      = Rx_signal(1:upsample_factor:end); % Decimate by 10
sound(m_play, Fs_play);                         % Play recovered audio

% Plot recovered signal spectrum
figure('Name','Recovered Signal','NumberTitle','off');
N   = length(Rx_signal);
f   = (-N/2 : N/2-1) * (Fs/N);
plot(f, abs(fftshift(fft(Rx_signal)))/N, 'g', 'LineWidth', 1.2);
xlabel('Frequency (Hz)'); ylabel('Magnitude');
title('Recovered Baseband Signal - BBC Arabic');
xlim([-15000 15000]); grid on;

%% --- 1. RF Stage Output ------------------------------------------------
figure('Name','RF Stage Output','NumberTitle','off');

N_rf  = length(modulated_signal_RF);
f_rf  = (-N_rf/2 : N_rf/2-1) * (Fs / N_rf);   % Two-sided frequency axis (Hz)
Y_rf  = abs(fftshift(fft(modulated_signal_RF))) / N_rf;        % Normalized magnitude spectrum

plot(f_rf, Y_rf, 'b', 'LineWidth', 1.4);
xlabel('Frequency (Hz)');
ylabel('Magnitude');
title('RF Stage Output Spectrum');
xlim([-200000 200000]);
ylim([0 max(Y_rf)*1.2]);
grid on;

% Mark the selected carrier on both sides
xline( Fc_desired, 'r--', sprintf('+Fc = %d kHz', Fc_desired/1000), ...
       'LabelVerticalAlignment', 'bottom', 'LineWidth', 1.5);
xline(-Fc_desired, 'r--', sprintf('-Fc = %d kHz', Fc_desired/1000), ...
       'LabelVerticalAlignment', 'bottom', 'LineWidth', 1.5);

legend('RF Output', 'Selected carrier');

%% --- 2. IF Stage Output ------------------------------------------------
figure('Name','IF Stage Output','NumberTitle','off');

N_if  = length(modulated_signal_IF);
f_if  = (-N_if/2 : N_if/2-1) * (Fs / N_if);   % Two-sided frequency axis (Hz)
Y_if  = abs(fftshift(fft(modulated_signal_IF))) / N_if;        % Normalized magnitude spectrum

plot(f_if, Y_if, 'r', 'LineWidth', 1.4);
xlabel('Frequency (Hz)');
ylabel('Magnitude');
title('IF Stage Output Spectrum');
xlim([-50000 50000]);
ylim([0 max(Y_if)*1.2]);
grid on;

% Mark the IF center frequency on both sides
xline( F_IF, 'b--', sprintf('+F_{IF} = %d kHz', F_IF/1000), ...
       'LabelVerticalAlignment', 'bottom', 'LineWidth', 1.5);
xline(-F_IF, 'b--', sprintf('-F_{IF} = %d kHz', F_IF/1000), ...
       'LabelVerticalAlignment', 'bottom', 'LineWidth', 1.5);

legend('IF Output', 'IF center frequency');

%% --- 3. Baseband Stage Output ------------------------------------------
figure('Name','Baseband Detection Output','NumberTitle','off');

N_bb  = length(Rx_signal);
f_bb  = (-N_bb/2 : N_bb/2-1) * (Fs / N_bb);   % Two-sided frequency axis (Hz)
Y_bb  = abs(fftshift(fft(Rx_signal))) / N_bb; % Normalized magnitude spectrum

plot(f_bb, Y_bb, 'g', 'LineWidth', 1.4);
xlabel('Frequency (Hz)');
ylabel('Magnitude');
title('Baseband Detection Output Spectrum (Recovered Message)');
xlim([-15000 15000]);
ylim([0 max(Y_bb)*1.2]);
grid on;

% Mark the bandwidth boundary
xline( Bw_desired, 'k--', sprintf('+Bw = %d kHz', Bw_desired/1000), ...
       'LabelVerticalAlignment', 'bottom', 'LineWidth', 1.5);
xline(-Bw_desired, 'k--', sprintf('-Bw = %d kHz', Bw_desired/1000), ...
       'LabelVerticalAlignment', 'bottom', 'LineWidth', 1.5);

legend('Recovered baseband', 'Bandwidth limit');
