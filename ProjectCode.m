function ProjectCode()
    global SAMPLE_PERIOD PEAK_THRESHOLD VOLUME_THRESHOLD SUBDIVISIONS ...
        BEAT1_THRESHOLD DECAY BEAT_LENGTH SHEET_MUSIC;
    SAMPLE_PERIOD = 0.1; % Length of time that frequency is sampled over
    PEAK_THRESHOLD = 0.06; % Cutoff amplitude for peak detection
    VOLUME_THRESHOLD = 300; % Cutoff amplitude for note vs rest detection
    BEAT1_THRESHOLD = 0.1; % Cutoff amplitude for finding first note played
    SUBDIVISIONS = 2; % Number of subdivisions per beat
    DECAY = 1; % Expected decrease in note amplitude between samples
    BEAT_LENGTH = 15; % Number of extra data points to sample for beat finding
    SHEET_MUSIC = 0; % Desired output format
    
    clf;
    transcribe({'Fields.m4a'},...%,'TestData1.m4a','FastPiano.m4a',...
                ...%'LowPiano.m4a','Trombone.m4a','Trumpet.m4a',...
                ...%'Piccolo.m4a','Flute.m4a'},...
                {'Fields.txt'});
end

% Turn audio and accelerometer data into notes and rhythms
function transcribe(file, footfile)
    global SAMPLE_PERIOD SHEET_MUSIC;
    j = round((length(file)+1)/3);
    k = 1+(length(file)>1)+(length(file)>2);
    for i = 1:length(file)
        % Plot raw sound data
        subplot(j, k, i);
        hold on;
        [x, Fs] = audioread(cell2mat(file(i)));
        if ~SHEET_MUSIC
            plot((1:length(x))/Fs, x);
        end
        title(cell2mat(file(i)));
        
        % If no accel file, sample at regular intervals
        if i>length(footfile)
            regularIntervalPlot(x, Fs, SAMPLE_PERIOD);
            continue
        end
        
        % Find beats
        accel = parseSensorsRecordData(cell2mat(footfile(i)));
        accel = accel(120:end, :);
        t = accel(:,1)-accel(1,1);
        jz = conv(accel(:,4)-accel(1,4), [-1, 1], 'same');
        beats = t(getBeats(jz));
        beat1 = getBeat1(x)/Fs;
        beats = beats - beats(1) + beat1;
        if ~SHEET_MUSIC
            plot(beats, zeros(1,length(beats)), 'o');
        end
        
        % Find notes
        music_data = irregularIntervalPlot(x, Fs, SAMPLE_PERIOD, beats);
        real(music_data)
        if SHEET_MUSIC
            plotMusic(music_data);
        end
    end
end

% Plot the notes in an audio file sampled based on the given beats
function music_data = irregularIntervalPlot(x, Fs, period, beats)
    global SUBDIVISIONS SHEET_MUSIC;
    beats = interp1(beats, 1:1/SUBDIVISIONS:length(beats));
    notes = zeros(length(beats), 1);
    volumes = zeros(length(beats), 1);
    for i = 1:length(beats)
        if i<length(beats)
            t = beats(i)+(beats(i+1)-beats(i))/(SUBDIVISIONS*4);
        else
            t = beats(i)+(beats(i)-beats(i-1))/(SUBDIVISIONS*4);
        end
        notes(i) = getNote(getFrequency([t, t+period], x, Fs));
        volumes(i) = max(x(round(t*Fs)+1:round((t+period)*Fs)));
    end
    if ~SHEET_MUSIC
        plot(beats, real(notes), 'k.');
    end
    music_data = groupNotes(notes, volumes);
end

% Group notes that are the same pitch together
function output = groupNotes(notes, volumes)
    global DECAY;
    output = zeros(2,0);
    k = 1;
    for i = 1:length(notes)
        if i<k
            continue
        end
        duration = 1;
        for j = i+1:length(notes)
            if notes(i)==notes(j)
                if notes(i) == sqrt(-1) || (volumes(j)/volumes(i) < DECAY)
                    duration = duration + 1;
                end
            else
                break
            end
        end
        k = k + duration;
        output = cat(2, output, [notes(i); duration]);
    end
end

% Plot the notes in an audio file sampled at a regular interval
function regularIntervalPlot(x, Fs, period)
    notes = zeros(int16(length(x)/Fs/period)-2, 1);
    for i = 1:length(notes)
        t = i*period;
        notes(i) = getNote(getFrequency([t, t+period], x, Fs));
    end
    plot((1:length(notes))*period, real(notes), 'k.');
end

% Determine the frequency of audio data over a given time interval
function freq = getFrequency(interval, x, Fs)
    global PEAK_THRESHOLD VOLUME_THRESHOLD;
    t0 = round(interval(1)*Fs)+1;
    t1 = round(interval(2)*Fs)+1;
    period = interval(2)-interval(1);
    subx = x(t0:t1);
    fourier = (abs(fft(subx, round(length(subx)*2))));
    fourier_flipped = flip(fourier);
    [~, I] = firstPeak(fourier, PEAK_THRESHOLD);
    [~, I2] = firstPeak(fourier_flipped, PEAK_THRESHOLD);
    f = (I-1)*Fs/length(subx)/2;
    f2 = I2*Fs/length(subx)/2;
    freq = mean([f, f2]);
    
%     if(interval(1)>3 & interval(1)<3.1)
%         fx = linspace(-Fs/2, (Fs/2 - Fs/length(subx)), 2*length(subx));
%         plot(fx, fftshift(fourier));
%         length(fourier)
%         f
%         f2
%         return;
%     end
    if max(fourier)<VOLUME_THRESHOLD*period
        freq = 1i;
    end
end

% Find the first peak in a Fourier transform while ignoring overtones
function [peak, I] = firstPeak(data, threshold)
    [m, i] = max(data);
    data = data - mean(data(1:i));% - data(round(i*5/8));
    for j = 1:int16(0.6*i)
        if (data(j)>threshold*m) && (data(j+1)<data(j))
            for overtone = [6,4,3,2]
                if abs(i/j-overtone)<.1
                    peak = data(j);
                    I = i/overtone;
                    return
                end
            end
        end
    end
    peak = m;
    I = i;
end

% Determine the note given a frequency (i = rest)
function note = getNote(f)
    if f==1i
        note = f;
    else
        fA = f/440;
        note = round(12*log(fA)/log(2));
    end
end

% Determine the time indices of foot taps
function beats = getBeats(a)
    global BEAT1_THRESHOLD BEAT_LENGTH;
    beats = [];
    m = max(a);
    for i = 1:length(a)
        if isempty(beats) || (i-beats(end)) > BEAT_LENGTH
            if a(i) > m*BEAT1_THRESHOLD
                [~,j] = max(a(i:i+BEAT_LENGTH));
                beats = cat(1,beats,j+i);
            end
        end
    end
end

% Determine the time index of the first note played
function beat1 = getBeat1(x)
    global BEAT1_THRESHOLD BEAT_LENGTH;
    beat1 = 0;
    m = max(x);
    for i = 1:length(x)
        if x(i) > m*BEAT1_THRESHOLD
            [~,j] = max(x(i:i+BEAT_LENGTH));
            beat1 = j+i;
            return
        end
    end
end