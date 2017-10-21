function plotMusic(music_data)
    hold on;
    axis equal tight;
    ylim([-7, 7]);

    notes = real(music_data(1, :));
    durations = music_data(2, :);
    song_length = sum(durations);

    drawStaff(song_length);
    times = zeros(1, length(durations));
    times(1) = durations(1);
    for i = 2:length(durations)
        times(i) = durations(i) + times(i - 1);
    end
    times = times - durations(1);
    drawNote(times, durations, notes);
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

function drawNote(time, durations, pitch)
    [ypos, is_flat] = pitchToY(pitch);
    xpos = time + (1:length(time))*0.8;
%         for i = 1:length(time)
%             drawCircle([xpos(i), ypos(i)], 0.4, 1);
%         end

    for i = 1:length(time)
        scale = [0.7, 0.4];
        note_duration = durations(i);
        x_offset = 0;
        while note_duration >= 1
            longest_dur = 2^floor(log2(note_duration));
            actuallyDrawNote(xpos(i) + x_offset, ypos(i), scale, longest_dur, is_flat(i));

            note_duration = note_duration - longest_dur;
            x_offset = x_offset + longest_dur;
        end
    end   
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
end

function [ypos, is_flat] = pitchToY(pitch)
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
    xpos = pos(1) - 1;
    ypos = pos(2) + 0.2;
    scale = [0.2, 0.6];
    [img, map, alpha] = imread('Flat.png');
    h = image('CData', img, 'XData', [xpos - scale(1), xpos + scale(1)], 'YData', [ypos - scale(2), ypos + scale(2)]);
    set(h, 'AlphaData', alpha);
end