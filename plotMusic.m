function plotMusic(music_data)
    hold on;

    notes = music_data(1, :);
    for i = 1:length(notes)
        if abs(notes(i)) > 9999
            notes(i) = 1j;
        end
    end
    durations = music_data(2, :);
    song_length = sum(durations);
    if song_length > 35
        subplot(2,1,1);
        set(gca, 'xtick', [], 'ytick', [])%, 'xcolor', [1, 1, 1], 'ycolor', [1, 1, 1])
        hold on;
        %title('Crossing Field');
        drawStaff(song_length*1.8);
        subplot(2,1,2);
        set(gca, 'xtick', [], 'ytick', [])%, 'xcolor', [1, 1, 1], 'ycolor', [1, 1, 1])
        hold on;
    else
        subplot(1, 1, 1);
        hold on;
        drawStaff(song_length*3.5);
        set(gca, 'xtick', [], 'ytick', [])
    end
    drawStaff(song_length*1.8);
    times = zeros(1, length(durations));
    times(1) = durations(1);
    for i = 2:length(durations)
        times(i) = durations(i) + times(i - 1);
    end
    times = times - durations(1);
    if song_length > 35
        subplot(2,1,1);
    end
    ylim([-9,9]);
    drawNotes(times, durations, notes);
    ylim([-9,9]);
    %axis equal tight;
end

function drawStaff(song_length)
    y_buffer = 2;
    x_buffer = 2;

    line_x = [0 - x_buffer, song_length + x_buffer];
    line_y = [-5:-1, 1:5];
    for i = 1:10
        plot([line_x(1), line_x(2)], [line_y(i), line_y(i)], 'k', 'LineWidth', 0.75)
    end

    ylim([line_y(1) - y_buffer, line_y(end) + y_buffer]);
end

function drawNotes(time, durations, pitch)
    [ypos, is_flat] = pitchToY(pitch);
    xpos = time(1);
    x_offset = 0;

    for i = 1:length(time)
        if i==round(length(time)/2) && length(time) > 35
            subplot(2,1,2);
            x_offset = 0;
        end
        scale = [0.7, 0.4];
        note_duration = durations(i);
        while note_duration >= 1
            x_offset = x_offset + 0.7;
            longest_dur = 2^floor(log2(note_duration));
            longest_dur = longest_dur*2;
            if pitch(i) == 1i
                drawRest(xpos + x_offset, longest_dur);
            else
                actuallyDrawNote(xpos + x_offset, ypos(i), scale, longest_dur, is_flat(i));
            end
            note_duration = note_duration - longest_dur;
            if pitch(i)~=1i && note_duration > 0
                drawTie(xpos + x_offset, ypos(i), longest_dur);
            end
            x_offset = x_offset + 1.5*longest_dur;
        end
    end   
end

function drawRest(xpos, duration)
    ypos = 3;
    switch(duration)
        case 1
            [img, ~, alpha] = imread('SixteenthRest.png');
            scale = [.45,.8];
            xpos = xpos + 0;
            ypos = ypos + 0;
        case 2
            [img, ~, alpha] = imread('EigthRest.png');
            scale = [.4,.7];
            xpos = xpos + 0;
            ypos = ypos + 0;
        case 4
            [img, ~, alpha] = imread('QuarterRest.png');
            scale = [.5,1.3];
            xpos = xpos + 0;
            ypos = ypos + 0;
        case 8
            [img, ~, alpha] = imread('HalfRest.png');
            scale = [1,.3];
            xpos = xpos + 0;
            ypos = ypos + .24;
        case 16
            [img, ~, alpha] = imread('WholeRest.png');
            scale = [1,.3];
            xpos = xpos + 0;
            ypos = ypos - 0.24;
        otherwise
            return;
    end
    h = image('CData', img, 'XData', [xpos - scale(1), xpos + scale(1)], 'YData', [ypos - scale(2), ypos + scale(2)]);
    h2 = image('CData', img, 'XData', [xpos - scale(1), xpos + scale(1)], 'YData', [ypos - scale(2)-6, ypos + scale(2)-6]);
    set(h, 'AlphaData', alpha);
    set(h2, 'AlphaData', alpha);
end

function drawStem(pos, scale)
    scale = [scale(1)/8, 1.3];
    offset = [0.6, 1.2];
    xpos = pos(1) + offset(1);
    ypos = pos(2) + offset(2);

    [img, map, alpha] = imread('Stem.png');
    h = image('CData', img, 'XData', [xpos - scale(1), xpos + scale(1)], 'YData', [ypos - scale(2), ypos + scale(2)]);
    set(h, 'AlphaData', alpha);
end

function drawFlag(pos, scale);
    scale = [scale(1)*0.6, 1.1];
    offset = [1.1, 1.4];
    xpos = pos(1) + offset(1);
    ypos = pos(2) + offset(2);

    [img, map, alpha] = imread('Flag.png');
    h = image('CData', img, 'XData', [xpos - scale(1), xpos + scale(1)], 'YData', [ypos - scale(2), ypos + scale(2)]);
    set(h, 'AlphaData', alpha);
end

function actuallyDrawNote(xpos, ypos, scale, note_dur, is_flat)
    if note_dur == 16 || note_dur == 8
        [img, map, alpha] = imread('WholeNote.png');
    else
        [img, map, alpha] = imread('FilledHead.png');
    end
    h = image('CData', img, 'XData', [xpos - scale(1), xpos + scale(1)], 'YData', [ypos - scale(2), ypos + scale(2)]);
    set(h, 'AlphaData', alpha);

    if note_dur <= 8
        drawStem([xpos, ypos], scale);
    end

    if note_dur <= 2
        drawFlag([xpos, ypos], scale);
    end

    if note_dur <= 1
        drawFlag([xpos, ypos - 0.5], scale);
    end

    if is_flat
        drawFlat([xpos, ypos]);
    end
    
    len = 2;
    line_x = [xpos-len/2, xpos+len/2];    
    if ypos == 0
        line_y = [0, 0];
        plot([line_x(1), line_x(2)], [line_y(1), line_y(2)], 'k', 'LineWidth', 0.75)
    end
    if ypos >= 6
        for i = 1:floor(ypos-5)
            line_y = [i+5, i+5];
            plot([line_x(1), line_x(2)], [line_y(1), line_y(2)], 'k', 'LineWidth', 0.75)
        end
    end
    if ypos <= -6
        for i = 1:-1:ceil(ypos+5)
            line_y = [i-5, i-5];
            plot([line_x(1), line_x(2)], [line_y(1), line_y(2)], 'k', 'LineWidth', 0.75)
        end
    end
end

function drawTie(xpos, ypos, duration)
    scale = [duration+1,.8];
    xpos = xpos+.5;
    ypos = ypos-1.5;
    [img, ~, alpha] = imread('Tie.png');
    h = image('CData', img, 'XData', [xpos, xpos + scale(1)], 'YData', [ypos, ypos + scale(2)]);
    set(h, 'AlphaData', alpha);
end

function [ypos, is_flat] = pitchToY(pitch)
    pitch = real(pitch);
    pitch_from_c = pitch + 9;
    oct = floor(pitch_from_c/12);
    note = mod(pitch_from_c, 12) + 1;

    note_map = [0, 1, 1, 2, 2, 3, 4, 4, 5, 5, 6, 6];
    flat_map = [0, 1, 0, 1, 0, 0, 1, 0, 1, 0, 1, 0];
    height = note_map(note);

    ypos = height/2 + 3.5*oct;
    is_flat = flat_map(note);
end

function drawCircle(pos, rad, fill)
    xs = linspace(-rad, rad, 20);
    ys1 = sqrt(rad^2 - xs.^2) + pos(2);
    ys2 = -ys1 + 2*pos(2);
    xs = xs + pos(1);

    plot([xs], [ys1], 'k', 'LineWidth', 1.5);
    plot([xs], [ys2], 'k', 'LineWidth', 1.5);
end

function drawFlat(pos)
    xpos = pos(1) - 1.2;
    ypos = pos(2) + 0.4;
    scale = [0.4, 1.1];
    [img, map, alpha] = imread('Flat.png');
    h = image('CData', img, 'XData', [xpos - scale(1), xpos + scale(1)], 'YData', [ypos - scale(2), ypos + scale(2)]);
    set(h, 'AlphaData', alpha);
end