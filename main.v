`timescale 1ns / 1ps


//audio port control, add this to constraints
//set_property -dict {PACKAGE_PIN N13 IOSTANDARD LVCMOS33} [get_ports {aud_dac_clk}]


module Final(
    input wire clk,         //100 MHz system clock
    input wire [15:0] sw,   //sw[15:4] for keys, sw[3:1] for songs, sw[0] wave tone
    input wire [3:0] btn,   //octave Controls
    output reg aud_dac_clk  //audio PWM output
);




    //sample tick (48 kHz) driver  


    //clk divider: 100e6 / 48e3 = 2083.333 (2083)
    reg [11:0] audio_div = 0;
    wire audio_tick = (audio_div == 2082);


    always @(posedge clk) begin
        if (audio_tick)
            audio_div <= 0;
        else
            audio_div <= audio_div + 1;
    end
module Final(
    input wire clk,         //100 MHz system clock
    input wire [15:0] sw,   //sw[15:4] for keys, sw[3:1] for songs, sw[0] wave tone
    input wire [3:0] btn,   //octave Controls
    output reg aud_dac_clk  //audio PWM output
);




    //sample tick (48 kHz) driver  
    //DDS note frequency local parameters
 
    localparam C4  = 43866;
    localparam Cs4 = 46512;
    localparam D4  = 49302;
    localparam Ds4 = 52153;
    localparam E4  = 55241;
    localparam F4  = 58604;
    localparam Fs4 = 62003;
    localparam G4  = 65785;
    localparam Gs4 = 69635;
    localparam A4  = 73728;
    localparam As4 = 77993;
    localparam B4  = 82899;
    localparam C5  = 87728;
    localparam E5  = 110480;
    localparam G5  = 131480;
    localparam A5  = 147456;
    localparam SILENCE = 0;






    //polyphonic keyboard logic
    wire [23:0] key_tuning_words [0:11];
    assign key_tuning_words[0]  = C4;
    assign key_tuning_words[1]  = Cs4;
    assign key_tuning_words[2]  = D4;
    assign key_tuning_words[3]  = Ds4;
    assign key_tuning_words[4]  = E4;
    assign key_tuning_words[5]  = F4;
    assign key_tuning_words[6]  = Fs4;
    assign key_tuning_words[7]  = G4;
    assign key_tuning_words[8]  = Gs4;
    assign key_tuning_words[9]  = A4;
    assign key_tuning_words[10] = As4;
    assign key_tuning_words[11] = B4;


    //octave shift buttons
    reg signed [2:0] octave_shift = 0;
    wire b0_pressed, b1_pressed, b2_pressed;


    ///button debounce apply
    Debounce db0 (clk, btn[0], b0_pressed);
    Debounce db1 (clk, btn[1], b1_pressed);
    Debounce db2 (clk, btn[2], b2_pressed);


    //octave shift 
    always @(posedge clk) begin
        if (b2_pressed) octave_shift <= 0;
        else if (b1_pressed && octave_shift < 2) octave_shift <= octave_shift + 1;
        else if (b0_pressed && octave_shift > -2) octave_shift <= octave_shift - 1;
    end


   
    //DDS phase accumulators for keys
    reg [23:0] key_phase [0:11];
    integer k;


    //changes each active key DDS phase accumulator w/octave shift
    always @(posedge clk) begin
        if (audio_tick) begin
            for (k = 0; k < 12; k = k + 1) begin
                if (sw[k+4])
                    key_phase[k] <= key_phase[k] +
                        (octave_shift >= 0 ?
                            (key_tuning_words[k] << octave_shift) :
                            (key_tuning_words[k] >> -octave_shift));
                else
                    key_phase[k] <= 0;
            end
        end
    end






    //DDS song player, sequenced notes
    reg [25:0] tempo_cnt = 0;
    reg [5:0]  note_index = 0;
    reg [23:0] song_freq = 0;
    wire song_active = sw[1] | sw[2] | sw[3];


    //step through defined notes
    always @(posedge clk) begin
        if (song_active) begin
            if (tempo_cnt >= 14_000_000) begin
                tempo_cnt <= 0;
                note_index <= note_index + 1;
                if (note_index > 31) note_index <= 0;
            end else
                tempo_cnt <= tempo_cnt + 1;
        end else begin
            tempo_cnt <= 0;
            note_index <= 0;
        end
    end


    //hard-coded songs
    always @(*) begin
        song_freq = SILENCE;
        //star wars theme
        if (sw[1]) begin
            case (note_index)
                0,1,2,3: song_freq = G4; 4,5,6,7: song_freq = G4; 
                8,9,10,11: song_freq = G4;
                12,13: song_freq = Ds4; 14,15: song_freq = As4; 
                16,17,18,19: song_freq = G4; 20,21: song_freq = Ds4; 
                22,23: song_freq = As4; 24,25,26,27: song_freq = G4;
            endcase
        end


        //super mario theme
        else if (sw[2]) begin
            case (note_index)
                0,1: song_freq = E5; 2,3: song_freq = E5; 
                4,5: song_freq = SILENCE; 6,7: song_freq = E5;
                8,9: song_freq = SILENCE; 10,11: song_freq = C5;
                12,13: song_freq = E5; 16,17,18,19: song_freq = G5;
                24,25,26,27: song_freq = G4;
            endcase
        end
        //twinkle twinkle little star
        else if (sw[3]) begin
            case (note_index)
                0,1,2,3: song_freq = C4; 4,5,6,7: song_freq = C4; 
                8,9,10,11: song_freq = G4; 12,13,14,15: song_freq = G4;
                16,17,18,19: song_freq = A4; 20,21,22,23: song_freq = A4;
                24,25,26,27: song_freq = G4;
            endcase
        end
    end


    reg [23:0] song_phase = 0;


    always @(posedge clk) begin
        if (audio_tick)
            song_phase <= song_phase + song_freq;
    end






    


    //audio mixer, keyboard/song audio sources into a single output sample based on switch
    reg [11:0] mixed_audio;
    integer m;


    always @(*) begin
        mixed_audio = 0;


        if (song_active) begin
            if (sw[0])
                mixed_audio = song_phase[23:16] * 4;
            else
                mixed_audio = song_phase[23] ? 12'd1000 : 0;
        end
        else begin
            for (m = 0; m < 12; m = m + 1) begin
                if (sw[m+4]) begin
                    if (sw[0])
                        mixed_audio = mixed_audio + (key_phase[m][23:16] >> 2);
                    else
                        mixed_audio = mixed_audio + (key_phase[m][23] ? 12'd255 : 0);
                end
            end
        end
    end




 
    //100 MHz PWM DAC
    reg [11:0] pwm_cnt = 0;
    always @(posedge clk) begin
        pwm_cnt <= pwm_cnt + 1;
        aud_dac_clk <= (mixed_audio > pwm_cnt);
    end


endmodule


//debounce module (definitions)
module Debounce(input clk, input btn_in, output reg pulse_out);
    reg [19:0] cnt;
    reg btn_sync_0, btn_sync_1, btn_state;
    always @(posedge clk) begin
        btn_sync_0 <= btn_in;
        btn_sync_1 <= btn_sync_0;
        pulse_out <= 0;
        if (btn_sync_1 != btn_state) begin
            cnt <= cnt + 1;
            if (cnt == 20'd1_000_000) begin
                btn_state <= btn_sync_1;
                cnt <= 0;
                if (btn_sync_1) pulse_out <= 1;
            end
        end else cnt <= 0;
    end
endmodule
