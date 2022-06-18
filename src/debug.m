clear all

music_path = ".\res\src\test.wav";
mp4_path = ".\res\input\src\"; % End with '\' for Windows and '/' for UNIX
mp4_num = 53; % The number of the mp4s.

% process bgm
[z, x, Fs, y1, y2, y3, y4, maxIdx, maxVal] = audio_process(music_path);

% plot parameter
x_grid_end = 12; % length(y1) / Fs;   % grid-x lim
plot_margin = 1.1;  % y-grid margin

figure(2);

subplot(6, 1, 1);
plot([1:length(x)]/Fs, x);
axis([0, x_grid_end, min(x(1 : 12 * Fs)) * plot_margin, max(x(1 : 12 * Fs)) * plot_margin]);

subplot(6, 1, 2);
plot([1:length(y1)]/Fs, y1);
axis([0, x_grid_end, 0, max(y1(1 : 12 * Fs)) * plot_margin]);

subplot(6, 1, 3);
plot([1:length(y2)]/Fs, y2);
axis([0, x_grid_end, 0, max(y2(1 : 12 * Fs)) * plot_margin]);

subplot(6, 1, 4);
plot([1:length(y3)]/Fs, y3);
axis([0, x_grid_end, min(y3(1 : 12 * Fs)) * plot_margin, max(y3(1 : 12 * Fs)) * plot_margin]);

subplot(6, 1, 5);
plot([1:length(y4)]/Fs, y4);
axis([0, x_grid_end, 0, max(y4(1 : 12 * Fs)) * plot_margin]);

subplot(6, 1, 6);
plot([1:length(y4)]/Fs, y4);
hold on
plot(maxIdx/Fs, maxVal, 'o');
axis([0, x_grid_end, 0, max(y4(1 : 12 * Fs)) * plot_margin]);

figure(5);
plot([1:length(z)]/Fs, z);
axis([0, x_grid_end, min(z(1 : 12 * Fs)), max(z(1 : 12 * Fs)) * plot_margin]);

% process mp4
z_mp4{mp4_num} = [0;0];
Fs_mp4(mp4_num) = 0;
x_mp4{mp4_num} = 0;
for i = 1 : mp4_num
    [z_mp4{i}, x_mp4{i}, Fs_mp4(i), ~, ~, ~, ~, ~, ~] = audio_process(mp4_path + string(i) + ".mp4");
end

time_mp4(mp4_num) = 0.0;  % Time of the mp4 vedios in seconds .
for i = 1 : length(z_mp4)
    time_mp4(i) = length(x_mp4{i}) / Fs_mp4(i);
end
average_time = mean(time_mp4);
average_time_in_bgm = round(average_time * Fs);

q_bgm(ceil(length(z) / average_time_in_bgm)) = 0;
q_idx = 1;
q_last_end = 0;
while q_last_end < length(x)
    q_bgm(q_idx) = norm(z(q_last_end + 1 : min(q_last_end + average_time_in_bgm, length(x))));
    q_last_end = q_last_end + average_time_in_bgm;
    q_idx = q_idx + 1;
end
q_bgm = q_bgm(1 : q_idx - 1);

p_mp4(mp4_num) = 0;
for i = 1 : mp4_num
    p_mp4(i) = norm(z_mp4{i});
end

[p, p_mp4_idx] = sort(p_mp4, 'descend');
[q, q_bgm_idx] = sort(q_bgm, 'descend');

figure(8)
plot(p);
figure(9)
plot(q);
figure(88)
plot(p_mp4);
figure(99)
plot(q_bgm);

% org_value:
% p: 220 | 290
% q: 130 | 200


